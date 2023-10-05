# GCP resourcers prefix description
variable "prefix" {
  type    = string
  default = "terraform"
}
variable "suffix" {
  type    = string
  default = "1"
}
# GCP region
variable "region" {
  type    = string
  default = "europe-west4" #Default Region
}
# GCP zone
variable "zone" {
  type    = string
  default = "europe-west4-a" #Default Zone
}

# list of subnet to create vm
variable "subnet_name" {
  type    = string
  default = null
}

# VM test Image name
variable "os_image" {
  type    = string
  default = "ubuntu-os-cloud/ubuntu-2204-lts"
}

// SSH RSA public key for KeyPair if not exists
variable "ssh-keys" {
  type    = string
  default = null
}

# GCP instance machine type for testing vm
variable "machine_type" {
  type    = string
  default = "e2-standard-4"
}

# SSH RSA public key for KeyPair if not exists
variable "rsa-public-key" {
  type    = string
  default = null
}

# GCP user name launch Terrafrom
variable "gcp-user_name" {
  type    = string
  default = null
}

# GCP user name launch Terrafrom
variable "user_data" {
  type    = string
  default = null
}

# Tags
variable "tags" {
  type    = list(string)
  default = ["tag-default"]
}

# GCP user name launch Terrafrom
variable "disk_size" {
  type    = number
  default = 30
}

variable "public_ip" {
  type    = string
  default = null
}

variable "private_ip" {
  type    = string
  default = null
}