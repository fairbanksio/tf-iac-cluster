terraform {
  backend "remote" {
    organization = "Fairbanks-io"

    workspaces {
      name = "tf-iac-cluster"
    }
  }
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    cloudflare = {
      # Source is required for providers in other namespaces, to avoid ambiguity.
      source  = "cloudflare/cloudflare"
      version = "~> 2.11.0"
    }
    kubernetes = {
      # Source is required for providers in other namespaces, to avoid ambiguity.
      source  = "hashicorp/kubernetes"
      version = "~> 2.6.1"
    }
    helm = {
      # Source is required for providers in other namespaces, to avoid ambiguity.
      source  = "hashicorp/helm"
      version = "~> 2.4.1"
    }
  }
}