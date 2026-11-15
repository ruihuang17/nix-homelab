terraform {
  required_version = ">= 1.10"

  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.5"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.29"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.73"
    }
  }
}

# Credentials and endpoint come from the environment (see README.md):
#   OVH_ENDPOINT, OVH_APPLICATION_KEY, OVH_APPLICATION_SECRET, OVH_CONSUMER_KEY
provider "ovh" {}

# CLOUDFLARE_API_TOKEN from the environment (see README.md).
provider "cloudflare" {}

# AWS_ACCESS_KEY_ID in the environment is the OVH S3 key for the state
# backend, so the AWS provider gets its own credentials through variables.
provider "aws" {
  region     = "us-east-2"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}
