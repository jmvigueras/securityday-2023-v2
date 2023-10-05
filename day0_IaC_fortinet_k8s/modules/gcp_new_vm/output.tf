output "vm" {
  value = {
    user       = var.gcp-user_name
    public_ip  = var.public_ip == null ? google_compute_address.instance_pip.address : var.public_ip
    private_ip = var.private_ip == null ? element(google_compute_instance.instance.*.network_interface.0.network_ip , 0) : var.private_ip
  }
}