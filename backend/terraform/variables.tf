# variables.tf

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ATCHA-backend"
}

variable "enable_app" {
  description = "Enable main application"
  type = bool
  default = true
}
variable "enable_frontend" {
  description = "Enable the frontend UI"
  type = bool
  default = true
}
variable "enable_prometheus" {
  description = "Enable prometheus metrics"
  type = bool
  default = true
}
variable "enable_grafana" {
  description = "Enable grafana server"
  type = bool
  default = true
}
variable "enable_graylog" {
  description = "Enable graylog server"
  type = bool
  default = false
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

variable "frontend_port" {
  description = "Port used by the frontend UI"
  type        = number
  default     = 3434
}

variable "frontend_build_target" {
  description = "Frontend Dockerfile target: 'prod' (static nginx bundle) or 'dev' (Expo dev server)"
  type        = string
  default     = "prod"
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