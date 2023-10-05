# Create pubic IP for instance
resource "google_compute_address" "instance_pip" {
  name         = "${var.prefix}-public-ip-${var.suffix}"
  address_type = "EXTERNAL"
  region       = var.region
}

# Create VM compute active instance with DHCP for private IP
resource "google_compute_instance" "instance" {
  count        = var.private_ip == null ? 1 : 0
  name         = "${var.prefix}-vm-${var.suffix}"
  machine_type = var.machine_type
  zone         = var.zone

  tags = concat(["${var.subnet_name}-t-route"], ["${var.subnet_name}-t-fwr"], var.tags)

  boot_disk {
    initialize_params {
      image = var.os_image
      size  = var.disk_size
    }
  }
  network_interface {
    subnetwork = var.subnet_name
    access_config {
      nat_ip = var.public_ip == null ? google_compute_address.instance_pip.address : var.public_ip
    }
  }
  metadata = {
    ssh-keys       = "${var.gcp-user_name}:${var.rsa-public-key}"
    startup-script = var.user_data != null ? var.user_data : file("${path.module}/templates/user-data.tpl")
  }
  service_account {
    scopes = ["userinfo-email", "compute-rw", "storage-ro", "cloud-platform"]
  }
  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}

# Create VM compute active instance private IP
resource "google_compute_instance" "instance_ip" {
  count        = var.private_ip != null ? 1 : 0
  name         = "${var.prefix}-vm-${var.suffix}"
  machine_type = var.machine_type
  zone         = var.zone

  tags = concat(["${var.subnet_name}-t-route"], ["${var.subnet_name}-t-fwr"], var.tags)

  boot_disk {
    initialize_params {
      image = var.os_image
      size  = var.disk_size
    }
  }
  network_interface {
    subnetwork = var.subnet_name
    network_ip = var.private_ip
    access_config {
      nat_ip = var.public_ip == null ? google_compute_address.instance_pip.address : var.public_ip
    }
  }
  metadata = {
    ssh-keys       = "${var.gcp-user_name}:${var.rsa-public-key}"
    startup-script = var.user_data != null ? var.user_data : file("${path.module}/templates/user-data.tpl")
  }
  service_account {
    scopes = ["userinfo-email", "compute-rw", "storage-ro", "cloud-platform"]
  }
  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}


