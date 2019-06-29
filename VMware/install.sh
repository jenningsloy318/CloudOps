#!/bin/bash
echo "please check if ESXi has DNS conifgured before deploy vcsa to that ESXi"
./vcsa-deploy install  vcsa.json  --accept-eula --no-ssl-certificate-verification