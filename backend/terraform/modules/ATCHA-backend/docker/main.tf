# modules/ATCHA-backend/docker/main.tf
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}

# Application docker image
resource "docker_image" "ATCHA_app" {
  name = "atcha-backend:latest"
  build {
    context    = "../../../../"
    dockerfile = var.dockerfile_path
    tag = ["atcha-backend:latest"]
    no_cache   = true
  }
}

# Application docker container
resource "docker_container" "ATCHA_app" {
  count    = var.container_count
  name     = "${var.container_name}-${count.index + 1}"
  hostname = "${var.container_name}-${count.index + 1}"
  image = docker_image.ATCHA_app.image_id

  # Memory limit
  memory = var.memory_limit

  # Restart policy
  restart = var.restart_policy

  # Ports configuration
  ports {
    internal = var.app_port
    external = var.app_port + count.index
  }

  # Network settings
  networks_advanced {
    name         = var.network
    aliases = ["${var.container_name}-${count.index + 1}"]
    ipv4_address = "172.33.0.${20 + count.index}"
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