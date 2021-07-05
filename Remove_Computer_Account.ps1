# ==================================================================
# Author:       Weithenn Wang (weithenn at weithenn.org)
# Version:      v0.1 - July 5, 2021
# Description:  Remove the computer account source by list
# ==================================================================

# Get credential
$ADUser = "LAB\Weithenn"
$Domain_Credential = Get-Credential -Credential $ADUser
$Computer_Account = Get-Content -Path C:\PowerShell\Remove_Computer_Account.txt



# Verify the number of computer accounts
(Get-Content -Path C:\PowerShell\Remove_Computer_Account.txt).Count



# Remove Computer Account
foreach ($Computer in $Computer_Account){
    If (Get-ADComputer -Filter {Name -eq $Computer}){
        Write-Host "$Computer - remove computer account!" -ForegroundColor Green
        Remove-ADComputer -Identity $Computer -Credential $Domain_Credential -Confirm:$false
    } else {
        Write-Host "$Computer - computer account does not exist in AD" -ForegroundColor Red
    }
}