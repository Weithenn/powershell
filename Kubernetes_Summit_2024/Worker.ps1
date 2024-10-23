# ==================================================================================
# Author:         Weithenn Wang (weithenn at weithenn.org)
# Version:        v0.1 - October, 2024
# IT event:       Kubernetes Summit 2024
# Workshop Name:  Azure Kubernetes Service with GitOps
# Description:    Step-by-step to build up AKS Edge Essential
# ==================================================================================





##### Install AKS Edge Essentials (K8s or K3s) #####
# Options 1 - K3s - Install AKS EE include Windows node
msiexec.exe /i C:\Temp\AksEdge-K3s-1.29.6-1.8.202.0.msi ADDLOCAL=CoreFeature,WindowsNodeFeature

# Options 2 - K8s - Install AKS EE include Windows node
msiexec.exe /i C:\Temp\AksEdge-K8s-1.29.4-1.8.202.0.msi ADDLOCAL=CoreFeature,WindowsNodeFeature

# Check the AKS Edge modules
Import-Module AksEdge -Verbose
Get-Command -Module AKSEdge | Format-Table Name, Version

# Check settings and features (Hyper-V, OpenSSH, and Power) - It will automatically restart the first time
Install-AksEdgeHostFeatures -Confirm:$false

# Go back to control plane generate ScaleConfig.json

# Open aksedge-config.json in PowerShell ISE (ClusterID, ClusterJoinToken)
PowerShell_Ise.exe -file C:\Temp\ScaleConfig.json

# Validate the configuration file
Test-AksEdgeNetworkParameters -JsonConfigFilePath C:\Temp\ScaleConfig.json

# Enable Hyper-V Manager
Add-WindowsFeature RSAT-Hyper-V-tools
virtmgmt.msc

# Deploy Linux and Windows worker node (10 mins)
New-AksEdgeDeployment -JsonConfigFilePath C:\Temp\ScaleConfig.json -Confirm:$false





#### Uninstall an AKS Edge Essentials Cluster #####
# Option: if kubectl cmdlet not found in system path environmentGet-ChildItem Env: | Where-Object {$_.name -eq "Path"} | Format-Table -Wrap$Env:Path += ";C:\Program Files\AksEdge\kubectl\"

# Remove nodes on AKS EE Single-Node cluster (Include Hyper-V vSwitch)
kubectl get nodes
Remove-AksEdgeNode -NodeType Windows -Confirm:$false
kubectl get nodes
Remove-AksEdgeDeployment -Confirm:$false


# Uninstall K3s or K8s AKS Edge Essentials
# Options 1 - K3s - Uninstall K3s AKS Edge Essentials
$AKSEE = 'AKS Edge Essentials - K3s'

# Options 2 - K8s - Uninstall K8s AKS Edge Essentials
$AKSEE = 'AKS Edge Essentials - K8s'

Get-Command -Module PackageManagement
Get-Package -Name $AKSEE
Uninstall-Package -Name $AKSEE -Confirm:$false

# Remove the AKS Edge modules
Remove-Module AksEdge -Verbose
Get-Command -Module AKSEdge | Format-Table Name, Version

# Restart for clean-up
Restart-Computer