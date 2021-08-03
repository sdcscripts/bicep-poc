// Example of similar "module" call out structure - https://github.com/Azure/bicep/blob/main/docs/examples/301/modules-vwan-to-vnet-s2s-with-fw/main.bicep

@minLength(36)
@maxLength(36)
@description('Used to set the Keyvault access policy - run this command using az cli to get your ObjectID : az ad signed-in-user show --query objectId -o tsv')
param adUserId string                  = ''
param Location string                  = 'UK South'
param ResourceGroupName string         = 'singlehost'
param FirstHostname string             = 'dkrhost1'
param SecondHostname string            = 'dkrhost2'
param HostVmSize string                = 'Standard_D2_v3'
param VmAdminUsername string           = 'localadmin'
param VNetName string                  = 'dockervnet'
param VNetAddressPrefix string         = '172.16.0.0/16'
param Subnet1Name string               = 'dockersubnet'
param Subnet1Prefix string             = '172.16.24.0/24'
param NetworkSecurityGroupName string  = 'dockernsg'
param publicIPAddressNameSuffix string = 'dockerhostip'



var subnet1ref = '${dockernetwork.outputs.vnid}/subnets/${dockernetwork.outputs.subnet1name}'

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: ResourceGroupName
  location: Location
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
    adminusername   : VmAdminUsername
    keyvault_name   : kv.outputs.keyvaultname
    vmname          : FirstHostname
    subnet1ref      : subnet1ref
    pipid           : dockernetwork.outputs.pipid
    vmSize          : HostVmSize
  }
  name: FirstHostname
  scope: rg
} 

module dockerhost2 './modules/vm.bicep' = {
  params: {
    adminusername   : VmAdminUsername
    keyvault_name   : kv.outputs.keyvaultname
    vmname          : SecondHostname
    subnet1ref      : subnet1ref
    pipid           : dockernetwork.outputs.pipid2
    vmSize          : HostVmSize
  }
  name: SecondHostname
  scope: rg
} 

module dockernetwork './modules/network.bicep' = {
  params: {
    addressPrefix            : VNetAddressPrefix
    location                 : Location
    networkSecurityGroupName : NetworkSecurityGroupName
    publicIPAddressNameSuffix: publicIPAddressNameSuffix
    subnet1Name              : Subnet1Name
    subnet1Prefix            : Subnet1Prefix
    virtualNetworkName       : VNetName
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
