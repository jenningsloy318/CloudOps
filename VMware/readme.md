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
1.1 install required packages and upgrade system to the latest
  ```sh
  yum install -y cloud-init cloud-utils-growpart  https://github.com/akutz/cloud-init-vmware-guestinfo/releases/download/v1.1.0/cloud-init-vmware-guestinfo-1.1.0-1.el7.noarch.rpm lvm2 cloud-utils
  yum update -y
  ```

1.2 clean system settings
  ```sh
  #!/bin/bash 
  #stop logging services 
  /sbin/service rsyslog stop 
  /sbin/service auditd stop 
  #remove old kernels 
  /bin/package-cleanup --oldkernels --count=1 
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
  sed -i '/^\(HWADDR\|UUID\)=/d' /etc/sysconfig/network-scripts/ifcfg-e*
  sed -i -e 's@^ONBOOT="no@ONBOOT="yes@' /etc/sysconfig/network-scripts/ifcfg-e*

  #remove SSH host keys 
  /bin/rm -f /etc/ssh/*key* 
  #remove root users shell history 
  /bin/rm -f ~root/.bash_history 
  unset HISTFILE 
  #remove root users SSH history 
  /bin/rm -rf ~root/.ssh/

  # configure sshd_config to only allow Pubkey Authentication
  sed -i -r 's/^#?(PermitRootLogin|PasswordAuthentication|PermitEmptyPasswords) (yes|no)/\1 no/' /etc/ssh/sshd_config
  sed -i -r 's/^#?(PubkeyAuthentication) (yes|no)/\1 no/' /etc/ssh/sshd_config

  # remove the root password
  passwd -l root

  # clear root history
  history -cw

  ```

1.3 configure cloud-init, disable network and configure datasource, instance retrieve data from `VMwareGuestInfo` provided by [cloud-init-vmware-guestinfo](https://github.com/akutz/cloud-init-vmware-guestinfo).
  ```yaml
  network:
    config: disabled
  datasource_list: [ "VMwareGuestInfo" ]
  datasource:
    VMwareGuestInfo：
      dsmode: local
  ```
