locals {
  #--------------------------------------------------------------------------------------------------
  # General variables
  #--------------------------------------------------------------------------------------------------
  prefix = "backend"

  # Clouds to deploy new APP
  csps = ["aws", "azure", "gcp"]

  #--------------------------------------------------------------------------------------------------
  # Github repo variables
  #--------------------------------------------------------------------------------------------------
  github_site      = "secdayforti"
  github_repo_name = "${local.prefix}-app"

  git_author_email = "secdayforti@gmail.com"
  git_author_name  = "secdayforti"

  #--------------------------------------------------------------------------------------------------
  # Github repo secrets
  #--------------------------------------------------------------------------------------------------
  # Docker repository details
  # - Necessary variable to point image to deploy first time
  # - Secrets to mapped to github to future image deployments
  dockerhub_username      = "jviguerasfortinet"
  dockerhub_image_name    = "vuln-flask-app"
  dockerhub_image_version = "v1"
  dockerhub_image_tag     = "${local.dockerhub_username}/${local.dockerhub_image_name}:${local.dockerhub_image_version}"

  dockerhub_secrets = {
    DOCKERHUB_TOKEN    = var.dockerhub_token
    DOCKERHUB_USERNAME = local.dockerhub_username
  }

  #--------------------------------------------------------------------------------------------------
  # K8S app details
  #--------------------------------------------------------------------------------------------------
  # variables used in deployment manifest
  app_name     = "backend"
  app_port     = "5000"
  app_nodeport = "30090"
  app_replicas = "1"

  #-----------------------------------------------------------------------------------------------------
  # AWS Route53
  #-----------------------------------------------------------------------------------------------------
  # AWS Route53 zone
  route53_zone_name = "securityday-demo.com"
  # AWS region to configure provider
  aws_region = {
    id  = "eu-west-1" //Ireland
    az1 = "eu-west-1a"
    az2 = "eu-west-1c"
  }
  #-----------------------------------------------------------------------------------------------------
  # FortiWEB Cloud
  #-----------------------------------------------------------------------------------------------------
  # Fortiweb Cloud template ID
  fwb_cloud_template = "b4516b99-3d08-4af8-8df7-00246da409cf"
  # FortiWEB Cloud regions where deploy
  fortiweb_region = {
    aws   = "eu-west-1"    // Ireland
    azure = "westeurope"   // Netherlands
    gcp   = "europe-west3" // Frankfurt
  }
  # FortiWEB Cloud platform names
  fortiweb_platform = {
    aws   = "AWS"
    azure = "Azure"
    gcp   = "GCP"
  }

  #--------------------------------------------------------------------------------------------------
  # FGT and K8S secrets
  #--------------------------------------------------------------------------------------------------
  # Import data from day0 
  fgt_values     = data.terraform_remote_state.day0.outputs.fgt_values
  k8s_values_cli = data.terraform_remote_state.day0.outputs.k8s_values_cli

  k8s_values = {
    aws   = module.get_k8s_values["aws"].results
    azure = module.get_k8s_values["azure"].results
    gcp   = module.get_k8s_values["gcp"].results
  }
}

#--------------------------------------------------------------------------------------------------
# Get data from day0 deployment and execute command to read K8S values
#--------------------------------------------------------------------------------------------------
# Get state file from day0 deployment
data "terraform_remote_state" "day0" {
  backend = "local"
  config = {
    path = "../day0_IaC_fortinet_k8s/terraform.tfstate"
  }
}
# Execute commmads to get K8S cluster data
module "get_k8s_values" {
  for_each = toset(local.csps)
  source   = "./modules/exec-command"

  commands = local.k8s_values_cli[each.value]
}