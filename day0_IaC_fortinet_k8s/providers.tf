#--------------------------------------------------------------------------
# Terraform providers
#--------------------------------------------------------------------------
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = local.aws_region["id"]
}
provider "google" {
  project      = var.project
  region       = local.gcp_region["id"]
  zone         = local.gcp_region["zone1"]
  access_token = var.token
}
provider "google-beta" {
  project      = var.project
  region       = local.gcp_region["id"]
  zone         = local.gcp_region["zone1"]
  access_token = var.token
}
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}


##############################################################################################################
# Providers variables
############################################################################################################### 
// AWS configuration
variable "access_key" {}
variable "secret_key" {}
// Azure configuration
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
// GCP configuration
variable "project" {}
variable "token" {}