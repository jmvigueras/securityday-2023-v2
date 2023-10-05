#--------------------------------------------------------------------------
# Create cluster nodes: master and workers
#--------------------------------------------------------------------------
// Create VPC Nodes K8S cluster
module "azure_nodes_vnet" {
  source = "git::github.com/jmvigueras/modules//azure/vnet-spoke_v2"

  prefix              = local.prefix
  location            = local.azure_location
  resource_group_name = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name
  tags                = local.tags

  vnet_spoke_cidr = local.nodes_cidr["azure"]
  # Peer with VNET vnet-fgt
  vnet_fgt = {
    id   = module.azure_fgt_vnet.vnet["id"]
    name = module.azure_fgt_vnet.vnet["name"]
  }
}
// Associate RouteTable to Fortigate
resource "azurerm_subnet_route_table_association" "rta_nodes_subnet_1" {
  subnet_id      = module.azure_nodes_vnet.subnet_ids["subnet_1"]
  route_table_id = azurerm_route_table.rt_rfc1918.id
}
// Associate RouteTable to Fortigate
resource "azurerm_subnet_route_table_association" "rta_nodes_subnet_2" {
  subnet_id      = module.azure_nodes_vnet.subnet_ids["subnet_2"]
  route_table_id = azurerm_route_table.rt_rfc1918.id
}
// Create public IP address for node master
resource "azurerm_public_ip" "master_public_ip" {
  name                = "${local.prefix}-master-pip"
  location            = local.azure_location
  resource_group_name = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"

  tags = local.tags
}
// Deploy cluster master node
module "azure_node_master" {
  source                   = "./modules/azure_new_vm"
  prefix                   = "${local.prefix}-master"
  location                 = local.azure_location
  resource_group_name      = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name
  tags                     = local.tags
  storage-account_endpoint = local.azure_storage-account_endpoint == null ? azurerm_storage_account.storageaccount[0].primary_blob_endpoint : local.azure_storage-account_endpoint
  vm_size                  = local.node_instance_type["azure"]
  admin_username           = local.linux_user["azure"]
  rsa-public-key           = tls_private_key.ssh.public_key_openssh

  user_data    = data.template_file.azure_node_master.rendered
  public_ip_id = azurerm_public_ip.master_public_ip.id
  public_ip    = azurerm_public_ip.master_public_ip.ip_address
  private_ip   = local.master_ip["azure"]
  subnet_id    = module.azure_nodes_vnet.subnet_ids["subnet_1"]
  subnet_cidr  = module.azure_nodes_vnet.subnet_cidrs["subnet_1"]
}
// Deploy cluster worker nodes
module "azure_node_worker" {
  depends_on               = [module.azure_node_master]
  count                    = local.worker_number
  source                   = "./modules/azure_new_vm"
  prefix                   = "${local.prefix}-worker-${count.index + 1}"
  location                 = local.azure_location
  resource_group_name      = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name
  tags                     = local.tags
  storage-account_endpoint = local.azure_storage-account_endpoint == null ? azurerm_storage_account.storageaccount[0].primary_blob_endpoint : local.azure_storage-account_endpoint
  vm_size                  = local.node_instance_type["azure"]
  admin_username           = local.linux_user["azure"]
  rsa-public-key           = tls_private_key.ssh.public_key_openssh

  user_data   = data.template_file.azure_node_worker.rendered
  private_ip  = null // DHCP
  subnet_id   = module.azure_nodes_vnet.subnet_ids["subnet_1"]
  subnet_cidr = module.azure_nodes_vnet.subnet_cidrs["subnet_1"]
}
// Create data template for master node
data "template_file" "azure_node_master" {
  template = file("./templates/k8s-master.sh")
  vars = {
    cert_extra_sans = local.master_public_ip["azure"]
    script          = data.template_file.azure_node_master_script.rendered
    k8s_version     = local.k8s_version
    forticnp_token  = var.forticnp_tokens["azure"]
    db_pass         = local.db_pass
    linux_user      = local.linux_user["azure"]
  }
}
data "template_file" "azure_node_master_script" {
  template = file("./templates/export-k8s-cluster-info.py")
  vars = {
    db_host         = local.db_host["azure"]
    db_port         = local.db_port
    db_pass         = local.db_pass
    db_prefix       = local.db_prefix["azure"]
    master_ip       = local.master_ip["azure"]
    master_api_port = local.api_port
  }
}
// Create data template for worker node
data "template_file" "azure_node_worker" {
  template = file("./templates/k8s-worker.sh")
  vars = {
    script      = data.template_file.azure_node_worker_script.rendered
    k8s_version = local.k8s_version
  }
}
data "template_file" "azure_node_worker_script" {
  template = file("./templates/join-k8s-cluster.py")
  vars = {
    db_host   = local.db_host["azure"]
    db_port   = local.db_port
    db_pass   = local.db_pass
    db_prefix = local.db_prefix["azure"]
  }
}

