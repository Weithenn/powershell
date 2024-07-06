# ==================================================================================
# Author:         Weithenn Wang (weithenn at weithenn.org)
# Version:        v0.5 - October 21, 2023
# IT event:       Kubernetes Summit 2023
# Workshop Name:  IoT/Edge Computing | AKS Edge Essential 超輕量容器平台
# Description:    Step-by-step to build up AKS Edge Essential for IoT/Edge Computing
# ==================================================================================



#### Download AKS Edge Essentials #####
# Do not start Server Manager automatically at logon
New-ItemProperty -Path HKCU:\Software\Microsoft\ServerManager -Name DoNotOpenServerManagerAtLogon -PropertyType DWORD -Value "0x1" –Force

# Sets the system time zone to a specified time zone
Set-TimeZone -Id "Taipei Standard Time"
Get-TimeZone

# Download AKS Edge Essentials files (K8s, K3s, and Windows worker node) - 5 mins
taskmgr

$SourceURL = "https://aka.ms/aks-edge/k8s-msi", `
             "https://aka.ms/aks-edge/k3s-msi", `
             "https://aka.ms/aks-edge/windows-node-zip"
$DestationFile = "C:\Temp\k8s.msi",`
                 "C:\Temp\k3s.msi", `
                 "C:\Temp\windows-node.zip"
Start-BitsTransfer -Source $SourceURL -Destination $DestationFile

# Install NuGet and 7Zip4PowerShell
Install-PackageProvider -Name NuGet -Force
Install-Module -Name 7Zip4Powershell -Force

# Extract the 7z contents of an archive in the C:\Temp folder
Expand-7Zip -ArchiveFileName C:\Temp\windows-node.zip -TargetPath C:\Temp\

# Extracting 7z contents to AksEdgeWindows-v1.vhdx
cd C:\Temp
Start-Process -FilePath .\AksEdgeWindows-v1.exe





#### Install AKS Edge Essentials (K8s or K3s) #####
# Options 1 - K3s - Install AKS EE include Windows node
msiexec.exe /i C:\Temp\k3s.msi ADDLOCAL=CoreFeature,WindowsNodeFeature

# Options 2 - K8s - Install AKS EE include Windows node
msiexec.exe /i C:\Temp\k8s.msi ADDLOCAL=CoreFeature,WindowsNodeFeature

# Check the AKS Edge modules
Import-Module AksEdge -Verbose
Get-Command -Module AKSEdge | Format-Table Name, Version

# Check settings and features (Hyper-V, OpenSSH, and Power) - It will automatically restart
Install-AksEdgeHostFeatures -Confirm:$false





#### Create Single Machine Cluster #####
# Single machine configuration parameters
New-AksEdgeConfig -DeploymentType SingleMachineCluster -NodeType LinuxAndWindows -outFile C:\Temp\aksedge-config.json | Out-Null

# Open aksedge-config.json in PowerShell ISE
PowerShell_Ise.exe -file C:\Temp\aksedge-config.json

# Enable Hyper-V Manager
Add-WindowsFeature RSAT-Hyper-V-tools
virtmgmt.msc

# Create a single machine cluster (10 mins)
New-AksEdgeDeployment -JsonConfigFilePath C:\Temp\aksedge-config.json -Confirm:$false

# Validate your cluster
kubectl get nodes -o wide
kubectl get pods -A -o wide

# Option: if kubectl cmdlet not found in system path environment
Get-ChildItem Env: | Where-Object {$_.name -eq "Path"} | Format-Table -Wrap
$Env:Path += ";C:\Program Files\AksEdge\kubectl\"

# Check Linux and Windows node IP address
Get-AksEdgeNodeAddr -NodeType Linux
Get-AksEdgeNodeAddr -NodeType Windows





#### Deploy a sample Linux application to Kubernetes Cluster #####
# Deploy the application
kubectl apply -f https://raw.githubusercontent.com/Azure/AKS-Edge/main/samples/others/linux-sample.yaml

# Verify the Pods
kubectl get pods -o wide
kubectl get pods -o wide --watch

# Verify the services (EXTERNAL-IP from pending to assing IP address)
kubectl get services

# Test your application (using EXTERNAL-IP)
start microsoft-edge:http://192.168.0.4

# If EXTERNAL-IP is not obtained (Linux node IP : azure-vote-front port)
Get-AksEdgeNodeAddr -NodeType Linux
kubectl get services
start microsoft-edge:http://192.168.0.2:31519





#### Deploy a sample Windows application to Kubernetes Cluster #####
# Deploy the application
kubectl apply -f https://raw.githubusercontent.com/Azure/AKS-Edge/main/samples/others/win-sample.yaml

# Verify the Pods (ContainerCreating to Running) - 10 mins
kubectl get pods -o wide
kubectl get pods -o wide --watch

# Test your application (Windows node IP : sample port)
Get-AksEdgeNodeAddr -NodeType Windows
kubectl get services
start microsoft-edge:http://192.168.0.3:31321





#### Deploy Metrics server to Kubernetes Cluster #####
# Deploy Metrics Server
kubectl apply -f https://raw.githubusercontent.com/Azure/AKS-Edge/main/samples/others/metrics-server.yaml

# Verify the Pods (metrics-server)
kubectl get pods -A
kubectl get pods -A --watch

# View your resource consumption
kubectl top nodes
kubectl top pods -A





#### Uninstall an AKS Edge Essentials Cluster #####
# Remove Linux application from AKS EE cluster
kubectl delete -f https://raw.githubusercontent.com/Azure/AKS-Edge/main/samples/others/linux-sample.yaml

# Remove Windows application from AKS EE cluster
kubectl delete -f https://raw.githubusercontent.com/Azure/AKS-Edge/main/samples/others/win-sample.yaml

# Remove Metrics Server from AKS EE cluster
kubectl delete -f https://raw.githubusercontent.com/Azure/AKS-Edge/main/samples/others/metrics-server.yaml

# Verify the Pods (clean up)
kubectl get pods -A -o wide

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
Uninstall-Package -Name $AKSEE

# Remove the AKS Edge modules
Remove-Module AksEdge -Verbose
Get-Command -Module AKSEdge | Format-Table Name, Version

# Restart for clean-up
Restart-Computer