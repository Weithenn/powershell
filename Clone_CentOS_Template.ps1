# File Name:        Clone_CentOS_Template.ps1
# Version:          0.1 - 2018/01/25
# Author:           Weithenn Wang (weithenn@weithenn.org)
# Lab Environment:  Windows Server 2016 Hyper-V / PowerShell
# description:      Clone CentOS VM Template for fixed Product_UUID issue
# URL:              http://www.weithenn.org/2018/01/centos-74-journey-part15.html
# License:          MIT License
###########################################################
$VM_Path = "C:\ClusterStorage\K8S-Cluster"
$VM_Name = "k8s-master"
$VM_vCPU = "2"
$VM_VLAN = "168"
$VM_NewVLAN = "268"
$HV_Host = "$env:computername"
$HV_vSwitch = "S2D-vSwitch"

###########################################################
# Create New VM folder
New-Item -Path "$VM_Path\$VM_Name" -ItemType "Directory"

# Copy CentOS template vhdx
Copy-Item "C:\ClusterStorage\ISO-Template\CentOS 7.4\CentOS74-Template.vhdx" "$VM_Path\$VM_Name\$VM_Name.vhdx"

# Create New CentOS VM
New-VM -Name "$VM_Name" -VHDPath "$VM_Path\$VM_Name\$VM_Name.vhdx" -Generation 2 -SwitchName "$HV_vSwitch"

# Disable Secure Boot
Set-VMFirmware "$VM_Name" -EnableSecureBoot Off

# Configure VM vCPU Count
Set-VMProcessor -VMName "$VM_Name" -Count "$VM_vCPU"

# Configure VM Dynamic Memory
Set-VMMemory -VMName "$VM_Name" -DynamicMemoryEnabled $True -MaximumBytes 8GB -MinimumBytes 512MB -StartupBytes 8GB
#Set-VMMemory -VMName "$VM_Name" -DynamicMemoryEnabled $false

# Configure VM VLAN ID
Set-VMNetworkAdapterVlan -VMName "$VM_Name" -Access -VlanId $VM_VLAN

# Mount CentOS 1708 ISO (generate shimx64.efi)
Add-VMDvdDrive -VMName "$VM_Name" -Path "C:\ClusterStorage\ISO-Template\CentOS 7.4\CentOS-7-x86_64-Minimal-1708.iso"
$dvd = Get-VMDvdDrive -VMName "$VM_Name"
Set-VMFirmware "$VM_Name" -FirstBootDevice $dvd

# Enable Guest Service Interface
Enable-VMIntegrationService -VMName "$VM_Name" -Name "Guest Service Interface"

# Configure VM Checkpoint Location
Set-VM -VMName "$VM_Name" -SnapshotFileLocation "$VM_Path\$VM_Name"

# Configure VM Smart Paging File Location
Set-VM -VMName "$VM_Name" -SmartPagingFilePath "$VM_Path\$VM_Name"

# Configure VM Automatic Start Action
Set-VM -VMName "$VM_Name" -AutomaticStartAction Nothing

# Move VM Current Configuration Location
Get-VM -Name $VM_Name | ft ConfigurationLocation
Move-VMStorage "$VM_Name" -VirtualMachinePath "$VM_Path\$VM_Name"
Get-VM -Name $VM_Name | ft ConfigurationLocation
Remove-Item -Path "$VM_Path\$VM_Name\UndoLog Configuration"

# Power On VM and Connect to VM
Start-VM -Name "$VM_Name"
vmconnect.exe "$HV_Host" "$VM_Name"

###########################################################
##### Boot to Rescure mode and generate shimx64.efi #####
# Boot from CentOS 7 ISO > Troubleshooting > Rescue a CentOS system
# 3) Skip to shell
# efibootmgr --create --label CentOS --disk /dev/sda1 --loader "\EFI\centos\shimx64.efi"
# halt -p

###########################################################
# Remove VM DVD Drive 
Get-VMDvdDrive -VMName "$VM_Name"
Remove-VMDvdDrive -VMName "$VM_Name" -ControllerNumber 0 -ControllerLocation 1
Get-VMFirmware "$VM_Name"

# Power On VM and Connect to VM
Start-VM -Name "$VM_Name"
vmconnect.exe "$HV_Host" "$VM_Name"

###########################################################
##### Template CentOS VM Basic Configuration #####
# yum -y update, ip, gateway, /etc/resolv.conf, /etc/hosts
# hostnamectl set-hostname "k8s-master.weithenn.org" --static
# /etc/firewalld/zones/public.xml
# <port protocol="tcp" port="7946"/>
# <port protocol="tcp" port="30000-32767"/>
# firewall-cmd --reload ; firewall-cmd --list-all
# adduser > passwd > /etc/group
# : > /etc/machine-id
# systemd-machine-id-setup
# halt -p

###########################################################
# Configure VM New VLAN ID
Set-VMNetworkAdapterVlan -VMName "$VM_Name" -Access -VlanId $VM_NewVLAN

# Power On VM and Connect to VM
Start-VM -Name "$VM_Name"
vmconnect.exe "$HV_Host" "$VM_Name"

###########################################################
##### Verify Machine-ID, Boot ID, Product_UUID #####
# hostnamectl
# ip a
# cat /sys/class/dmi/id/product_uuid
# history -c
