# Remote state backend (Azure Storage). Value-free: coordinates are passed at
# init time via `terraform init -backend-config=...` (see infra-ci/infra-cd
# workflows) so nothing environment-specific is committed.

terraform {
  backend "azurerm" {
    use_oidc         = true
    use_azuread_auth = true
  }
}
