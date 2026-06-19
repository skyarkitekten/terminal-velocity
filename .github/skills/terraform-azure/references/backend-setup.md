# Bootstrapping the remote state backend

The `azurerm` backend needs an Azure Storage account and container to exist
**before** `terraform init`. This is a one-time, per-subscription bootstrap that
isn't managed by the stacks that consume it (chicken-and-egg). Run it once, then
reuse the backend for every stack via `key`.

## What you create

- A dedicated resource group for state (e.g. `rg-tfstate`).
- A Storage account with versioning + soft delete (recover bad applies).
- A blob container (e.g. `tfstate`).
- RBAC so CI (via OIDC / managed identity) can read/write state — grant
  **Storage Blob Data Contributor** on the account, not account keys.

## CLI bootstrap

```bash
# Variables — pick a globally-unique storage account name (3-24 lowercase/digits).
LOCATION="westeurope"
RG="rg-tfstate"
SA="sttfstate$RANDOM"          # must be globally unique
CONTAINER="tfstate"

az group create --name "$RG" --location "$LOCATION"

az storage account create \
  --name "$SA" \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Enable blob versioning + soft delete for state recovery.
az storage account blob-service-properties update \
  --account-name "$SA" \
  --resource-group "$RG" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 30

# Create the container using your Entra identity (no account keys).
az storage container create \
  --name "$CONTAINER" \
  --account-name "$SA" \
  --auth-mode login

echo "backend storage_account_name = $SA"
```

## Wire it to a stack

Fill in `assets/backend.tf` (or pass via `-backend-config`):

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstateXXXXX"
    container_name       = "tfstate"
    key                  = "dev/network.tfstate"  # unique per env + stack
    use_oidc             = true
    use_azuread_auth     = true
  }
}
```

Or keep `backend.tf` value-free and init per environment:

```bash
terraform init \
  -backend-config="resource_group_name=rg-tfstate" \
  -backend-config="storage_account_name=sttfstateXXXXX" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev/network.tfstate"
```

## Authentication

- **CI**: authenticate with OIDC (`use_oidc = true`, `use_azuread_auth = true`)
  and set `ARM_CLIENT_ID`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID` — no client
  secrets, no storage keys.
- **Local**: `az login`; the backend uses your Entra credentials with
  `use_azuread_auth`/`use_oidc`. Avoid `ARM_ACCESS_KEY`.

## Notes

- Use one container with a per-env/per-stack `key`, or separate containers per
  environment — be consistent and document the choice.
- State contains secrets in plaintext. Lock down RBAC, enable encryption at rest
  (default), and never expose the account publicly.
