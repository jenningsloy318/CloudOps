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