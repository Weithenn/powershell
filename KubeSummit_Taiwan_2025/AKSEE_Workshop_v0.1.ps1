# ==================================================================================
# Author:         Weithenn Wang (weithenn at weithenn.org)
# Version:        v0.1 - October 22, 2025
# IT event:       KubeSummit Taiwan 2025
# Workshop Name:  整合 KMS 加密打造安全的 Kubernetes 容器環境
# Description:    Step-by-step to build up AKS Edge Essential with KMS
# ==================================================================================





##### Install AKS Edge Essentials (K3s or K8s) #####
# Options 1 - K3s - Install AKS EE with Linux Node or Linux+Windows Nodes
msiexec.exe /i C:\Temp\AksEdge-K3s-1.30.6.msi   # Linux node only
msiexec.exe /i C:\Temp\AksEdge-K3s-1.30.6.msi ADDLOCAL=CoreFeature,WindowsNodeFeature   # Linux+Windows Nodes

# Options 2 - K8s - Install AKS EE include Windows node
msiexec.exe /i C:\Temp\AksEdge-K8s-1.30.5.msi   # Linux node only
msiexec.exe /i C:\Temp\AksEdge-K8s-1.30.5.msi ADDLOCAL=CoreFeature,WindowsNodeFeature   # Linux+Windows Nodes

# Check the AKS Edge Essentials modules
Import-Module AksEdge -Verbose
Get-Command -Module AKSEdge | Format-Table Name, Version

# Check settings and features (Hyper-V, OpenSSH, and Power) - This might require a system reboot
Install-AksEdgeHostFeatures -Confirm:$false

# Enable Hyper-V Manager (take a few minutes)
Add-WindowsFeature RSAT-Hyper-V-tools





##### Create Single Machine Cluster #####
# Single machine configuration parameters
New-AksEdgeConfig -DeploymentType SingleMachineCluster -NodeType Linux -outFile C:\Temp\aksedge-config.json | Out-Null   # Linux node only
New-AksEdgeConfig -DeploymentType SingleMachineCluster -NodeType LinuxAndWindows -outFile C:\Temp\aksedge-config.json | Out-Null   # Linux+Windows Nodes

# Open aksedge-config.json in PowerShell ISE
PowerShell_Ise.exe -file C:\Temp\aksedge-config.json

# Open Hyper-V Manager
virtmgmt.msc

# Create a single machine cluster (6 mins)
New-AksEdgeDeployment -JsonConfigFilePath C:\Temp\aksedge-config.json -Confirm:$false

# Option: if kubectl cmdlet not found in system path environment
Get-ChildItem Env: | Where-Object {$_.name -eq "Path"} | Format-Table -Wrap
$Env:Path += ";C:\Program Files\AksEdge\kubectl\"

# Validate your cluster
kubectl get nodes -o wide
kubectl get pods -A -o wide

# Check Linux and Windows node IP address
Get-AksEdgeNodeAddr -NodeType Linux
Get-AksEdgeNodeAddr -NodeType Windows





##### Deploy a sample Linux application to Kubernetes Cluster #####
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
start microsoft-edge:http://192.168.0.2:31316





##### Verify AKS EE KMS Plugin #####
# Verify that the KMS plugin is enabled
kubectl get --raw='/readyz?verbose'
kubectl get --raw='/readyz?verbose' | Select-String "kms"

# Create a Secret
Kubectl get secrets
kubectl create secret generic my-secret --from-literal=username=weithenn --from-literal=password='HelloWorld@2025'

# Verify the Secret
Kubectl get secrets
Kubectl describe secret my-secret

# Decode the Secret
Kubectl get secret my-secret -o yaml
Kubectl get secret my-secret -o jsonpath='{.data}'

Function ConvertFrom-Base64($base64) {
    return [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($base64))
}

"Username: {0}" -f ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("d2VpdGhlbm4=")))
"Password: {0}" -f ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("SGVsbG9Xb3JsZEAyMDI1")))





##### Deploy a sample Windows application to Kubernetes Cluster #####
# Deploy the application
kubectl apply -f https://raw.githubusercontent.com/Azure/AKS-Edge/main/samples/others/win-sample.yaml

# Verify the Pods (ContainerCreating to Running) - 10 mins
kubectl get pods -o wide
kubectl get pods -o wide --watch

# Test your application (Windows node IP : sample port)
Get-AksEdgeNodeAddr -NodeType Windows
kubectl get services
start microsoft-edge:http://192.168.0.3:30941





##### Deploy Metrics server to Kubernetes Cluster #####
# Deploy Metrics Server
kubectl apply -f https://raw.githubusercontent.com/Azure/AKS-Edge/main/samples/others/metrics-server.yaml

# Verify the Pods (metrics-server)
kubectl get pods -A
kubectl get pods -A --watch

# View your resource consumption
kubectl top nodes
kubectl top pods -A





##### Uninstall an AKS Edge Essentials Cluster #####
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





##### Installation kubectl-ai #####
# Open Microsoft Edge and navigate to kubectl-ai Releases page
Start-Process "msedge.exe" "https://github.com/GoogleCloudPlatform/kubectl-ai/releases?WT.mc_id=AZ-MVP-4039747"

# Download kubectl-ai windows installer
$kubectl_ai_URL = "https://github.com/GoogleCloudPlatform/kubectl-ai/releases/download/v0.0.23/kubectl-ai_Windows_x86_64.zip?WT.mc_id=AZ-MVP-4039747"
$kubectl_ai_ZIP = "C:\Temp\kubectl-ai_Windows_x86_64.zip"

# Ensure directory exists
New-Item -ItemType Directory -Path (Split-Path $kubectl_ai_ZIP) -Force | Out-Null

# Download using BITS
Start-BitsTransfer -Source $kubectl_ai_URL -Destination $kubectl_ai_ZIP
Write-Host "Download completed, file location：$kubectl_ai_ZIP"

# Extract the kubectl-ai ZIP file into C:\Temp\kubectl-ai
Expand-Archive $kubectl_ai_ZIP -DestinationPath "C:\Temp\kubectl-ai"

# Add kubectl-ai to system path environment
$source = "C:\Temp\kubectl-ai\kubectl-ai.exe"
$destination = "C:\Program Files\AksEdge\kubectl\kubectl-ai.exe"

if (Test-Path $source) {
    # Create the destination folder if it does not exist
    $destDir = Split-Path $destination
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    # Copy the file, overwrite if it already exists
    Copy-Item -Path $source -Destination $destination -Force
    Write-Output "kubectl-ai.exe has been copied to $destDir"
} else {
    Write-Output "Source file does not exist: $source"
}

# Check kubectl-ai version
kubectl-ai version





##### Installation PowerShell 7 #####
# Check PowerShell and PSReadLine version
$PSVersionTable.PSVersion

# Open Microsoft Edge and navigate to PowerShell Releases page
Start-Process "msedge.exe" "https://github.com/PowerShell/PowerShell/releases?WT.mc_id=AZ-MVP-4039747"

# Download PowerShell 7.5.4 MSI installer
$PowerShell7_URL = "https://github.com/PowerShell/PowerShell/releases/download/v7.5.4/PowerShell-7.5.4-win-x64.msi?WT.mc_id=AZ-MVP-4039747"
$PowerShell7_MSI = "C:\Temp\PowerShell-7.5.4-win-x64.msi"

# Ensure directory exists
New-Item -ItemType Directory -Path (Split-Path $PowerShell7_MSI) -Force | Out-Null

# Download using BITS
Start-BitsTransfer -Source $PowerShell7_URL -Destination $PowerShell7_MSI
Write-Host "Download completed, file location：$PowerShell7_MSI"

# Install PowerShell 7 using msiexec
Start-Process msiexec.exe -ArgumentList "/i `"$PowerShell7_MSI`"" -Wait -Verb RunAs

# Check PowerShell 7 version
$pwsh = "C:\Program Files\PowerShell\7\pwsh.exe"

if (Test-Path $pwsh) {
    Write-Host "✅ PowerShell 7 executable found: $pwsh"
    & $pwsh -NoLogo -Command "[string]`$PSVersionTable.PSVersion"
} else {
    Write-Host "❌ PowerShell 7 not found, please check installation."
}





##### Installation WSL2 #####
# Install AlmaLinux 10 as a new WSL distribution
wsl --install AlmaLinux-10

# List all available Linux distributions that can be installed with WSL
wsl --list --online

# Launch the AlmaLinux 10 distribution in WSL
wsl -d AlmaLinux-10

# Download and run the Ollama installation script
sudo curl -fsSL https://ollama.com/install.sh | sh

# Check the installed Ollama version
ollama --version

# Enable and start the Ollama service immediately
sudo systemctl enable --now ollama

# Display the current status of the Ollama service
systemctl status ollama

# Verify that Ollama is listening on port 11434
ss -tunpl | grep :11434

# kubectl-ai configuration file
C:\Users\Weithenn\.kube\kubectl-ai\config.yaml

# Global WSL configuration file
C:\Users\Weithenn\.wslconfig

# Shut down all running WSL distributions
wsl --shutdown

# Start the default WSL distribution
wsl

# Stop the Ollama service (requires sudo)
sudo systemctl stop ollama

# Run Ollama in debug mode to view detailed logs
OLLAMA_DEBUG=1 ollama serve

# Query the local Ollama API to list available model tags
curl http://127.0.0.1:11434/api/tags

# Download the specified Ollama model (gemma3:4b-it-qat)
ollama pull gemma3:4b-it-qat
ollama list

# Run the model interactively with a simple prompt
ollama run gemma3:4b-it-qat "Hello!"
ollama ps

# Use the Ollama REST API to generate text with a prompt
curl http://127.0.0.1:11434/api/generate -d '{
  "model": "gemma3:4b-it-qat",
  "prompt": "How are you?"
}'

# Use the Ollama REST API in chat mode with role-based messages
curl http://127.0.0.1:11434/api/chat -d '{
  "model": "gemma3:4b-it-qat",
  "messages": [{"role":"user","content":"How are you?"}]
}'

# Run kubectl-ai with Ollama as the LLM provider, enabling tool-use shim
kubectl-ai --llm-provider ollama --model gemma3:4b-it-qat --enable-tool-use-shim





### Integrate Open WebUI with Ollama ###
# Installation via Python pip (run as Administrator with PowerShell 7 and take a few minutes)
winget install Python.Python.3.11
python.exe -m pip --version
python.exe -m pip install --upgrade pip
python.exe -m pip install open-webui

# Running Open WebUI (run inside PowerShell 7)
open-webui serve

# Check if port 8080 is listening
Get-NetTCPConnection -LocalPort 8080 -State Listen

# Open Microsoft Edge and navigate to Open WebUI
Start-Process "msedge.exe" "http://localhost:8080"




##### Installation Warp #####
winget search Warp.Warp
winget install Warp.Warp

列出運作中的 Pods
撰寫部署 3 Replica Nigix 的 YAML