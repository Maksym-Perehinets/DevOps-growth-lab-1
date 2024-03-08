
resource "azurerm_resource_group" "tfstate-ResourceGroup" {
  name     = "tf-tfstate-ResourceGroup"
  location = var.location
}

resource "random_id" "tfstate-RandomStoragePrefix" {
  byte_length = 4
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstatestac${random_id.tfstate-RandomStoragePrefix.hex}"
  resource_group_name      = azurerm_resource_group.tfstate-ResourceGroup.name
  location                 = azurerm_resource_group.tfstate-ResourceGroup.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tf-tfstate-for-production"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}