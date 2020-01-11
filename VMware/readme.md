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
## 3 vm operations
```sh
## list vm/host ... 
# govc ls vm   ---> for exsi 
/ha-datacenter/vm/DC1-DMZ-WAF-PROD01
/ha-datacenter/vm/DC1-EDG-TM-PROD01
## find vm info 
# govc vm.info -vm.ipath=/ha-datacenter/vm/DC1-DMZ-WAF-PROD01
Name:           DC1-DMZ-WAF-PROD01
  Path:         /ha-datacenter/vm/DC1-DMZ-WAF-PROD01
  UUID:         4227bd31-871a-8054-eb09-09281ef47a7f
  Guest name:   Other 3.x Linux (64-bit)
  Memory:       16384MB
  CPU:          4 vCPU(s)
  Power state:  poweredOn
  Boot time:    2019-05-16 06:49:18.96594 +0000 UTC
  IP address:   10.36.47.253
  Host:         ESXi1

## remove file from datastore 
#  govc datastore.rm -ds ESXI1-DS2 dc1-vm-ansible-prod01/dc1-vm-ansible-prod01.vmdk

## copy  file to othere  location in same datastore
# govc datastore.cp  -ds ESXI1-DS2 dc1-oob-vm-ansible-prod01/dc1-oob-vm-ansible-prod01.vmdk dc1-vm-ansible-prod01/dc1-vm-ansible-prod01.vmdk
[20-05-19 10:58:40] Copying [ESXI1-DS2] dc1-oob-vm-ansible-prod01/dc1-oob-vm-ansible-prod01.vmdk to [ESXI1-DS2] dc1-vm-ansible-prod01/dc1-vm-ansible-prod01.vmdk...OK

## create vm 
# govc vm.create -m 8192 -c 4 -g rhel7_64Guest -net.adapter vmxnet3 -net=VLAN101  -ds=ESXI1-DS2  -disk=100G -disk.controller pvscsi dc1-vm-smtp-prod01


```


# Configure VM template with cloud-init enabled

## 1. Configure Template VM 

>-  since default cloud-init in the centos repos lacked some feature, we can compile it from source; the template require cloud-init >=18.4
> - git clone  https://github.com/cloud-init/cloud-init.git
> - git checkout 18.5 # change to release 18.5
> - make ci-deps-centos  # install dependency, make sure epel repo is installed
> - yum install -y python34-jinja2.noarch python36-jinja2.noarch python36-requests python36-six python36-yaml  python-oauthlib python-jsonpatch  python-jsonschema  
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

1.3 configure  datasource for cloud-init, instance retrieve data from `VMwareGuestInfo` provided by [cloud-init-vmware-guestinfo](https://github.com/vmware/cloud-init-vmware-guestinfo), modify `/etc/cloud/cloud.cfg.d/99-DataSourceVMwareGuestInfo.cfg` with following content
  ```yaml
  datasource_list: ['VMwareGuestInfo']
  ```
1.4 (optional) disabled network, since we can use vSphere api to customize the network info, create file `/etc/cloud/cloud.cfg.d/06-network.cfg`, and add following content
  ```yaml
  network:
    config: disabled
  ```

1.5 adjust modules(the sequence, and remove useless modules) in sections such as `cloud_init_modules`,`cloud_config_modules`,`cloud_final_modules`, even change the modules in these sections.

1.6 install other software that as needed, for example monitoring agent.



# Provision VM with configured template
1.  [Terraform](examples/terraform) demonstrates the terraform role to provision vm, VM network is configured by terraform which invokes vsphere api 
    - modify `variables.tf` to fit the require and then execute `terraform apply` to provision new vm
    - v1 shows the example to set network info within terraform which actually calls vsphere api achieve
    - v2 shows the example to set network info via cloud-init metadata, if using this one, 
      > - VM templates shoud remove file `/etc/cloud/cloud.cfg.d/06-network.cfg` to enable cloudinit configure the network; 
      > - VM templates should install  `cloud-init-vmware-guestinfo` 1.1.0, new versions are not tested
2. [Ansible](examples/ansible) demonstrates ansible role to  provision VM
    - create a ansible playbook to include the ansible to to provision new vm
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
          - {'vm_name': 'dc1-vm-hana-exporter-prod03','domain': 'inb.cnsgas.com','template': 'RHEL74-TEMPLATE','vm_folder': '/DC1/vm/DevOps','vm_resource_pool': 'DevOps','vm_cluster': "APP-Cluster01", disks: [{'size_gb': 100, 'datastore': 'INB_DATA_DEVOPS'}],'vm_memory_size': '4096','vm_cpu_count': '2',networks: [{'name': 'VLAN101','ip': '10.36.52.162','netmask': '255.255.255.192','gateway': '10.36.52.129'}]
        ```

  -  pass the metadata.json encoded string to `guestinfo.metadata`  and  `guestinfo.metadata.encoding` to `terraform` `extra_config` or `ansible` `customvalues`
# export and import VM via ovftool
- import to vCenter 
  ```
  ovftool  --name=dc1-vm-smtp-prod01 --datastore=INB_DATA_DEVOPS --network=VLAN101 --vmFolder=DevOps  --powerOn --skipManifestCheck --noSSLVerify --acce
  ptAllEulas --sourceType=OVA  dc1-vm-smtp-prod01.ova vi://user:pass@10.36.51.11:443/DC1/host/APP-Cluster01/Resources/DevOps
  ```
- import to ESXi
  ```
  ovftool --name=dc1-vm-smtp-prod01 --datastore=INB_DATA_DEVOPS --network=VLAN101  --powerOn --skipManifestCheck --noSSLVerify --acceptAllEulas --sourceType=OVA  dc1-vm-smtp-prod01.ova vi://user:pass@10.36.51.141:443/
  ```
- export from vCenter 
  ```
  ovftool  --acceptAllEulas --noSSLVerify --acceptAllEulas vi://user:pass@10.36.51.11:443/DC1/vm/Templates/RHEL74-TEMPLATE RHEL74-TEMPLATE.ova
  ```

