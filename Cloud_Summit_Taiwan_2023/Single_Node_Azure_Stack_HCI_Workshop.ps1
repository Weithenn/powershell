# ==================================================================================
# Author:         Weithenn Wang (weithenn at weithenn.org)
# Version:        v0.1 - July 19, 2023
# IT event:       Cloud Summit Taiwan 2023
# Workshop Name:  Azure Stack HCI (22H2) Single-Node
# Description:    Step-by-step to build up Single-Node Azure Stack HCI Cluster
# ==================================================================================

##### Azure VM #####
# Do not start Server Manager automatically at logon
New-ItemProperty -Path HKCU:\Software\Microsoft\ServerManager -Name DoNotOpenServerManagerAtLogon -PropertyType DWORD -Value "0x1" –Force

# Sets the system time zone to a specified time zone
Set-TimeZone -Id "Taipei Standard Time"
Get-TimeZone

# Install Hyper-V Role and feature
Add-WindowsFeature "Hyper-V", "Hyper-V-PowerShell" -IncludeAllSubFeature -IncludeManagementTools -Restart

# Create NAT vSwitch for Nested VM
New-VMSwitch -Name "AzSHCI-NATSwitch" -SwitchType Internal
New-NetIPAddress -IPAddress 10.10.75.1 -AddressFamily IPv4 -PrefixLength 24 -InterfaceAlias "vEthernet (AzSHCI-NATSwitch)"
New-NetNat -Name "AzSHCI-VMsNAT" -InternalIPInterfaceAddressPrefix "10.10.75.0/24"
Get-NetNat

# Download ISOs (Azure Stack HCI, WAC, Windows Server 2022)
taskmgr

$SourceURL = "https://aka.ms/AAkk1p4", `
             "https://aka.ms/wacdownload", `
             "https://go.microsoft.com/fwlink/p/?LinkID=2195280&clcid=0x409&culture=en-us&country=US"
$DestationFile = "D:\AzSHCI.vhdx",`
                 "D:\WAC.msi", `
                 "D:\WS2022.iso"
Start-BitsTransfer -Source $SourceURL -Destination $DestationFile

# Striped disks for more IOPS (64GBx16=1TB)
diskmgmt

# Create VMs folder in V:
New-Item -Path "V:\" -Name "VMs" -ItemType "directory"

# Open Hyper-V Manager and change default path to V:\VMs
virtmgmt.msc
Set-VMHost -VirtualHardDiskPath 'V:\VMs\' -VirtualMachinePath 'V:\VMs\'





#### DC (Domain Controller) #####
$VM_DC = "DC"
$VHD_Path = "V:\VMs\DC.vhdx"
$NAT_vSwitch = "AzSHCI-NATSwitch"
$ISO = "D:\WS2022.iso"

# Create DC VM
New-VM -Name $VM_DC -MemoryStartupBytes 8GB -NewVHDPath $VHD_Path -NewVHDSizeBytes 127GB -Generation 2 -SwitchName $NAT_vSwitch
Set-VMMemory -VMName $VM_DC -DynamicMemoryEnabled $false
Set-VmProcessor -VmName $VM_DC -Count 2
Get-VMNetworkAdapter -VMName $VM_DC | Set-VMNetworkAdapter -MacAddressSpoofing On
Add-VMDvdDrive -VMName $VM_DC -Path $ISO
$DVD = Get-VMDVDDrive -VMName $VM_DC
Set-VMFirmware -VMName $VM_DC -FirstBootDevice $DVD

Start-VM $VM_DC
VMConnect localhost $VM_DC
Start-Sleep -Seconds 2
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

# DC basic setting
Enter-PSSession -VMName $VM_DC -Credential Administrator

New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 10.10.75.10 -PrefixLength 24 -DefaultGateway '10.10.75.1'
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("10.10.75.10")

$VM_DC = "DC"
Rename-Computer -NewName $VM_DC -DomainCredential Administrator -Force -Restart
Start-Sleep -Seconds 1
Exit-PSSession

# Install ADDS feature and promote to domain controller
Enter-PSSession -VMName $VM_DC -Credential Administrator

Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools
Get-WindowsFeature | where displayname -like "Active Directory Domain*"

Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainName "lab.weithenn.org" `
-DomainNetbiosName "LAB" `
-Forestmode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true
Start-Sleep -Seconds 1
Exit-PSSession





#### AzSHCI VM - Node01 #####
$HCINode01 = "AzSHCI-Node01"
$VHD_Path = "V:\VMs\Node01.vhdx"
$NAT_vSwitch = "AzSHCI-NATSwitch"
$Copy_SourceFile = "D:\AzSHCI.vhdx"

# Create AzSHCI Nested VM
Copy-Item $Copy_SourceFile -Destination $VHD_Path

New-VM -Name $HCINode01 -MemoryStartupBytes 20GB -VHDPath $VHD_Path -Generation 2 -SwitchName $NAT_vSwitch
Set-VMMemory -VMName $HCINode01 -DynamicMemoryEnabled $false
Set-VmProcessor -VmName $HCINode01 -Count 4
Get-VMNetworkAdapter -VMName $HCINode01 | Set-VMNetworkAdapter -MacAddressSpoofing On
Add-VMScsiController -VMName $HCINode01
foreach ($i in 1..4) {
New-VHD -Path V:\VMs\$HCINode01-$i.vhdx -SizeBytes 300GB
Add-VMHardDiskDrive -VMName $HCINode01 -Path V:\VMs\$HCINode01-$i.vhdx -ControllerNumber 1
}

# Enable Nested Virtualzation for AzSHCI VM
Set-VmProcessor -VmName $HCINode01 -ExposeVirtualizationExtensions $true -Verbose
Get-VMProcessor -VMName $HCINode01 | fl -Property ExposeVirtualizationExtensions

# Power On AzSHCI VM
VMConnect localhost $HCINode01
Start-VM $HCINode01

# AzSHCI VM basic setting
Enter-PSSession -VMName $HCINode01 -Credential Administrator

New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 10.10.75.21 -PrefixLength 24 -DefaultGateway '10.10.75.1'
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("8.8.8.8")

powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg /list

$HCINode01 = "AzSHCI-Node01"
Rename-Computer -NewName $HCINode01 -DomainCredential Administrator -Force -Restart
Start-Sleep -Seconds 1
Exit-PSSession

# Update to AzSHCI 22H2 20349.1850 (about 10 mins)

# AzSHCI VM - Install roles and features
Enter-PSSession -VMName $HCINode01 -Credential Administrator

Install-WindowsFeature -Name "BitLocker", "Data-Center-Bridging", "Failover-Clustering", "FS-FileServer", "FS-Data-Deduplication", "Hyper-V-PowerShell", "RSAT-AD-Powershell", "RSAT-Clustering-PowerShell", "NetworkATC", "Storage-Replica" -IncludeAllSubFeature -IncludeManagementTools
Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V" -All -NoRestart

Restart-Computer -Force
Start-Sleep -Seconds 1
Exit-PSSession

# Join Domain (lab.weithenn.org)
Enter-PSSession -VMName $HCINode01 -Credential Administrator

Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("10.10.75.10")
Add-Computer -DomainName lab.weithenn.org -DomainCredential LAB\Administrator -Force -Restart
Start-Sleep -Seconds 1
Exit-PSSession

# Create Single-Node Azure Stack HCI Cluster
Enter-PSSession -VMName $HCINode01 -Credential LAB\Administrator

Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

$HCINode01 = "AzSHCI-Node01"
New-Cluster -Name HCI-Cluster -Node $HCINode01 -NOSTORAGE -StaticAddress 10.10.75.20

Enable-ClusterStorageSpacesDirect -CacheState Disabled -Confirm:$false

# Change mediatype to SSD (Nested VM only)
Get-PhysicalDisk | ft Size
Get-PhysicalDisk | Where Size -eq "322122547200" | Set-PhysicalDisk -MediaType SSD
Get-PhysicalDisk

# Create CSVFS_ReFS volume
Get-StoragePool "S2D*"

New-Volume -FriendlyName "Volume01" -Size 100GB

New-Volume -FriendlyName "Volume02" -Size 100GB -ProvisioningType Thin

Get-StoragePool "S2D*"

Get-VirtualDisk

Get-Volume

Start-Sleep -Seconds 1
Exit-PSSession





#### AzSHCI VM - Node02 #####
$HCINode02 = "AzSHCI-Node02"
$VHD_Path = "V:\VMs\Node02.vhdx"
$NAT_vSwitch = "AzSHCI-NATSwitch"
$Copy_SourceFile = "D:\AzSHCI.vhdx"

# Create AzSHCI Nested VM
Copy-Item $Copy_SourceFile -Destination $VHD_Path

New-VM -Name $HCINode02 -MemoryStartupBytes 20GB -VHDPath $VHD_Path -Generation 2 -SwitchName $NAT_vSwitch
Set-VMMemory -VMName $HCINode02 -DynamicMemoryEnabled $false
Set-VmProcessor -VmName $HCINode02 -Count 4
Get-VMNetworkAdapter -VMName $HCINode02 | Set-VMNetworkAdapter -MacAddressSpoofing On
Add-VMScsiController -VMName $HCINode02
foreach ($i in 1..4) {
    New-VHD -Path V:\VMs\$HCINode02-$i.vhdx -SizeBytes 300GB
    Add-VMHardDiskDrive -VMName $HCINode02 -Path V:\VMs\$HCINode02-$i.vhdx -ControllerNumber 1
}

# Enable Nested Virtualzation for AzSHCI VM
Set-VmProcessor -VmName $HCINode02 -ExposeVirtualizationExtensions $true -Verbose
Get-VMProcessor -VMName $HCINode02 | fl -Property ExposeVirtualizationExtensions

# Power On AzSHCI VM
VMConnect localhost $HCINode02
Start-VM $HCINode02

# AzSHCI VM basic setting
Enter-PSSession -VMName $HCINode02 -Credential Administrator

New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 10.10.75.22 -PrefixLength 24 -DefaultGateway '10.10.75.1'
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("8.8.8.8")
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg /list

$HCINode02 = "AzSHCI-Node02"
Rename-Computer -NewName $HCINode02 -DomainCredential Administrator -Force -Restart
Start-Sleep -Seconds 1
Exit-PSSession

# Update to AzSHCI 22H2 20349.1850 (about 10 mins)

# AzSHCI VM - Install roles and features
Enter-PSSession -VMName $HCINode02 -Credential Administrator

Install-WindowsFeature -Name "BitLocker", "Data-Center-Bridging", "Failover-Clustering", "FS-FileServer", "FS-Data-Deduplication", "Hyper-V-PowerShell", "RSAT-AD-Powershell", "RSAT-Clustering-PowerShell", "NetworkATC", "Storage-Replica" -IncludeAllSubFeature -IncludeManagementTools
Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V" -All -NoRestart

Restart-Computer -Force
Start-Sleep -Seconds 1
Exit-PSSession

# Join Domain (lab.weithenn.org)
Enter-PSSession -VMName $HCINode02 -Credential Administrator

Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("10.10.75.10")
Add-Computer -DomainName lab.weithenn.org -DomainCredential LAB\Administrator -Force -Restart
Start-Sleep -Seconds 1
Exit-PSSession





##### Adding node to Azure Stack HCI cluster #####
$HCINode02 = "AzSHCI-Node02"
Enter-PSSession -VMName $HCINode02 -Credential LAB\Administrator

Get-PhysicalDisk | Where Size -eq "322122547200" | Set-PhysicalDisk -MediaType SSD
Get-PhysicalDisk

Start-Sleep -Seconds 1
Exit-PSSession

$HCINode01 = "AzSHCI-Node01"
Enter-PSSession -VMName $HCINode01 -Credential LAB\Administrator

Get-ClusterNode
$HCINode02 = "AzSHCI-Node02"
Add-ClusterNode -Name $HCINode02
Get-ClusterNode
Get-StorageHealthAction
Get-StoragePool "S2D*"
Start-Sleep -Seconds 1
Exit-PSSession


$HCINode02 = "AzSHCI-Node02"
Enter-PSSession -VMName $HCINode02 -Credential LAB\Administrator
Get-PhysicalDisk
Get-PhysicalDisk | Where Size -eq "322122547200" | Set-PhysicalDisk -MediaType SSD
Get-PhysicalDisk
Get-PhysicalDisk | Select MediaType, CanPool, CannotPoolReason
Get-StoragePool "S2D*"
Get-StoragePool -IsPrimordial $False | Add-PhysicalDisk -PhysicalDisks (Get-PhysicalDisk -CanPool $True)
Get-PhysicalDisk
Get-StoragePool "S2D*"
Get-StorageJob
Get-StorageHealthAction
Get-ClusterPerformanceHistory
Get-StoragePool "S2D*" | Optimize-StoragePool
Get-StorageJob
Get-AzureStackHCI

Start-Sleep -Seconds 1
Exit-PSSession

# Install WAC to Azure VM and connect to Azure Stack HCI Cluster
D:\WAC.msi

$Hosts = @"
10.10.75.20	hci-cluster.lab.weithenn.org
10.10.75.21	azshci-node01.lab.weithenn.org
10.10.75.22	azshci-node02.lab.weithenn.org
"@
Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value $Hosts
Get-Content -Path "C:\Windows\System32\drivers\etc\hosts"

start microsoft-edge:https://localhost
