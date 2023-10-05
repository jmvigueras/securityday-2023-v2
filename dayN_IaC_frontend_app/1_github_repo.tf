#-----------------------------------------------------------------------------------------------------
# Create Github repo and actions secret
#-----------------------------------------------------------------------------------------------------
# Create new repository in Github
resource "github_repository" "repo" {
  name        = local.github_repo_name
  description = "An example repository created using Terraform"
}
# Create K8S master secrets
module "k8s_secrets" {
  depends_on = [github_repository.repo]
  for_each   = toset(local.csps)
  source     = "./modules/github-secrets"

  prefix     = "${upper(each.value)}_"
  repository = github_repository.repo.name
  secrets    = local.k8s_values[each.value]
}
# Create dockers secrets
module "docker_secrets" {
  depends_on = [github_repository.repo]
  source     = "./modules/github-secrets"

  repository = github_repository.repo.name
  secrets    = local.dockerhub_secrets
}
#-----------------------------------------------------------------------------------------------------
# Update local repo-content
#-----------------------------------------------------------------------------------------------------
# Create Github actions workflow from template
data "template_file" "github_actions_workflow" {
  template = file("./templates/github-actions-workflow.tpl")
  vars = {
    deploy_k8s = join("\n", data.template_file.github_actions_workflow_k8s.*.rendered)
  }
}
data "template_file" "github_actions_workflow_k8s" {
  count    = length(local.csps)
  template = file("./templates/github-actions-workflow_k8s.tpl")
  vars = {
    dockerhub_username   = local.dockerhub_username
    dockerhub_image_name = local.dockerhub_image_name
    app_name             = local.app_name
    prefix               = "${upper(local.csps[count.index])}_"
  }
}

resource "local_file" "github_actions_workflow" {
  content  = data.template_file.github_actions_workflow.rendered
  filename = "./repo-content/.github/workflows/main.yaml"
}
# Create k8s manifest from template
data "template_file" "k8s_manifest_deployment" {
  template = file("./templates/k8s-deployment.tpl")
  vars = {
    app_name            = local.app_name
    app_port            = local.app_port
    app_nodeport        = local.app_nodeport
    app_replicas        = local.app_replicas
    dockerhub_image_tag = local.dockerhub_image_tag
  }
}
resource "local_file" "k8s_manifest_deployment" {
  content  = data.template_file.k8s_manifest_deployment.rendered
  filename = "./repo-content/manifest/app-deployment.yaml"
}
# Create file for FortiDevSec manifest from template
data "template_file" "fdevsec_file" {
  template = file("./templates/fdevsec.yaml.tpl")
  vars = {
    devsc_org = var.devsc_org
    devsc_app = var.devsc_app
    # app_url   = "http://${local.fgt_values[local.csp]["PUBLIC_IP"]}:${local.app_nodeport}"
  }
}
resource "local_file" "fdevsec_file" {
  content  = data.template_file.fdevsec_file.rendered
  filename = "./repo-content/fdevsec.yaml"
}
#-----------------------------------------------------------------------------------------------------
# Upload content to new repo
#-----------------------------------------------------------------------------------------------------
# Upload content to new repo
resource "null_resource" "upload_repo_code" {
  depends_on = [github_repository.repo, module.k8s_secrets, module.docker_secrets, local_file.github_actions_workflow]
  provisioner "local-exec" {
    command = "cd ./repo-content && rm -rf .git && git init && git add . && git commit -m 'first commit' && git branch -M master && git remote add origin https://${var.github_token}@github.com/${local.github_site}/${local.github_repo_name}.git && git push -u origin master"
    environment = {
      GIT_AUTHOR_EMAIL = local.git_author_email
      GIT_AUTHOR_NAME  = local.git_author_name
    }
  }
}