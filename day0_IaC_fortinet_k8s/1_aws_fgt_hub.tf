#------------------------------------------------------------------------------
# Create HUB AWS
# - VPC FGT hub
# - config FGT hub (FGCP)
# - FGT hub
# - Create test instances in bastion subnet
#------------------------------------------------------------------------------
// Create VPC for hub
module "fgt_hub_vpc" {
  source = "git::github.com/jmvigueras/modules//aws/vpc-fgt-2az_tgw"

  prefix     = "${local.prefix}-hub"
  admin_cidr = local.fgt_admin_cidr
  admin_port = local.fgt_admin_port
  region     = local.aws_region

  vpc-sec_cidr = local.fgt_cidrs["aws"]

  tgw_id                = module.tgw.tgw_id
  tgw_rt-association_id = module.tgw.rt-vpc-sec-N-S_id
  tgw_rt-propagation_id = module.tgw.rt_vpc-spoke_id
}
// Create config for FGT hub (FGCP)
module "fgt_hub_config" {
  source = "git::github.com/jmvigueras/modules//aws/fgt-config"

  admin_cidr     = local.fgt_admin_cidr
  admin_port     = local.fgt_admin_port
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  api_key        = trimspace(random_string.api_key.result)

  subnet_active_cidrs  = module.fgt_hub_vpc.subnet_az1_cidrs
  subnet_passive_cidrs = module.fgt_hub_vpc.subnet_az1_cidrs
  fgt-active-ni_ips    = module.fgt_hub_vpc.fgt-active-ni_ips
  fgt-passive-ni_ips   = module.fgt_hub_vpc.fgt-passive-ni_ips

  fgt_active_extra-config  = join("\n", [data.template_file.aws_fgt_1_extra_config_api.rendered], [data.template_file.aws_fgt_1_extra_config_redis.rendered])
  fgt_passive_extra-config = join("\n", [data.template_file.aws_fgt_2_extra_config_api.rendered], [data.template_file.aws_fgt_2_extra_config_redis.rendered])

  config_fgcp = true
  config_hub  = true
  config_fmg  = true
  config_faz  = true

  fmg_ip = module.fmg.ni_ips["private"]
  faz_ip = module.faz.ni_ips["private"]
  hub    = local.hub

  vpc-spoke_cidr = tolist([module.fgt_hub_vpc.subnet_az1_cidrs["bastion"], local.nodes_cidr["aws"]])
}
# Create data template extra-config fgt
data "template_file" "aws_fgt_1_extra_config_api" {
  template = file("./templates/fgt_extra-config.tpl")
  vars = {
    external_ip   = module.fgt_hub_vpc.fgt-active-ni_ips["public"]
    mapped_ip     = local.master_ip["aws"]
    external_port = local.api_port
    mapped_port   = local.api_port
    public_port   = "port1"
    private_port  = "port2"
    suffix        = local.api_port
  }
}
data "template_file" "aws_fgt_2_extra_config_api" {
  template = file("./templates/fgt_extra-config.tpl")
  vars = {
    external_ip   = module.fgt_hub_vpc.fgt-passive-ni_ips["public"]
    mapped_ip     = local.master_ip["aws"]
    external_port = local.api_port
    mapped_port   = local.api_port
    public_port   = "port1"
    private_port  = "port2"
    suffix        = local.api_port
  }
}
data "template_file" "aws_fgt_1_extra_config_redis" {
  template = file("./templates/fgt_extra-config.tpl")
  vars = {
    external_ip   = module.fgt_hub_vpc.fgt-active-ni_ips["public"]
    mapped_ip     = local.master_ip["aws"]
    external_port = local.db_port
    mapped_port   = local.db_port
    public_port   = "port1"
    private_port  = "port2"
    suffix        = local.db_port
  }
}
data "template_file" "aws_fgt_2_extra_config_redis" {
  template = file("./templates/fgt_extra-config.tpl")
  vars = {
    external_ip   = module.fgt_hub_vpc.fgt-passive-ni_ips["public"]
    mapped_ip     = local.master_ip["aws"]
    external_port = local.db_port
    mapped_port   = local.db_port
    public_port   = "port1"
    private_port  = "port2"
    suffix        = local.db_port
  }
}

// Create FGT instances
module "fgt_hub" {
  source = "git::github.com/jmvigueras/modules//aws/fgt-ha"

  prefix        = "${local.prefix}-hub"
  region        = local.aws_region
  instance_type = local.fgt_instance_type["aws"]
  keypair       = aws_key_pair.keypair.key_name

  license_type = local.fgt_license_type
  fgt_build    = local.fgt_build

  fgt-active-ni_ids  = module.fgt_hub_vpc.fgt-active-ni_ids
  fgt-passive-ni_ids = module.fgt_hub_vpc.fgt-passive-ni_ids
  fgt_config_1       = module.fgt_hub_config.fgt_config_1
  fgt_config_2       = module.fgt_hub_config.fgt_config_2

  fgt_passive = local.fgt_passive
}
/*
// Create VM in bastion subnet
resource "aws_instance" "vm_fgt_hub" {
  depends_on                  = [module.faz, module.fmg]
  ami                         = "ami-0c06c45b5455eb326"
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.keypair.key_name
  get_password_data           = true
  subnet_id                   = module.fgt_hub_vpc.subnet_az1_ids["bastion"]
  vpc_security_group_ids      = [module.fgt_hub_vpc.nsg_ids["bastion"]]
  associate_public_ip_address = true

  user_data = base64encode(data.template_file.win_ps_script.rendered)

  tags = {
    Name    = "${local.prefix}-hub-vm"
    Project = local.prefix
  }
}

// Create windows script from template
data "template_file" "win_ps_script" {
  template = file("./templates/win_ps_script.tpl")
  vars = {
    github_token = var.github_token
    github_site  = local.github_site
  }
}
*/
#------------------------------------------------------------------------------
# Create TGW and VPC k8s nodes
#------------------------------------------------------------------------------
// Create TGW
module "tgw" {
  source = "git::github.com/jmvigueras/modules//aws/tgw"

  prefix = local.prefix

  tgw_cidr    = local.tgw_cidr
  tgw_bgp-asn = local.tgw_bgp-asn
}
#------------------------------------------------------------------------------
# Create FAZ and FMG
#------------------------------------------------------------------------------
// Create FAZ
module "faz" {
  source = "git::github.com/jmvigueras/modules//aws/faz"

  prefix         = "${local.prefix}-hub"
  region         = local.aws_region
  keypair        = aws_key_pair.keypair.key_name
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  api_key        = trimspace(random_string.api_key.result)

  license_type = "byol"
  license_file = "./licenses/licenseFAZ.lic"

  nsg_ids = {
    public  = [module.fgt_hub_vpc.nsg_ids["allow_all"]]
    private = [module.fgt_hub_vpc.nsg_ids["bastion"]]
  }
  subnet_ids = {
    public  = module.fgt_hub_vpc.subnet_az1_ids["public"]
    private = module.fgt_hub_vpc.subnet_az1_ids["bastion"]
  }
  subnet_cidrs = {
    public  = module.fgt_hub_vpc.subnet_az1_cidrs["public"]
    private = module.fgt_hub_vpc.subnet_az1_cidrs["bastion"]
  }
}
// Create FMG
module "fmg" {
  source = "git::github.com/jmvigueras/modules//aws/fmg"

  prefix         = "${local.prefix}-hub"
  region         = local.aws_region
  keypair        = aws_key_pair.keypair.key_name
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  api_key        = trimspace(random_string.api_key.result)

  license_type = "byol"
  license_file = "./licenses/licenseFMG.lic"

  nsg_ids = {
    public  = [module.fgt_hub_vpc.nsg_ids["allow_all"]]
    private = [module.fgt_hub_vpc.nsg_ids["bastion"]]
  }
  subnet_ids = {
    public  = module.fgt_hub_vpc.subnet_az1_ids["public"]
    private = module.fgt_hub_vpc.subnet_az1_ids["bastion"]
  }
  subnet_cidrs = {
    public  = module.fgt_hub_vpc.subnet_az1_cidrs["public"]
    private = module.fgt_hub_vpc.subnet_az1_cidrs["bastion"]
  }
}