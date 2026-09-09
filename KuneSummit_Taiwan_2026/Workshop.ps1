# ==================================================================================
# Author:         Weithenn Wang (weithenn at weithenn.org)
# Version:        v0.1 - September 10, 2026
# IT event:       KubeSummit Taiwan 2026
# Workshop Name:  讓 Kubernetes 會思考：AI 助手強化維運診斷與資源操作
# ==================================================================================





##### Install AKS Edge Essentials (K3s) #####
# K3s - Install AKS EE with Linux Node
msiexec.exe /i C:\Temp\AksEdge-K3s-1.30.6.msi   # Linux node only

# Check the AKS Edge Essentials modules
Import-Module AksEdge -Verbose
Get-Command -Module AKSEdge | Format-Table Name, Version

# Check settings and features (Hyper-V, OpenSSH, and Power) - This might require a system reboot
Install-AksEdgeHostFeatures -Confirm:$false

# Enable Hyper-V Manager (take a few minutes)
Add-WindowsFeature RSAT-Hyper-V-tools





##### Create Single Machine K3s Cluster #####
# Single machine configuration parameters
New-AksEdgeConfig -DeploymentType SingleMachineCluster -NodeType Linux -outFile C:\Temp\aksedge-config.json | Out-Null   # Linux node only

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





##### Deploy a sample Linux application to Kubernetes Cluster #####
# Deploy the application
kubectl apply -f https://raw.githubusercontent.com/Azure/AKS-Edge/main/samples/others/linux-sample.yaml

# Verify the Pods
kubectl get pods -o wide --watch
kubectl get pods -o wide

# Verify the services (EXTERNAL-IP from pending to assing IP address)
kubectl get services

# Test your application (using EXTERNAL-IP)
start microsoft-edge:http://192.168.0.4

# If EXTERNAL-IP is not obtained (Linux node IP : azure-vote-front port)
Get-AksEdgeNodeAddr -NodeType Linux
kubectl get services
start microsoft-edge:http://192.168.0.2:31793





##### Deploy Metrics server to Kubernetes Cluster #####
# Deploy Metrics Server
kubectl apply -f https://raw.githubusercontent.com/Azure/AKS-Edge/main/samples/others/metrics-server.yaml

# Verify the Pods (metrics-server)
kubectl get pods -A --watch
kubectl get pods -A

# View your resource consumption
kubectl top nodes
kubectl top pods -A





##### Install Ollama #####
# Installs the Ollama application package from the Windows Package Manager repository onto your system.
winget install Ollama.Ollama --accept-source-agreements --accept-package-agreements

# Refresh environment and check the installed Ollama version
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
ollama --version

# Verify that the Ollama service is running locally
Invoke-RestMethod -Uri "http://localhost:11434"

# Download the specified Ollama model (gemma4:e4b)
ollama pull gemma4:e4b
ollama list

# Test Ollama API
start microsoft-edge:http://localhost:11434/api/tags





##### Install MCP Server (Azure/mcp-kubernetes) #####
start microsoft-edge:https://github.com/Azure/mcp-kubernetes?WT.mc_id=AZ-MVP-4039747
New-Item -ItemType Directory -Force -Path "C:\mcp-server"

# Download the latest Azure Kubernetes MCP Server executable for Windows
Invoke-WebRequest -Uri "https://github.com/Azure/aks-mcp/releases/latest/download/aks-mcp-windows-amd64.exe" -OutFile "C:\mcp-server\mcp-kubernetes.exe"

# Start the Kubernetes MCP server with read-write access for kubectl tools
$env:KUBECONFIG="C:\Users\weithenn\.kube\config"
C:\mcp-server\mcp-kubernetes.exe --access-level=readwrite --enabled-components=kubectl





##### Install Visual Studio Code #####
winget install Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements





##### Continue extension - config.yaml #####
name: Main Config
version: 1.0.0
schema: v1
models:
  - name: Ollama Gemma4
    provider: ollama
    model: gemma4:e4b
    apiBase: http://localhost:11434
    systemMessage: "You are a professional Kubernetes expert. Always communicate and respond in Traditional Chinese (繁體中文)."
mcpServers:
  - name: kubernetes
    command: C:\mcp-server\mcp-kubernetes.exe
    args:
      - --access-level=admin
      - --enabled-components=kubectl
    env:
      KUBECONFIG: C:\Users\weithenn\.kube\config





##### Lab - Environment #####
# Check the status and node information of the Kubernetes cluster
kubectl get nodes

# List all running pods in the default namespace
kubectl get pods

# Prompt
1.請幫我查詢目前的 Kubernetes 叢集有哪些 Node 節點和 Pod 容器?
2.請全程使用繁體中文回答。





##### Lab01 - Prompt #####
# Create a test Pod with intentionally excessive resource requests to simulate a Pending state
@"
apiVersion: v1
kind: Pod
metadata:
  name: pending-demo-pod
  namespace: default
spec:
  containers:
  - name: demo
    image: nginx:alpine
    resources:
      requests:
        memory: "128Gi"
        cpu: "100"
"@ | kubectl apply -f -


# Retrieve the current status of the pending-demo-pod (Status is Pending)
kubectl get pod pending-demo-pod

# Prompt
1.幫我檢查 default namespace 底下的 Pod 狀態，為什麼有一個 Pod 停在 Pending?
2.請告訴我原因與解決方法。
3.請全程使用繁體中文回答。

# Delete the pending-demo-pod from the default namespace
kubectl delete pod pending-demo-pod -n default




##### Lab02 - Nginx CRUD #####
# Create - Prompt
1.請幫我在 Kubernetes 叢集中建立一個名為 frontend 的 Namespace，並在裡面部署一個名稱為 web-nginx 的 Nginx 應用程式，使用 nginx:alpine 鏡像，Replicas 設定為 3，並建立一個 Port 80 的 EXTERNAL-IP 以便部署完成後能存取服務。
2.建立完成後請檢查 Pod 和 EXTERNAL-IP 是否正常運行。
3.請全程使用繁體中文回答。

# Verify and test your web-nginx (using EXTERNAL-IP)
kubectl get all -n frontend
start microsoft-edge:http://192.168.0.5


# Read - Prompt
1.請檢查 frontend Namespace 下所有資源的運行狀態。確認 Nginx Pod 是否都已正常 running？
2.如果正常，請讀取其中一個 Pod 最新印出的 Log 給我看。
3.請全程使用繁體中文回答。


# Update - Prompt
1.請幫我將 frontend Namespace 中的 web-nginx Deployment 副本數（Replicas）擴充到 5 個。
2.確認所有 Pod 都成功啟動。
3.請全程使用繁體中文回答。

# Verify and test your web-nginx (using EXTERNAL-IP)
kubectl get all -n frontend
start microsoft-edge:http://192.168.0.5


# Delete - Prompt
1.測試完成，請刪除 frontend Namespace 以及裡面所有的資源，並確認是否已完全清除。
2.請全程使用繁體中文回答。

# Retrieve all resources (Pods, Services, Deployments, ReplicaSets) in the default namespace
kubectl get all





##### Lab03 - MCP Server (Azure/mcp-kubernetes) --access-level #####
start microsoft-edge:https://github.com/Azure/mcp-kubernetes?WT.mc_id=AZ-MVP-4039747
--access-level=readonly
--access-level=readwrite
--access-level=admin




# Register for a free Microsoft Ignite digital pass now!
start microsoft-edge:https://ignite.microsoft.com/en-US/home?WT.mc_id=AZ-MVP-4039747