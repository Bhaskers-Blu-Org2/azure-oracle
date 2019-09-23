# Peoplesoft/main.tf

locals {
    subnet_bits = 8   # want 256 entries per subnet.
    # determine difference between VNET CIDR bits and that size subnetBits.
    vnet_cidr_increase = "${32 - element(split("/",var.vnet_cidr),1) - local.subnet_bits}"
    subnetPrefixes = {
        application     = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 1)}"
        webserver       = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 2)}"
        elasticsearch   = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 3)}"
        client          = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 4)}"
        bastion         = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 5)}"
        identity        = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 6)}"
    } 

    vnet_name = "${var.vnet_cidr == "0" ? 
    element(concat(data.azurerm_virtual_network.primary_vnet.*.name, list("")), 0) :
    element(concat(azurerm_virtual_network.primary_vnet.*.name, list("")), 0)}"
 
    vnet_cidr = "${var.vnet_cidr == "0" ? element(concat(data.azurerm_virtual_network.primary_vnet.*.address_space, list("")), 0) : var.vnet_cidr}"
    
    #####################
    ## NSGs
    #Note that only one of prefix or prefixes is allowed and keywords can't be in the list.

    bastion_sr_inbound = [
        {   # SSH from outside
            source_port_ranges = "*" 
            source_address_prefix = "*"
            destination_port_ranges =  "22" 
            destination_address_prefix = "${local.subnetPrefixes["bastion"]}"    
            priority = "200"
        }
    ]

    bastion_sr_outbound = [
        {  # SSH to any of the servers
            source_port_ranges =  "*" 
            source_address_prefix = "VirtualNetwork"
            destination_port_ranges =  "22" 
            destination_address_prefix = "*"    
            priority = "250"
        }    
    ]

    application_sr_inbound = [
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["bastion"]}"              
            destination_port_ranges = "22" 
            destination_address_prefix = "*"             
        },
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["webserver"]}"              
            destination_port_ranges = "9033-9039"
            destination_address_prefix = "*"           
        },
        
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["elasticsearch"]}"              
            destination_port_ranges = "2320-2321"
            destination_address_prefix = "*"              
        }
    ]

    application_sr_outbound = [
        {  # SSH to any of the servers
            source_port_ranges =  "*" 
            source_address_prefix = "VirtualNetwork"
            destination_port_ranges =  "22" 
        
        }
    ]
    webserver_sr_inbound = [
        {
            source_port_ranges =  "*" 
            source_address_prefix = "AzureLoadBalancer"  # input from the Load Balancer only.             
            destination_port_ranges = "8000" 
            destination_address_prefix = "*"             
        },
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["bastion"]}"                
            destination_port_ranges = "22" 
            destination_address_prefix = "${local.subnetPrefixes["webserver"]}"               
        },
               {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["elasticsearch"]}"                
            destination_port_ranges = "80" 
            destination_address_prefix = "${local.subnetPrefixes["webserver"]}"                
        }
    ]

    webserver_sr_outbound = [
                {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["webserver"]}"                 
            destination_port_ranges = "80" 
            destination_address_prefix = "${local.subnetPrefixes["application"]}"             
        },
                      {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["webserver"]}"                 
            destination_port_ranges = "443" 
            destination_address_prefix = "${local.subnetPrefixes["application"]}"             
        },
                   {
            source_port_ranges =  "*" 
            source_address_prefix = "*"              
            destination_port_ranges = "9200" 
            destination_address_prefix = "${local.subnetPrefixes["elasticsearch"]}"    # ob to Elastic Servers            
        }
    ]
    elasticsearch_sr_inbound = [
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["webserver"]}"             
            destination_port_ranges = "9200"
            destination_address_prefix = "*"             
        },
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["bastion"]}"                
            destination_port_ranges = "22" 
            destination_address_prefix = "*"             
        }
    ]

    elasticsearch_sr_outbound = [
                {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["application"]}"  # ob to Application Servers               
            destination_port_ranges = "9033-9039" 
            destination_address_prefix = "*"             # Need to support ASG
        },
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["webserver"]}"  # ob to WebServers            
            destination_port_ranges = "8000" 
            destination_address_prefix = "*"            
        }
    ]

    toolsclient_sr_inbound = [
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["application"]}"             
            destination_port_ranges = "5985-5986"
            destination_address_prefix = "*"             
        },
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["bastion"]}"                
            destination_port_ranges = "22" 
            destination_address_prefix = "*"             
        }
    ]

    toolsclient_sr_outbound = [

    ]
    
    identity_sr_inbound = [
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["bastion"]}"              
            destination_port_ranges = "22" 
            destination_address_prefix = "*"             
        },
        {
            source_port_ranges =  "*" 
            source_address_prefix = "*"              
            destination_port_ranges = "80"
            destination_address_prefix = "*"           
        },
        
        {
            source_port_ranges =  "*" 
            source_address_prefix = "*"            
            destination_port_ranges = "443"
            destination_address_prefix = "*"              
        }
    ]

     identity_sr_outbound = [
        {  # SSH to any of the servers
            source_port_ranges =  "*" 
            source_address_prefix =  "${local.subnetPrefixes["identity"]}"     
            destination_port_ranges =  "1521" 
            destination_address_prefix = "192.168.10.0"      
        }
    ]

    # database_sr_inbound = [
    #     {
    #         source_port_ranges =  "*" 
    #         source_address_prefix = "${local.subnetPrefixes["application"]}"                 
    #         destination_port_ranges =  "1521" 
    #         destination_address_prefix = "*"             
    #     },
    #     {
    #         source_port_ranges =  "*" 
    #         source_address_prefix = "${local.subnetPrefixes["bastion"]}"  # input from the Load Balancer only.            
    #         destination_port_ranges =  "22" 
    #         destination_address_prefix = "*"                
    #     }
    # ]
    # database_sr_outbound = [
    # ]


}

############################################################################################
# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
  tags     = "${var.tags}"     
}
resource "azurerm_resource_group" "vnet_rg" {
    name = "${var.vnet_resource_group_name}"
    location = "${var.location}"
    tags = "${var.tags}"
}

############################################################################################
# Create the virtual network 

data "azurerm_virtual_network" "primary_vnet" {
    name = "${var.vnet_name}"
    resource_group_name = "${var.vnet_resource_group_name}"
    count = "${var.vnet_cidr == "0" ? 1 : 0}"
}

resource "azurerm_virtual_network" "primary_vnet" {
  name                = "${var.vnet_name}"
  resource_group_name = "${azurerm_resource_group.vnet_rg.name}"
  location            = "${var.location}"
  tags                = "${var.tags}"
  address_space       = ["${local.vnet_cidr}"]
  count = "${var.vnet_cidr != "0" ? 1 : 0}"

}

#################################################
# Setting up a private DNS Zone & A-records for OCI DNS resolution
 
resource "azurerm_dns_zone" "oci_vcn_dns" {
 name = "${var.oci_vcn_name}.oraclevcn.com"
 resource_group_name = "${azurerm_resource_group.rg.name}"
}
 
# Setting up A-records for the DB
 
resource "azurerm_dns_a_record" "db_a_record" {
 name = "${var.db_name}-scan.${var.oci_subnet_name}"
 resource_group_name = "${azurerm_resource_group.rg.name}"
 zone_name = "${azurerm_dns_zone.oci_vcn_dns.name}"
 ttl = 3600
 records = ["${var.db_scan_ip_addresses}"]
}

###############################################################
# Create each of the Network Security Groups
###############################################################

module "create_networkSGsForBastion" {
    source = "./modules/network/nsgWithRules"

    nsg_name            = "${azurerm_virtual_network.primary_vnet.name}-nsg-bastion"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"    
    subnet_id           = "${module.create_subnets.subnet_names["bastion"]}"
    inboundOverrides    = "${local.bastion_sr_inbound}"
    outboundOverrides   = "${local.bastion_sr_outbound}"
}

module "create_networkSGsForApplication" {
    source = "./modules/network/nsgWithRules"

    nsg_name = "${azurerm_virtual_network.primary_vnet.name}-nsg-application"    
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location = "${var.location}"
    tags = "${var.tags}"    
    subnet_id = "${module.create_subnets.subnet_names["application"]}"
    inboundOverrides  = "${local.application_sr_inbound}"
    outboundOverrides = "${local.application_sr_outbound}"
}
module "create_networkSGsForWebserver" {
    source = "./modules/network/nsgWithRules"

    nsg_name            = "${azurerm_virtual_network.primary_vnet.name}-nsg-webserver"    
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"
    subnet_id           = "${module.create_subnets.subnet_names["webserver"]}"
    inboundOverrides    = "${local.webserver_sr_inbound}"
    outboundOverrides   = "${local.webserver_sr_outbound}"
}

module "create_networkSGsForElasticsearch" {
    source = "./modules/network/nsgWithRules"

    nsg_name            = "${azurerm_virtual_network.primary_vnet.name}-nsg-elasticsearch"    
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"
    subnet_id           = "${module.create_subnets.subnet_names["elasticsearch"]}"
    inboundOverrides    = "${local.elasticsearch_sr_inbound}"
    outboundOverrides   = "${local.elasticsearch_sr_outbound}"
}

module "create_networkSGsForClient" {
    source = "./modules/network/nsgWithRules"

    nsg_name            = "${azurerm_virtual_network.primary_vnet.name}-nsg-client"    
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"
    subnet_id           = "${module.create_subnets.subnet_names["client"]}"
    inboundOverrides    = "${local.toolsclient_sr_inbound}"
    outboundOverrides   = "${local.toolsclient_sr_outbound}"
}

module "create_networkSGsForIdentity" {
    source = "./modules/network/nsgWithRules"

    nsg_name            = "${azurerm_virtual_network.primary_vnet.name}-nsg-identity"    
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"
    subnet_id           = "${module.create_subnets.subnet_names["identity"]}"
    inboundOverrides    = "${local.identity_sr_inbound}"
    outboundOverrides   = "${local.identity_sr_outbound}"
}


locals {
    # map of subnets which are to have NSGs attached.
    nsg_ids = {  
        # Note: if you change the number of subnets in this map, be sure to
        #       also adjust nsg_ids_len value (below) as well to the new number
        #       of entries.   The value of nsg_ids_len should be calculated 
        #       dynamically (e.g., "${length(local.nsg_ids)}"), but terraform then 
        #       refuses to allow it to be used as a count later.  Thus it is
        #       "hard-coded" below.   TF 0.12 can work around this, but not 0.11.
        application = "${module.create_networkSGsForApplication.nsg_id}"
        webserver = "${module.create_networkSGsForWebserver.nsg_id}"
        elasticsearch = "${module.create_networkSGsForElasticsearch.nsg_id}"
        client = "${module.create_networkSGsForClient.nsg_id}"
        bastion = "${module.create_networkSGsForBastion.nsg_id}"
        identity = "${module.create_networkSGsForIdentity.nsg_id}"

    }
    nsg_ids_len = 6
    # Number of entries in nsg_ids. Can't be calculated. See note above.
    
}

############################################################################################
# Create each of the subnets
module "create_subnets" {
    source = "./modules/network/subnets"

    subnet_cidr_map = "${local.subnetPrefixes}"
    resource_group_name = "${azurerm_resource_group.vnet_rg.name}"
    vnet_name = "${azurerm_virtual_network.primary_vnet.name}"
    nsg_ids = "${local.nsg_ids}"
    nsg_ids_len = "${local.nsg_ids_len}"  # Note: terraform has to have this for count later.
    vnet_cidr = "${var.vnet_cidr}"

}

####################
# Create Boot Diag Storage Account

module "create_boot_sa" {
  source  = "./modules/storage"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "${var.compute_hostname_prefix}"
}



###################################################
# Create bastion host

module "create_bastion" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "${var.compute_hostname_prefix_bastion}"
  compute_instance_count    = "${var.bastion_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  compute_boot_volume_size_in_gb    = "${var.bastion_boot_volume_size_in_gb}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.bastion_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["bastion"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  create_vm                 = true
  create_av_set             = false  
  create_public_ip          = true
  assign_bepool             = false
  create_data_disk          = false
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  
}


###################################################
# Create Application server
module "create_app" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "${var.compute_hostname_prefix_app}"
  compute_instance_count    = "${var.compute_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  compute_boot_volume_size_in_gb    = "${var.compute_boot_volume_size_in_gb}"
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.compute_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["application"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  create_vm                 = true
  create_av_set             = true 
  create_public_ip          = false
  assign_bepool             = false
  create_data_disk          = true
 
}


###################################################
# Create Webserver
module "create_web" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "${var.compute_hostname_prefix_web}"
  compute_instance_count  = "${var.webserver_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  compute_boot_volume_size_in_gb    = "${var.webserver_boot_volume_size_in_gb}"
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.webserver_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["webserver"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  create_vm                 = true
  create_av_set             = true 
  create_public_ip          = false
  assign_bepool             = false
  create_data_disk          = true
}

###################################################
# Create Elastic Search server
module "create_es" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "${var.compute_hostname_prefix_es}"
  compute_instance_count    = "${var.elastic_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  compute_boot_volume_size_in_gb    = "${var.elastic_boot_volume_size_in_gb}"
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.elastic_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["elasticsearch"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  create_vm                 = true
  create_av_set             = true 
  create_public_ip          = false
  assign_bepool             = false
  create_data_disk          = true
}

###################################################
# Create Process Scheduler server
module "create_ps" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "${var.compute_hostname_prefix_ps}"
  compute_instance_count   = "${var.prosched_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  compute_boot_volume_size_in_gb    = "${var.prosched_boot_volume_size_in_gb}"
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.prosched_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["application"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  create_vm                 = true
  create_av_set             = true 
  create_public_ip          = false
  assign_bepool             = false
  create_data_disk          = true

 
}
###################################################
# Create Identity VMs

module "create_identity" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix  = "${var.compute_hostname_prefix_id}"
  compute_instance_count    = "${var.identity_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  compute_boot_volume_size_in_gb    = "${var.identity_boot_volume_size_in_gb}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.identity_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["identity"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  create_vm                 = true
  create_av_set             = false
  create_public_ip          = false
  assign_bepool             = false
  create_data_disk          = false
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
}


###################################################
# Create Tools Client machine

module "create_toolsclient" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix  = "${var.compute_hostname_prefix_tc}"
  compute_instance_count    = "${var.toolsclient_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  compute_boot_volume_size_in_gb    = "${var.toolsclient_boot_volume_size_in_gb}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.toolsclient_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["client"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  create_vm                 = true
  create_av_set             = false
  create_public_ip          = false
  assign_bepool             = false
  create_data_disk          = true
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
}

############################################################
# Create Application Gateway

module "create_app_gateway" {
  source = "./modules/app_gateway"

  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  prefix              = "appgw"
  frontend_subnet_id  = "${module.create_subnets.appgw_subnet_id}"
  vnet_name           = "${azurerm_virtual_network.primary_vnet.name}"
  web_backend_ips     = "${module.create_web.backend_ips}"

 
}




