# modules/grafana/variables.tf
variable "network" {
  description = "Name of Docker network"
  type        = string
  default     = "monitoring_network"
}

variable "prometheus_url" {
  description = "Prometheus URL"
  type        = string
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  default     = "admin"
  sensitive   = true
}