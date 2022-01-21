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
