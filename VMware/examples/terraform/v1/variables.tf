variable "vsphere_server" {
   description ="vsphere server address"
   type = string
   default =  ""
}
variable "vsphere_user" {
   description ="vsphere server user name"
   type = string
   default =  ""
}
variable "vsphere_password" {
   description ="vsphere server user name"
   type = string
   default =  ""
}

variable "vm_datacenter" {
   description ="datacenter this vm will be created in"
   type = string
   default =  "DC1"

}

variable "vm_resource_pool" {
   description ="resource pool this vm will be created in"
   type = string
   default =  "DevOps"
}
variable "vm_folder" {
    description = "the vm folder to put the VM,must under directory vm for VMs, if set vm/abc, we can see the vm under the vm folder abc in vcenter inventory"
    type = string  
    default  = "vm/DevOps"

}
variable "vm_template" {
   description ="vm template this vm will be created from"
   type = string
   default =  "RHEL74-TEMPLATE"
}

variable "vm_datastore_os" {
   description ="datastore for new vm os disk"
   type = string
   default =  "INB_DATA_DEVOPS"

}
variable "vm_datastore_data" {
   description ="datastore for new vm data disks"
   type = string
   default =  "INB_DATA_DEVOPS"

}
variable "vm_network" {
   description ="network for new vm"
   type = map
   default =  {
     name = "VLAN101"
     addr = "10.36.52.187"
     mask = "25"
     gateway = "10.36.52.129"
   }
}


variable "vscloud_keys" {
   description =" the ssh keys for vscloud"
   type= string
   default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDBJkrhbsq0e02D5SHl+veUsoQW5EVY5ROr3Wm+Uc4aFb4vCMUfT4koKau5j5wHCBe5gqDkx55uzbD/xvsHUSn4NY0hzspBMy4cHQw5SvpLb5brArKk2TP1C3HMJRv+K8N9we9Hk6dbf9VgSQmPcp6uHUKgfd42h4sAlQJVOVoS73wTcP4Gg8x4ePnYW2Nd8moUpS+eCMyj/pj0hnMyK9B14E17Hb+89f0NU7LrweqZlieoYuuZLgCMzq1mThW2ES2kTx1CGnyz0iicPbENdezNF7J4Po0bEWjjSS1cW1Lj3pREbEpIM/vsJJLdF8ZME7Zp1EWXLBhrJcqX1zTf0Jx vscloud"
}

variable "dns_servers" {
   description =" the dns server list"
   type = list(string)
   default =  ["10.36.52.172","10.36.52.173"]

}

variable "dns_domain" {
   description =" the dns domain"
   type = string
   default = "inb.cnsgas.com"


}

variable "host_name" {
   description =" the hostname info"
   type = string
   default = "jennings-terraform"

}

variable "timezone" {
   description =" the timezone info"
   type = string
   default = "Asia/Chongqing"


}

variable  "devices_resize"{
    description =" the devices or filesystem path to reisze " 
    type = list
    default = ["/dev/sda2"]
}

variable "installed_packages" {
   description =" the mount info you use for the disk "
   type = list 
   default =["ipa-client","nscd","nss-pam-ldapd"]
}