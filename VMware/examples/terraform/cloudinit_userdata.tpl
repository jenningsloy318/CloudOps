users:
 - name: vscloud
   home: /home/vscloud
   shell: /bin/bash
   gecos: Centos vSphere
   groups: [adm, root,wheel]
   sudo:  ALL=(ALL) ALL
   lock_passwd: false
   ssh_authorized_keys: 
    - ${vscloud_keys}
   password: ${vscloud_password}
chpasswd:
    expire: false
    list: 
    - test:${vscloud_password}
timezone: ${timezone}
ntp:
  enabled: true
  ntp_client: chrony
  servers: 
  - 120.25.115.20
  - 203.107.6.88

manage_resolv_conf: true 
resolv_conf:
    nameservers: [ %{ for addr in nameservers ~}
    ${addr},
    %{ endfor ~} ] 
    domain: ${domain}
growpart:
  mode: growpart
  devices: [ %{ for device in devices_resize ~}
             ${device},
             %{ endfor ~}]
resize_rootfs: true
preserve_hostname: false
manage_etc_hosts: true

packages: 
            %{ for package in packages ~}
            -  ${package}
             %{ endfor ~}
hostname: "${host_name}.${dns_domain}"
fqdn: "${host_name}.${dns_domain}