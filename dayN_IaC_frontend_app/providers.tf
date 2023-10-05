##############################################################################################################
# Terraform state
##############################################################################################################
terraform {
  required_version = ">= 0.12"
  required_providers {
    fortios = {
      source = "fortinetdev/fortios"
    }
  }
}
##############################################################################################################
# AWS Provider
##############################################################################################################
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = local.aws_region["id"]
  # Uncomment if using AWS SSO:
  # token      = var.token
}
##############################################################################################################
# Github provider
##############################################################################################################
provider "github" {
  token = var.github_token
}
##############################################################################################################
# FortiOS provider
##############################################################################################################
provider "fortios" {
  alias    = "aws"
  hostname = local.fgt_values["aws"]["HOST"]
  token    = local.fgt_values["aws"]["TOKEN"]
  insecure = "true"
}

provider "fortios" {
  alias    = "gcp"
  hostname = local.fgt_values["gcp"]["HOST"]
  token    = local.fgt_values["gcp"]["TOKEN"]
  insecure = "true"
}

provider "fortios" {
  alias    = "azure"
  hostname = local.fgt_values["azure"]["HOST"]
  token    = local.fgt_values["azure"]["TOKEN"]
  insecure = "true"
}