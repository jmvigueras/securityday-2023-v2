# ------------------------------------------------------------------------------------------
# AWS Define a new VIP resource
# ------------------------------------------------------------------------------------------
resource "fortios_firewall_vip" "aws_app_vip" {
  provider = fortios.aws
  count    = contains(local.csps, "aws") ? 1 : 0

  name = "vip-${local.fgt_values["aws"]["MAPPED_IP"]}-${local.app_nodeport}"

  type        = "static-nat"
  extintf     = "port1"
  extip       = local.fgt_values["aws"]["EXTERNAL_IP"]
  extport     = local.app_nodeport
  mappedport  = local.app_nodeport
  portforward = "enable"

  mappedip {
    range = local.fgt_values["aws"]["MAPPED_IP"]
  }
}
# Define a new firewall policy with default intrusion prevention profile
resource "fortios_firewall_policy" "aws_app_policy" {
  provider   = fortios.aws
  depends_on = [fortios_firewall_vip.aws_app_vip]
  count      = contains(local.csps, "aws") ? 1 : 0

  name = "vip-${local.fgt_values["aws"]["EXTERNAL_IP"]}-${local.app_nodeport}"

  schedule        = "always"
  action          = "accept"
  utm_status      = "enable"
  ips_sensor      = "all_default_pass"
  ssl_ssh_profile = "certificate-inspection"
  nat             = "enable"
  logtraffic      = "all"

  dstintf {
    name = "port2"
  }
  srcintf {
    name = "port1"
  }
  srcaddr {
    name = "all"
  }
  dstaddr {
    name = "vip-${local.fgt_values["aws"]["MAPPED_IP"]}-${local.app_nodeport}"
  }
  service {
    name = "ALL"
  }
}
# ------------------------------------------------------------------------------------------
# Azure Define a new VIP resource
# ------------------------------------------------------------------------------------------
resource "fortios_firewall_vip" "azure_app_vip" {
  provider = fortios.azure
  count    = contains(local.csps, "azure") ? 1 : 0

  name = "vip-${local.fgt_values["azure"]["MAPPED_IP"]}-${local.app_nodeport}"

  type        = "static-nat"
  extintf     = "port1"
  extip       = local.fgt_values["azure"]["EXTERNAL_IP"]
  extport     = local.app_nodeport
  mappedport  = local.app_nodeport
  portforward = "enable"

  mappedip {
    range = local.fgt_values["azure"]["MAPPED_IP"]
  }
}
# Define a new firewall policy with default intrusion prevention profile
resource "fortios_firewall_policy" "azure_app_policy" {
  provider = fortios.azure
  count    = contains(local.csps, "azure") ? 1 : 0

  depends_on = [fortios_firewall_vip.aws_app_vip]

  name = "vip-${local.fgt_values["azure"]["EXTERNAL_IP"]}-${local.app_nodeport}"

  schedule        = "always"
  action          = "accept"
  utm_status      = "enable"
  ips_sensor      = "all_default_pass"
  ssl_ssh_profile = "certificate-inspection"
  nat             = "enable"
  logtraffic      = "all"

  dstintf {
    name = "port2"
  }
  srcintf {
    name = "port1"
  }
  srcaddr {
    name = "all"
  }
  dstaddr {
    name = "vip-${local.fgt_values["azure"]["MAPPED_IP"]}-${local.app_nodeport}"
  }
  service {
    name = "ALL"
  }
}
# ------------------------------------------------------------------------------------------
# GCP Define a new VIP resource
# ------------------------------------------------------------------------------------------
resource "fortios_firewall_vip" "gcp_app_vip" {
  provider = fortios.gcp
  count    = contains(local.csps, "gcp") ? 1 : 0

  name = "vip-${local.fgt_values["gcp"]["MAPPED_IP"]}-${local.app_nodeport}"

  type        = "static-nat"
  extintf     = "port1"
  extip       = local.fgt_values["gcp"]["EXTERNAL_IP"]
  extport     = local.app_nodeport
  mappedport  = local.app_nodeport
  portforward = "enable"

  mappedip {
    range = local.fgt_values["gcp"]["MAPPED_IP"]
  }
}
# Define a new firewall policy with default intrusion prevention profile
resource "fortios_firewall_policy" "gcp_app_policy" {
  provider = fortios.gcp
  count    = contains(local.csps, "gcp") ? 1 : 0

  depends_on = [fortios_firewall_vip.aws_app_vip]

  name = "vip-${local.fgt_values["gcp"]["EXTERNAL_IP"]}-${local.app_nodeport}"

  schedule        = "always"
  action          = "accept"
  utm_status      = "enable"
  ips_sensor      = "all_default_pass"
  ssl_ssh_profile = "certificate-inspection"
  nat             = "enable"
  logtraffic      = "all"

  dstintf {
    name = "port2"
  }
  srcintf {
    name = "port1"
  }
  srcaddr {
    name = "all"
  }
  dstaddr {
    name = "vip-${local.fgt_values["gcp"]["MAPPED_IP"]}-${local.app_nodeport}"
  }
  service {
    name = "ALL"
  }
}