#!/bin/bash

# Soruce to color print:
source infra-as-code/bicep/resources/echo_color.sh
source infra-as-code/bicep/resources/ascii_mas.sh

# Function to check the result of the previous command
check_command() {
    if [ $? -ne 0 ]; then
        echo "-------->Error: $1 failed"
        exit 1
    fi
    echo_color "$1 completed successfully" "green"
    echo "--------------------------------------------------------------------"
}

# Function to remove non alphabetic characters from a string
remove_non_alpha() {
    local input_string="$1"
    # Use tr to remove all non-alphabetic characters
    local cleaned_string=$(echo "$input_string" | tr -cd '[:alpha:]')
    echo "$cleaned_string"
}

# Suppress az CLI warnings and recommendations
export AZURE_CORE_OUTPUT=none

# Read global parameters from JSON file
GLOBAL_PARAMETERS_FILE="globalParameters.json"
if [ ! -f "$GLOBAL_PARAMETERS_FILE" ]; then
    echo_color "Error: $GLOBAL_PARAMETERS_FILE not found!" "red"
    exit 1
fi

# Read global parameters from JSON file
parNombreCompletoCliente=$(jq -r '.parNombreCompletoCliente' $GLOBAL_PARAMETERS_FILE)
parNombreCortoCliente=$(jq -r '.parNombreCortoCliente' $GLOBAL_PARAMETERS_FILE)
parLocation=$(jq -r '.parLocation' $GLOBAL_PARAMETERS_FILE)
parSubscriptionIdAnalytics=$(jq -r '.parSubscriptionIdAnalytics' $GLOBAL_PARAMETERS_FILE)
parSubscriptionIdPlatform=$(jq -r '.parSubscriptionIdPlatform' $GLOBAL_PARAMETERS_FILE)
environments=$(jq -c '.parEnvironments[]' $GLOBAL_PARAMETERS_FILE)


# Inititiate Deployment Process:
echo_color "--------------------------------------------------------------------" "yellow"
echo_color "---------------    Starting deployment process...    ---------------" "yellow"
echo_color "--------------------------------------------------------------------" "yellow"

# Setea la suscripcicion a usar para el resto de los deployments
AnalyticsSubscriptionId="$parSubscriptionIdAnalytics"
az account set --subscription $AnalyticsSubscriptionId
az provider register --namespace Microsoft.Sql
check_command "Registration of Sql Provider in Subscription ${AnalyticsSubscriptionId}"

# Iterar sobre el listado de entornos de parEnvironments en globalParameters.json
echo "$environments" | while IFS= read -r env; do
    
    # Extrae el nombre de entorno y region
    environmentName=$(echo "$env" | jq -r '.environmentName')
    region=$(echo "$env" | jq -r '.region')
    ENV=$(remove_non_alpha "$environmentName")

    # Setea la suscripcicion a usar para el resto de los deployments
    AnalyticsSubscriptionId="$parSubscriptionIdAnalytics"
    az account set --subscription $AnalyticsSubscriptionId

    echo ""
    echo_color "--------------->    Starting Environtment: $ENV...    <---------------" "bold_white"
    
    # Modulo 1: Crear Resource Group con el nombre y ubicacion de globalParameters.json:
    LOCATION="$region"
    
    echo_color "Modulo 1: Grupos de recurso ($ENV)" "bold_blue"
    echo_color "Creating Resource Group $GROUP in location: $LOCATION..." "cyan"

    GROUP="GR_MASANALYTICS_${ENV}"

    az group create --name "$GROUP" --location "$LOCATION" > /dev/null 
    check_command "Resource Group $GROUP"

    # Modulo 2: Crear Storage Account y containers raw/silver/gold:
    echo_color "Modulo 2: Storage Account ($ENV)" "bold_blue"
    echo_color "Creating Storage Accounts for environment: $ENV..." "cyan"
    
    dateYMD=$(date +%Y%m%dT%H%M%S%NZ)
    NAME="dlz-StorageDeployment-${ENV}-${dateYMD}"
    LOCATION="$parLocation"
    TEMPLATEFILE="infra-as-code/bicep/modules/storageAccount/storageAccount.bicep"   
    
    az deployment group create --name ${NAME:0:63} --resource-group $GROUP --template-file $TEMPLATEFILE --parameters environment=$ENV > /dev/null
    check_command "Storage Accounts for Environment: $ENV"
    
    # Modulo 3: Crear Data Factory por entorno
    echo_color "Modulo 3: Data Factory ($ENV)" "bold_blue"
    echo_color "Creating Data Factory for environment: $ENV..." "cyan"

    dateYMD=$(date +%Y%m%dT%H%M%S%NZ)
    NAME="dlz-FactoryDeployment-${ENV}-${dateYMD}"
    LOCATION="$parLocation"
    TEMPLATEFILE="infra-as-code/bicep/modules/dataFactory/dataFactory.bicep"

    az deployment group create --name ${NAME:0:63} --resource-group $GROUP --template-file $TEMPLATEFILE --parameters environment=$ENV > /dev/null
    check_command "Data Factory for Environment: $ENV"

    # Modulo 4: Crear Azure Key Vault por entorno
    echo_color "Modulo 4: Azure Key Vault ($ENV)" "bold_blue"
    echo_color "Creating Azure Key Vault for environment: $ENV..." "cyan"

    dateYMD=$(date +%Y%m%dT%H%M%S%NZ)
    NAME="dlz-KeyVaultDeployment-${ENV}-${dateYMD}"
    LOCATION="$parLocation"
    TEMPLATEFILE="infra-as-code/bicep/modules/keyVault/keyVault.bicep"
    OBJECT_ID=$(az ad signed-in-user show --query id --output tsv) ## Para obtener el id de la cuenta haciendo el deployment y darle acceso al Key Vault

    az deployment group create --name ${NAME:0:63} --resource-group $GROUP --template-file $TEMPLATEFILE --parameters environment=$ENV objectId=$OBJECT_ID > /dev/null
    check_command "Key Vault for Environment: $ENV"

    # Modulo 5: Crear Synapse Analytics
    echo_color "Modulo 5: Azure Synapse Analytics ($ENV)" "bold_blue"
    echo_color "Creating Azure Synapse Analytics for environment: $ENV..." "cyan"   
    
    dateYMD=$(date +%Y%m%dT%H%M%S%NZ)
    NAME="dlz-KeyVaultDeployment-${ENV}-${dateYMD}"
    LOCATION="$parLocation"
    PASSWORD_SYNW=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '') 
    TEMPLATEFILE="infra-as-code/bicep/modules/synapseAnalytics/synapseAnalytics.bicep"

    az deployment group create --name ${NAME:0:63} --resource-group $GROUP --template-file $TEMPLATEFILE --parameters environment=$ENV sqlAdministratorPassword=$PASSWORD_SYNW > /dev/null
    check_command "Synapse Analytics Workspace for Environment: $ENV"
    
    ### Modulo 5.1: Agregar contraseña Synapse a Azure Key Vault
    echo_color "Modulo 5.1: Agregar contraseña a Key Vault ($ENV)" "bold_blue"
    echo_color "Adding Sql Admin Password Azure Synapse Analytics: $ENV..." "cyan" 
    ENV_LOWER="${ENV,,}" ## Codigo para hacer lower() la variable ENV
    KEYVAULT="azkv-${parNombreCortoCliente}-${ENV_LOWER}"
    SECRETNAME="SynapseSqlAdminPassword-${ENV}"

    az keyvault secret set --vault-name $KEYVAULT --name $SECRETNAME --value $PASSWORD_SYNW
    check_command "Sql Admin Password Azure Synapse Analytics: $ENV"

    # Modulo X:

    # Fin Modulo X

    echo_color "--------------------------------------------------------------------" "bold_yellow"
    echo_color "--------------->    Deployed Environtment: $ENV      <---------------" "bold_yellow"
    sleep 1
done
check_command "Deployment"

ascii_mas
echo ""
echo_color "--------------------------------------------------------------------" "yellow"
echo_color "---------------    Finished deployment process <3    ---------------" "yellow"
echo_color "--------------------------------------------------------------------" "yellow"