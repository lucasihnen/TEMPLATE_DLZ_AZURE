//Parameters to define
param environment string
var environment_lower = toLower(environment)
param location string = resourceGroup().location

// Load the JSON content from globalParams and LocalParams
var globalParams = json(loadTextContent('../../../../globalParameters.json'))
var localParams = json(loadTextContent('parameters/localParameters.json'))

// Define variables to extract values from the Global JSON Parameters
var storageAccountName = '${globalParams.parNombreCortoCliente}storage${environment_lower}'

// Define variables to extract values from the Local JSON Parameters
var skuName = localParams.skuName

// Define the resource for the storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// Define the resource for the raw-data container
resource rawDataContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storageAccount.name}/default/raw-data'
  properties: {}
  dependsOn: [
    storageAccount
  ]
}

// Define the resource for the silver-data container
resource silverDataContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storageAccount.name}/default/silver-data'
  properties: {}
  dependsOn: [
    storageAccount
  ]
}

// Define the resource for the gold-data container
resource goldDataContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storageAccount.name}/default/gold-data'
  properties: {}
  dependsOn: [
    storageAccount
  ]
}
