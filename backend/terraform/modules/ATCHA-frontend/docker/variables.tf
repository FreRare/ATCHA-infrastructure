variable "frontend_path" {
  description = "Path to the Expo frontend folder, relative to the terraform root working directory"
  type        = string
  default     = "../../../../frontend"
}

variable "dockerfile_path" {
  description = "Path to the frontend Dockerfile, relative to frontend_path"
  type        = string
  default     = "Dockerfile"
}

variable "build_target" {
  description = "Multi-stage Dockerfile target to build: 'prod' (static nginx bundle) or 'dev' (Expo dev server)"
  type        = string
  default     = "prod"
}

variable "container_name" {
  description = "Name of docker container"
  type        = string
  default     = "atcha-frontend"
}

variable "app_port" {
  description = "Port of the frontend app"
  type        = number
  default     = 3434
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "memory_limit" {
  description = "Memory limit in MB"
  type        = number
  default     = 1024  # 1 GB
}

variable "restart_policy" {
  description = "Restart policy"
  type        = string
  default     = "always"  # always, on-failure, unless-stopped
}

variable "healthcheck" {
  description = "Healthcheck settings"
  type = object({
    enabled      = bool
    test         = list(string)
    interval     = string
    timeout      = string
    retries      = number
    start_period = string
  })
  # nginx:alpine ships busybox wget (no curl), so probe with wget.
  default = {
    enabled      = true
    test         = ["CMD", "wget", "--spider", "-q", "http://172.33.0.21:3434/"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "40s"
  }
}

variable "network" {
  description = "Name of the docker network"
  type        = string
  default     = "atcha-sample-network"
}
