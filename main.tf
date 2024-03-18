#local 
locals {
  location = replace(lower(var.location), " ", "-")
}
# Client info test 
data "azurerm_client_config" "current" {}

# Resource group creation
resource "azurerm_resource_group" "BeStrong-rg" {
  name     = "tf-BeStrong-project"
  location = var.location
}

# Random hexidecimal
resource "random_id" "tf-RandomPrefix" {
  byte_length = 4
}

# VNet creation with defauld production VNet and subnet inside it
resource "azurerm_virtual_network" "production" {
  name                = "tf-production-network"
  location            = azurerm_resource_group.BeStrong-rg.location
  resource_group_name = azurerm_resource_group.BeStrong-rg.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "production" {
  name                 = "tf-production-subnet"
  resource_group_name  = azurerm_resource_group.BeStrong-rg.name
  virtual_network_name = azurerm_virtual_network.production.name
  address_prefixes     = ["10.10.1.0/24"]
  service_endpoints    = ["Microsoft.KeyVault"]

  # To allow conncetion with web app services add delegation to Microsoft.Web/serverFarms
  delegation {
    name = "allow-web-app"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "production-db" {
  name                                      = "tf-production-db-subnet"
  resource_group_name                       = azurerm_resource_group.BeStrong-rg.name
  virtual_network_name                      = azurerm_virtual_network.production.name
  address_prefixes                          = ["10.10.2.0/24"]
  private_endpoint_network_policies_enabled = true
}

# Key Vault creation
resource "azurerm_key_vault" "main-kv" {
  name                        = "tf-prodkeyvault-${random_id.tf-RandomPrefix.hex}"
  location                    = azurerm_resource_group.BeStrong-rg.location
  resource_group_name         = azurerm_resource_group.BeStrong-rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 30
  purge_protection_enabled    = false

  sku_name = "standard"

  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.production.id]
  }
}

# Application Insights app declaretion
resource "azurerm_application_insights" "main-app-ins" {
  name                = "tf-production-appinsights"
  location            = azurerm_resource_group.BeStrong-rg.location
  resource_group_name = azurerm_resource_group.BeStrong-rg.name
  application_type    = "web"
}

# Storage account creation with endpoint and file share
resource "azurerm_storage_account" "file-share" {
  name                     = "tffileshare${random_id.tf-RandomPrefix.hex}"
  resource_group_name      = azurerm_resource_group.BeStrong-rg.name
  location                 = azurerm_resource_group.BeStrong-rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

# Private endpoint configuration to default subnet for storage account
resource "azurerm_private_endpoint" "StorageAccount-PrivateEndpoint" {
  name                = "tf-StorageAccount-endpoint"
  resource_group_name = azurerm_resource_group.BeStrong-rg.name
  location            = azurerm_resource_group.BeStrong-rg.location
  subnet_id           = azurerm_subnet.production-db.id

  private_service_connection {
    name                           = "tf-StorageAccount-PrivateServiceConnection"
    private_connection_resource_id = azurerm_storage_account.file-share.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

# Service plan with service app declaretion. With additional key vault access policy set up
resource "azurerm_service_plan" "default" {
  name                = "tf-AppServicePlan-standart-BeStrong"
  location            = azurerm_resource_group.BeStrong-rg.location
  resource_group_name = azurerm_resource_group.BeStrong-rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "web-app" {
  name                      = "tf-web-app-${random_id.tf-RandomPrefix.hex}"
  resource_group_name       = azurerm_resource_group.BeStrong-rg.name
  location                  = azurerm_resource_group.BeStrong-rg.location
  service_plan_id           = azurerm_service_plan.default.id
  virtual_network_subnet_id = azurerm_subnet.production.id
  site_config {}
  identity {
    type = "SystemAssigned"
  }
  storage_account {
    access_key   = azurerm_storage_account.file-share.primary_access_key
    account_name = azurerm_storage_account.file-share.name
    name         = "fileshare"
    share_name   = "fileshare"
    type         = "AzureFiles"
    mount_path   = "/file-share"
  }

  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY             = azurerm_application_insights.main-app-ins.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING      = azurerm_application_insights.main-app-ins.connection_string
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
  }
}

# Garant App service identety access to Key Vault
resource "azurerm_key_vault_access_policy" "AppService-conncetion" {
  key_vault_id = azurerm_key_vault.main-kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.web-app.identity[0].principal_id
  key_permissions = [
    "Get",
    "Decrypt"
  ]
  secret_permissions = [
    "Get"
  ]
}

# Azure Container Registry creation
resource "azurerm_container_registry" "acr-default" {
  name                = "tfcontaineregistry${random_id.tf-RandomPrefix.hex}"
  resource_group_name = azurerm_resource_group.BeStrong-rg.name
  location            = azurerm_resource_group.BeStrong-rg.location
  sku                 = "Basic"
}

# Assign roles to app service to be able to pull and push images from ACR
resource "azurerm_role_assignment" "app-service-PullPush" {
  scope                = azurerm_container_registry.acr-default.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_linux_web_app.web-app.identity[0].principal_id
}

# MS sql db creation
# Server creation
resource "azurerm_mssql_server" "mssql-server" {
  name                = "mssql-server-prod-${local.location}-${random_id.tf-RandomPrefix.hex}"
  resource_group_name = azurerm_resource_group.BeStrong-rg.name
  location            = azurerm_resource_group.BeStrong-rg.location
  version             = "12.0"

  administrator_login          = var.MSSQL-AdministratorLogin
  administrator_login_password = var.MSSQL-AdministratorPassword
}
# DB creation
resource "azurerm_mssql_database" "db" {
  name      = "tf-mssql-db"
  server_id = azurerm_mssql_server.mssql-server.id
}


# Private endpoint configuration to default database designated subnet for ms sql
resource "azurerm_private_endpoint" "mssql-server-PrivateEndpoint" {
  name                = "tf-MsSql-db-endpoint"
  resource_group_name = azurerm_resource_group.BeStrong-rg.name
  location            = azurerm_resource_group.BeStrong-rg.location
  subnet_id           = azurerm_subnet.production-db.id

  private_service_connection {
    name                           = "tf-MsSql-PrivateServiceConnection"
    private_connection_resource_id = azurerm_mssql_server.mssql-server.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}
