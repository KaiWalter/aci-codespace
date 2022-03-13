[CmdletBinding()]
param (
        [Parameter(Position = 1)]
        [string]
        $Image = "01-base-ssh",
        [string]
        $PublicKeyFile = "codespace.pub",
        [string]
        $PrivateKeyFile = "codespace",
        [string]
        $User = "code"
)

function updateSshConfig {
        param (
                [string]
                $addContent = $null
        )

        $configFilePath = Join-Path -Resolve $HOME ".ssh" "config"

        if (Test-Path $configFilePath) {
                $content = Get-Content $configFilePath -Raw
                $content = $content -replace "(?msi)Host codespace.*?HostName.*?User.*?IdentityFile.*\s", ""
                if ($addContent) {
                        $content += $addContent
                } 
                $content | Set-Content -Path $configFilePath
        }
}

function cleanupKnownHosts {
        param (
                [string]
                $aciIp
        )

        $KnownHostsFilePath = Join-Path -Resolve $HOME ".ssh" "known_hosts"

        if (Test-Path $KnownHostsFilePath) {
                $content = Get-Content $KnownHostsFilePath -Raw
                $content = $content -replace "$aciIp.*\s", ""
                $content | Set-Content -Path $KnownHostsFilePath
                $content = Get-Content $KnownHostsFilePath
                $content | ? { $_ -match "\S" } | Set-Content $KnownHostsFilePath
        }

}

$resourceGroupName = "aci-codespaces"
$acrName = "kwacicodespaces"
$miName = "kw-aci-codespaces"
$aciName = "kw-aci-codespaces"

$acrLoginServer = $(az acr show -g $resourceGroupName -n $acrName  --query loginServer -o tsv)

$userID = $(az identity show -g $resourceGroupName --name $miName --query id --output tsv)
$PublicKeyPath = $(Join-Path -Resolve $HOME ".ssh" $PublicKeyFile)
$publicKey = Get-Content $PublicKeyPath
# $PrivateKeyPath = $(Join-Path -Resolve $HOME ".ssh" $PrivateKeyFile)

az container create --name $aciName `
        --resource-group $resourceGroupName `
        --image $acrLoginServer/$Image `
        --acr-identity $userID `
        --assign-identity $userID `
        --ports 22 `
        --dns-name-label $aciName `
        --secrets authorized_keys="$publicKey" `
        --secrets-mount-path "/home/${User}/.ssh" `
        --restart-policy OnFailure


$aciIp = $(az container show --name $aciName --resource-group $resourceGroupName --query ipAddress.ip -o tsv)

$addContent = @"
Host codespace
  HostName $aciIp
  User $User
  IdentityFile ~/.ssh/$PrivateKeyFile

"@

updateSshConfig $addContent

cleanupKnownHosts $aciIp

"-" * 80

# initial connect to skip host key checking

$retries = 10
$success = $false

while ($retries -gt 0) {
        ssh -o "StrictHostKeyChecking no" $User@codespace lsb_release -a
        if ($?) {
                $retries = 0
                $success = $true
        }
        else {
                $retries -= 1
                Write-Host "ssh failed - attempts left:" $retries " - sleeping 15 seconds..."
                if ($retries -gt 0) {
                        Start-Sleep -Seconds 15
                }
        }
}

# final connect

if ($success) {
        if ($Image -match "vscode") {
                code -n --remote ssh-remote+code@codespace /home/code
        }
        else {
                ssh $User@codespace
        }
}

"-" * 80

Read-Host "hit enter to stop & delete container instance"

az container stop --name $aciName -g $resourceGroupName

az container delete --name $aciName -g $resourceGroupName --yes

cleanupKnownHosts $aciIp
