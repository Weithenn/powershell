# ==================================================================================
# Author:       Weithenn Wang (weithenn at weithenn.org)
# Version:      v0.1 - July 18, 2023
# Description:  Execution multi RDP connection to Azure VM
# ==================================================================================

# Cloud Summit 2023 workshop variable
$Username = "hciuser"
$Password = "HCIworkshop@0719"
$AzureHost = "hci-hol-"
$Wshell = New-Object -ComObject WScript.Shell;
$Array = 1..35

Foreach ($i in $Array){
    cmdkey /generic:$AzureHost$i.japaneast.cloudapp.azure.com /user:$Username /pass:$Password
    mstsc /v:$AzureHost$i.japaneast.cloudapp.azure.com
    Start-Sleep 5
    $Wshell.SendKeys("{TAB}{TAB}{TAB}{ENTER}")
    cmdkey /delete:$AzureHost$i.japaneast.cloudapp.azure.com
}



# Clear RDP connections history
Get-ChildItem "HKCU:\Software\Microsoft\Terminal Server Client" -Recurse | Remove-ItemProperty -Name UsernameHint -Ea 0
Remove-Item -Path 'HKCU:\Software\Microsoft\Terminal Server Client\servers' -Recurse 2>&1 | Out-Null
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Terminal Server Client\Default' 'MRU*' 2>&1 | Out-Null
$docs = [environment]::getfolderpath("mydocuments") + '\Default.rdp'
remove-item $docs -Force 2>&1 | Out-Null
