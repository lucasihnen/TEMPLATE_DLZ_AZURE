#!/bin/bash

# Function to check the result of the previous command
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed"
        exit 1
    fi
    echo "$1 completed successfully"
}

# Function to remove non alphabetic characters from a string
remove_non_alpha() {
    local input_string="$1"
    # Use tr to remove all non-alphabetic characters
    local cleaned_string=$(echo "$input_string" | tr -cd '[:alpha:]')
    echo "$cleaned_string"
}

# Read global parameters from JSON file
GLOBAL_PARAMETERS_FILE="globalParameters.json"
if [ ! -f "$GLOBAL_PARAMETERS_FILE" ]; then
    echo "Error: $GLOBAL_PARAMETERS_FILE not found!"
    exit 1
fi

# Read global parameters from JSON file
parNombreCompletoCliente=$(jq -r '.parNombreCompletoCliente' $GLOBAL_PARAMETERS_FILE)
parNombreCortoCliente=$(jq -r '.parNombreCortoCliente' $GLOBAL_PARAMETERS_FILE)
parLocation=$(jq -r '.parLocation' $GLOBAL_PARAMETERS_FILE)
parSubscriptionIdAnalytics=$(jq -r '.parSubscriptionIdAnalytics' $GLOBAL_PARAMETERS_FILE)
parSubscriptionIdPlatform=$(jq -r '.parSubscriptionIdPlatform' $GLOBAL_PARAMETERS_FILE)
parEnvironments=($(jq -r '.parEnvironments[]' $GLOBAL_PARAMETERS_FILE))

for ENVIRONMENT in "${parEnvironments[@]}"; do

    # Modulo 1: Crear storage Accounts:
    echo "Storage Accounts for environment: $ENVIRONMENT"

    ENV=$(remove_non_alpha "$ENVIRONMENT")
    dateYMD=$(date +%Y%m%dT%H%M%S%NZ)
    NAME="alz-MGDeployment-${dateYMD}"
    LOCATION="$parLocation"
    GROUP="GR_MASANALYTICS_${ENV}"
    TEMPLATEFILE="infra-as-code/bicep/modules/storageAccount/storageAccount.bicep"
    AnalyticsSubscriptionId="$parSubscriptionIdAnalytics"

    az account set --subscription $AnalyticsSubscriptionId

    echo "Creating RG $GROUP in location: $LOCATION"

    az group create --name "$GROUP" --location "$LOCATION"
    az deployment group create --name ${NAME:0:63} --resource-group $GROUP --template-file $TEMPLATEFILE --parameters environment=$ENV
    echo "------------------------"

    check_command "Storage Accounts for Environment: $ENV"
    sleep 1

done
