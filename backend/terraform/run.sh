# Use terraform in containerized mode
alias terraform='docker run -it --rm -v "$PWD":/workspace -v /var/run/docker.sock:/var/run/docker.sock -w /workspace hashicorp/terraform:light'

# Initialization
terraform init

# Check modifications (IaC)
terraform plan

# Build infrastructure
terraform apply

# Stop infrastructure
terraform destroy