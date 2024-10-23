# ==================================================================================
# Author:         Weithenn Wang (weithenn at weithenn.org)
# Version:        v0.1 - October, 2024
# IT event:       Kubernetes Summit 2024
# Workshop Name:  Azure Kubernetes Service with GitOps
# Description:    Step-by-step to build up AKS Edge Essential
# ==================================================================================





$Username = "AKSEE"
$Password = "K8sSummit@20241023"
$AzureHost = "aksee-hol-"
$Wshell = New-Object -ComObject WScript.Shell;

$Array = 1..70

Foreach ($i in $Array){
    cmdkey /generic:$AzureHost$i.eastasia.cloudapp.azure.com /user:$Username /pass:$Password
    mstsc /v:$AzureHost$i.eastasia.cloudapp.azure.com
    Start-Sleep 5
    $Wshell.SendKeys("{TAB}{TAB}{TAB}{ENTER}")
    cmdkey /delete:$AzureHost$i.eastasia.cloudapp.azure.com
}

# Clear RDP connections history
Get-ChildItem "HKCU:\Software\Microsoft\Terminal Server Client" -Recurse | Remove-ItemProperty -Name UsernameHint -Ea 0
Remove-Item -Path 'HKCU:\Software\Microsoft\Terminal Server Client\servers' -Recurse 2>&1 | Out-Null
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Terminal Server Client\Default' 'MRU*' 2>&1 | Out-Null
$docs = [environment]::getfolderpath("mydocuments") + '\Default.rdp'
remove-item $docs -Force 2>&1 | Out-Null