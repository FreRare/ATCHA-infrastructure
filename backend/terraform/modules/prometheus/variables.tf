# modules/prometheus/variables.tf
variable "network" {
  description = "Name of Docker network"
  type        = string
}

variable "ATCHA_app_name" {
  description = "Name of the ATCHA application"
  type        = string
}


variable "app_port" {
  description = "App port"
  type        = number
  default     = 3333
}