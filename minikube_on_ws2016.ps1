# File Name:        minikube_on_ws2016.ps1
# Version:          0.1 - 2018/06/12
# Author:           Weithenn Wang (weithenn@weithenn.org)
# Lab Environment:  Azure VM (D8s v3) - Windows Server 2016 Hyper-V / PowerShell
# description:      Windows Server 2016 nested virtualization environment install minikube.
# URL:              https://www.weithenn.org/2018/06/minikube-on-windows-server-2016.html
# License:          MIT License
###########################################################
# Change system Timezone to UTC+8
Set-TimeZone -Name "Taipei Standard Time"
Get-TimeZone

# Disable Administrators IE ESC
$AdminIEOff = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminIEOff -Name "IsInstalled" -Value 0
Stop-Process -Name Explorer

# Install Hyper-V windows feature
Add-WindowsFeature Hyper-V -IncludeManagementTools -Restart

# Create Hyper-V NAT vSwitch
New-VMSwitch -Name "Minikube-NATSwitch" -SwitchType Internal
New-NetNat -Name "Minikube-ContainerNAT" -InternalIPInterfaceAddressPrefix "10.10.75.0/24"
Get-NetAdapter "vEthernet (Minikube-NATSwitch)" | New-NetIPAddress -IPAddress 10.10.75.1 -AddressFamily IPv4 -PrefixLength 24

# Install DHcp Server and setting scope
Install-WindowsFeature DHCP -IncludeManagementTools
Add-DhcpServerV4Scope -Name "Minikube-Lab" -StartRange 10.10.75.51 -EndRange 10.10.75.200 -SubnetMask 255.255.255.0
Set-DhcpServerV4OptionValue -DnsServer 8.8.8.8 -Router 10.10.75.1 -ScopeId 10.10.75.0
Get-DhcpServerV4Scope
Restart-service dhcpserver

# Install kubectl with Powershell from PSGallery
Install-Script -Name install-kubectl -Scope CurrentUser -Force
install-kubectl.ps1 -DownloadLocation C:\tmp
Copy-Item "C:\tmp\kubectl.exe" -Destination "C:\Windows\System32\"

# Install minikube
Invoke-WebRequest -Uri https://storage.googleapis.com/minikube/releases/v0.27.0/minikube-windows-amd64.exe -OutFile "C:\tmp\minikube.exe"
Copy-Item "C:\tmp\minikube.exe" -Destination "C:\Windows\System32\" 
minikube version

# Buildup Minikube VM (Single node kubernetes cluster)
Get-VMSwitch
minikube start --cpus=4 --memory=16384 --disk-size=50g --vm-driver="hyperv" --hyperv-virtual-switch="Minikube-NATSwitch"
Get-ChildItem -Path "C:\Users\Weithenn\.minikube\"
Get-Content "C:\Users\Weithenn\.kube\config"

# Verify single node kubernetes cluster environment
kubectl version
kubectl cluster-info
kubectl get nodes
kubectl get namespaces

# Open Kubernetes Dashboard
minikube status
minikube service list
minikube dashboard

# Deploy a sample pod and expose to external network to minikube
kubectl run hello-minikube --image=gcr.io/google_containers/echoserver:1.4 --port=8080
kubectl expose deployment hello-minikube --type=NodePort
Kubectl get pods
minikube service list
curl $(minikube service hello-minikube --url)

# Login to Minikube VM
minikube ip
minikube docker-env
minikube ssh

# Delete sample pod
kubectl get deployment
kubectl delete deployment hello-minikube
kubectl get pods

# Delete Minikube VM
minikube status
minikube stop
minikube delete
minikube status
