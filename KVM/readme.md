
1. create meta-data and user-data
```sh
# cat meta-data
instance-id: centos7
network-interfaces: |
  auto eth0
  iface eth0 inet static
  address 192.168.3.50
  netmask 255.255.255.128
  gateway 192.168.3.1
hostname: logstash.lmy.com
#cat user-data 
#cloud-config
preserve_hostname: false
hostname: logstash.lmy.com
ssh_pwauth: True
manage_resolv_conf: true
resolv_conf:
    nameservers: ['114.114.144.114', '8.8.8.8']
chpasswd:
    list: |
        root:$6$oJcrtka/1w50zPDy$XmbumwMPTrFlrJsMyAsibrh0uxC9vJcoFZKOSxXwhz8PckEIj10VmlKKgCyeEH.MFqTXSYxYPToU1XJSmAqNg0
users:
  - name: jenningsl
    groups: wheel
    lock_passwd: false
    passwd: $6$oJcrtka/1w50zPDy$XmbumwMPTrFlrJsMyAsibrh0uxC9vJcoFZKOSxXwhz8PckEIj10VmlKKgCyeEH.MFqTXSYxYPToU1XJSmAqNg0
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      -sh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6tTttVie4t/vkg5UkzRH9SVAjejS7BGceYrzjI4Stk5/qp/S5E6cNEo7LW240dS128ya7lcAVbvxX/dY9AygVB6r82M+qUAL+COdVqgypzY9TmxBiL8+e5+56wN1V3h6xa584AjZ5eGANm4rmHp4uproOby6Xk5QxkM+5xPoOFGP+xBHj9EWciMiGxspfiPOqT7Cof5ldbdf4n0XMICSWgGRmfQoM4n/yeWrIu5cPx0MLfn7BfTM+CfM6gtMJcu5J46J8eKZiH2ZxIMOlht8xUfphC+WFQHf1aGWQoZEA8sXZ43V4CSjSRRZFSJIHqTcArwY38guTFBi28tJhyDv1 jennings.liu@sap.com
  - name: root
    passwd: $6$oJcrtka/1w50zPDy$XmbumwMPTrFlrJsMyAsibrh0uxC9vJcoFZKOSxXwhz8PckEIj10VmlKKgCyeEH.MFqTXSYxYPToU1XJSmAqNg0
    shell: /bin/bash
    ssh-authorized-keys:
      -sh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6tTttVie4t/vkg5UkzRH9SVAjejS7BGceYrzjI4Stk5/qp/S5E6cNEo7LW240dS128ya7lcAVbvxX/dY9AygVB6r82M+qUAL+COdVqgypzY9TmxBiL8+e5+56wN1V3h6xa584AjZ5eGANm4rmHp4uproOby6Xk5QxkM+5xPoOFGP+xBHj9EWciMiGxspfiPOqT7Cof5ldbdf4n0XMICSWgGRmfQoM4n/yeWrIu5cPx0MLfn7BfTM+CfM6gtMJcu5J46J8eKZiH2ZxIMOlht8xUfphC+WFQHf1aGWQoZEA8sXZ43V4CSjSRRZFSJIHqTcArwY38guTFBi28tJhyDv1 jennings.liu@sap.com
# genisoimage -output cidata.iso -volid cidata -joliet -r user-data meta-data
```
2. create VM
```sh
# virt-install  -n logstash  --import --description "logstash "  --os-type=Linux  --os-variant=centos7.0  --ram=4086 --vcpus=2  --disk path=/data/VMs/logstash/os.qcow2,bus=virtio --disk path=/data/VMs/logstash/data.qcow2,bus=virtio  --disk path=/data/VMs/logstash/cidata.iso,device=cdrom  --network network:ovs-network --graphics none  
```