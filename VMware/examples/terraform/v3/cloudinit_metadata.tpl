instance-id: vscloud-vm
local-hostname: ${host_name}.${dns_domain}
network:
  version: 1
  config:
  - type: physical
    name: ens192
    subnets:
       - type: static
         address: ${vm_network_addr}/${vm_network_mask}
         gateway: ${vm_network_gateway}