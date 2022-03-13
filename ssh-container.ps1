$resourceGroupName = "aci-codespaces"
$acrName = "kwacicodespaces"
$miName = "kw-aci-codespaces"
$aciName = "kw-aci-codespaces"

$acrLoginServer = $(az acr show -g $resourceGroupName -n $acrName  --query loginServer -o tsv)

$userID = $(az identity show -g $resourceGroupName --name $miName --query id --output tsv)

$aciIp = $(az container create --name $aciName `
        --resource-group $resourceGroupName `
        --image $acrLoginServer/base-image `
        --acr-identity $userID `
        --assign-identity $userID `
        --ports 22 `
        --dns-name-label $aciName `
        --restart-policy OnFailure `
        --query ipAddress.ip -o tsv)

"-" * 80

ssh test@$($aciIp)

"-" * 80

Read-Host "hit enter to stop & delete container instance"

az container stop --name $aciName -g $resourceGroupName

az container delete --name $aciName -g $resourceGroupName --yes