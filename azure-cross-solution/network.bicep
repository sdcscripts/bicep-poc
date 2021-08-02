// May want to introduce later a more complex but far more scalable way to manage this, including RT and NSG rules for each subnet - https://github.com/ChristopherGLewis/vNet-Bicep
// For now, this creates the vnet and you could add multiple subnets here too and output the names accordingly (subnet1,subnet2 etc).

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

resource sg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        'properties': {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
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
output subnet1name string = vn.properties.subnets[0].name
output vnid string = vn.id
output pipaddressname string = pip.name
output pipid string = pip.id
