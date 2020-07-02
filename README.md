# azure-network-lab

`go/azure-trainers`

## Create a resource group
`az group create --name myResourceGroup --location eastus`

## Create a Virtual Network
```
az network vnet create \
  --name myVirtualNetwork \
  --resource-group myResourceGroup \
  --subnet-name default
```

## Add / Remove Address Space

## Create another Subnet

## Create a couple Virtual Machines in your Subnet

```
az vm create \
  --resource-group myResourceGroup \
  --name myVm1 \
  --image UbuntuLTS \
  --generate-ssh-keys \
  --no-wait
```

```
az vm create \
  --resource-group myResourceGroup \
  --name myVm2 \
  --image UbuntuLTS \
  --generate-ssh-keys \
  --no-wait
```

## ssh to VM2
```
ssh <publicIpAddress>
```

## Try to Ping VM1
```
ping myVm1 -c 4
```

## Create another Virtual Network / Subnet / VM in another region
`az group create --name myResourceGroup2 --location westus`

```
az network vnet create \
  --name myVirtualNetwork \
  --resource-group myResourceGroup2 \
  --subnet-name default
```

```
az vm create \
  --resource-group myResourceGroup \
  --name myVm3 \
  --image UbuntuLTS \
  --generate-ssh-keys
```

```
ssh <publicIpAddress>
```

```
ping myVm1 -c 4
```
This will fail ^

## Peer them together


## Try to ping

## Add NSG's

## Change rules around
## Change NSG rules to allow/deny internet access
## Change rules to...



## Create a Load Balancer

## Create a Public IP Address



## Create a Routing Table

## Create an Azure Traffic Manager Policy

## Create an Application Gateway

### Add Application Gateway to NSG


## Service Tags
### Add Service Tag to NSG
allow/deny traffic to load balancer

## Create a Service Endpoint

## Create a Private Endpoint
Create storage account
Create private IP address
Storage account resource firewall

## Clean Up
```
az group delete --name myResourceGroup --yes
az group delete --name myResourceGroup2 --yes
```


Other stuff:
## Create a Virtual Network Gateway (but can't create an ER connection...)

