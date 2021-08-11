# ==========================================================================================
# Author:       Weithenn Wang (weithenn at weithenn.org)
# Version:      v0.2 - Auguest 11, 2021
# Description:  Execution multi SSH connection through Windows Terminal by hosts list
# Requirment:
#  - Get Windows Terminal from Windows Store
#      https://www.microsoft.com/en-us/p/windows-terminal/9n0dx20hk701
#  - Install OpenSSH Client
#      Get-WindowsCapability -Online | ? Name -Like 'OpenSSH.Client*'
#      Add-WindowsCapability -Online -Name 'OpenSSH.Client*'
# ==========================================================================================


# Get credential and convert secure straing to plain text
$Today = Get-Date -Format "yyyyMMdd"
$Linux_Credential = Get-Credential -Credential $Linux_Account
$Username = $Linux_Credential.UserName
$SecuresPassword = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Linux_Credential.Password) 
$Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($SecuresPassword)
$Wshell = New-Object -ComObject WScript.Shell



# Get SSH hosts list
$SSH_hosts = Get-Content -Path ".\ssh_hosts.txt"



# Test ping connectivity and ssh logon by hosts list
foreach ($Hosts in $SSH_hosts){
    If (Test-Connection -ComputerName $Hosts -Count 1 -Quiet){
        Start-Process -FilePath wt.exe -ArgumentList "-w 0 nt","ssh -o StrictHostKeyChecking=no $Username@$Hosts"
        Start-Sleep 5
        $Wshell.SendKeys($Password)
        $Wshell.SendKeys("{ENTER}")
    } else {
        Write-Host "$Hosts - ping and hostname resolution failed!" -ForegroundColor Red
        "$(Get-Date) - $Hosts" | Out-File -FilePath ".\$($Today)_ssh_failed_hosts.txt" -Append
    }
}