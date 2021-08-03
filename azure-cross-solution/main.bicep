// Example of similar "module" call out structure - https://github.com/Azure/bicep/blob/main/docs/examples/301/modules-vwan-to-vnet-s2s-with-fw/main.bicep

param vmadminusername string
param location string
param rgname string
param firsthostname string  // hostname of the single docker host
param adUserId string  // Used for Keyvault access policy, change to your user ObjectID (az ad signed-in-user show --query objectId -o tsv)
param networkSecurityGroupName string
param addressprefix string
param publicIPAddressNameSuffix string
param subnet1name string
param subnet1prefix string
param virtualnetworkname string
param host1vmSize string

var subnet1ref = '${dockernetwork.outputs.vnid}/subnets/${dockernetwork.outputs.subnet1name}'

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: rgname
  location: location
}

module kv './modules/kv.bicep' = {
  params: {
    adUserId: adUserId
  }
  name: 'kv'
  scope: rg
}

module vm './modules/vm.bicep' = {
  params: {
    adminusername   : vmadminusername
    keyvault_name   : kv.outputs.keyvaultname
    vmname          : firsthostname
    subnet1ref      : subnet1ref
    pipid           : dockernetwork.outputs.pipid
    vmSize          : host1vmSize
  }
  name: firsthostname
  scope: rg
} 

module dockernetwork './modules/network.bicep' = {
  params: {
    addressPrefix            : addressprefix
    location                 : location
    networkSecurityGroupName : networkSecurityGroupName
    publicIPAddressNameSuffix: publicIPAddressNameSuffix
    subnet1Name              : subnet1name
    subnet1Prefix            : subnet1prefix
    virtualNetworkName       : virtualnetworkname
  }

  name: 'dockernetwork'
  scope: rg
} 

output host1fqdn string = dockernetwork.outputs.dockerhost1fqdn


/* Deployment

The first command retrieves the signed-in usr object ID to use for setting Keyvault permissions. 
The second command deploys. Note that the --% allows the parameter file to be read correctly when launching from a powershell windows, this is because @ is interpreted as "splatting" by Powershell.
az ad signed-in-user show --query objectId -o tsv
az --% deployment sub create --name docker-single-host --resource-group docker-single-host --template-file .\main.bicep --parameters @main.parameters.json

 */
