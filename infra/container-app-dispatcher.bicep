param location string = resourceGroup().location
resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-airfreight-coldchain'
  location: location
  properties: { sku: { name: 'PerGB2018' }, retentionInDays: 90 }
}
