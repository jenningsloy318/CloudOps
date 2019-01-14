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
  # remove duplicate cloud-init conf
  rm -f /etc/cloud/cloud.cfg.d/99-DataSourceVMwareGuestInfo.cfg
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
  sed -i".bak" '/UUID/d' /etc/sysconfig/network-scripts/ifcfg-ens192
  #remove SSH host keys
  /bin/rm -f /etc/ssh/*key*
  #remove root users shell history
  /bin/rm -f ~root/.bash_history
  unset HISTFILE
  #remove root users SSH history
  /bin/rm -rf ~root/.ssh/
  ```

1.3 configure  datasource for cloud-init, instance retrieve data from `VMwareGuestInfo` provided by [cloud-init-vmware-guestinfo](https://github.com/akutz/cloud-init-vmware-guestinfo), add following content to `/etc/cloud/cloud.cfg`, and remove other datasource setting
  ```yaml
  datasource_list: [ "VMwareGuestInfo" ]
  datasource:
    VMwareGuestInfo：
      dsmode: local
  ```
1.4 disabled network, since we can use vSphere to customize the IP add domain info, create file `/etc/cloud/cloud.cfg.d/06_network.cfg`, and add following content
  ```yaml
  network:
  config: disabled
  ```
1.5 adjust modules(the sequence, and remove useless modules) in sections such as `cloud_init_modules`,`cloud_config_modules`,`cloud_final_modules`, even change the modules in these sections.

1.6 install other software that as needed, for example monitoring agent.