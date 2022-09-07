@description('A unique name that is appended to the service names. If empty a unique string will be generated.')
@allowed([
  'Test'
  'UAT'
  'Prod'
])
@minLength(2)
@maxLength(4)
param environmentName string = 'Test'

param appName string = 'devops22-mattias'
param location string = resourceGroup().location
param costing string = 'nackademin'

var dbAdmin = 'devops22admin'
var dbPassword = 'Test123!'
var sqlDbName = 'sqldb-${appName}-${toLower(environmentName)}'
var sqlServerName = 'sql-devops22-mattias'

module appModule 'app.bicep' = {
  name: 'appDeploy'
  params: {
    environmentName: environmentName
    location: location
    appName: appName
    dbAdmin: dbAdmin
    dbPassword: dbPassword
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
    dbPassword: dbPassword
    sqlDbName: sqlDbName
    sqlServerName: sqlServerName
    costing: costing
  }
}
