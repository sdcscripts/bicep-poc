// Example of similar "module" call out structure - https://github.com/Azure/bicep/blob/main/docs/examples/301/modules-vwan-to-vnet-s2s-with-fw/main.bicep

@minLength(36)
@maxLength(36)
@description('Used to set the Keyvault access policy - run this command using az cli to get your ObjectID : az ad signed-in-user show --query objectId -o tsv')
param adUserId string  = ''

@description('Set the location for the resource group and all resources')
param Location string = 'UK South'

@description('Set the resource group name, this will be created automatically')
param ResourceGroupName string = 'singlehost'

@description('Set the prefix of the docker hosts')
@maxLength(8)
param VmHostname string = 'dkrhost'

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
param publicIPAddressNameSuffix string = 'dhostip'

@description('Set the path to the github directory that has the custom script extension scripts')
param githubPath string = 'https://raw.githubusercontent.com/sdcscripts/bicep-poc/main/azure-cross-solution/scripts/'

@description('Set the number of hosts to create')
@maxValue(2)
@minValue(2)
param numberOfHosts int = 2

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
module dockerhost './modules/vm.bicep' =[for i in range (1,numberOfHosts): {
  params: {
    adminusername            : VmAdminUsername
    keyvault_name            : kv.outputs.keyvaultname
    vmname                   : '${VmHostname}${i}'
    subnet1ref               : subnet1ref
    vmSize                   : HostVmSize
    githubPath               : githubPath
    publicIPAddressNameSuffix: '${publicIPAddressNameSuffix}${i}'
  }
  name: '${VmHostname}${i}'
  scope: rg
} ]

module dockernetwork './modules/network.bicep' = {
  params: {
    addressPrefix            : VnetAddressPrefix
    location                 : Location
    networkSecurityGroupName : NetworkSecurityGroupName
    subnet1Name              : Subnet1Name
    subnet1Prefix            : Subnet1Prefix
    virtualNetworkName       : VnetName
  }

  name: 'dockernetwork'
  scope: rg
} 

// Future iteration this should be replaced with a loop through outputs of the module
output dockerhost1 string = dockerhost[0].outputs.dockerhostfqdn
output dockerhost2 string = dockerhost[1].outputs.dockerhostfqdn


/* Deployment using bicep (via az cli)

The first command retrieves the signed-in usr object ID to use for setting Keyvault permissions, you need to add this ObjectID to the adUserId parameter at the top of this file.
Command:   az ad signed-in-user show --query objectId -o tsv

The second command deploys this main.json 
Command: az deployment sub create --name docker-single-host --template-file .\main.bicep --location uksouth

 */
