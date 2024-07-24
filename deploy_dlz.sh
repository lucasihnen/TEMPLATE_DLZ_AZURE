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
echo_color "--------------------------------------------------------------" "yellow"
echo_color "------------    Starting deployment process...    ------------" "yellow"
echo_color "--------------------------------------------------------------" "yellow"

# Iterar sobre el listado de entornos de parEnvironments en globalParameters.json
echo "$environments" | while IFS= read -r env; do
    
    # Extrae el nombre de entorno y region
    environmentName=$(echo "$env" | jq -r '.environmentName')
    region=$(echo "$env" | jq -r '.region')
    ENV=$(remove_non_alpha "$environmentName")
    echo ""
    
    echo_color "---------->    Starting Environtment: $ENV...    <----------" "bold_white"
    
    # Modulo 1: Crear Resource Group con el nombre y ubicacion de globalParameters.json:
    echo_color "Modulo 1: Grupos de recurso ($ENV)" "bold_blue"

    LOCATION="$region"
    GROUP="GR_MASANALYTICS_${ENV}"

    AnalyticsSubscriptionId="$parSubscriptionIdAnalytics"
    az account set --subscription $AnalyticsSubscriptionId

    echo_color "Creating Resource Group $GROUP in location: $LOCATION..." "cyan"
    
    az group create --name "$GROUP" --location "$LOCATION" > /dev/null 
    echo_color "Resource Group $GROUP completed successfully" "green"
    echo "----------------------------------------------"

   # Modulo 2: Crear Storage Account y containers raw/silver/gold:
   echo_color "Modulo 2: Storage Account ($ENV)" "bold_blue"
   echo_color "Creating Storage Accounts for environment: $ENV" "cyan"

   dateYMD=$(date +%Y%m%dT%H%M%S%NZ)
   NAME="alz-MGDeployment-${ENV}-${dateYMD}"
   LOCATION="$parLocation"
   TEMPLATEFILE="infra-as-code/bicep/modules/storageAccount/storageAccount.bicep"

   AnalyticsSubscriptionId="$parSubscriptionIdAnalytics"
   az account set --subscription $AnalyticsSubscriptionId

   az deployment group create --name ${NAME:0:63} --resource-group $GROUP --template-file $TEMPLATEFILE --parameters environment=$ENV > /dev/null

   check_command "Storage Accounts for Environment: $ENV"

   echo_color "----------------------------------------------------------" "bold_yellow"
   echo_color "---------->    Deployed Environtment: $ENV      <----------" "bold_yellow"
   sleep 1
done

ascii_mas
echo ""
echo_color "--------------------------------------------------------------------" "yellow"
echo_color "---------------    Finished deployment process <3    ---------------" "yellow"
echo_color "--------------------------------------------------------------------" "yellow"