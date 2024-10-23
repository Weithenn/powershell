# ==================================================================================
# Author:         Weithenn Wang (weithenn at weithenn.org)
# Version:        v0.1 - October, 2024
# IT event:       Kubernetes Summit 2024
# Workshop Name:  Azure Kubernetes Service with GitOps
# Description:    Step-by-step to build up AKS Edge Essential
# ==================================================================================





##### Install AKS Edge Essentials (K8s or K3s) for Control Plane #####
# Options 1 - K3s - Install AKS EE on Control Plane
msiexec.exe /i C:\Temp\AksEdge-K3s-1.29.6-1.8.202.0.msi

# Options 2 - K8s - Install AKS EE on Control Plane
msiexec.exe /i C:\Temp\AksEdge-K8s-1.29.4-1.8.202.0.msi

# Check the AKS Edge modules
Import-Module AksEdge -Verbose
Get-Command -Module AKSEdge

# Check settings and features (Hyper-V, OpenSSH, and Power) - It will automatically restart the first time
Install-AksEdgeHostFeatures -Confirm:$false





##### Deploy Multi Nodes Cluster #####
# Multi Nodes Cluster configuration parameters
New-AksEdgeConfig -DeploymentType ScalableCluster -outFile C:\Temp\aksedge-config.json | Out-Null

# Open aksedge-config.json by PowerShell ISE
PowerShell_Ise.exe -file C:\Temp\aksedge-config.json

# Validate the configuration file
Test-AksEdgeNetworkParameters -JsonConfigFilePath C:\Temp\aksedge-config.json

# Enable Hyper-V Manager
Add-WindowsFeature RSAT-Hyper-V-tools
virtmgmt.msc

# Deploy AKSEE Control Plane (7 mins)
New-AksEdgeDeployment -JsonConfigFilePath C:\Temp\aksedge-config.json -Confirm:$false

# Option: if kubectl cmdlet not found in system path environment
Get-ChildItem Env: | Where-Object {$_.name -eq "Path"} | Format-Table -Wrap
$Env:Path += ";C:\Program Files\AksEdge\kubectl\"

# Validate your control plane
kubectl get nodes -o wide
kubectl get pods -A -o wide

# Check Linux node IP address
Get-AksEdgeNodeAddr -NodeType Linux

# Switch to worker01 and worker02
# Install AKS Edge Essentials (K8s or K3s)

# Get cluser configuration for worker01 - primary machine
New-AksEdgeScaleConfig -scaleType AddMachine -NodeType LinuxandWindows -LinuxNodeIp 10.10.75.61 -WindowsNodeIp 10.10.75.71 -outFile .\ScaleConfig.json

# Validate worker01 join the cluster
kubectl get nodes -o wide

# Get cluser configuration for worker02 - scale-out node
New-AksEdgeScaleConfig -scaleType AddMachine -NodeType LinuxandWindows -LinuxNodeIp 10.10.75.62 -WindowsNodeIp 10.10.75.72 -outFile .\ScaleConfig.json

# Validate worker02 join the cluster
kubectl get nodes -o wide





#### Deploy a sample Linux application to AKSEE Cluster #####
# Deploy the application
#kubectl apply -f https://raw.githubusercontent.com/Azure/AKS-Edge/main/samples/others/linux-sample.yaml
kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/aks-store-demo/refs/heads/main/aks-store-quickstart.yaml

# Verify the Pods
kubectl get pods -o wide --watch
kubectl get pods -o wide


# Verify the services (EXTERNAL-IP from pending to assing IP address)
kubectl get services

# Test your application (using EXTERNAL-IP)
start microsoft-edge:http://10.10.75.101





#### Deploy a sample Windows application to AKSEE Cluster #####
# Deploy the application
#kubectl apply -f https://raw.githubusercontent.com/Azure/AKS-Edge/main/samples/others/win-sample.yaml
kubectl apply -f https://raw.githubusercontent.com/dotnet/dotnet-docker/main/samples/kubernetes/hello-dotnet/hello-dotnet-loadbalancer.yaml

# Verify the Pods (ContainerCreating to Running) - 10 mins
kubectl get pods -o wide --watch
kubectl get pods -o wide

# Verify the services (EXTERNAL-IP from pending to assing IP address)
kubectl get services

# Test your application (using EXTERNAL-IP)
start microsoft-edge:http://10.10.75.102





#### Deploy Metrics server to Kubernetes Cluster #####
# Deploy Metrics Server
kubectl apply -f https://raw.githubusercontent.com/Azure/AKS-Edge/main/samples/others/metrics-server.yaml

# Verify the Pods (metrics-server)
kubectl get pods -A --watch
kubectl get pods -A

# View your resource consumption
kubectl top nodes
kubectl top pods -A





#### Uninstall an AKS Edge Essentials Cluster #####
# Remove Linux application from AKS EE cluster
kubectl delete -f https://raw.githubusercontent.com/Azure-Samples/aks-store-demo/refs/heads/main/aks-store-quickstart.yaml

# Remove Windows application from AKS EE cluster
kubectl delete -f https://raw.githubusercontent.com/dotnet/dotnet-docker/main/samples/kubernetes/hello-dotnet/hello-dotnet-loadbalancer.yaml

# Remove Metrics Server from AKS EE cluster
kubectl delete -f https://raw.githubusercontent.com/Azure/AKS-Edge/main/samples/others/metrics-server.yaml

# Verify the Pods (clean up)
kubectl get pods -A -o wide

# Remove nodes on AKS EE multi nodes cluster (Include Hyper-V vSwitch)
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