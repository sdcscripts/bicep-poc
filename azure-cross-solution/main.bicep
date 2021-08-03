// Example of similar "module" call out structure - https://github.com/Azure/bicep/blob/main/docs/examples/301/modules-vwan-to-vnet-s2s-with-fw/main.bicep

@minLength(36)
@maxLength(36)
@description('Used to set the Keyvault access policy - run this command using az cli to get your ObjectID : az ad signed-in-user show --query objectId -o tsv')
param adUserId string  = ''

@description('Set the location for the resource group and all resources')
param Location string = 'UK South'

@description('Set the resource group name, this will be created automatically')
param ResourceGroupName string = 'singlehost'

@description('Set the name of the first docker host')
@maxLength(8)
param FirstHostname string = 'dkrhost1'

@description('Set the name of the second docker host')
@maxLength(8)
param SecondHostname string = 'dkrhost2'

@description('Set the size for the VM')
param HostVmSize string = 'Standard_D2_v3'

@description('Set a username to log in to the hosts')
param VmAdminUsername string = 'localadmin'

@description('Name of the first docker host')
param VnetName string = 'dockervnet'

@description('Set the address space for the VNet')
param VnetAddressPrefix string = '172.16.0.0/16'

@description('Set the name for Subnet1')
param Subnet1Name string = 'dockersubnet'

@description('Set the subnet range for Subnet1')
param Subnet1Prefix string = '172.16.24.0/24'

@description('Set the NSG name')
param NetworkSecurityGroupName string = 'dockernsg'

@description('Set the Public IP Address suffix to append to the FQDN for the hosts')
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
    addressPrefix            : VnetAddressPrefix
    location                 : Location
    networkSecurityGroupName : NetworkSecurityGroupName
    publicIPAddressNameSuffix: publicIPAddressNameSuffix
    subnet1Name              : Subnet1Name
    subnet1Prefix            : Subnet1Prefix
    virtualNetworkName       : VnetName
  }

  name: 'dockernetwork'
  scope: rg
} 

output host1fqdn string = dockernetwork.outputs.dockerhost1fqdn
output host2fqdn string = dockernetwork.outputs.dockerhost2fqdn

/* Deployment using bicep (via az cli)

The first command retrieves the signed-in usr object ID to use for setting Keyvault permissions, you need to add this ObjectID to the adUserId parameter at the top of this file.
Command:   az ad signed-in-user show --query objectId -o tsv

The second command deploys this main.json 
Command: az deployment sub create --name docker-single-host --template-file .\main.bicep --location uksouth

 */
