# modules/prometheus/main.tf
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}

resource "docker_volume" "prometheus_data"{
  name = "prometheus_data"
}

resource "docker_image" "prometheus" {
  name = "custom-prometheus:latest"
  build {
    context    = "."
    dockerfile = "Dockerfile_prometheus"
    no_cache   = true
  }
}

resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = docker_image.prometheus.image_id

  lifecycle {
    ignore_changes = [
      network_mode,
    ]
  }

  ports {
    ip       = "0.0.0.0"
    internal = 9090
    external = 9090
  }

  networks_advanced {
    name         = var.network
    ipv4_address = "172.33.0.6"
  }

  volumes{
    volume_name = docker_volume.prometheus_data.name
    container_path = "/prometheus"
  }
}