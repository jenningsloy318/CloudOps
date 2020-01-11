data "template_cloudinit_config" "userdata" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "userdata.yaml"
    content_type = "text/cloud-config"
    content     =    templatefile("${path.module}/cloudinit_userdata.tpl", 
      {
        vscloud_password ="$6$rounds=10000$vscloudsecretsal$gQPUKHeXQPHyofrLYKXG9HHm4KUwWXQ01HNA6ozHhszISTcoIHkx121BiCXI3zzlZMWdxreesGs3HYlCnkpB60",
        vscloud_keys = var.vscloud_keys,
        timezone = var.timezone,
        nameservers = var.dns_servers,
        domain=var.dns_domain,
        devices_resize= var.devices_resize,
        packages=var.installed_packages
   })
  }
  part {
     content_type = "text/x-shellscript"
     content =  templatefile("${path.module}/lvm.sh",{
                DEVICE = "/dev/sdb",
                MOUNT_PATH = "/data"
     })
  }
}

data "template_file" "netconfig" {
  template = "${file("${path.module}/cloudinit_netconfig.tpl")}"

  vars ={
    vm_network_addr = var.vm_network["addr"]
    vm_network_mask = var.vm_network["mask"]
    vm_network_gateway = var.vm_network["gateway"]
  }
}


data "template_file" "metadata" {

    template     =    "${file("${path.module}/cloudinit_metadata.tpl")}"
    vars = {
        host_name = var.host_name
        dns_domain = var.dns_domain
        
        #vm_network_addr = var.vm_network["addr"]
        #vm_network_mask = var.vm_network["mask"]
        #vm_network_gateway = var.vm_network["gateway"]

        netconfig = base64gzip(data.template_file.netconfig.rendered)
  }
}

data "vsphere_datacenter" "datacenter" {
  name = var.vm_datacenter
}


data "vsphere_resource_pool" "pool" {
  name          = var.vm_resource_pool
  datacenter_id = data.vsphere_datacenter.datacenter.id
}


data "vsphere_virtual_machine" "template" {
  name          = var.vm_template
  datacenter_id = data.vsphere_datacenter.datacenter.id
}


data "vsphere_datastore" "datastore_os" {
  name          = var.vm_datastore_os
  datacenter_id = data.vsphere_datacenter.datacenter.id
}
data "vsphere_datastore" "datastore_data" {
  name          = var.vm_datastore_data
  datacenter_id = data.vsphere_datacenter.datacenter.id
}


data "vsphere_network" "network" {
  name          = var.vm_network["name"]
  datacenter_id = data.vsphere_datacenter.datacenter.id
}