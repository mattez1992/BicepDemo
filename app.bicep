param environmentName string = 'environment-name'
param location string = resourceGroup().location
param appName string = 'devops22-firstName'
param costing string = 'bill-payer'

@secure()
param dbPassword string
param dbAdmin string = 'admin-name'
param sqlDbName string = 'db-name'
param sqlServerName string = 'sql-server-name'

var appFullName = 'app-${appName}-${toLower(environmentName)}'
var planName = 'plan-devops22-bicep'
var shouldRestrictIp = toLower(environmentName) == 'test'
var skuName = 'F1'
var skuCapacity = 1

resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: 'kv-bicep-test'
}
resource secret 'Microsoft.KeyVault/vaults/secrets@2019-09-01'= {
  name: 'TestConnection'
  parent:kv
  properties:{
    value:'Data Source=tcp:${sqlServerName}.database.windows.net,1433;Initial Catalog=${sqlDbName};User Id=${dbAdmin};Password=${dbPassword})}'
  }
}
resource appPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  location: location
  name: planName
  kind: 'app'
  properties: {
    elasticScaleEnabled: false
    reserved: false
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  tags: {
    costing: costing
  }
}

resource app 'Microsoft.Web/sites@2022-03-01' = {
  kind: 'api'
  dependsOn: [
    appInsightsModule
  ]
  location: location
  name: appFullName
  identity:{
      type:'SystemAssigned'
  }
  properties: {
    enabled: true
    serverFarmId: appPlan.id
    reserved: false
    hostNamesDisabled: false
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      http20Enabled: true
      ipSecurityRestrictions: shouldRestrictIp ? [
        {
          action: 'Allow'
          ipAddress: '80.216.164.225/32'
          name: 'Home'
          priority: 100
        }
      ] : []
      ftpsState: 'Disabled'
      remoteDebuggingEnabled: false
      appSettings: [
        {
          name: 'EmailFrom'
          value: 'iac@nackademin.se'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsModule.outputs.instrumentationKey
        }
      ]
      connectionStrings: [
        {
          name: 'TestConnection'
          // connectionString: 'Data Source=tcp:${sqlServerName}.database.windows.net,1433;Initial Catalog=${sqlDbName};User Id=${dbAdmin};Password=${dbPassword}'
          connectionString:'@Microsoft.KeyVault(SecretUri=${secret.properties.secretUri})'
          type: 'SQLAzure'
        }
      ]
    }
  }
  tags: {
    costing: costing
  }
}
output appObjectId string = app.identity.principalId
module appInsightsModule 'appinsights.bicep' = {
  name: 'appInsightsDeploy'
  params: {
    environmentName: environmentName
    location: location
    appName: appName
    costing: costing
  }

}

module storageModule 'storage.bicep' = {
  name:'storageDeploy'
  params:{
    location:location
    storageName:appFullName
    tags: {
      costing: costing
    }
  }
}

module functionModule 'functionapp.bicep'= {
  name:'functionDeploy'
  dependsOn:[
    appInsightsModule
    storageModule
  ]
  params:{
    applicationInsightsInstrumentationKey:appInsightsModule.outputs.instrumentationKey
    hostingPlanId:appPlan.id
    storageAccountName:storageModule.outputs.storageAccountName
    storageKey:storageModule.outputs.storageKeyValue
    location:location
  }

}
