# ############################################################
# ||                                                        ||
# ||             Created by: Douwe van de Ruit              ||
# ||        Role: GenAI SPOC / Principle Consultant         ||
# ||   Purpose of this file: Deploy the infra components    ||
# ||           needed for the Avatar prototype.             ||
# ||                                                        ||
# ############################################################

# Parameters for generating local.settings.json
$postfix = "dyt362iqwnlli"
$resourceGroupName = "rg-ufs-avatar-t-04"
$region = "eastus2"

# Install the Azure PowerShell module if not already installed
# Check if the Az module is loaded in the current session
if (Get-Module -Name Az) {
    # If it's loaded, remove it
    Remove-Module -Name Az
    Remove-Module -Name Az.Storage
}

# Check if the Az module is available
if (-not (Get-Module -Name Az -ListAvailable)) {
    # If it's not available, install it
    Install-Module -Name Az -AllowClobber -Force
    Install-Module -Name Az.Search -AllowClobber -Force
}

# Connect to Azure using your credentials
# Connect-AzAccount -subscription "c200e3e7-0839-483b-848b-25a98451f2cd"

# Set the values for the Azure Resources
$azure_openai_endpoint_name = "cs-" + $postfix
$azure_search_endpoint_name = "https://ss-" + $postfix + ".search.windows.net"
$azure_search_resource_name = "ss-" + $postfix
$azure_speech_endpoint_name = "sps-" + $postfix
$azure_text_analytics_endpoint_name = "https://" + $region + ".cognitiveservices.azure.com/"
$azure_text_analytics_resource_name = "tas-" + $postfix
$azure_storage_account_name = "sta" + $postfix

$azure_storage_context = New-AzStorageContext -StorageAccountName $azure_storage_account_name -UseConnectedAccount
$myIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content

# Retrieve the values from Azure
$azureValues = @{
    "AZURE_OPENAI_ENDPOINT" = (Get-AzCognitiveServicesAccount -ResourceGroupName $resourceGroupName -Name $azure_openai_endpoint_name).Endpoint
    "AZURE_OPENAI_API_KEY" = (Get-AzCognitiveServicesAccountKey -ResourceGroupName $resourceGroupName -Name $azure_openai_endpoint_name).Key1
    "AZURE_SEARCH_ENDPOINT" = $azure_search_endpoint_name
    "AZURE_SEARCH_API_KEY" = (Get-AzSearchAdminKeyPair -ResourceGroupName $resourceGroupName -ServiceName $azure_search_resource_name).Primary
    "AZURE_SPEECH_API_KEY" = (Get-AzCognitiveServicesAccountKey -ResourceGroupName $resourceGroupName -Name $azure_speech_endpoint_name).Key1
    "TEXT_ANALYTICS_ENDPOINT" = $azure_text_analytics_endpoint_name
    "TEXT_ANALYTICS_KEY" = (Get-AzCognitiveServicesAccountKey -ResourceGroupName $resourceGroupName -Name $azure_text_analytics_resource_name).Key1
    "BLOB_SAS_URL" = (New-AzStorageContainerSASToken -Name "product-images" -Context $azure_storage_context -FullUri -Permission rwd)
    "SQL_DB_SERVER" = (Get-AzSqlServer -ResourceGroupName "$resourceGroupName" -ServerName "sql-$postfix").FullyQualifiedDomainName
}

# Output the values
$azureValues

# Generate local.settings.json.verify file
$localSettingsJson = @{
    "IsEncrypted" = $false
    "Values" = @{
        "AzureWebJobsStorage" = ""
        "FUNCTIONS_WORKER_RUNTIME" = "node"
        "AZURE_OPENAI_ENDPOINT" = $azureValues["AZURE_OPENAI_ENDPOINT"]
        "AZURE_OPENAI_API_KEY" = $azureValues["AZURE_OPENAI_API_KEY"]
        "AZURE_OPENAI_CHAT_DEPLOYMENT" = "gpt-4o"
        "AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT" = "text-embedding-ada-002"
        "AZURE_OPENAI_API_VERSION" = "2024-02-01"
        "AZURE_SEARCH_ENDPOINT" = $azureValues["AZURE_SEARCH_ENDPOINT"]
        "AZURE_SEARCH_API_KEY" = $azureValues["AZURE_SEARCH_API_KEY"]
        "AZURE_SEARCH_INDEX" = "demo-index"
        "AZURE_SPEECH_REGION" = "westus2"
        "AZURE_SPEECH_API_KEY" = $azureValues["AZURE_SPEECH_API_KEY"]
        "TEXT_ANALYTICS_ENDPOINT" = $azureValues["TEXT_ANALYTICS_ENDPOINT"]
        "TEXT_ANALYTICS_KEY" = $azureValues["TEXT_ANALYTICS_KEY"]
        "BLOB_SAS_URL" = $azureValues["BLOB_SAS_URL"]
        "SQL_DB_SERVER" = $azureValues["SQL_DB_SERVER"]
        "SQL_DB_USER" = "sqladmin"
        "SQL_DB_PASSWORD" = "Password1234!"
        "SQL_DB_NAME" = "OnlineShop"
    }
}

$filePath = "../api/local.settings.json"
New-Item -ItemType File -Path $filePath -Force
$localSettingsJson | ConvertTo-Json | Out-File -FilePath $filePath -Encoding UTF8
$localSettingsJson | ConvertTo-Json | Out-File -FilePath "../api/local.settings.json" -Encoding UTF8

$infraBicepParam = @"
using './infra.bicep'

param clientIPAddress = '$myIP'
"@

$infraBicepParam | Out-File -FilePath "./infra.bicepparam" -Encoding UTF8

