# ==================================================================================
# Author:       Weithenn Wang (weithenn at weithenn.org)
# Version:      v0.1 - Auguest 10, 2021
# Description:  Execution multi SSH connection through putty.exe by hosts list
# ==================================================================================

# Get credential and convert secure straing to plain text
$Today = Get-Date -Format "yyyyMMdd"
$Linux_Credential = Get-Credential -Credential $Linux_Account
$Username = $Linux_Credential.UserName
$SecuresPassword = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Linux_Credential.Password) 
$Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($SecuresPassword)
$Putty = "C:\PowerShell_Lab\putty.exe"
$Wshell = New-Object -ComObject WScript.Shell



# Get SSH hosts list
$SSH_hosts = Get-Content -Path C:\PowerShell_Lab\ssh_hosts.txt



# Test ping connectivity and ssh logon by hosts list
foreach ($Hosts in $SSH_hosts){
    If (Test-Connection -ComputerName $Hosts -Count 1 -Quiet){
        Start-Process -FilePath $Putty -ArgumentList "-ssh $Username@$Hosts -pw $Password"
        Start-Sleep 1
        $Wshell.SendKeys("Y")
    } else {
        Write-Host "$Hosts - ping and hostname resolution failed!" -ForegroundColor Red
        "$(Get-Date) - $Hosts" | Out-File -FilePath C:\PowerShell_Lab\"$Today"_ssh_failed_hosts.txt -Append
    }
}