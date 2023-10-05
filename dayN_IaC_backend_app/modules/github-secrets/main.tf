# Create secrets
resource "github_actions_secret" "github_secrets" {
  for_each        = var.secrets
  repository      = var.repository
  secret_name     = "${var.prefix}${each.key}"
  plaintext_value = each.value
}

# Secrets key-pair
variable "secrets" {
    type = map(string)
    default = null
}
# GitHub repository name
variable "repository" {
    type = string
    default = null
}

# GitHub repository name
variable "prefix" {
    type = string
    default = ""
}