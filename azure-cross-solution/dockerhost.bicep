@minLength(36)
@maxLength(36)
@description('Used to set the Keyvault access policy - run this command using az cli to get your ObjectID : az ad signed-in-user show --query objectId -o tsv')
param adUserId string  = ''

@description('Set the resource group name, this will be created automatically')
@minLength(3)
@maxLength(10)
param ResourceGroupName string = 'dockerhost'

@description('Set the prefix of the docker hosts')
@minLength(3)
@maxLength(8)
param VmHostname string = 'dkrhost'

@description('Set the size for the VM')
@minLength(6)
param HostVmSize string = 'Standard_D2_v3'

@description('Set a username to log in to the hosts')
@minLength(3)
param VmAdminUsername string = 'localadmin'

@description('Name of the vnet')
@minLength(3)
param VnetName string = 'dockervnet'

@description('Set the name for the docker subnet')
param Subnet1Name string = 'dockersubnet'

@description('Set the path to the github directory that has the custom script extension scripts')
@minLength(10)
param githubPath string = 'https://raw.githubusercontent.com/sdcscripts/bicep-poc/main/azure-cross-solution/scripts/'

@description('Set the number of hosts to create')
@minValue(2)
@maxValue(9)
param numberOfHosts int  = 2

var location           = deployment().location
var VnetAddressPrefix  = '172.16.0.0/16'
var Subnet1Prefix      = '172.16.24.0/24'
var bastionSubnet      = '172.16.1.0/24'
var bastionNetworkName = 'AzureBastionSubnet'
var subnet1ref         = '${dockernetwork.outputs.vnid}/subnets/${dockernetwork.outputs.subnet1name}'
var bastionNetworkref  = '${dockernetwork.outputs.vnid}/subnets/${dockernetwork.outputs.bastionSubnetName}'

targetScope  = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: ResourceGroupName
  location: location
}

module kv './modules/kv.bicep' = {
  params: {
    adUserId: adUserId
  }
  name: 'kv'
  scope: rg
}

module dockerhost './modules/vm.bicep' =[for i in range (1,numberOfHosts): {
  params: {
    adminusername            : VmAdminUsername
    keyvault_name            : kv.outputs.keyvaultname
    vmname                   : '${VmHostname}${i}'
    subnet1ref               : subnet1ref
    vmSize                   : HostVmSize
    githubPath               : githubPath
  }
  name: '${VmHostname}${i}'
  scope: rg
} ]

module dockernetwork './modules/network.bicep' = {
  params: {
    addressPrefix            : VnetAddressPrefix
    location                 : location
    subnet1Name              : Subnet1Name
    subnet1Prefix            : Subnet1Prefix
    bastionNetworkName       : bastionNetworkName
    bastionSubnet            : bastionSubnet
    virtualNetworkName       : VnetName
  }

  name: 'dockernetwork'
  scope: rg
} 

module defaultNSG './modules/nsg.bicep' = {
  name: 'hubNSG'
  params:{
    location: location
    destinationAddressPrefix:dockernetwork.outputs.subnet1addressPrefix
  }
scope:rg
}

module onpremNsgAttachment './modules/nsgAttachment.bicep' = {
  name: 'onpremNsgAttachment'
  params:{
    nsgId              : defaultNSG.outputs.nsgId
    subnetAddressPrefix: dockernetwork.outputs.subnet1addressPrefix                    
    subnetName         : dockernetwork.outputs.subnet1name
    vnetName           : dockernetwork.outputs.vnName
  }
  scope:rg
}

module Bastion './modules/bastion.bicep' = {
  params:{
    bastionHostName: 'bastion'
    location: location
    subnetRef: bastionNetworkref
  }
  scope:rg
  name: 'bastion'
  }
