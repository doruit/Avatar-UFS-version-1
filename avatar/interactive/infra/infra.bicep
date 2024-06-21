// ############################################################
// ||                                                        ||
// ||             Created by: Douwe van de Ruit              ||
// ||        Role: GenAI SPOC / Principle Consultant         ||
// ||   Purpose of this file: Deploy the infra components    ||
// ||           needed for the Avatar prototype.             ||
// ||                                                        ||
// ############################################################

// Parameters
param location string = 'eastus2'
param storageAccountName string = 'sta${uniqueString(resourceGroup().id)}'
param SearchServiceName string = 'ss-${uniqueString(resourceGroup().id)}'
param cognitiveServiceName string = 'cs-${uniqueString(resourceGroup().id)}'
param sqlServerName string = 'sql-${uniqueString(resourceGroup().id)}'
param speechServicesName string = 'sps-${uniqueString(resourceGroup().id)}'
param textAnalyticsName string = 'tas-${uniqueString(resourceGroup().id)}'
param staticWebAppName string = 'OnlineShop-${uniqueString(resourceGroup().id)}'
param clientIPAddress string

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_0'
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    accessTier: 'Hot'
  }
}

// A Storage blob container named product-images
resource productImageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  name: '${storageAccount.name}/default/product-images'
  properties: {
    immutableStorageWithVersioning: {
      enabled: false
    }
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}


// Search Service
resource SearchService 'Microsoft.Search/searchServices@2024-03-01-preview' = {
  name: SearchServiceName
  location: location
  sku: {
    name: 'standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: 'Enabled'
    semanticSearch: 'free'
  }
}

// Cognitive Service Open AI
resource cognitiveService 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: cognitiveServiceName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

// Deploy Open AI model gpt-35-turbo
resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = {
  parent: cognitiveService
  name: 'gpt-4o'
  sku: {
    name: 'Standard'
    capacity: 20
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-05-13'
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    raiPolicyName: 'Microsoft.Default'
  }
  dependsOn: [
    textEmbeddingAda002Deployment
  ]
}

// Deploy Open AI model text-embedding-ada-002
resource textEmbeddingAda002Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = {
  parent: cognitiveService
  name: 'text-embedding-ada-002'
  sku: {
    name: 'Standard'
    capacity: 20
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'text-embedding-ada-002'
      version: '2'
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    raiPolicyName: 'Microsoft.Default'
  }
}

// Azure SQL Database with SQL and Microsoft Entra authentication enabled. Also Allow Azure Services and resources to access this server
resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: 'sqladmin'
    administratorLoginPassword: 'Password1234!'
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'User'
      login: 'Douwe@Capgeminilanding.onmicrosoft.com'
      sid: '1d18bbec-ccea-4818-8f94-1e2f80306df1'
      tenantId: '20c1f0e2-fd5c-4015-842d-13c4088e745f'
      azureADOnlyAuthentication: false
    }
    restrictOutboundNetworkAccess: 'Disabled'
  }
}

// Database with the name 'OnlineShop'
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  location: location
  name: 'OnlineShop'
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
    availabilityZone: 'NoPreference'
  }
}

resource AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource ClientIPAddress 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  parent: sqlServer
  name: 'ClientIPAddress'
  properties: {
    startIpAddress: clientIPAddress
    endIpAddress: clientIPAddress
  }
}

resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  parent: sqlServer
  name: 'AzureRange'
  properties: {
    startIpAddress: '147.161.0.0'
    endIpAddress: '147.161.255.255'
  }
}

// Deploy Azure Speech Services 
resource speechServices 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: speechServicesName
  location: 'westus2'
  kind: 'SpeechServices'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

// Deploy Azure Text Analytics Language Services
resource textAnalytics 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: textAnalyticsName
  location: location
  kind: 'TextAnalytics'
  sku: {
    name: 'S'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }
}

