data "external" "commands" {
  for_each = var.commands
  program  = ["bash", "${path.module}/templates/exec_command.sh"]
  query = {
    key     = each.key
    command = each.value
  }
}

# Secrets key-pair
variable "commands" {
    type = map(string)
    default = null
}

output "results" {
  value     = {
    KUBE_CERTIFICATE = data.external.commands["KUBE_CERTIFICATE"].result["KUBE_CERTIFICATE"]
    KUBE_HOST        = data.external.commands["KUBE_HOST"].result["KUBE_HOST"]
    KUBE_TOKEN       = data.external.commands["KUBE_TOKEN"].result["KUBE_TOKEN"]
  }
}