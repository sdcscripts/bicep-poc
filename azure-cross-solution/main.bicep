// Example of similar "module" call out structure - https://github.com/Azure/bicep/blob/main/docs/examples/301/modules-vwan-to-vnet-s2s-with-fw/main.bicep

@minLength(36)
@maxLength(36)
@description('Used to set the Keyvault access policy - run this command using az cli to get your ObjectID : az ad signed-in-user show --query objectId -o tsv')
param adUserId string                  = ''                
param vmadminusername string           = 'localadmin'
param location string                  = 'UK South'
param rgname string                    = 'singlehost'
param firsthostname string             = 'dkrhost1'
param secondhostname string            = 'dkrhost2'
param networkSecurityGroupName string  = 'dockernsg'
param addressprefix string             = '172.16.0.0/16'
param publicIPAddressNameSuffix string = 'dockerhostip'
param subnet1name string               = 'dockersubnet'
param subnet1prefix string             = '172.16.24.0/24'
param virtualnetworkname string        = 'dockervnet'
param host1vmSize string               = 'Standard_D2_v3'

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

// The VM passwords are generated at run time and automatically stored in Keyvault. 
module dockerhost1 './modules/vm.bicep' = {
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

module dockerhost2 './modules/vm.bicep' = {
  params: {
    adminusername   : vmadminusername
    keyvault_name   : kv.outputs.keyvaultname
    vmname          : secondhostname
    subnet1ref      : subnet1ref
    pipid           : dockernetwork.outputs.pipid2
    vmSize          : host1vmSize
  }
  name: secondhostname
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
output host2fqdn string = dockernetwork.outputs.dockerhost2fqdn

/* Deployment

The first command retrieves the signed-in usr object ID to use for setting Keyvault permissions, you need to add this ObjectID to aduserid in the main.parameters.json file .
Command:   az ad signed-in-user show --query objectId -o tsv

The second command deploys this main.json 
Command:   az deployment sub create --name docker-single-host --resource-group docker-single-host --template-file .\main.bicep --parameters '@main.parameters.json'

 */
