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
  cpu_hot_add_enabled = true
  cpu_hot_remove_enabled = true

  memory   = "8192"
  memory_hot_add_enabled = true

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
    size             = "50"
    unit_number      =  "1"
    datastore_id     = data.vsphere_datastore.datastore_data.id
    }

  cdrom {
    client_device = true
  }

  wait_for_guest_net_timeout = 0
  extra_config = { 
    "guestinfo.metadata" = base64gzip(data.template_file.metadata.rendered)
    "guestinfo.metadata.encoding" = "gzip+base64"
    "guestinfo.userdata" = data.template_cloudinit_config.userdata.rendered  
    "guestinfo.userdata.encoding" = "gzip+base64"
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    }
  
  }
