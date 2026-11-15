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
  }
}

# Credentials and endpoint come from the environment (see README.md):
#   OVH_ENDPOINT, OVH_APPLICATION_KEY, OVH_APPLICATION_SECRET, OVH_CONSUMER_KEY
provider "ovh" {}

# CLOUDFLARE_API_TOKEN from the environment (see README.md).
provider "cloudflare" {}
