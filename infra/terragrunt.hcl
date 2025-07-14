terraform {
  source = "./terraform"
}

locals {
  # Common variables
  project_name = "idc-ocr"
  environment  = "dev"
  region       = "us-east-1"
  
  # Common tags
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terragrunt"
  }
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = var.common_tags
  }
}
EOF
}

# Configure Terragrunt to automatically init and apply
inputs = {
  project_name = local.project_name
  environment  = local.environment
  aws_region   = local.region
  common_tags  = local.common_tags
} 