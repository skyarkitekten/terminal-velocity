terraform {
  required_version = "~> 1.12"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.6"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      # avm-ptn-aiml-ai-foundry 0.11.2 requires azurerm >= 4.38.
      version = "~> 4.38"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}
