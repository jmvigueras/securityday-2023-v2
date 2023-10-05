output "github_repo" {
  value = github_repository.repo.html_url
}

/* # -- Use it with 1_fwb_cloud_route53.tf.v2 -- #
output "app_url" {
  value = { for idx, csps in local.csps :
    local.csps[idx] => "http://${local.csps[idx]}-${local.app_name}.${data.aws_route53_zone.route53_zone.name}"
  }
}*/

output "app_url" {
    value = "http://${local.app_name}.${data.aws_route53_zone.route53_zone.name}"
}

/*# -- Use it with 1_fwb_cloud_route53.tf.v2 -- #
output "fw_cloud_url" {
  value = { for idx, csps in local.csps :
    local.csps[idx] => trimspace(data.local_file.fwb_cloud_app_cname[csps].content)
  }
}*/

output "fw_cloud_url" {
   value = trimspace(data.local_file.fwb_cloud_app_cname.content)
}

output "server_internal" {
  sensitive = true
  value = { for idx, csps in local.csps :
    local.csps[idx] => "${local.fgt_values[csps]["EXTERNAL_IP"]}:${local.app_nodeport}"
  }
}

output "server_public" {
  sensitive = true
  value = { for idx, csps in local.csps :
    local.csps[idx] => "${local.fgt_values[csps]["PUBLIC_IP"]}:${local.app_nodeport}"
  }
}