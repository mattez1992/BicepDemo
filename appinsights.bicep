param environmentName string = 'environment-name'
param location string = resourceGroup().location
param costing string = 'bill-payer'
param appName string = 'app-name'

var workspaceName = 'ws-devops22'
var appInsightFullName = 'appi-${appName}-${toLower(environmentName)}'

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: workspaceName
  location: location
  tags: {
    costing: costing
  }
}

resource ai 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightFullName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
  }
  tags: {
    costing: costing
  }
}

output instrumentationKey string = ai.properties.InstrumentationKey
