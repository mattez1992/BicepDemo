@description('A unique name that is appended to the service names. If empty a unique string will be generated.')
@allowed([
  'Test'
  'UAT'
  'Prod'
])
@minLength(2)
@maxLength(4)
param environmentName string = 'Prod'

param appName string = 'dev-mattias-bic'
param location string = resourceGroup().location
param costing string = 'nackademin'

var dbAdmin = 'devops22admin'

var sqlDbName = 'bicdb-${appName}-${toLower(environmentName)}-${environmentName}'
var sqlServerName = 'sql-dev-mattias-bic'

resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: 'kv-bicep-test'
}

module appModule 'app.bicep' = {
  name: 'appDeploy'
  params: {
    environmentName: environmentName
    location: location
    appName: appName
    dbAdmin: dbAdmin
    dbPassword: kv.getSecret('dbPassword')
    sqlDbName: sqlDbName
    sqlServerName: sqlServerName
    costing: costing
  }
}

module sqlServerModule 'sqlserver.bicep' = {
  name: 'sqlServerDeploy'
  params: {
    location: location
    dbAdmin: dbAdmin
    dbPassword: kv.getSecret('dbPassword')
    sqlDbName: sqlDbName
    sqlServerName: sqlServerName
    costing: costing
  }
}

resource accessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: '${kv.name}/add'
  dependsOn:[
    appModule
  ]
  properties: {
    accessPolicies: [
      {
        objectId: appModule.outputs.appObjectId
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}
