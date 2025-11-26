# variables.tf

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ATCHA-backend"
}

variable "environment" {
  description = "Name of the used environment"
  type        = string
  default     = "dev"
}

variable "app_port" {
  description = "Port used by the application"
  type        = number
  default     = 3333
}

variable "sqlite_root_password" {
  description = "Password to the SQLite database used by the app"
  type        = string
  sensitive   = true
}

variable "graylog_password_secret" {
  description = "Graylog password secret"
  type        = string
  sensitive   = true
}

variable "graylog_root_password_sha2" {
  description = "Graylog root password SHA-256"
  type        = string
  sensitive   = true
}