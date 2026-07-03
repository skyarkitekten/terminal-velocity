terraform {
  # avm-res-storage-storageaccount 0.7.2 requires >= 1.10; ~> 1.9 (>= 1.9, <
  # 2.0) already satisfies that, matching the convention used elsewhere.
  required_version = "~> 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
