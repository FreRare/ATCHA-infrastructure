variable "ATCHA_path" {
  description = "Path to the rust app folder if this submodule is loaded to the project folder"
  type        = string
  default     = "../../../../"
}

variable "dockerfile_path" {
  description = "Path to the rust app docker file if this submodule is loaded to the project folder"
  type        = string
  default     = "../../../../Dockerfile"
}

variable "container_name" {
  description = "Name of docker container"
  type        = string
  default     = "ATCHA-backend"
}

variable "app_port" {
  description = "Port of the app"
  type        = number
  default     = 3333
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "container_count" {
  description = "Number of containers to start"
  type        = number
  default     = 1
}

variable "memory_limit" {
  description = "Memory limit in MB"
  type        = number
  default     = 2048  # 2 GB
}

variable "restart_policy" {
  description = "Restart policy"
  type        = string
  default     = "unless-stopped"  # always, on-failure, unless-stopped
}

variable "healthcheck" {
  description = "Healthcheck settings"
  type = object({
    enabled      = bool
    test = list(string)
    interval     = string
    timeout      = string
    retries      = number
    start_period = string
  })
  default = {
    enabled      = true
    test = ["CMD", "curl", "-f", "http://172.33.0.20:33333/healthcheck"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "40s"
  }
}

variable "network" {
  description = "Name of the docker network"
  type        = string
  default     = "ATCHA-sample-network"
}
