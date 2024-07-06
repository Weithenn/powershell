# ===========================================================================
# Author:       Weithenn Wang (weithenn at weithenn.org)
# Version:      v0.1 - July 26, 2022
# Description:  Windows Server 2022 Single Node Caching/Tiering for Azure VM
# ===========================================================================

# Install the Failover Clustering feature
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools


# Check physical disk
Get-PhysicalDisk | Sort-Object -Property Size


# Check configurable field of the SBC(Storage Bus Cache)
Get-StorageBusCache


# Import the SBC module
Import-Module StorageBusCache


# Enable SBC feature (For Nested VM)
Enable-StorageBusCache -AutoConfig:0
Get-StorageBusCache



# Check physical disk, storage bus disk, and storage bus binding (For Nested VM)
Get-PhysicalDisk | Sort-Object -Property Size
Get-PhysicalDisk | Where Size -eq "512GB" | Set-PhysicalDisk -MediaType SSD
Get-PhysicalDisk | Where Size -eq "4TB" | Set-PhysicalDisk -MediaType HDD
Get-PhysicalDisk | Sort-Object -Property Size
Get-StorageBusDisk | Sort-Object Number


# Create Storage Pool (For Nested VM)
New-StoragePool -FriendlyName SBC-Pool -StorageSubsystemFriendlyName "Windows Storage*" -PhysicalDisks (Get-PhysicalDisk -CanPool $True)
Update-StorageBusCache


# Create 1TB MAP(Mirror-Accelerated Parity) volume with a Mirror:Parity ratio of 20:80
New-Volume -FriendlyName "MAP-Volume" -FileSystem ReFS -StoragePoolFriendlyName SBC-Pool -StorageTierFriendlyNames MirrorOnSSD, ParityOnHDD -StorageTierSizes 200GB, 800GB


# Set an MAP-Volume partition and drive letter
Get-VirtualDisk
Get-Disk -FriendlyName "MAP-Volume"
Get-Partition -DiskNumber 8
Get-Partition -DiskNumber 8 -PartitionNumber 2 | Set-Partition -NewDriveLetter M
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
Get-StoragePool -FriendlyName SBC-Pool
Get-PhysicalDisk | Sort-Object -Property CanPool
Get-PhysicalDisk | Where Size -eq "4TB" | Set-PhysicalDisk -MediaType HDD
$PDToAdd = Get-PhysicalDisk -CanPool $True
Add-PhysicalDisk -StoragePoolFriendlyName SBC-Pool -PhysicalDisks $PDToAdd
Get-StoragePool -FriendlyName SBC-Pool
Get-StoragePool -FriendlyName SBC-Pool | Optimize-StoragePool
Get-StorageJob


# Retire and remove the fail disk
Get-StoragePool -FriendlyName SBC-Pool
Get-VirtualDisk
Get-PhysicalDisk | Sort-Object -Property HealthStatus | ft DeviceId, MediaType, CanPool, OperationalStatus, HealthStatus, Usage, Size -AutoSize
$FailedDisk = Get-PhysicalDisk | Where-Object -Property HealthStatus -ne Healthy
$FailedDisk | Set-PhysicalDisk -Usage Retired
Get-StoragePool –FriendlyName SBC-Pool | Get-Virtualdisk | Repair-VirtualDisk -Asjob
Get-StorageJob
Get-PhysicalDisk | Sort-Object -Property HealthStatus | ft DeviceId, MediaType, CanPool, OperationalStatus, HealthStatus, Usage, Size -AutoSize
Remove-PhysicalDisk -PhysicalDisks (Get-PhysicalDisk | ? OperationalStatus -eq "Lost Communication") -StoragePoolFriendlyName "SBC-Pool"


# Disable SBC and clean all disk
Disable-StorageBusCache

Update-StorageProviderCache
    Get-StoragePool | ? IsPrimordial -eq $false | Set-StoragePool -IsReadOnly:$false -ErrorAction SilentlyContinue
    Get-StoragePool | ? IsPrimordial -eq $false | Get-VirtualDisk | Remove-VirtualDisk -Confirm:$false -ErrorAction SilentlyContinue
    Get-StoragePool | ? IsPrimordial -eq $false | Remove-StoragePool -Confirm:$false -ErrorAction SilentlyContinue
    Get-PhysicalDisk | Reset-PhysicalDisk -ErrorAction SilentlyContinue
    Get-Disk | ? Number -ne $null | ? IsBoot -ne $true | ? IsSystem -ne $true | ? PartitionStyle -ne RAW | % {
        $_ | Set-Disk -isoffline:$false
        $_ | Set-Disk -isreadonly:$false
        $_ | Clear-Disk -RemoveData -RemoveOEM -Confirm:$false
        $_ | Set-Disk -isreadonly:$true
        $_ | Set-Disk -isoffline:$true
    }
    Get-Disk | Where Number -Ne $Null | Where IsBoot -Ne $True | Where IsSystem -Ne $True | Where PartitionStyle -Eq RAW | Group -NoElement -Property FriendlyName
