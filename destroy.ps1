$resourceGroupName = "aci-codespaces"

if ((az group exists --name $resourceGroupName) -eq "true") {
    az group delete --name $resourceGroupName
}
