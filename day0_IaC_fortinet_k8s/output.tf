#------------------------------------------------------------------------------
# FGT clusters
#------------------------------------------------------------------------------
output "aws_fgt_hub" {
  value = {
    fgt-1_mgmt   = "https://${module.fgt_hub.fgt_active_eip_mgmt}:${local.fgt_admin_port}"
    fgt-1_public = module.fgt_hub.fgt_active_eip_public
    username     = "admin"
    fgt-1_pass   = module.fgt_hub.fgt_active_id
    admin_cidr   = "${chomp(data.http.my-public-ip.response_body)}/32"
    api_key      = trimspace(random_string.api_key.result)
  }
}
output "azure_fgt" {
  value = {
    username     = local.fgt_admin["azure"]
    fgt-1_pass   = local.fgt_password["azure"]
    fgt-1_mgmt   = "https://${module.azure_fgt_vnet.fgt-active-mgmt-ip}:${local.fgt_admin_port}"
    fgt-1_public = module.azure_xlb.elb_public-ip
    api_key      = trimspace(random_string.api_key.result)
  }
}
output "gcp_fgt" {
  value = {
    fgt-1_mgmt   = "https://${module.gcp_fgt.fgt_active_eip_mgmt}:${local.fgt_admin_port}"
    username     = "admin"
    fgt-1_pass   = module.gcp_fgt.fgt_active_id
    fgt-1_public = module.gcp_fgt.fgt_active_eip_public
    api_key      = trimspace(random_string.api_key.result)
  }
}
/*
output "vm_fgt_hub" {
  value = {
    public_ip = aws_instance.vm_fgt_hub.public_ip
    username  = "Administrator"
    password  = fileexists("./ssh-key/${local.prefix}-ssh-key.pem") ? "${rsadecrypt(aws_instance.vm_fgt_hub.password_data, file("./ssh-key/${local.prefix}-ssh-key.pem"))}" : ""
  }
}
*/
#------------------------------------------------------------------------------
# Kubernetes cluster export config
#------------------------------------------------------------------------------
output "kubectl_config" {
  value = {
    aws = {
      command_1 = "export KUBE_HOST=${local.master_public_ip["aws"]}:${local.api_port}"
      command_2 = "export KUBE_TOKEN=$(redis-cli -h ${local.db_host_public_ip["aws"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["aws"]}_cicd-access_token)"
      command_3 = "redis-cli -h ${local.db_host_public_ip["aws"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["aws"]}_master_ca_cert | base64 --decode >${local.db_prefix["aws"]}_ca.crt"
      command_4 = "kubectl get nodes --token $KUBE_TOKEN -s https://$KUBE_HOST --certificate-authority ${local.db_prefix["aws"]}_ca.crt"
    }
    gcp = {
      command_1 = "export KUBE_HOST=${local.master_public_ip["gcp"]}:${local.api_port}"
      command_2 = "export KUBE_TOKEN=$(redis-cli -h ${local.db_host_public_ip["gcp"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["gcp"]}_cicd-access_token)"
      command_3 = "redis-cli -h ${local.db_host_public_ip["gcp"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["gcp"]}_master_ca_cert | base64 --decode >${local.db_prefix["gcp"]}_ca.crt"
      command_4 = "kubectl get nodes --token $KUBE_TOKEN -s https://$KUBE_HOST --certificate-authority ${local.db_prefix["gcp"]}_ca.crt"
    }
    azure = {
      command_1 = "export KUBE_HOST=${local.master_public_ip["azure"]}:${local.api_port}"
      command_2 = "export KUBE_TOKEN=$(redis-cli -h ${local.db_host_public_ip["azure"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["azure"]}_cicd-access_token)"
      command_3 = "redis-cli -h ${local.db_host_public_ip["azure"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["azure"]}_master_ca_cert | base64 --decode >${local.db_prefix["azure"]}_ca.crt"
      command_4 = "kubectl get nodes --token $KUBE_TOKEN -s https://$KUBE_HOST --certificate-authority ${local.db_prefix["azure"]}_ca.crt"
    }
  }
}
#------------------------------------------------------------------------------
# Kubernetes cluster nodes
#------------------------------------------------------------------------------
output "gcp_node_master" {
  value = module.gcp_node_master.vm
}
output "gcp_node_worker" {
  value = module.gcp_node_worker.*.vm
}
output "aws_node_master" {
  value = module.aws_node_master.vm
}
output "aws_node_worker" {
  value = module.aws_node_worker.*.vm
}
output "azure_node_master" {
  value = module.azure_node_master.vm
}
output "azure_node_worker" {
  value = module.azure_node_worker.*.vm
}
/*
output "aws_db" {
  value = module.aws_db.*.vm
}
*/
#------------------------------------------------------------------------------
# FMG and FAZ
#------------------------------------------------------------------------------
output "faz" {
  value = {
    faz_mgmt = "https://${module.faz.eip_public}"
    faz_pass = module.faz.id
  }
}
output "fmg" {
  value = {
    fmg_mgmt = "https://${module.fmg.eip_public}"
    fmg_pass = module.fmg.id
  }
}
#------------------------------------------------------------------------------
# FGT details 
#------------------------------------------------------------------------------
# FGT values
output "fgt_values" {
  sensitive = true
  value = {
    aws = {
      HOST        = "${module.fgt_hub.fgt_active_eip_mgmt}:${local.fgt_admin_port}"
      PUBLIC_IP   = module.fgt_hub.fgt_active_eip_public
      EXTERNAL_IP = module.fgt_hub_vpc.fgt-active-ni_ips["public"]
      MAPPED_IP   = element(module.aws_node_worker.*.vm, 0)["private_ip"]
      TOKEN       = trimspace(random_string.api_key.result)
    }
    azure = {
      HOST        = "${module.azure_fgt_vnet.fgt-active-mgmt-ip}:${local.fgt_admin_port}"
      PUBLIC_IP   = module.azure_xlb.elb_public-ip
      EXTERNAL_IP = module.azure_fgt_vnet.fgt-active-ni_ips["public"]
      MAPPED_IP   = element(module.azure_node_worker.*.vm, 0)["private_ip"]
      TOKEN       = trimspace(random_string.api_key.result)
    }
    gcp = {
      HOST        = "${module.gcp_fgt.fgt_active_eip_mgmt}:${local.fgt_admin_port}"
      PUBLIC_IP   = module.gcp_fgt.fgt_active_eip_public
      EXTERNAL_IP = module.gcp_fgt_vpc.fgt-active-ni_ips["public"]
      MAPPED_IP   = element(module.gcp_node_worker.*.vm, 0)["private_ip"]
      TOKEN       = trimspace(random_string.api_key.result)
    }
  }
}
#-----------------------------------------------------------------------------------------------------
# K8S Clusters (CLI commands to retrieve data from redis)
#-----------------------------------------------------------------------------------------------------
# Commands to get K8S clusters variables
output "k8s_values_cli" {
  sensitive = true
  value = {
    aws = {
      KUBE_TOKEN       = "redis-cli -h ${local.db_host_public_ip["aws"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["aws"]}_cicd-access_token"
      KUBE_HOST        = "echo ${local.master_public_ip["aws"]}:${local.api_port}"
      KUBE_CERTIFICATE = "redis-cli -h ${local.db_host_public_ip["aws"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["aws"]}_master_ca_cert"
    }
    azure = {
      KUBE_TOKEN       = "redis-cli -h ${local.db_host_public_ip["azure"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["azure"]}_cicd-access_token"
      KUBE_HOST        = "echo ${local.master_public_ip["azure"]}:${local.api_port}"
      KUBE_CERTIFICATE = "redis-cli -h ${local.db_host_public_ip["azure"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["azure"]}_master_ca_cert"
    }
    gcp = {
      KUBE_TOKEN       = "redis-cli -h ${local.db_host_public_ip["gcp"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["gcp"]}_cicd-access_token"
      KUBE_HOST        = "echo ${local.master_public_ip["gcp"]}:${local.api_port}"
      KUBE_CERTIFICATE = "redis-cli -h ${local.db_host_public_ip["gcp"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["gcp"]}_master_ca_cert"
    }
  }
}

