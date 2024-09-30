//Parameters to define
param environment string
var environment_lower = toLower(environment)
param location string = resourceGroup().location

// Load the JSON content from globalParams and LocalParams
var globalParams = json(loadTextContent('../../../../globalParameters.json'))
var localParams = json(loadTextContent('parameters/localParameters.json'))

// Create variables
var dataFactoryName = 'azdf-mas-${globalParams.parNombreCortoCliente}-${environment_lower}'

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  tags: {
    Entorno: environment
    Desarrollador: 'MAS Analytics'
  }
  properties: {
    // Additional properties can be added here if needed
  }
}

output dataFactoryId string = dataFactory.id
