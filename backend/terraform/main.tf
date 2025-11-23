# main.tf
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
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
}

# App backend module
module "ATCHA_backend_app" {
  source = "./modules/ATCHA-backend/docker"

  app_port       = var.app_port
  container_name = var.project_name
  network        = docker_network.monitoring_network.name

  depends_on = [docker_network.monitoring_network]
}

module "prometheus" {
  source = "./modules/prometheus"

  network        = docker_network.monitoring_network.name
  ATCHA_app_name = module.ATCHA_backend_app.container_name
}


# Grafana modul
module "grafana" {
  source = "./modules/grafana"

  network        = docker_network.monitoring_network.name
  prometheus_url = "http://prometheus:9090"
}

# Graylog modul
module "graylog" {
  source = "./modules/graylog"

  network                    = docker_network.monitoring_network.name
  graylog_password_secret    = var.graylog_password_secret
  graylog_root_password_sha2 = var.graylog_root_password_sha2
}

output "network_info" {
  value = {
    network_id   = docker_network.monitoring_network.id
    network_name = docker_network.monitoring_network.name
  }
}