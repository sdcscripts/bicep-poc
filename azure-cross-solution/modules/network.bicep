// May want to introduce later a more complex but far more scalable way to manage this, including RT and NSG rules for each subnet - https://github.com/ChristopherGLewis/vNet-Bicep
// It is also possible to pass an array into the vnet module, which is probably a good move later on - https://github.com/Azure/bicep/blob/main/docs/examples/101/hub-and-spoke/modules/vnet.bicep

// For now, this creates the vnet and you can add multiple subnets here too and output the names accordingly (subnet1,subnet2 etc), but this is temporary as it does not scale and isn't neat.

param addressPrefix string          
param subnet1Name  string             
param subnet1Prefix string     
param bastionNetworkName string   
param bastionSubnet string     
param virtualNetworkName string      
param location string

resource vn 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
        }
      }
      {
        name: bastionNetworkName
        properties: {
          addressPrefix: bastionSubnet
        }
      }
    ]
  }
}

output subnet1name string = vn.properties.subnets[0].name
output bastionSubnetName string = vn.properties.subnets[1].name
output subnet1addressPrefix string = vn.properties.subnets[0].properties.addressPrefix 
output vnid string = vn.id
output vnName string = vn.name
