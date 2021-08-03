// May want to introduce later a more complex but far more scalable way to manage this, including RT and NSG rules for each subnet - https://github.com/ChristopherGLewis/vNet-Bicep
// It is also possible to pass an array into the vnet module, which is probably a good move later on - https://github.com/Azure/bicep/blob/main/docs/examples/101/hub-and-spoke/modules/vnet.bicep

// For now, this creates the vnet and you can add multiple subnets here too and output the names accordingly (subnet1,subnet2 etc), but this is temporary as it does not scale and isn't neat.

param addressPrefix string            = '10.0.0.0/16'
param subnet1Name  string              = 'Subnet'
param subnet1Prefix string             = '10.0.0.0/24'
param virtualNetworkName string       = 'MyVNET'
param networkSecurityGroupName string = 'default-NSG'
param location string
param publicIPAddressNameSuffix string

var dnsLabelPrefix = 'dns-${uniqueString(subscription().id, resourceGroup().id)}-${publicIPAddressNameSuffix}'

resource pip 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIPAddressNameSuffix
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource pip2 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: '${publicIPAddressNameSuffix}2'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: '${dnsLabelPrefix}2'
    }
  }
}

resource sg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-ssh'
        'properties': {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

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
          networkSecurityGroup: {
            id: sg.id
          }
        }
      }
    ]
  }
}

output dockerhost1fqdn string = pip.properties.dnsSettings.fqdn
output dockerhost2fqdn string = pip2.properties.dnsSettings.fqdn
output subnet1name string = vn.properties.subnets[0].name
output vnid string = vn.id
output pipaddressname string = pip.name
output pipid string = pip.id
output pipid2 string = pip2.id
