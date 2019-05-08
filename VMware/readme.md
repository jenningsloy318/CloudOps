Multiple tools can be used to manage vsphere

- [govc](https://github.com/vmware/govmomi)
- ansible
- terraform
---
# Govc to manage Vsphere
---
## 1. create env  and source the env 
```conf
export GOVC_URL= 
export GOVC_USERNAME='administrator@vc.local'
export GOVC_PASSWORD='pass'
export GOVC_INSECURE=true
```

## 2. Create user and assign the permission
```sh
govc sso.user.create  -p Password#123 monitor
govc role.ls 
govc permissions.set -role  ReadOnly --principal=monitor@vc.local
```


# Terraform integrated with Cloud-init to provision VM

## 1. Configure Template VM 

>-  since default cloud-init in the centos repos lacked some feature, we can compile it from source
> - git clone  https://github.com/cloud-init/cloud-init.git
> - git checkout 18.5 # change to release 18.5
> - make ci-deps-centos  # install dependency, make sure epel repo is installed
> - make rpm # build rpm

1.1 install required packages and upgrade system to the latest
  ```sh
  yum install -y cloud-init cloud-utils-growpart  https://github.com/akutz/cloud-init-vmware-guestinfo/releases/download/v1.1.0/cloud-init-vmware-guestinfo-1.1.0-1.el7.noarch.rpm lvm2 cloud-utils
  yum update -y
  ```

1.2 clean system settings
  ```sh
  #!/bin/bash
  #stop logging services
  systemctl stop rsyslog
  systemctl stop auditd
  systemctl disable autitd
  # enable cloud-init services
  systemctl enable cloud-init
  #remove old kernels
  package-cleanup --oldkernels --count=1
  #clean yum cache
  /usr/bin/yum clean all
  #force logrotate to shrink logspace and remove old logs as well as truncate logs
  /usr/sbin/logrotate -f /etc/logrotate.conf
  /bin/rm -f /var/log/*-???????? /var/log/*.gz
  /bin/rm -f /var/log/dmesg.old
  /bin/rm -rf /var/log/anaconda
  /bin/cat /dev/null > /var/log/audit/audit.log
  /bin/cat /dev/null > /var/log/wtmp
  /bin/cat /dev/null > /var/log/lastlog
  /bin/cat /dev/null > /var/log/grubby
  #remove udev hardware rules
  /bin/rm -f /etc/udev/rules.d/70*
  #remove uuid from ifcfg scripts
  sed -i '/^\(HWADDR|UUID|IPADDR|NETMASK|GATEWAY\)=/d' /etc/sysconfig/network-scripts/ifcfg-e*
  sed -i -e 's@^ONBOOT="no@ONBOOT="yes@' /etc/sysconfig/network-scripts/ifcfg-e*

  #remove SSH host keys
  /bin/rm -f /etc/ssh/*key*
  #remove root users shell history
  /bin/rm -f ~root/.bash_history
  unset HISTFILE
  #remove root users SSH history
  /bin/rm -rf ~root/.ssh/

  # lock the root 
  passwd -l root

  # clear root history
  history -cw
  ```

1.3 configure  datasource for cloud-init, instance retrieve data from `VMwareGuestInfo` provided by [cloud-init-vmware-guestinfo](https://github.com/akutz/cloud-init-vmware-guestinfo), modify `/etc/cloud/cloud.cfg.d/99-DataSourceVMwareGuestInfo.cfg` with following content
  ```yaml
  datasource_list: ['VMwareGuestInfo']
  datasource:
    VMwareGuestInfo:
      dsmode: local
  ```
1.4 disabled network, since we can use vSphere to customize the IP add domain info, create file `/etc/cloud/cloud.cfg.d/06-network.cfg`, and add following content
  ```yaml
  network:
  config: disabled
  ```
1.5 adjust modules(the sequence, and remove useless modules) in sections such as `cloud_init_modules`,`cloud_config_modules`,`cloud_final_modules`, even change the modules in these sections.

1.6 install other software that as needed, for example monitoring agent.




## 2. create VM with terraform

2.1 create `userdata` to configure the instance
```yaml
#cloud-config
hostname:  dc1-vm-prometheus-prod01


system_info:
  default_user:
   name: vscloud
   home: /home/vscloud
   shell: /bin/bash
   gecos: Centos vSphere
   groups: [adm, root,wheel]
   sudo:  ALL=(ALL) ALL
   ssh_authorized_keys:
   - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDBJkrhbsq0e02D5SHl+veUsoQW5EVY5ROr3Wm+Uc4aFb4vCMUfT4koKau5j5wHCBe5gqDkx55uzbD/xvsHUSn4NY0hzspBMy4cHQw5SvpLb5brArKk2TP1C3HMJRv+K8N9we9Hk6dbf9VgSQmPcp6uHUKgfd42h4sAlQJVO
VoS73wTcP4Gg8x4ePnYW2Nd8moUpS+eCMyj/pj0hnMyK9B14E17Hb+89f0NU7LrweqZlieoYuuZLgCMzq1mThW2ES2kTx1CGnyz0iicPbENdezNF7J4Po0bEWjjSS1cW1Lj3pREbEpIM/vsJJLdF8ZME7Zp1EWXLBhrJcqX1zTf0Jx vscloud

chpasswd:
    list:
        - vscloud:$6$.7Lt.WZiFe7Wphgs$bxXXMacpMFzUzpi23p.ITL0h7DLH9orJj5nid3Id2wR3fld9.voFGUlJQTXotu8qr53q68e3GAPZ7QViBbAXe1

growpart:
  mode: growpart
  devices: [ '/dev/sda2' ]

resize_rootfs: true

disk_setup:
    /dev/sdb:
         table_type: mbr
         layout: True
         overwrite: True

runcmd:
  - [ cloud-init-per, once, create_pv, pvcreate, /dev/sdb1 ]
  - [ cloud-init-per, once, create_vg, vgcreate, datavg, /dev/sdb1 ]
  - [ cloud-init-per, once, create_lv, lvcreate,-l, 100%VG,-n,datalv,datavg]
  - [ cloud-init-per, once, create_fs, mkfs,-t, ext4,/dev/mapper/datavg-datalv]
  - [ cloud-init-per, once, create_mount_point,mkdir,/data]
  - [ cloud-init-per, once, mount_data, mount,/dev/mapper/datavg-datalv,/data]

mounts:
 - [ /dev/mapper/datavg-datalv, /data, "ext4", "defaults", "0", "0" ]

timezone: Asia/Chongqing

ntp:
  enabled: true
  ntp_client: chrony
  servers:
    - 120.25.115.20
    - 203.107.6.88
```


2.2 create template for userdata 
```yaml
data "template_file" "cloudinit_userdata" {
  template ="/opt/terraform/cloudinit_userdata"
  template ="${file("/opt/terraform/cloudinit_userdata")}"
}

data "template_cloudinit_config" "cloudinit_userdata" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content = "${data.template_file.cloudinit_userdata.rendered}"
  }
}
```

2.3 in the vsphere_virtual_machine to add extra_config to include this userdata
```yaml
resource "vsphere_virtual_machine" "instance" {
  name             = "dc1-vm-prometheus-prod01"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore_os.id}"

  num_cpus = "4"
  memory   = "8192"
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network_VLAN101.id}"
  }

  disk {
    label            = "os"
    size             = "70"
    unit_number      =  "0"
    datastore_id     = "${data.vsphere_datastore.datastore_os.id}"
    }
  disk {
    label            = "data"
    size             = "100"
    unit_number      =  "1"
    datastore_id     = "${data.vsphere_datastore.datastore_data.id}"
    }

  cdrom {
    client_device = true
  }

  extra_config {
    "guestinfo.userdata"          = "${base64gzip(data.template_file.cloudinit_userdata.rendered)}"
    "guestinfo.userdata.encoding" = "gzip+base64"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "dc1-vm-prometheus-prod01"
        domain = "xywlty.com"
      }
      network_interface {
        ipv4_address = "10.36.52.150"
        ipv4_netmask = "25"
      }
      ipv4_gateway = "10.36.52.129"
      dns_server_list =["114.114.114.114","223.5.5.5","119.29.29.29"]


    }
  }
}
```

2.3 use terraform apply to create instance, then when instance is started, cloud-init will begin to customize it as our need.





## 2. create VM with ansible
we can also use ansible to create vm, pass the userdata to `customvalues` with key and value. 

create a ansible role `ansible-role-vcenter-clone-vm`

- `tasks/main.yml`
```yaml
- name: encoding userdata
  shell: gzip -c9 < "{{role_path}}/files/cloudinit_userdata" | base64 -w0
  register: cloudinit_userdata

- name:  Create virtual machine from templates
  vmware_guest:
    hostname: "{{ vcenter_hostname }}"
    username: "{{ vcenter_username }}"
    password: "{{ vcenter_password }}"
    validate_certs: no
    datacenter: "{{ vcenter_datacenter|default('DC1') }}"
    state: present
    folder: "{{item.vm_folder}}"
    resource_pool: "{{item.vm_resource_pool}}"
    template: "{{item.template}}"
    name: "{{ item.vm_name }}"
    cluster: "{{ item.vm_cluster|default('Cluster01') }}"
    cdrom:
      type: client
    disk: "{{item.disks}}"
    hardware:
      memory_mb: "{{item.vm_memory_size}}"
      num_cpus:  "{{item.vm_cpu_count}}"
      hotadd_cpu: True
      hotremove_cpu: True
      hotadd_memory: true
    networks:
      - name: "{{item.vm_network}}"
        ip: "{{item.vm_ip_addr}}"
        netmask: "{{item.vm_ip_mask}}"
        gateway: "{{item.vm_ip_gateway}}"
    wait_for_ip_address: True
    customization:
      hostname: "{{item.vm_name}}"
      dns_servers:
        - 114.114.114.11
        - 223.5.5.5
        - 119.29.29.29
      domain: xywlty.com
    customvalues:
    - key: guestinfo.userdata
      value: "{{ cloudinit_userdata.stdout }}"
    - key: guestinfo.userdata.encoding
      value: "gzip+base64"
  delegate_to: localhost
  with_items: "{{vm_list}}"
```
- `files/userdata`
```yaml
#cloud-config
system_info:
  default_user:
   name: vscloud
   home: /home/vscloud
   shell: /bin/bash
   gecos: Centos vSphere
   groups: [adm, root,wheel]
   sudo:  ALL=(ALL) ALL
   ssh_authorized_keys:
   - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDBJkrhbsq0e02D5SHl+veUsoQW5EVY5ROr3Wm+Uc4aFb4vCMUfT4koKau5j5wHCBe5gqDkx55uzbD/xvsHUSn4NY0hzspBMy4cHQw5SvpLb5brArKk2TP1C3HMJRv+K8N9we9Hk6dbf9VgSQmPcp6uHUKgfd42h4sAlQJVOVoS73wTcP4Gg8x4ePnYW2Nd8moUpS+eCMyj/pj0hnMyK9B14E17Hb+89f0NU7LrweqZlieoYuuZLgCMzq1mThW2ES2kTx1CGnyz0iicPbENdezNF7J4Po0bEWjjSS1cW1Lj3pREbEpIM/vsJJLdF8ZME7Zp1EWXLBhrJcqX1zTf0Jx vscloud

chpasswd:
    list:
        - vscloud:$6$.7Lt.WZiFe7Wphgs$bxXXMacpMFzUzpi23p.ITL0h7DLH9orJj5nid3Id2wR3fld9.voFGUlJQTXotu8qr53q68e3GAPZ7QViBbAXe1
 
growpart:
  mode: growpart
  devices: [ '/dev/sda2' ]

resize_rootfs: true

disk_setup:
    /dev/sdb:
         table_type: mbr
         layout: True
         overwrite: True

runcmd:
  - [ cloud-init-per, once, create_pv, pvcreate, /dev/sdb1 ]
  - [ cloud-init-per, once, create_vg, vgcreate, datavg, /dev/sdb1 ]
  - [ cloud-init-per, once, create_lv, lvcreate,-l, 100%VG,-n,datalv,datavg]
  - [ cloud-init-per, once, create_fs, mkfs,-t, ext4,/dev/mapper/datavg-datalv]
  - [ cloud-init-per, once, create_mount_point,mkdir,/data]
  - [ cloud-init-per, once, mount_data, mount,/dev/mapper/datavg-datalv,/data]

mounts:
 - [ /dev/mapper/datavg-datalv, /data, "ext4", "defaults", "0", "0" ]


ntp:
  enabled: true
  ntp_client: chrony
  servers: 
  - 120.25.115.20
  - 203.107.6.88

timezone: Asia/Chongqing
```

- `defaults/main.yml`
```yaml
vcenter_hostname:
vcenter_username:
vcenter_password: 
vcenter_datacenter:
vm_list:
```

- we can use an playbook to include this role as follows
```yaml

- name: create vm in dc1
  hosts: 127.0.0.1
  connection: local
  become: yes
  roles:
  - ansible-role-vcenter-clone-vm
  vars:
  - vcenter_hostname: 10.36.51.11
  - vcenter_username: "administrator@lmy.com"
  - vcenter_password: "Devops@2018"
  - vcenter_datacenter: DC1
  - vm_list:
    - {'vm_name': 'dc1-oob-vm-mfa-prod01','template': 'Centos7-template2','vm_folder': '/DC1/vm/DevOps','vm_resource_pool': 'Resources','vm_cluster': "Cluster01", disks: [{'size_gb': 80, 'datastore': '10.36.51.141-ds'},{'size_gb': 100, 'datastore': '10.36.51.141-ds'}],'vm_memory_size':'8192','vm_cpu_count': '4','vm_network': 'VLAN520','vm_ip_addr': '10.36.47.218','vm_ip_mask': '255.255.255.192','vm_ip_gateway': '10.36.47.193'}
    - {'vm_name': 'dc1-oob-vm-mfa-prod02','template': 'Centos7-template2','vm_folder': '/DC1/vm/DevOps','vm_resource_pool': 'Resources','vm_cluster': "Cluster01", disks: [{'size_gb': 80, 'datastore': '10.36.51.142-ds'},{'size_gb': 100, 'datastore': '10.36.51.142-ds'}],'vm_memory_size':'8192','vm_cpu_count': '4','vm_network': 'VLAN520','vm_ip_addr': '10.36.47.219','vm_ip_mask': '255.255.255.192','vm_ip_gateway': '10.36.47.193'}    
```
