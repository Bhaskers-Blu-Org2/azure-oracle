################################################################
## Create Multiple Subnets based on the lists 
## subnet_names, subnet_cidrs
################################################################
resource "azurerm_subnet" "subnet" {
  name                 = "${element(keys(var.subnet_cidr_map),count.index)}"
  resource_group_name  = "${var.resource_group_name}"  
  virtual_network_name = "${var.vnet_name}"
  address_prefix       = "${element(values(var.subnet_cidr_map),count.index)}"
  count = "${length(var.subnet_cidr_map)}"
}

###################################################
##  Create NSG
###################################################
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.vnet_name}-nsg-${element(keys(var.tier_names), count.index)}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  tags                = "${var.tags}"
  count               = "${length(var.tier_names)}"
}


###################################################
##  Security Rules for NSGs
###################################################



###################################################
##  Associate the NSG with the Subnet from above.
###################################################
resource "azurerm_subnet_network_security_group_association" "associateSubnetWithNSG" {
  subnet_id                 = "${element(azurerm_subnet.subnet.*.id,count.index)}"
  network_security_group_id = "${element(values(var.nsg_ids),count.index)}"
  count = "${length(var.subnet_cidr_map)}"
  depends_on = [ "azurerm_subnet.subnet" ]
}