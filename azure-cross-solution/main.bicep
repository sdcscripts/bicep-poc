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
param windowsOSVersion string
param host1vmSize string

var subnet1ref = '${dockernetwork.outputs.vnid}/subnets/${dockernetwork.outputs.subnet1name}'

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: rgname
  location: location
}

module kv './kv.bicep' = {
  params: {
    adUserId: adUserId
  }
  name: 'kv'
  scope: rg
}

module vm './vm.bicep' = {
  params: {
    adminusername   : vmadminusername
    keyvault_name   : kv.outputs.keyvaultname
    vmname          : firsthostname
    subnet1ref      : subnet1ref
    pipid           : dockernetwork.outputs.pipid
    windowsOSVersion: windowsOSVersion
    vmSize          : host1vmSize
  }
  name: firsthostname
  scope: rg
} 

module dockernetwork './network.bicep' = {
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


// todo  - subnetRef = '${vn.id}/subnets/${subnetName}'




/* Deployment

 $currentuserObjectID = az ad signed-in-user show --query objectId -o tsv
 az deployment sub create --name docker-single-host --resource-group docker-single-host --template-file .\main.bicep --parameters @main.parameters.json

 */
