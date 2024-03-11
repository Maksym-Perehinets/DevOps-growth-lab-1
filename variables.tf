variable "location" {
  type        = string
  default     = "East US"
  description = "Location where all our resources are located"
}

variable "MSSQL-AdministratorLogin" {
  type        = string
  description = "Administrator login for ms sql db"
}

variable "MSSQL-AdministratorPassword" {
  type        = string
  description = "password for ms sql administrator"
}





# variable "kv-key-permissions-full" {
#   type        = list(string)
#   description = "List of full key permissions, must be one or more from the following: backup, create, decrypt, delete, encrypt, get, import, list, purge, recover, restore, sign, unwrapKey, update, verify and wrapKey."
#   default = ["Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge",
#   "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey"]
# }

# variable "kv-secret-permissions-full" {
#   type        = list(string)
#   description = "List of full secret permissions, must be one or more from the following: backup, delete, get, list, purge, recover, restore and set"
#   default     = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
# }

# variable back_end_ResourceGroup {
#   type        = string
#   description = "Resource group which holds our backend account and container"
# }

# variable back_end_StorageAccount {
#   type        = string
#   description = "Storage account where our backen tfstate file is stored"

#   validation {
#     condition     = length(var.back_end_StorageAccount) > 3 && length(var.back_end_StorageAccount) <= 24
#     error_message = "Valid Storage account name must be longer then 3 symbols and shorter than 24"
#   }
# }

# variable back_end_StorageContainer {
#   type        = string
#   description = "Storage account where our backen tfstate file is stored"

#   validation {
#     condition     = length(var.back_end_StorageContainer) > 3 && length(var.back_end_StorageContainer) <= 63
#     error_message = "Valid Storage container name must be longer then 3 symbols and shorter than 63"
#   }
# }