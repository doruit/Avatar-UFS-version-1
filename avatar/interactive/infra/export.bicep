param staticSites_Avatar_2_name string = 'Avatar-2'

resource staticSites_Avatar_2_name_resource 'Microsoft.Web/staticSites@2023-12-01' = {
  name: staticSites_Avatar_2_name
  location: 'East US 2'
  tags: {
    'hidden-link: /app-insights-resource-id': '/subscriptions/c200e3e7-0839-483b-848b-25a98451f2cd/resourceGroups/rg-ufs-copilot-web-t-02/providers/microsoft.insights/components/ai-ufs-copilot-web-t-02'
    'hidden-link: /app-insights-instrumentation-key': 'c1a8d6d3-25db-42ee-9e6c-569dc9bf4345'
    'hidden-link: /app-insights-conn-string': 'InstrumentationKey=c1a8d6d3-25db-42ee-9e6c-569dc9bf4345;IngestionEndpoint=https://eastus2-3.in.applicationinsights.azure.com/;LiveEndpoint=https://eastus2.livediagnostics.monitor.azure.com/;ApplicationId=6e684829-1c22-40ab-bea6-1f9659872964'
  }
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    repositoryUrl: 'https://github.com/doruit/${staticSites_Avatar_2_name}'
    branch: 'main'
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
    provider: 'GitHub'
    enterpriseGradeCdnStatus: 'Disabled'
  }
}

resource staticSites_Avatar_2_name_default 'Microsoft.Web/staticSites/basicAuth@2023-12-01' = {
  parent: staticSites_Avatar_2_name_resource
  name: 'default'
  location: 'East US 2'
  properties: {
    applicableEnvironmentsMode: 'SpecifiedEnvironments'
  }
}
