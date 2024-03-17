variable "location" {
  type        = string
  default     = "East US"
  description = "Location where all our resources are located"
}

variable "MSSQL-AdministratorLogin" {
  type        = string
  sensitive   = true
  description = "Administrator login for ms sql db"
}

variable "MSSQL-AdministratorPassword" {
  type        = string
  sensitive   = true
  description = "password for ms sql administrator"
}