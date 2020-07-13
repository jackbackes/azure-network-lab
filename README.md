# azure-network-lab

`go/azure-trainers`

## Create a resource group
In Azure, every object you create is called a "resource".
A "resource group" is a logical, operational container of resources. It has
no technical impact on the resources themselves,
but allows common role based access control and cost attributions.
Also an entire resource group can be deleted at once.

```
az group create --name myResourceGroup --location eastus
az configure --defaults group=myResourceGroup
```

## Create a Virtual Network

Create your first virtual network. You can designate any address space you wish.

```
az network vnet create \
  --name virtualNetwork1 \
  --address-prefixes 10.0.0.0/16 \
  --subnet-name subnet1
```

## Add / Remove Address Space

```
az network vnet update \
  --name virtualNetwork1 \
  --add addressSpace.addressPrefixes 10.1.0.0/16
```

```
az network vnet show \
  --name virtualNetwork1 \
  --query addressSpace.addressPrefixes

[
  "10.0.0.0/16",
  "10.1.0.0/16"
]
```

```
az network vnet update \
  --name virtualNetwork1 \
  --remove addressSpace.addressPrefixes 1
```

```
az network vnet show \
  --name virtualNetwork1 \
  --query addressSpace.addressPrefixes

[
  "10.0.0.0/16",
]
```

## Create another Subnet

Show existing subnets:

`az network vnet subnet list --vnet-name virtualNetwork1 --query "[].addressPrefix"`

Add a subnet:

```
az network vnet subnet create \
  --vnet-name virtualNetwork1 \
  -n subnet2 \
  --address-prefixes 10.0.1.0/24

export SUBNET_ID=$(az network vnet subnet show --vnet-name virtualNetwork1 -n subnet2 --query id --output tsv)
```

## Create a couple Virtual Machines in your Subnet

```
az vm create \
  --name myVm1 \
  --image UbuntuLTS \
  --generate-ssh-keys \
  --no-wait \
  --subnet $SUBNET_ID
```

```
az vm create \
  --name myVm2 \
  --image UbuntuLTS \
  --generate-ssh-keys \
  --no-wait \
  --subnet $SUBNET_ID
```

## ssh to VM2

A VM is given a Public IP when it is created. By default the public IP is exposed to the internet for SSH.
SSH keys are auto-generated and added to the ~/.ssh config in whatever client you are using to
create the VM.

```
ssh $(az vm list-ip-addresses --name myVm2 --query [0].virtualMachine.network.publicIpAddresses[0].ipAddress --output tsv)
```

## Try to Ping VM1

Azure will automatically resolve the name of the VM to its private IP address
```
ping myVm1 -c 4
```

## Create another Virtual Network / Subnet / VM in another region

```
az group create --name myResourceGroup2 --location westus
az configure --defaults group=myResourceGroup2
```

```
az network vnet create \
  --name myVirtualNetwork2 \
  --address-prefixes 172.16.0.0/12 \
  --subnet-name subnet1 \
  --subnet-prefixes 172.16.0.0/16
```

```
az vm create \
  --name myVm3 \
  --image UbuntuLTS \
  --generate-ssh-keys \
  --no-wait \
  --subnet $(az network vnet subnet show --vnet-name myVirtualNetwork2 -n subnet1 --query id --output tsv)

```

```
ssh $(az vm list-ip-addresses --name myVm3 --query [0].virtualMachine.network.publicIpAddresses[0].ipAddress --output tsv)
```

```
ping myVm1 -w 1
```
This will fail ^

## Peer them together

```
az network vnet peering create \
  --name VnetPeering \
  --resource-group myResourceGroup \
  --remote-vnet $(az network vnet show --name myVirtualNetwork2 -g myResourceGroup2 --query id --output tsv) \
  --vnet-name virtualNetwork1 \
  --verbose

az network vnet peering create \
  --name VnetPeering \
  --resource-group myResourceGroup2 \
  --vnet-name myVirtualNetwork2 \
  --remote-vnet $(az network vnet show --name virtualNetwork1 -g myResourceGroup --query id --output tsv) \
  --verbose
```

## Try to ping

```
export vm3PublicIp=$(az vm list-ip-addresses --name myVm3 --query [0].virtualMachine.network.publicIpAddresses[0].ipAddress --output tsv)
export vm3PrivateIp=$(az vm list-ip-addresses --name myVm3 --query [0].virtualMachine.network.privateIpAddresses[0] --output tsv)
export vm1PublicIp=$(az vm list-ip-addresses --name myVm1 -g myResourceGroup --query [0].virtualMachine.network.publicIpAddresses[0].ipAddress --output tsv)
export vm1PrivateIp=$(az vm list-ip-addresses --name myVm1 -g myResourceGroup --query [0].virtualMachine.network.privateIpAddresses[0] --output tsv)
ssh $vm3PublicIp "ping -c 4 $vm1PrivateIp"
```

## Add NSG's

```
# Create the NSG
az network nsg create --name vnet1subnet2nsg -g myResourceGroup -l eastus

# Add the NSG to Vnet1 Subnet2
az network vnet subnet update -g myResourceGroup -n subnet2 --vnet-name virtualNetwork1 \
  --network-security-group vnet1subnet2nsg

# Test your connection
ssh $vm3PublicIp "ping -c 4 $vm1PrivateIp"
```

## Add a rule

```
# This NSG rule will block inbound ICMP traffic from VM3 to VM1

az network nsg rule create -g myResourceGroup --nsg-name vnet1subnet2nsg \
  --source-address-prefixes $vm3PrivateIp --source-port-ranges '*' \
  --destination-address-prefixes $vm1PrivateIp --destination-port-ranges '*' \
  --access Deny \
  --protocol ICMP \
  --priority 100 \
  --name "block-icmp-vm3-to-vm1" \
  --description "Block ICMP Ping from VM3 to VM1"

# Test your connection
ssh $vm3PublicIp "ping -W 1 -c 4 $vm1PrivateIp"
```

## Change NSG rules to allow/deny internet access

By default your VM has unrestricted outbound access to the internet. You may not want this, but it's great for webscraping!

```
ssh $vm3PublicIp "wget -q -S -O - 2>&1 http://www.google.com"
```

## Change rules to block internet access.

```
az network nsg rule create -g myResourceGroup --nsg-name vnet1subnet2nsg \
  --source-address-prefixes $vm1PrivateIp --source-port-ranges '*' \
  --destination-address-prefixes 'Internet' --destination-port-ranges '*' \
  --access Deny \
  --direction Outbound \
  --protocol TCP \
  --priority 110 \
  --name "block-internet-from-vm1" \
  --description "Block Internet from VM1"

# Now run your web scraper again:
ssh $vm1PublicIp "wget --timeout=5 http://www.google.com"

```

## Create a Load Balancer
```
az network lb create \
  --name myLB \
  -g myResourceGroup \
  -l eastus \
  --sku Standard \
  --subnet subnet2 \
  --vnet-name virtualNetwork1

# This doesn't work but should:

az network lb address-pool address add --lb-name myLB2 --pool-name myLB2bepool --resource-group myResourceGroup -n "address-name" --vnet virtualNetwork1 --ip-address 10.0.1.8
```

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

