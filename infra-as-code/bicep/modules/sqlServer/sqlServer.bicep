//Parameters to define
param environment string
var environment_lower = toLower(environment)
param location string = resourceGroup().location
param sqlAdminPassword string

// Load the JSON content from globalParams and LocalParams
var globalParams = json(loadTextContent('../../../../globalParameters.json'))
var localParams = json(loadTextContent('parameters/localParameters.json'))

var nombre_cliente_lower = replace(toLower(globalParams.parNombreCompletoCliente), ' ', '') // Quita Mayusculas y espacios intermedios "Cliente Generico" --> "clientegenerico"
var nombre_corto_cliente_lower = toLower(globalParams.parNombreCortoCliente)

// Parameters for the deployment
var sqlDatabaseEdition = localParams.sqlDatabaseEdition
var sqlDatabaseServiceObjective = localParams.sqlDatabaseServiceObjective
// var sqlDatabaseDtu = localParams.sqlDatabaseDTU
var sqlServerName = 'azsqls-${nombre_cliente_lower}-${environment_lower}'
var sqlDatabaseName = 'dw-${nombre_corto_cliente_lower}-${environment_lower}'
var sqlAdminUsername = 'SqlAdmin'

// Resource for the SQL server
resource sqlServer 'Microsoft.Sql/servers@2022-02-01-preview' = {
  name: sqlServerName
  location: location
  tags: {
    Entorno: environment
    Desarrollador: 'MAS Analytics'
  }
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
  }
  sku: {
    name: sqlDatabaseEdition
  }
}

// Resource for the SQL database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-02-01-preview' = {
  name: '${sqlServer.name}/${sqlDatabaseName}'
  location: location
  tags: {
    Entorno: environment
    Desarrollador: 'MAS Analytics'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
  sku: {
    name: sqlDatabaseServiceObjective
    tier: sqlDatabaseEdition
    //capacity: sqlDatabaseDtu
  }
  dependsOn: [
    sqlServer
  ]
}

resource sqlServerFirewallRule 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  name: '${sqlServerName}/AllowAllWindowsAzureIps'
  dependsOn: [
    sqlServer
  ]
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDatabase.name
