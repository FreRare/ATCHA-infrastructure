# modules/grafana/main.tf
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}

resource "docker_image" "grafana" {
  name = "grafana/grafana:latest"
}

resource "docker_container" "grafana" {
  name  = "grafana"
  image = docker_image.grafana.image_id

  networks_advanced {
    name         = var.network
    ipv4_address = "172.33.0.5"
  }

  ports {
    internal = 3000
    external = 4000
  }

  env = [
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    "GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource"  # Optional plugins
  ]

  volumes {
    host_path      = "/workspace/grafana/provisioning"
    container_path = "/etc/grafana/provisioning"
  }
}