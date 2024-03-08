variable location {
  type        = string
  default     = "East US"
  description = "Location where all our resources are located"
}

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