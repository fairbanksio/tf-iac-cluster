###
# Terraform Cloud
###

terraform {
  backend "remote" {
    organization = "Fairbanks-io"

    workspaces {
      name = "tf-iac-cluster"
    }
  }
}

