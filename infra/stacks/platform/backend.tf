# Remote state backend (Azure Storage). Value-free: coordinates are passed at
# init time via `terraform init -backend-config=...` (see infra-ci/infra-cd
# workflows) so nothing environment-specific is committed.
#
# Auth is keyless: use_oidc exchanges the CI OIDC token, and use_azuread_auth
# reaches the blob via Entra ID/RBAC (the "Storage Blob Data Contributor" grant
# from scripts/bootstrap-cicd-oidc.sh) instead of storage account access keys.

terraform {
  backend "azurerm" {
    use_oidc         = true
    use_azuread_auth = true
  }
}
