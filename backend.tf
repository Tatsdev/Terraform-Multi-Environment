terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstatetatzsa"
    container_name       = "tfstate"

  }
}