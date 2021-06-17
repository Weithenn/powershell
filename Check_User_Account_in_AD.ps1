# ==================================================================
# Author:        Weithenn Wang (weithenn at weithenn.org)
# Version:       v0.1 - June 16, 2021
# Description:   Check whether the user exists in AD or not
# ==================================================================

# Read users list
$Users_List = Get-Content -Path C:\tmp\UsersList.txt
$Today = Get-Date -Format "yyyyMMdd"



# Option 1: Check whether the user exists in AD or not
foreach ($User in $Users_List){
    If (Get-ADUser -Filter {SamAccountName -eq $User}){
        Write-Host "$User - OK!" -ForegroundColor Green
    } else {
        Write-Host "$User - account does not exist in AD" -ForegroundColor Red
    }
}



# Option 2: Check whether the user exists in AD or not and export result
foreach ($User in $Users_List){
    If (Get-ADUser -Filter {SamAccountName -eq $User}){
        $User | Out-File -FilePath C:\PowerCLI\"$Today"_UsersList_OK.txt -Append
    } else {
        $User | Out-File -FilePath C:\PowerCLI\"$Today"_UsersList_not_exist.txt -Append
    }
}
