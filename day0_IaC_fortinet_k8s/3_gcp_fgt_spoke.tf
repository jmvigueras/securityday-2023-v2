#------------------------------------------------------------------------------------------------------------
# Create VPCs and subnets Fortigate
# - VPC for MGMT and HA interface
# - VPC for Public interface
# - VPC for Private interface  
#------------------------------------------------------------------------------------------------------------
module "gcp_fgt_vpc" {
  source = "git::github.com/jmvigueras/modules//gcp/vpc-fgt"

  region = local.gcp_region["id"]
  prefix = local.prefix

  vpc-sec_cidr = local.fgt_cidrs["gcp"]
}
#------------------------------------------------------------------------------------------------------------
# Create FGT cluster config
#------------------------------------------------------------------------------------------------------------
module "gcp_fgt_config" {
  source = "git::github.com/jmvigueras/modules//gcp/fgt-config"

  admin_cidr     = local.fgt_admin_cidr
  admin_port     = local.fgt_admin_port
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  api_key        = trimspace(random_string.api_key.result)

  subnet_cidrs       = module.gcp_fgt_vpc.subnet_cidrs
  fgt-active-ni_ips  = module.gcp_fgt_vpc.fgt-active-ni_ips
  fgt-passive-ni_ips = module.gcp_fgt_vpc.fgt-passive-ni_ips

  fgt_active_extra-config  = join("\n", [data.template_file.gcp_fgt_1_extra_config_api.rendered], [data.template_file.gcp_fgt_1_extra_config_redis.rendered])
  fgt_passive_extra-config = join("\n", [data.template_file.gcp_fgt_2_extra_config_api.rendered], [data.template_file.gcp_fgt_2_extra_config_redis.rendered])

  config_fgcp  = true
  config_spoke = true
  config_xlb   = true
  config_fmg   = true
  config_faz   = true

  ilb_ip = module.gcp_fgt_vpc.ilb_ip
  fmg_ip = module.fmg.ni_ips["private"]
  faz_ip = module.faz.ni_ips["private"]
  hubs   = local.hubs
  spoke  = local.gcp_spoke

  vpc-spoke_cidr = [local.nodes_cidr["gcp"]]
}
# Create data template extra-config fgt
data "template_file" "gcp_fgt_1_extra_config_api" {
  template = file("./templates/fgt_extra-config.tpl")
  vars = {
    external_ip   = module.gcp_fgt_vpc.fgt-active-ni_ips["public"]
    mapped_ip     = local.master_ip["gcp"]
    external_port = local.api_port
    mapped_port   = local.api_port
    public_port   = "port1"
    private_port  = "port2"
    suffix        = local.api_port
  }
}
data "template_file" "gcp_fgt_2_extra_config_api" {
  template = file("./templates/fgt_extra-config.tpl")
  vars = {
    external_ip   = module.gcp_fgt_vpc.fgt-passive-ni_ips["public"]
    mapped_ip     = local.master_ip["gcp"]
    external_port = local.api_port
    mapped_port   = local.api_port
    public_port   = "port1"
    private_port  = "port2"
    suffix        = local.api_port
  }
}
data "template_file" "gcp_fgt_1_extra_config_redis" {
  template = file("./templates/fgt_extra-config.tpl")
  vars = {
    external_ip   = module.gcp_fgt_vpc.fgt-active-ni_ips["public"]
    mapped_ip     = local.master_ip["gcp"]
    external_port = local.db_port
    mapped_port   = local.db_port
    public_port   = "port1"
    private_port  = "port2"
    suffix        = local.db_port
  }
}
data "template_file" "gcp_fgt_2_extra_config_redis" {
  template = file("./templates/fgt_extra-config.tpl")
  vars = {
    external_ip   = module.gcp_fgt_vpc.fgt-passive-ni_ips["public"]
    mapped_ip     = local.master_ip["gcp"]
    external_port = local.api_port
    mapped_port   = local.api_port
    public_port   = "port1"
    private_port  = "port2"
    suffix        = local.db_port
  }
}
#------------------------------------------------------------------------------------------------------------
# Create FGT cluster instances
#------------------------------------------------------------------------------------------------------------
module "gcp_fgt" {
  source = "git::github.com/jmvigueras/modules//gcp/fgt-ha"

  region = local.gcp_region["id"]
  prefix = local.prefix
  zone1  = local.gcp_region["zone1"]
  zone2  = local.gcp_region["zone2"]

  machine        = local.fgt_instance_type["gcp"]
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  gcp-user_name  = split("@", data.google_client_openid_userinfo.me.email)[0]
  license_type   = local.fgt_license_type

  subnet_names       = module.gcp_fgt_vpc.subnet_names
  fgt-active-ni_ips  = module.gcp_fgt_vpc.fgt-active-ni_ips
  fgt-passive-ni_ips = module.gcp_fgt_vpc.fgt-passive-ni_ips

  fgt_config_1 = module.gcp_fgt_config.fgt_config_1
  fgt_config_2 = module.gcp_fgt_config.fgt_config_2

  fgt_passive = true
}
#------------------------------------------------------------------------------------------------------------
# Create Internal and External Load Balancer
#------------------------------------------------------------------------------------------------------------
module "gcp_xlb" {
  source = "git::github.com/jmvigueras/modules//gcp/xlb"

  region = local.gcp_region["id"]
  prefix = local.prefix
  zone1  = local.gcp_region["zone1"]
  zone2  = local.gcp_region["zone2"]

  vpc_names             = module.gcp_fgt_vpc.vpc_names
  subnet_names          = module.gcp_fgt_vpc.subnet_names
  ilb_ip                = module.gcp_fgt_vpc.ilb_ip
  fgt_active_self_link  = module.gcp_fgt.fgt_active_self_link
  fgt_passive_self_link = module.gcp_fgt.fgt_passive_self_link[0]
}