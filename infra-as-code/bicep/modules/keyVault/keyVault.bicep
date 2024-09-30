//Parameters to define
param environment string
var environment_lower = toLower(environment)
param location string = resourceGroup().location
param tenantId string = subscription().tenantId
param objectId string 

// Load the JSON content from globalParams and LocalParams
var globalParams = json(loadTextContent('../../../../globalParameters.json'))
var localParams = json(loadTextContent('parameters/localParameters.json'))

// Parameters for the deployment
var skuName  = localParams.skuName 
var keyVaultName = 'azkv-${globalParams.parNombreCortoCliente}-${environment_lower}'

// Resource for the Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
  tags: {
    Entorno: environment
    Desarrollador: 'MAS Analytics'
  }
  properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: tenantId
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: objectId
        permissions: {
          keys: [
            'get'
            'list'
            'create'
            'update'
            'import'
            'delete'
            'backup'
            'restore'
            'recover'
            'purge'
          ]
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'backup'
            'restore'
            'recover'
            'purge'
          ]
          certificates: [
            'get'
            'list'
            'delete'
            'create'
            'import'
            'update'
            'managecontacts'
            'getissuers'
            'listissuers'
            'setissuers'
            'deleteissuers'
            'manageissuers'
            'recover'
            'purge'
          ]
          storage: [
            'get'
            'list'
            'delete'
            'set'
            'update'
            'regeneratekey'
            'setsas'
            'listsas'
            'getsas'
            'deletesas'
          ]
        }
      }
    ]
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableSoftDelete: true
  }
}

output keyVaultId string = keyVault.id
