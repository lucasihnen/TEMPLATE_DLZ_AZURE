//Parameters to define
param environment string
var environment_lower = toLower(environment)
param location string = resourceGroup().location

// Load the JSON content from globalParams and LocalParams
var globalParams = json(loadTextContent('../../../../globalParameters.json'))
var localParams = json(loadTextContent('parameters/localParameters.json'))

// Parameters for the deployment
var synapseWorkspaceName = 'azsynw-${globalParams.parNombreCortoCliente}-${environment_lower}'
param sqlAdministratorLogin string = 'sqlAdminUser'
param sqlAdministratorPassword string
var storageAccountName = '${globalParams.parNombreCortoCliente}storage${environment_lower}'
param fileSystemName string = 'myFileSystem'

// Reference the existing storage account
resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

// Resource for the Synapse workspace
resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: synapseWorkspaceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    Entorno: environment
    Desarrollador: 'MAS Analytics'
  }
  properties: {
    defaultDataLakeStorage: {
      accountUrl: 'https://${existingStorageAccount.name}.dfs.core.windows.net'
      filesystem: fileSystemName
    }
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorPassword
  }
}

//// Resource for the SQL pool (optional)
//resource sqlPool 'Microsoft.Synapse/workspaces/sqlPools@2021-06-01' = {
//  name: '${synapseWorkspace.name}/mySqlPool'
//  location: location
//  properties: {
//    sku: {
//      name: 'DW100c'
//      tier: 'DataWarehouse'
//    }
//  }
//  dependsOn: [
//    synapseWorkspace
//  ]
//}

output synapseWorkspaceId string = synapseWorkspace.id
