#-----------------------------------------------------------------------------------
# VMs
#-----------------------------------------------------------------------------------
// Create public IP address for NI subnet_1
resource "azurerm_public_ip" "vm_ni_pip" {
  name                = "${var.prefix}-vm-ni-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"

  tags = var.tags
}
// Network Interface VM Test Spoke-1 subnet 1
resource "azurerm_network_interface" "vm_ni" {
  count               = var.private_ip != null ? 1 : 0
  name                = "${var.prefix}-vm-ni"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip
    primary                       = true
    public_ip_address_id          = var.public_ip_id == null ? azurerm_public_ip.vm_ni_pip.id : var.public_ip_id
  }

  tags = var.tags
}
resource "azurerm_network_interface" "vm_ni_dhcp" {
  count               = var.private_ip == null ? 1 : 0
  name                = "${var.prefix}-vm-ni"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = var.public_ip_id == null ? azurerm_public_ip.vm_ni_pip.id : var.public_ip_id
  }

  tags = var.tags
}
// Create virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "${var.prefix}-vm"
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.vm_size
  network_interface_ids = [var.private_ip != null ? element(azurerm_network_interface.vm_ni.*.id,0) : element(azurerm_network_interface.vm_ni_dhcp.*.id, 0)]

  custom_data = base64encode(var.user_data == null ? file("${path.module}/templates/user-data.tpl") : var.user_data)

  os_disk {
    name                 = "${var.prefix}-disk${random_string.random.result}-vm"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  computer_name                   = "${var.prefix}-vm"
  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = trimspace(var.rsa-public-key)
  }
  boot_diagnostics {
    storage_account_uri = var.storage-account_endpoint
  }
}


# Random string to add at disk name
resource "random_string" "random" {
  length  = 3
  special = false
  numeric = false
  upper   = false
}