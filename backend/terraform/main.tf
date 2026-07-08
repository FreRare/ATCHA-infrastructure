# main.tf
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
  }
}
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Common network
resource "docker_network" "monitoring_network" {
  name   = "${var.project_name}-network"
  driver = "bridge"
  ipam_config {
    subnet  = "172.33.0.0/16"
    gateway = "172.33.0.1"
  }
  lifecycle {
    ignore_changes = [
      options,
      ipam_config,
    ]
  }
}

# App backend module
module "atcha_backend_app" {
  source = "./modules/ATCHA-backend/docker"

  app_port       = var.app_port
  container_name = var.project_name
  network        = docker_network.monitoring_network.name

  depends_on = [docker_network.monitoring_network]

  count = var.enable_app ? 1 : 0
}

# Frontend UI module
module "atcha_frontend_app" {
  source = "./modules/ATCHA-frontend/docker"

  app_port     = var.frontend_port
  network      = docker_network.monitoring_network.name
  build_target = var.frontend_build_target

  depends_on = [docker_network.monitoring_network]

  count = var.enable_frontend ? 1 : 0
}

module "prometheus" {
  source = "./modules/prometheus"

  network        = docker_network.monitoring_network.name
  atcha_app_name = module.atcha_backend_app[0].container_name

  depends_on = [docker_network.monitoring_network]

  count = var.enable_prometheus ? 1 : 0
}


# Grafana modul
module "grafana" {
  source = "./modules/grafana"

  network        = docker_network.monitoring_network.name
  prometheus_url = "http://prometheus:9090"

  depends_on = [docker_network.monitoring_network]

  count = var.enable_grafana ? 1 : 0
}

# Graylog modul
module "graylog" {
  source = "./modules/graylog"

  network                    = docker_network.monitoring_network.name
  graylog_password_secret    = var.graylog_password_secret
  graylog_root_password_sha2 = var.graylog_root_password_sha2

  depends_on = [docker_network.monitoring_network]

  count = var.enable_graylog ? 1 : 0
}

output "network_info" {
  value = {
    network_id   = docker_network.monitoring_network.id
    network_name = docker_network.monitoring_network.name
  }
}

variable "enabled_modules" {
  description = "Set of the loadable modules"
  type = set(string)
  default = ["atcha_backed_app", "prometheus", "grafana"]
}
