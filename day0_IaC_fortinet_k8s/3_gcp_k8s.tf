#------------------------------------------------------------------------------------------------------------
# Create cluster nodes: master and workers
#------------------------------------------------------------------------------------------------------------
# Create VPC Nodes K8S cluster
module "gcp_nodes_vpc" {
  source = "git::github.com/jmvigueras/modules//gcp/vpc-spoke"

  region = local.gcp_region["id"]
  prefix = local.prefix

  spoke-subnet_cidrs = [local.nodes_cidr["gcp"]]
  fgt_vpc_self_link  = module.gcp_fgt_vpc.vpc_self_links["private"]
}
# Create pubic IP for master node
resource "google_compute_address" "master_node_pip" {
  name         = "${local.prefix}-master-public-ip"
  address_type = "EXTERNAL"
  region       = local.gcp_region["id"]
}
# Deploy cluster master node
module "gcp_node_master" {
  source = "./modules/gcp_new_vm"
  prefix = "${local.prefix}-master"
  region = local.gcp_region["id"]
  zone   = local.gcp_region["zone1"]

  machine_type   = local.node_instance_type["gcp"]
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  gcp-user_name  = local.linux_user["gcp"]
  user_data      = data.template_file.gcp_node_master.rendered
  disk_size      = local.disk_size

  public_ip   = google_compute_address.master_node_pip.address
  private_ip  = local.master_ip["gcp"]
  subnet_name = module.gcp_nodes_vpc.subnet_name[0]
}
# Deploy cluster worker nodes
module "gcp_node_worker" {
  depends_on = [module.gcp_node_master]
  count      = local.worker_number
  source     = "./modules/gcp_new_vm"
  prefix     = "${local.prefix}-worker"
  suffix     = count.index + 1
  region     = local.gcp_region["id"]
  zone       = local.gcp_region["zone1"]

  machine_type   = local.node_instance_type["gcp"]
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  gcp-user_name  = local.linux_user["gcp"]
  user_data      = data.template_file.gcp_node_worker.rendered
  disk_size      = local.disk_size

  private_ip  = null // DHCP
  subnet_name = module.gcp_nodes_vpc.subnet_name[0]
}
# Create data template for master node
data "template_file" "gcp_node_master" {
  template = file("./templates/k8s-master.sh")
  vars = {
    cert_extra_sans = local.master_public_ip["gcp"]
    script          = data.template_file.gcp_node_master_script.rendered
    k8s_version     = local.k8s_version
    forticnp_token  = var.forticnp_tokens["gcp"]
    db_pass         = local.db_pass
    linux_user      = local.linux_user["gcp"]
  }
}
data "template_file" "gcp_node_master_script" {
  template = file("./templates/export-k8s-cluster-info.py")
  vars = {
    db_host         = local.db_host["gcp"]
    db_port         = local.db_port
    db_pass         = local.db_pass
    db_prefix       = local.db_prefix["gcp"]
    master_ip       = local.master_ip["gcp"]
    master_api_port = local.api_port
  }
}
# Create data template for worker node
data "template_file" "gcp_node_worker" {
  template = file("./templates/k8s-worker.sh")
  vars = {
    script      = data.template_file.gcp_node_worker_script.rendered
    k8s_version = local.k8s_version
  }
}
data "template_file" "gcp_node_worker_script" {
  template = file("./templates/join-k8s-cluster.py")
  vars = {
    db_host   = local.db_host["gcp"]
    db_port   = local.db_port
    db_pass   = local.db_pass
    db_prefix = local.db_prefix["gcp"]
  }
}
