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