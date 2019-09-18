terraform {
  required_version = "~> 0.11.0"
}

provider "vsphere" {
  user           = "administrator"
  password       = "passw0rd"
  vsphere_server = "10.36.51.11"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "template_file" "cloudinit_userdata" {
  template ="${file("./cloudinit_userdata.yaml")}"
}

data "template_cloudinit_config" "cloudinit_userdata" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content = "${data.template_file.cloudinit_userdata.rendered}"
  }
}


data "template_file" "cloudinit_metadata_network" {
  template ="${file("./cloudinit_metadata_netconfig.yaml")}"
}

data "template_file" "cloudinit_metadata" {
  template = "${file("./cloudinit_metadata.json")}"
  vars = {
    networ-config = "${base64gzip(data.template_file.cloudinit_metadata_network.rendered)}"
  }
}


data "template_cloudinit_config" "cloudinit_metadata" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content = "${data.template_file.cloudinit_metadata.rendered}"
  }
}


output "cloudinit_metadata" {
  value = "${data.template_file.cloudinit_metadata.rendered}"
}


data "vsphere_datacenter" "datacenter" {
  name = "yuhua"
}

data "vsphere_resource_pool" "pool" {
  name          = "DevOps Applications"
  datacenter_id = "${data.vsphere_datacenter.datacenter.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "centos74-2"
  datacenter_id = "${data.vsphere_datacenter.datacenter.id}"
}


data "vsphere_datastore" "datastore_os" {
  name          = "OS"
  datacenter_id = "${data.vsphere_datacenter.datacenter.id}"
}


data "vsphere_network" "network_VLAN101" {
  name          = "VLAN101"
  datacenter_id = "${data.vsphere_datacenter.datacenter.id}"
}

resource "vsphere_virtual_machine" "instance" {
  name             = "dc1-vm-myprometheus-prod01"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore_os.id}"

  num_cpus = "4"
  cpu_hot_add_enabled = true
  cpu_hot_remove_enabled = true
  memory   = "8192"
  memory_hot_add_enabled = true
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network_VLAN101.id}"
  }

  disk {
    label            = "os"
    size             = "100"
    unit_number      =  "0"
    datastore_id     = "${data.vsphere_datastore.datastore_os.id}"
    }

  cdrom {
    client_device = true
  }


  extra_config {
     "guestinfo.userdata" = "${base64gzip(data.template_file.cloudinit_userdata.rendered)}"
     "guestinfo.userdata.encoding" = "gzip+base64"
     "guestinfo.metadata" = "${base64gzip(data.template_file.cloudinit_metadata.rendered)}"
     guestinfo.metadata.encoding	= "gzip+base64"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

  }

  wait_for_guest_net_timeout= 0
}