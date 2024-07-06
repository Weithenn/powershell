# ==================================================================================
# Author:       Weithenn Wang (weithenn at weithenn.org)
# Version:      v0.1 - July 26, 2022
# Description:  Windows Server 2022 Single Node Caching/Tiering for physical server
# ==================================================================================

# Install the Failover Clustering feature
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools


# Check physical disk
Get-PhysicalDisk | Sort-Object -Property Size | ft DeviceId, MediaType, CanPool, HealthStatus, Usage, Size -AutoSize


# Check configurable field of the SBC(Storage Bus Cache)
Get-StorageBusCache


# Import the SBC module
Import-Module StorageBusCache


# Enable SBC feature
Enable-StorageBusCache
Get-StorageBusCache


# Check storage pool, physical disk, storage bus disk, and storage bus binding
Get-StoragePool -FriendlyName Storage*
Get-PhysicalDisk | Sort-Object -Property Size | ft DeviceId, MediaType, CanPool, HealthStatus, Usage, Size -AutoSize
Get-StorageBusDisk | Sort-Object Number
Get-StorageBusBinding


# Create 1TB MAP(Mirror-Accelerated Parity) volume with a Mirror:Parity ratio of 20:80
New-Volume -FriendlyName "MAP-Volume" -FileSystem ReFS -StoragePoolFriendlyName Storage* -StorageTierFriendlyNames MirrorOnSSD, ParityOnHDD -StorageTierSizes 200GB, 800GB


# Set an MAP-Volume partition and drive letter
Get-VirtualDisk
Get-Disk -FriendlyName "MAP-Volume"
Get-Partition -DiskNumber 7
Get-Partition -DiskNumber 7 -PartitionNumber 2 | Set-Partition -NewDriveLetter M
Get-Volume -FriendlyName "MAP-Volume"


# Expand the virtual disk with storage tiers
Get-StorageTier -FriendlyName MAP-Volume*
Get-StorageTierSupportedSize Performance | ft @{E={$_.TierSizeMin/1GB};L="TierSizeMin(GB)"}, @{E={$_.TierSizeMax/1GB};L="TierSizeMax(GB)"}, @{E={$_.TierSizeDivisor/1GB};L="TierSizeDivisor(GB)"} -AutoSize
Get-StorageTierSupportedSize Capacity | ft @{E={$_.TierSizeMin/1GB};L="TierSizeMin(GB)"}, @{E={$_.TierSizeMax/1GB};L="TierSizeMax(GB)"}, @{E={$_.TierSizeDivisor/1GB};L="TierSizeDivisor(GB)"} -AutoSize
Get-StorageTier -FriendlyName MAP-Volume-MirrorOnSSD | Resize-StorageTier -Size 300GB
Get-StorageTier -FriendlyName MAP-Volume-ParityOnHDD | Resize-StorageTier -Size 1.2TB
Get-StorageTier -FriendlyName MAP-Volume*


# Expand the partition and volume
Get-Volume M
$VirtualDisk = Get-VirtualDisk MAP-Volume
$Partition = $VirtualDisk | Get-Disk | Get-Partition | Where PartitionNumber -Eq 2
$Partition | Resize-Partition -Size ($Partition | Get-PartitionSupportedSize).SizeMax
Get-Volume M


# Expand Storage Pool
Get-StoragePool -FriendlyName Storage*
Get-PhysicalDisk | Sort-Object -Property CanPool | ft DeviceId, MediaType, CanPool, HealthStatus, Usage, Size -AutoSize
Update-StorageBusCache
Get-StoragePool -FriendlyName Storage*
Get-StorageBusBinding
Get-StoragePool -FriendlyName Storage* | Optimize-StoragePool
Get-StorageJob


# Retire and remove the fail disk
Get-StoragePool -FriendlyName Storage*
Get-VirtualDisk
Get-PhysicalDisk | Sort-Object -Property HealthStatus | ft DeviceId, MediaType, CanPool, OperationalStatus, HealthStatus, Usage, Size -AutoSize
$FailedDisk = Get-PhysicalDisk | Where-Object -Property HealthStatus -ne Healthy
$FailedDisk | Set-PhysicalDisk -Usage Retired
Get-StoragePool –FriendlyName Storage* | Get-Virtualdisk | Repair-VirtualDisk -Asjob
Remove-PhysicalDisk -PhysicalDisks (Get-PhysicalDisk | ? OperationalStatus -eq "Lost Communication") -StoragePoolFriendlyName "Storage Bus Cache on SBC-LAB"
