#!/bin/bash -x

RgName="MyServiceEndPointResourceGroup"
Location="westus"
MysqlServer="MyServiceEndPointDemoserver"

# Create a resource group
az group create \
--name $RgName \
--location $Location

# Create a MySQL server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
az mysql server create \
--name $MysqlServer \
--resource-group $RgName \
--location $Location \
--admin-user mylogin \
--admin-password testPassword1! \
--sku-name GP_Gen5_2 \
--version 5.7

# Get available service endpoints for Azure region output is JSON
# Use the command below to get the list of services supported for endpoints, for an Azure region, say "$Location".
az network vnet list-endpoint-services \
-l $Location

# Add Azure SQL service endpoint to a subnet *mySubnet* while creating the virtual network *myVNet* output is JSON
az network vnet create \
-g $RgName \
-n myVNet \
--address-prefixes 10.0.0.0/16 \
-l $Location

# Creates the service endpoint
az network vnet subnet create \
-g $RgName \
-n mySubnet \
--vnet-name myVNet \
--address-prefix 10.0.1.0/24 \
--service-endpoints Microsoft.SQL

# View service endpoints configured on a subnet
az network vnet subnet show \
-g $RgName \
-n mySubnet \
--vnet-name myVNet

# Create a VNet rule on the sever to secure it to the subnet Note: resource group (-g) parameter is where the database exists. VNet resource group if different should be specified using subnet id (URI) instead of subnet, VNet pair.
az mysql server vnet-rule create \
-n myRule \
-g $RgName \
-s $MysqlServer \
--vnet-name myVNet \
--subnet mySubnet

#Delete RG once done
## az group delete --name $RgName --yes
