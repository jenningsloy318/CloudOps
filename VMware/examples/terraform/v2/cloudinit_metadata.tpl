instance-id: vscloud-vm
local-hostname: ${host_name}.${dns_domain}
network:
  version: 2
  ethernets:
    ens192:
      addresses:
      - ${vm_network["addr"]}/${vm_network["mask"]}
      gateway4: ${vm_network["gateway"]}

