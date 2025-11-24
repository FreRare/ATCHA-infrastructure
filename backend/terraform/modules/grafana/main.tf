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

resource "docker_volume" "grafana_volume"{
  name = "grafana_volume"
}

resource "docker_volume" "grafana_provisioning" {
  name = "grafana_provisioning"
}

resource "docker_container" "grafana" {
  name  = "grafana"
  image = docker_image.grafana.image_id

  lifecycle {
    ignore_changes = [
      network_mode,
    ]
  }

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
    volume_name = docker_volume.grafana_provisioning.name
    container_path = "/etc/grafana/provisioning"
  }

  volumes {
    volume_name = docker_volume.grafana_volume.name
    container_path = "/var/lib/grafana"
  }
}