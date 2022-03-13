$resourceGroupName = "aci-codespaces"
$location = "westeurope"
$acrName = "kwacicodespaces"
$miName = "kw-aci-codespaces"
$aciName = "kw-aci-codespaces"

if ((az group exists --name $resourceGroupName) -eq "false") {
    az group create --name $resourceGroupName --location $location
}

if ((az acr list -g $resourceGroupName --query "[?name == '$acrName'].id") -eq "[]") {
    az acr create --name $acrName -g $resourceGroupName --sku Basic
}


if ((az identity list -g $resourceGroupName --query "[?name == '$miName'].id") -eq "[]") {
    az identity create --name $miName -g $resourceGroupName
}

# source: https://docs.microsoft.com/en-us/azure/container-instances/using-azure-container-registry-mi
$acrId = $(az acr show -g $resourceGroupName -n $acrName --query id -o tsv)
$spID = $(az identity show -g $resourceGroupName --name $miName --query principalId --output tsv)
az role assignment create --assignee $spID --scope $acrId --role acrpull

az acr build -r $acrName -t base-image ./base-image