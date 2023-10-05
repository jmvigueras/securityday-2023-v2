locals {
  #-----------------------------------------------------------------------------------------------------
  # General variables
  #-----------------------------------------------------------------------------------------------------
  prefix = "sec-day"

  # Clouds to deploy
  csps = ["aws", "azure", "gcp"]

  tags = {
    Deploy  = "sec-day"
    Project = "platform-engineering"
  }
  aws_region = {
    id  = "eu-west-3" // Paris
    az1 = "eu-west-3a"
    az2 = "eu-west-3c"
  }
  gcp_region = {
    id    = "europe-west4" // Netherlands
    zone1 = "europe-west4-a"
    zone2 = "europe-west4-c"
  }
  azure_location                 = "francecentral" // Amsterdam
  azure_resource_group_name      = null            // a new resource group will be created if null
  azure_storage-account_endpoint = null            // a new resource group will be created if null

  #-----------------------------------------------------------------------------------------------------
  # FGT Clusters
  #-----------------------------------------------------------------------------------------------------
  fgt_admin_port = "8443"
  //fgt_admin_cidr   = "${chomp(data.http.my-public-ip.response_body)}/32"
  fgt_admin_cidr   = "0.0.0.0/0"
  fgt_license_type = "payg"
  fgt_build        = "build1517"
  fgt_version      = "7.2.5"
  fgt_instance_type = {
    aws   = "c6i.large"
    azure = "Standard_F4s"
    gcp   = "n1-standard-4"
  }
  fgt_cidrs = {
    aws   = "172.20.0.0/24"
    azure = "172.25.0.0/24"
    gcp   = "172.30.0.0/23"
  }
  fgt_admin = {
    azure = "azureadmin"
  }
  fgt_password = {
    azure = "Terraform123#"
  }
  fgt_passive = false
  #-----------------------------------------------------------------------------------------------------
  # K8S Clusters
  #-----------------------------------------------------------------------------------------------------
  worker_number        = 1
  k8s_version          = "1.24.10-00"
  node_master_cidrhost = 10 //Network IP address for master node
  disk_size            = 30

  linux_user = {
    aws   = "ubuntu"
    azure = "azureadmin"
    gcp   = split("@", data.google_client_openid_userinfo.me.email)[0]
  }
  node_instance_type = {
    aws   = "t3.2xlarge"
    azure = "Standard_B2ms"
    gcp   = "e2-standard-4"
  }
  nodes_cidr = {
    aws   = "172.20.20.0/24"
    azure = "172.25.20.0/24"
    gcp   = "172.30.20.0/24"
  }
  master_public_ip = {
    aws   = module.fgt_hub.fgt_active_eip_public
    azure = module.azure_xlb.elb_public-ip
    gcp   = module.gcp_fgt.fgt_active_eip_public
  }
  db_host_public_ip = {
    aws   = module.fgt_hub.fgt_active_eip_public
    azure = module.azure_xlb.elb_public-ip
    gcp   = module.gcp_fgt.fgt_active_eip_public
  }
  master_ip = {
    aws   = cidrhost(module.aws_nodes_vpc.subnet_az1_cidrs["vm"], local.node_master_cidrhost)
    azure = cidrhost(module.azure_nodes_vnet.subnet_cidrs["subnet_1"], local.node_master_cidrhost)
    gcp   = cidrhost(local.nodes_cidr["gcp"], local.node_master_cidrhost)
  }
  db_host = {
    aws   = cidrhost(module.aws_nodes_vpc.subnet_az1_cidrs["vm"], local.node_master_cidrhost)
    azure = cidrhost(module.azure_nodes_vnet.subnet_cidrs["subnet_1"], local.node_master_cidrhost)
    gcp   = cidrhost(local.nodes_cidr["gcp"], local.node_master_cidrhost)
  }
  db_port = 6379
  db_pass = random_string.db_pass.result
  db_prefix = {
    aws   = "aws"
    gcp   = "gcp"
    azure = "azure"
  }

  api_port = 6443

  #-----------------------------------------------------------------------------------------------------
  # AWS Nodes and TGW
  #-----------------------------------------------------------------------------------------------------
  tgw_bgp-asn     = "65515"
  tgw_cidr        = ["172.20.10.0/24"]
  tgw_inside_cidr = ["169.254.100.0/29", "169.254.101.0/29"]

  nodes_subnet_id   = module.aws_nodes_vpc.subnet_az1_ids["vm"]
  nodes_subnet_cidr = module.aws_nodes_vpc.subnet_az1_cidrs["vm"]
  nodes_sg_id       = module.aws_nodes_vpc.nsg_ids["vm"]

  #-----------------------------------------------------------------------------------------------------
  # AWS FGT HUB
  #-----------------------------------------------------------------------------------------------------
  hub = [{
    id                = "hub"
    bgp_asn_hub       = "65000"
    bgp_asn_spoke     = "65000"
    vpn_cidr          = "10.10.10.0/24"
    vpn_psk           = "secret-key-123"
    cidr              = local.fgt_cidrs["aws"]
    ike_version       = "2"
    network_id        = "1"
    dpd_retryinterval = "5"
    mode_cfg          = true
    vpn_port          = "public"
  }]
  hubs = [{
    id                = local.hub[0]["id"]
    bgp_asn           = local.hub[0]["bgp_asn_hub"]
    external_ip       = module.fgt_hub.fgt_active_eip_public
    hub_ip            = cidrhost(local.hub[0]["vpn_cidr"], 1)
    site_ip           = "" // set to "" if VPN mode-cfg is enable
    hck_ip            = cidrhost(local.hub[0]["vpn_cidr"], 1)
    vpn_psk           = module.fgt_hub_config.vpn_psk
    cidr              = local.hub[0]["cidr"]
    ike_version       = local.hub[0]["ike_version"]
    network_id        = local.hub[0]["network_id"]
    dpd_retryinterval = local.hub[0]["dpd_retryinterval"]
    sdwan_port        = local.hub[0]["vpn_port"]
  }]
  #-----------------------------------------------------------------------------------------------------
  # AZURE FGT ONRAMP
  #-----------------------------------------------------------------------------------------------------
  azure_spoke = {
    id      = "azure"
    cidr    = local.fgt_cidrs["azure"]
    bgp_asn = local.hub[0]["bgp_asn_spoke"]
  }
  #-----------------------------------------------------------------------------------------------------
  # GCP FGT ONRAMP
  #-----------------------------------------------------------------------------------------------------
  gcp_spoke = {
    id      = "gcp"
    cidr    = local.fgt_cidrs["gcp"]
    bgp_asn = local.hub[0]["bgp_asn_spoke"]
  }
  #---------------------------------------------------------------------
  # Github repo variables
  #---------------------------------------------------------------------
  github_site = "secdayforti"

}