variable "vm_hostname" {
  description = "VM Hostname"
  default = "appvm"
}
variable "resource_group_name" {
    default = "ebs-rg"
}
variable "location" {
    description = "Azure region"
}
variable "tags" {
  type = "map"

  default = {
    application = "Oracle EBusinessSuite"
  }
}

variable "compute_hostname_prefix" {
  description = "Application hostname prefix"
  default = "app"
}
variable "compute_instance_count" {
  description = "Application instance count"
  default = 2
}
variable "vm_size" {
    default = "Standard_D2_V2"
}
variable "os_publisher" {
    default = "Oracle"
}
variable "os_offer" {
    default = "Oracle-Linux"
}
variable "os_sku" {
    default = "7.6"
}
variable "os_version" {
    default = "latest"

}
variable "storage_account_type" {
    default = "Standard_LRS"
}
variable "compute_boot_volume_size_in_gb" {
  description = "Boot volume size of compute instance"
  default = 128
}
variable "data_disk_size_gb" {
    default = 128
}
variable "data_sa_type" {
    default = "Premium_LRS"
}
variable "admin_username" {
    default = "sysadmin"
}
variable "admin_password" {
}
variable "custom_data" {
}
variable "compute_ssh_public_key" {
  description = "Path to the public key to be used for ssh access to the VM."
  default     = "~/.ssh/id_rsa.pub"
}
variable "nb_instances" {
    default = 1
}
variable "enable_accelerated_networking" {
    default = "false"
}
variable "vnet_name" {
    default = "ebs-vnet"
}
variable "vnet_cidr" {
    default = "10.2.0.0/16"
}


