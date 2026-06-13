# Remote state backend (Azure Storage). Stack/root level only.
#
# Do NOT put secrets here. Leave values to `terraform init -backend-config=...`
# or environment variables (ARM_* / OIDC) so nothing sensitive is committed.
# See references/backend-setup.md to bootstrap the storage account + container.

terraform {
  backend "azurerm" {
    # resource_group_name  = "rg-tfstate"
    # storage_account_name = "sttfstate<unique>"
    # container_name       = "tfstate"
    # key                  = "<env>/<stack>.tfstate"
    use_oidc = true
  }
}
