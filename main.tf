# The configuration for the `remote` backend.
terraform {
  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "Fairbanks-io"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "k8s-prod-us-sfo"
    }
  }
}