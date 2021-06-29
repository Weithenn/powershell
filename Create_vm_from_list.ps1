# ==================================================================
# Author:       Weithenn Wang (weithenn at weithenn.org)
# Version:      v0.4 - June 29, 2021
# Description:  Create new vm in vSAN or NFS datastore
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
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore
Connect-VIServer -Server $vCenter -Credential $Domain_Credential



# Clone VM from vm template 
$VM_Prefix = Get-Content -Path C:\PowerCLI\VMList.txt
$VM_Postfix = "-vm"
$vSAN_Cluster = "vSAN-Cluster01"
$vSAN_Datastore = "vsan01-ds01"
$NFS_Cluster = "NFS-Cluster01"
$NFS_Datastore = "nfs01-ds01"
$VM_vCPU = "2"
$VM_vRAM = "16"
$VM_vDisk = "120"
$VM_vDiskType = "Thin"
$VM_vNet = Get-VDPortgroup "vsan01-vds01-vlan168"
$VM_Folder = "Windows_VMs"
$VM_OS = "windows9_64Guest"



# Option 1: for vSAN datastore
foreach ($VM_List in ($VM_Prefix)){
    If (Get-VM -Name "$VM_List$($VM_Postfix)" -ErrorAction SilentlyContinue){
        Write-Host "$VM_List$($VM_Postfix) - already exists!" -ForegroundColor Red
    } else {
        Write-Host "$VM_List$($VM_Postfix) - ready to create vm" -ForegroundColor Green
        New-VM -Name "$VM_List$($VM_Postfix)" -ResourcePool $vSAN_Cluster -Datastore $vSAN_Datastore -NumCpu $VM_vCPU -MemoryGB $VM_vRAM -DiskGB $VM_vDisk -Portgroup $VM_vNet -Location $VM_Folder -GuestId $VM_OS -RunAsync
        Start-Sleep -Seconds 3
        # Change network adapter from e1000e to vmxnet3
        Get-VM "$VM_List$($VM_Postfix)" | Get-NetworkAdapter | Set-NetworkAdapter -Type Vmxnet3 -Confirm:$false
        # Add CD/DVD drive (for vmware tools upgrade)
        New-CDDrive -VM "$VM_List$($VM_Postfix)" -StartConnected:$true -Confirm:$false
    }    
}



# Option 2: for NFS datastore 
foreach ($VM_List in ($VM_Prefix)){
    If (Get-VM -Name "$VM_List$($VM_Postfix)" -ErrorAction SilentlyContinue){
        Write-Host "$VM_List$($VM_Postfix) - already exists!" -ForegroundColor Red
    } else {
        Write-Host "$VM_List$($VM_Postfix) - ready to create vm" -ForegroundColor Green
        New-VM -Name "$VM_List$($VM_Postfix)" -ResourcePool $NFS_Cluster -Datastore $NFS_Datastore -NumCpu $VM_vCPU -MemoryGB $VM_vRAM -DiskGB $VM_vDisk -DiskStorageFormat $VM_vDiskType -Portgroup $VM_vNet -Location $VM_Folder -GuestId $VM_OS -RunAsync
        Start-Sleep -Seconds 3
        # Change network adapter from e1000e to vmxnet3
        Get-VM "$VM_List$($VM_Postfix)" | Get-NetworkAdapter | Set-NetworkAdapter -Type Vmxnet3 -Confirm:$false
        # Add CD/DVD drive (for vmware tools upgrade)
        New-CDDrive -VM "$VM_List$($VM_Postfix)" -StartConnected:$true -Confirm:$false
    }    
}



# Close the connection to a vCenter Server
Disconnect-VIServer -Server $vCenter