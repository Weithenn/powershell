﻿# ==================================================================================
# Author:         Weithenn Wang (weithenn at weithenn.org)
# Version:        v0.1 - July 2, 2024
# IT event:       Cloud Summit Taiwan 2024
# Workshop Name:  實戰演練 - 打造超大型規模 Azure Stack HCI 和 AKS 基礎架構
# Description:    Step-by-step to build up Cluster Set with Azure Stack HCI
# ==================================================================================



# Create a Cluster Set (Scaleout Master)
New-ClusterSet -name "CS-Master" -NamespaceRoot "SOFS-ClusterSet" -CimSession "MGMT-Cluster" -StaticAddress "10.10.75.40"



# To add cluster members to the Cluster Set (Scaleout Worker)
Add-ClusterSetMember -ClusterName MBR-Cluster01 -CimSession CS-Master -InfraSOFSName MBR01-SOFS
Add-ClusterSetMember -ClusterName MBR-Cluster02 -CimSession CS-Master -InfraSOFSName MBR02-SOFS



# Check and verify Cluster Set information
Get-ClusterSet -CimSession "CS-Master"
Get-ClusterSetMember -CimSession "CS-Master"
Get-ClusterSetNode -CimSession "CS-Master"



# To verify the cluster set contains SMB share on the infrastructure SOFS for each cluster member CSV volume
Get-SmbShare -CimSession "CS-Master"



# To verify \\SOFS-ClusterSet
invoke-item .



# Enable Live migration with kerberos authentication (for Node11 - Node22)
$ClusterSet="CS-Master"
$Clusters=(get-clustersetmember -CimSession $ClusterSet).ClusterName
$Nodes=Get-ClusterSetNode -CimSession $ClusterSet

foreach ($Cluster in $Clusters){
        $SourceNodes=($nodes | where member -eq $Cluster).Name
        $DestinationNodes=($nodes | where member -ne $Cluster).Name
        Foreach ($DestinationNode in $DestinationNodes){
            $HostName = $DestinationNode
            $HostFQDN = (Resolve-DnsName $HostName).name | Select-Object -First 1
            Foreach ($SourceNode in $SourceNodes){
                Get-ADComputer $SourceNode | Set-ADObject -Add @{"msDS-AllowedToDelegateTo"="Microsoft Virtual System Migration Service/$HostFQDN", "Microsoft Virtual System Migration Service/$HostName", "cifs/$HostFQDN", "cifs/$HostName"}
            }
        }
    }

Foreach ($Node in $Nodes){
        $GUID=(Get-ADComputer $Node.Name).ObjectGUID
        $comp=Get-ADObject -identity $Guid -Properties "userAccountControl"
        $Comp.userAccountControl = $Comp.userAccountControl -bor 16777216
        Set-ADObject -Instance $Comp
}

Set-VMHost -CimSession $Nodes.Name -VirtualMachineMigrationAuthenticationType Kerberos



# Add Management cluster computer account to each node local Administrators group
$ClusterSet="CS-Master"
$MgmtClusterterName=(Get-ClusterSet -CimSession $ClusterSet).ClusterName

Invoke-Command -ComputerName (Get-ClusterSetNode -CimSession $ClusterSet).Name -ScriptBlock {
    Add-LocalGroupMember -Group Administrators -Member "$using:MgmtClusterterName$"
}

Invoke-Command -ComputerName (Get-ClusterSetNode -CimSession $ClusterSet).Name -ScriptBlock {
    Get-LocalGroupMember -Group Administrators
} | format-table Name,PSComputerName



# Create Logical Fault Domains (LFD)
$ClusterSet="CS-Master"
New-ClusterSetFaultDomain -Name FD01 -FdType Logical -CimSession $ClusterSet -MemberCluster MBR-Cluster01 -Description "Fault Domain - A"
New-ClusterSetFaultDomain -Name FD02 -FdType Logical -CimSession $ClusterSet -MemberCluster MBR-Cluster02 -Description "Fault Domain - B"



# Check and verify Logical Fault Domains (LFD)
Get-ClusterSetFaultDomain -CimSession CS-Master
Get-ClusterSetFaultDomain -CimSession CS-Master -FdName FD01 | fl *
Get-ClusterSetFaultDomain -CimSession CS-Master -FdName FD02 | fl *



# Create Availability Set (AS)
$ClusterSet="CS-Master"
$AvailabilitySetName="AvailabilitySet"
$FaultDomainNames=(Get-ClusterSetFaultDomain -CimSession $clusterset).FDName
New-ClusterSetAvailabilitySet -Name $AvailabilitySetName -FdType Logical -CimSession $ClusterSet -ParticipantName $FaultDomainNames

Get-ClusterSetAvailabilitySet -AvailabilitySetName AvailabilitySet -CimSession CS-Master



# Create Cluster Set VMs
# \\SOFS-ClusterSet\MBR01-Volume or \\SOFS-ClusterSet\MBR02-Volume
$memoryinMB="2048"
$vcpucount="1"
Get-ClusterSetOptimalNodeForVM -CimSession CS-Master -VMMemory $memoryinMB -VMVirtualCoreCount $vcpucount -VMCpuReservation 10 -AvailabilitySet AvailabilitySet



# Check and register Cluster Set VM and Availability Set
Get-VM -ComputerName Node12
$CS_VM="CS-VM01"
Get-ClusterSetVM -CimSession CS-Master
Get-ClusterSetNode -CimSession CS-Master

Register-ClusterSetVM -CimSession CS-Master -MemberName MBR-Cluster01 -VMName $CS_VM
Get-ClusterSetVM -CimSession CS-Master
Get-ClusterSetVM -CimSession CS-Master |ft VMName,MemberName,AvailabilitySet,FaultDomain,UpdateDomain

Get-ClusterSetVM -CimSession CS-Master | Set-ClusterSetVm -AvailabilitySetName AvailabilitySet
Get-ClusterSetVM -CimSession CS-Master | ft VMName,MemberName,AvailabilitySet,FaultDomain,UpdateDomain

Get-ClusterSetAvailabilitySet -AvailabilitySetName AvailabilitySet -CimSession CS-Master



# Unregister Cluster Set VM
Get-ClusterSetVM -CimSession CS-Master
$CS_VM="CS-VM01"
Unregister-ClusterSetVM -CimSession CS-Master -VMName $CS_VM
Get-ClusterSetVM -CimSession CS-Master



# Create Cluster Set VMs
# \\SOFS-ClusterSet\MBR01-Volume or \\SOFS-ClusterSet\MBR02-Volume
Get-ClusterSetOptimalNodeForVM -CimSession CS-Master -VMMemory 4096 -VMVirtualCoreCount 2 -VMCpuReservation 10 -AvailabilitySet AvailabilitySet



# To register all Cluster Set VMs at once
Get-ClusterSetVM -CimSession CS-Master
Get-ClusterSetMember -CimSession CS-Master
Get-ClusterSetMember -CimSession CS-Master | Register-ClusterSetVM -RegisterAll
Get-ClusterSetVM -CimSession CS-Master



# To register all Availability Set VMs at once
Get-ClusterSetVM -CimSession CS-Master
Get-ClusterSetVM -CimSession CS-Master | Set-ClusterSetVm -AvailabilitySetName AvailabilitySet
Get-ClusterSetVM -CimSession CS-Master |ft VMName,MemberName,AvailabilitySet,FaultDomain,UpdateDomain

Get-ClusterSetAvailabilitySet -AvailabilitySetName AvailabilitySet -CimSession CS-Master
Get-ClusterSetAvailabilitySet -AvailabilitySetName AvailabilitySet -CimSession CS-Master | fl *



# Enable all networks to be available for the migration
$Nodes = ("Node11", "Node12", "Node21", "Node22")
icm $Nodes {Set-VMHost -UseAnyNetworkForMigration $true}



# To move a Cluster Set VM
Get-ClusterSetVM -CimSession CS-Master |ft VMName,MemberName,AvailabilitySet,FaultDomain,UpdateDomain
$move_vm="CS-VM02"
$dest_node="Node11"
Move-ClusterSetVM -CimSession CS-Master -VMName $move_vm -Node $dest_node

Get-ClusterSetVM -CimSession CS-Master |ft VMName,MemberName,AvailabilitySet,FaultDomain,UpdateDomain
