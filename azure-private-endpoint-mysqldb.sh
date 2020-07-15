#!/bin/bash -x

RgName="MyPrivateEndPointResourceGroup"
Location="southcentralus"

# Create a resource group.
az group create \
  --name $RgName \
  --location $Location

# Create a virtual network 
az network vnet create \
  --name MyVnet \
  --resource-group $RgName \
  --subnet-name mySubnet \

# Disable subnet private endpoint policies
az network vnet subnet update \
 --name mySubnet \
 --resource-group $RgName \
 --vnet-name MyVnet \
 --disable-private-endpoint-network-policies true

# Create VM
az vm create \
  --resource-group $RgName \
  --name myVm \
  --image UbuntuLTS \
  --generate-ssh-keys \
  --subnet $(az network vnet subnet show -g MyPrivateEndPointResourceGroup --vnet-name MyVnet -n mySubnet --query id --output tsv)

# Create a server in SQL Database
# Create a server in the resource group
az sql server create \
    --name "mypeserver"\
    --resource-group $RgName \
    --location $Location \
    --admin-user "sqladmin" \
    --admin-password "XCHANGE_PASSW!!ORD_1"

# Create a database in the server with zone redundancy as false
az sql db create \
    --resource-group $RgName  \
    --server mypeserver \
    --name mySampleDatabase \
    --sample-name AdventureWorksLT \
    --edition GeneralPurpose \
    --family Gen5 \
    --capacity 2

#Create a private endpoint for the logical SQL server in the Virtual Network:
az network private-endpoint create \
    --name myPrivateEndpoint \
    --resource-group $RgName \
    --vnet-name MyVnet  \
    --subnet mySubnet \
    --private-connection-resource-id $(az sql server show --name mypeserver --resource-group MyPrivateEndPointResourceGroup --query id --output tsv) \
    --group-ids sqlServer \
    --connection-name myConnection

#Create a Private DNS Zone for SQL Database domain, create an association link with the Virtual Network and create a DNS Zone Group to associate the private endpoint with the Private DNS Zone.
az network private-dns zone create \
   --resource-group $RgName \
   --name  "privatelink.database.windows.net"

az network private-dns link vnet create \
   --resource-group $RgName \
   --zone-name  "privatelink.database.windows.net"\
   --name MyDNSLink \
   --virtual-network MyVnet \
   --registration-enabled false

az network private-endpoint dns-zone-group create \
   --resource-group $RgName \
   --endpoint-name myPrivateEndpoint \
   --name MyZoneGroup \
   --private-dns-zone "privatelink.database.windows.net" \
   --zone-name sql


##Testing 
# ssh to myVM public ip from cloud shell

##connect to the SQL Database from the VM using the Private Endpoint.
#run: nslookup myserver.database.windows.net 

#Response should be similar to below:
#Server:  UnKnown
#Address:  168.63.129.16
#Non-authoritative answer:
#Name:    myserver.privatelink.database.windows.net
#Address:  10.0.0.5
#Aliases:  myserver.database.windows.net

#Delete RG once done 
## az group delete --name $RgName --yes
