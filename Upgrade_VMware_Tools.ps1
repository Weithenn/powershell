# ==================================================================
# Author:       Weithenn Wang (weithenn at weithenn.org)
# Version:      v0.1 - July 7, 2021
# Description:  Check and upgrade the VMware tools of the VMs
# ==================================================================

# Check Powershell version
$PSVersionTable

# Check, install, and verify PowerCLI module
Find-Module -Name VMware.PowerCLI
Install-Module -Name VMware.PowerCLI -Scope CurrentUser
Get-Module -Name VMware.PowerCLI -ListAvailable



# Connect to vCenter Server
$vCenter = "vcenter.lab.weithenn.org"
$ADUser = "LAB\Weithenn"
$Domain_Credential = Get-Credential -Credential $ADUser
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Connect-VIServer -server $vCenter -Credential $Domain_Credential



# VMs list from vSAN cluster
$vSAN_Cluster = "vSAN-Cluster01"



# Checking VMware Tools Compliance (guestToolsCurrent, guestToolsNotInstalled, guestToolsNeedUpgrade)
$Total_VMs = (Get-Cluster -name $vSAN_Cluster | Get-VM).Count
$Current_VMs = (Get-Cluster -name $vSAN_Cluster | Get-VM | % { get-view $_.id } | Where-Object {$_.Guest.ToolsVersionStatus -like "guestToolsCurrent"} | select name).Count
$NeedUpgrade_VMs = (Get-Cluster -name $vSAN_Cluster | Get-VM | % { get-view $_.id } | Where-Object {$_.Guest.ToolsVersionStatus -like "guestToolsNeedUpgrade"} | select name).Count
$NotInstalled_VMs = (Get-Cluster -name $vSAN_Cluster | Get-VM | % { get-view $_.id } | Where-Object {$_.Guest.ToolsVersionStatus -like "guestToolsNotInstalled"} | select name).Count

$VMware_Tools_Status = New-Object PSObject -Property ([ordered]@{
   "Current VMs"      = $Current_VMs
   "NeedUpgrade VMs"  = $NeedUpgrade_VMs
   "NotInstalled VMs" = $NotInstalled_VMs
   "Total VMs"        = $Total_VMs
})

$VMware_Tools_Status



# Checking VMware Tools Compliance and export to csv
Get-Cluster -name $vSAN_Cluster | Get-VM | % { get-view $_.id } | select name, @{Name=“ToolsVersion”; Expression={$_.config.tools.toolsversion}}, @{ Name=“ToolStatus”; Expression={$_.Guest.ToolsVersionStatus}} | Sort-Object ToolStatus | Export-Csv -Path C:\PowerCLI\vmtools.csv -NoTypeInformation



# Upgrading VMware Tools one at a time
$OutofDateVMs = Get-Cluster -name $vSAN_Cluster | Get-VM | % { get-view $_.id } |Where-Object {$_.Guest.ToolsVersionStatus -like "guestToolsNeedUpgrade"} | select name

ForEach ($VMs in $OutOfDateVMs){
    Update-Tools -VM $VMs -Verbose
}



# Close the connection to a vCenter Server
Disconnect-VIServer -Server $vCenter -Confirm:$false