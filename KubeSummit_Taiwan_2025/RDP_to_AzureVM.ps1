# ==================================================================================
# Author:         Weithenn Wang (weithenn at weithenn.org)
# Version:        v0.1 - October 22, 2025
# IT event:       KubeSummit Taiwan 2025
# Workshop Name:  整合 KMS 加密打造安全的 Kubernetes 容器環境
# Description:    Step-by-step to build up AKS Edge Essential with KMS
# ==================================================================================


$Username = "KubeAdmin"
$Password = "KubeSummit@2025"
$AzureHost = "kubesummit-"
$Wshell = New-Object -ComObject WScript.Shell;

$Array = 1..35

Foreach ($i in $Array) {
    # 將數字轉成兩位數字串，例如 1 -> 01, 9 -> 09, 10 -> 10
    $num = "{0:D2}" -f $i

    cmdkey /generic:$AzureHost$num.eastasia.cloudapp.azure.com /user:$Username /pass:$Password
    mstsc /v:$AzureHost$num.eastasia.cloudapp.azure.com
    Start-Sleep 5
    $Wshell.SendKeys("{TAB}{TAB}{TAB}{ENTER}")
    cmdkey /delete:$AzureHost$num.eastasia.cloudapp.azure.com
}


# Clear RDP connections history
Get-ChildItem "HKCU:\Software\Microsoft\Terminal Server Client" -Recurse | Remove-ItemProperty -Name UsernameHint -Ea 0
Remove-Item -Path 'HKCU:\Software\Microsoft\Terminal Server Client\servers' -Recurse 2>&1 | Out-Null
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Terminal Server Client\Default' 'MRU*' 2>&1 | Out-Null
$docs = [environment]::getfolderpath("mydocuments") + '\Default.rdp'
remove-item $docs -Force 2>&1 | Out-Null