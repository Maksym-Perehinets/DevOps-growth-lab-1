# Client info 
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
  service_endpoints = ["Microsoft.KeyVault"]

  # To allow conncetion with web app services add delegation to Microsoft.Web/serverFarms
  delegation {
    name = "allow-web-app"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }

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
    bypass = "AzureServices"
    default_action = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.production.id]
  }
}

# #Default access policy for terraform service
# resource "azurerm_key_vault_access_policy" "terrafrom-access-policy" {
#   key_vault_id = azurerm_key_vault.main-kv.id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = data.azurerm_client_config.current.object_id

#   lifecycle {
#     create_before_destroy = true
#   }

#   key_permissions         = var.kv-key-permissions-full
#   secret_permissions      = var.kv-secret-permissions-full
# }


# Application Insights app declaretion
resource "azurerm_application_insights" "main-app-ins" {
  name                = "tf-production-appinsights"
  location            = azurerm_resource_group.BeStrong-rg.location
  resource_group_name = azurerm_resource_group.BeStrong-rg.name
  application_type    = "web"
}

# resource "azurerm_key_vault_secret" "AppInsights-InstKey-secret" {
#   # Secret for APPINSIGHTS_INSTRUMENTATIONKEY

#   name         = "tf-AppInsights-InstrumentationKey-${random_id.tf-RandomPrefix.hex}"
#   value        = azurerm_application_insights.main-app-ins.instrumentation_key
#   key_vault_id = azurerm_key_vault.main-kv.id
  
#   lifecycle {
#     ignore_changes = [value, version]
#   }
# }

# resource "azurerm_key_vault_secret" "ApplicationInsights-Connection-secret" {
#   # Secret for APPLICATIONINSIGHTS_CONNECTION_STRING

#   name         = "tf-ApplicationInsights-Connection-String-${random_id.tf-RandomPrefix.hex}"
#   value        = azurerm_application_insights.main-app-ins.connection_string
#   key_vault_id = azurerm_key_vault.main-kv.id

#   lifecycle {
#     ignore_changes = [value, version]
#   }
# }

# Storage account creation with endpoint and file share
resource "azurerm_storage_account" "file-share" {
  name                     = "storageaccountname"
  resource_group_name      = azurerm_resource_group.BeStrong-rg.name
  location                 = azurerm_resource_group.BeStrong-rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
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
  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.main-app-ins.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.main-app-ins.connection_string
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
  }
}

# Garant App service identety access to Key Vault
resource "azurerm_key_vault_access_policy" "AppService-conncetion" {
  key_vault_id = azurerm_key_vault.main-kv.id
  tenant_id = data.azurerm_client_config.current.tenant_id
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
  admin_enabled       = true
}

# Assign roles to app service to be able to pull and push images from ACR
resource "azurerm_role_assignment" "app-service-PullPush" {
  scope = azurerm_container_registry.acr-default.id
  role_definition_name = "AcrPush"
  principal_id = azurerm_linux_web_app.web-app.identity[0].principal_id
}

# MS sql db creation
resource "azurerm_mssql_server" "mssql-db" {
  name                         = "tf-MsSql-db-${random_id.tf-RandomPrefix.hex}"
  resource_group_name          = azurerm_resource_group.BeStrong-rg.name
  location                     = azurerm_resource_group.BeStrong-rg.location
  version                      = "12.0"

  administrator_login          = var.MSSQL-AdministratorLogin
  administrator_login_password = var.MSSQL-AdministratorPassword
}


# Private endpoint configuration to default subnet
resource "azurerm_private_endpoint" "mssql-db-PrivateEndpoint" {
  name                = "tf-MsSql-db-endpoint-${random_id.tf-RandomPrefix.hex}"
  resource_group_name = azurerm_resource_group.BeStrong-rg.name
  location            = azurerm_resource_group.BeStrong-rg.location
  subnet_id           = azurerm_subnet.production.id

  private_service_connection {
    name                           = "${random_id.tf-RandomPrefix.hex}-privateserviceconnection"
    private_connection_resource_id = azurerm_mssql_server.mssql-db.id
    subresource_names              = [azurerm_subnet.production.name]
    is_manual_connection           = false
  }
}

