# modules/ATCHA-frontend/docker/main.tf
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
  }
}

# Frontend docker image
resource "docker_image" "atcha_frontend" {
  name = "atcha-frontend:latest"
  build {
    context    = var.frontend_path
    dockerfile = var.dockerfile_path
    target     = var.build_target
    tag        = ["atcha-frontend:latest"]
    no_cache   = true
  }
}

# Frontend docker container
resource "docker_container" "atcha_frontend" {
  name     = var.container_name
  hostname = var.container_name
  image    = docker_image.atcha_frontend.image_id

  lifecycle {
    ignore_changes = [
      network_mode,
    ]
  }

  # Memory limit
  memory = var.memory_limit

  # Restart policy
  restart = var.restart_policy

  # Ports configuration
  ports {
    internal = var.app_port
    external = var.app_port
  }

  # Network settings
  networks_advanced {
    name         = var.network
    aliases      = [var.container_name]
    ipv4_address = "172.33.0.21"
  }

  # Custom health check settings
  dynamic "healthcheck" {
    for_each = var.healthcheck.enabled ? [1] : []
    content {
      test         = var.healthcheck.test
      interval     = var.healthcheck.interval
      timeout      = var.healthcheck.timeout
      retries      = var.healthcheck.retries
      start_period = var.healthcheck.start_period
    }
  }
}

# Output to expose container_name
output "container_name" {
  value = var.container_name
}
