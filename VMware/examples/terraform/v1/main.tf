provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}
resource "vsphere_virtual_machine" "instance" {
  name             = var.host_name
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder =   var.vm_folder
  datastore_id     = data.vsphere_datastore.datastore_os.id

  num_cpus = "4"
  memory   = "8192"
  guest_id = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
  }

  disk {
    label            = "os"
    size             = "100"
    unit_number      =  "0"
    datastore_id     = data.vsphere_datastore.datastore_os.id
    }
  disk {
    label            = "data"
    size             = "100"
    unit_number      =  "1"
    datastore_id     = data.vsphere_datastore.datastore_data.id
    }

  cdrom {
    client_device = true
  }


  extra_config = { /* sine the argument guestinfo.userdata and guestinfo.userdata.encoding contains dot(.), so we should quote them, as arguments can't be quoted, so should add = at the outmost extra_config argument */
     "guestinfo.userdata" = data.template_cloudinit_config.config.rendered  
     "guestinfo.userdata.encoding" = "gzip+base64"
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = var.host_name
        domain = var.dns_domain
      }
      network_interface {
        ipv4_address = var.vm_network["addr"]
        ipv4_netmask = var.vm_network["mask"]
      }
      ipv4_gateway =  var.vm_network["gateway"]


    }
  }
}