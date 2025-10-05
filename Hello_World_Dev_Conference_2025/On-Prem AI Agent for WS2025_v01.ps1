# ==================================================================================================
# Author:         Weithenn Wang (weithenn at weithenn.org)
# Version:        v0.1 - October 14, 2025
# IT event:       Hello World Dev Conference 2025
# Workshop Name:  Building an On-Prem AI Agent for Windows Server 2025: Hands-on System Maintenance
# Description:    Step-by-step to build up AI Agents on Windows Server 2025
# ==================================================================================================





### Workshop 1 - AI Shell ###
# Check PowerShell and PSReadLine version
$PSVersionTable.PSVersion
Get-Module PSReadLine -ListAvailable

# Open Microsoft Edge and navigate to PowerShell Releases page
Start-Process "msedge.exe" "https://github.com/PowerShell/PowerShell/releases?WT.mc_id=AZ-MVP-4039747"

# Download PowerShell 7.5.3 MSI installer
$PowerShell7_URL = "https://github.com/PowerShell/PowerShell/releases/download/v7.5.3/PowerShell-7.5.3-win-x64.msi?WT.mc_id=AZ-MVP-4039747"
$PowerShell7_MSI = "C:\Temp\PowerShell-7.5.3-win-x64.msi"

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

# === IMPORTANT: From here, open a PowerShell 7 (pwsh.exe) window to continue ===
# Update PowerShellGet and PSReadLine with PowerShell 7 (must be executed inside PowerShell 7 console, not ISE)
Install-Module -Name PowerShellGet -AllowClobber -Force
Install-Module -Name Microsoft.PowerShell.PSResourceGet -AllowClobber -Force
Install-PSResource -Name PSReadLine -Prerelease -Reinstall -TrustRepository
Get-InstalledPSResource -Name PSReadLine

# Install AI Shell with PowerShell 7 (PowerShell ISE is 5.1 and not supported)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-aishell.ps1') }"

# Start AI Shell with PowerShell 7 (Maybe need to reopen it)
Import-Module AIShell
Start-AIShell

# Open Microsoft Edge and navigate to Azure CLI page
Start-Process "msedge.exe" "https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest&WT.mc_id=AZ-MVP-4039747"

# Download Azure CLI MSI installer
$AzureCLI_URL = "https://aka.ms/installazurecliwindowsx64?WT.mc_id=AZ-MVP-4039747"
$AzureCLI_MSI = "C:\Temp\azure-cli-2.77.0-x64.msi"

# Download using BITS
Start-BitsTransfer -Source $AzureCLI_URL -Destination $AzureCLI_MSI
Write-Host "Download completed, file location：$AzureCLI_MSI"

# Install using msiexec
Start-Process msiexec.exe -ArgumentList "/i `"$AzureCLI_MSI`"" -Wait -Verb RunAs

# Install Azure PowerShell (take a few minutes)
Install-Module -Name Az -Repository PSGallery -Force
Get-InstalledModule -Name Az -AllVersions

# For Copilot in Azure Agent
$TenantId = "4da9e387-89d2-4e05-bac1-7d764acc6e5a"
$TenantId = "<Your_Azure_TenantId>"

Connect-AzAccount -TenantId $TenantId
Get-AzContext
Get-AzSubscription

# Copilot in Azure Agent chat example (run inside AI Shell in PowerShell 7)
# Example prompt in Traditional Chinese:
你可以看得懂正體中文嗎？ 可以的話，後續都回答我正體中文。
如何一次建立 10 台 Windows Server 2025 的 Azure VMs，參數隨便幫我填即可。

# Inserting code
/code post

# Resolving Errors
test
Resolve-Error

# Switching agents and chat commands
@openai-gpt
/help

# Invoking AI Shell
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 | Invoke-AIShell "CPU(s) is?"
回答我正體中文





### Workshop 2 - Foundry Local and Open WebUI###
# === IMPORTANT: From here, open a PowerShell 7 (pwsh.exe) window to continue ===
# Install Foundry Local latest version (take a few minutes)
winget search Microsoft.FoundryLocal
winget install Microsoft.FoundryLocal

# Check Foundry Local version and service
foundry --version
foundry service status
foundry service start
foundry service status
foundry model list

# Model list filtering
foundry model list --filter device=CPU
foundry model list --filter "alias=phi* device=CPU"
foundry --help

# Run your model
foundry model run phi-4-mini

# Maintenance Windows Server 2025 chat example
請幫我寫一個 PowerShell 腳本，檢查 Windows Server 2025 的 CPU、記憶體、磁碟使用率，並輸出成表格。
請幫我寫一個 PowerShell 腳本，過濾 Windows Server 2025 系統事件日誌中過去 24 小時的錯誤與警告。
請幫我寫一個 PowerShell 腳本，每週日凌晨 2 點自動清理 Temp 資料夾，並寫入排程工作。
請幫我寫一個 PowerShell 腳本，檢查 Windows Server 2025 上有哪些帳號屬於 Administrators 群組。

### The following lines perform manual installation if the latest version fails. ###
# Open Microsoft Edge and navigate to Foundry Local Releases page
Start-Process "msedge.exe" "https://github.com/microsoft/Foundry-Local/releases?WT.mc_id=AZ-MVP-4039747"

# Uninstalling Foundry Local
winget uninstall Microsoft.FoundryLocal

# Download Foundry Local 0.6.87 Release
$FoundryLocal_URL = "https://github.com/microsoft/Foundry-Local/releases/download/v0.6.87/FoundryLocal-x64-0.6.87.msix?WT.mc_id=AZ-MVP-4039747"
$FoundryLocal_MSIX = "C:\Temp\FoundryLocal-x64-0.6.87.msix"

# Ensure directory exists
New-Item -ItemType Directory -Path (Split-Path $FoundryLocal_MSIX) -Force | Out-Null

# Download using BITS
Start-BitsTransfer -Source $FoundryLocal_URL -Destination $FoundryLocal_MSIX
Write-Host "Download completed, file location：$FoundryLocal_MSIX"

# Install Foundry Local 0.6.87 Release (run inside PowerShell 7 and take a few minutes)
cd C:\Temp
Add-AppxPackage .\FoundryLocal-x64-0.6.87.msix

# Check Foundry Local version and service
foundry --version
foundry service status
foundry service start
foundry service status
foundry model list
### The above lines handle removal of the failed version and manual installation ###

### Integrate Open WebUI with Foundry Local ###
# Download and install Visual C++ Redistributable (x64)
$vcURL = "https://aka.ms/vs/16/release/vc_redist.x64.exe?WT.mc_id=AZ-MVP-4039747"
$vcInstaller = "C:\Temp\vc_redist.x64.exe"

# Ensure the target directory exists
New-Item -ItemType Directory -Path (Split-Path $vcInstaller) -Force | Out-Null

# Download using BITS
Start-BitsTransfer -Source $vcURL -Destination $vcInstaller
Write-Host "Download completed, file location: $vcInstaller"

# Run installer in silent mode (/quiet /norestart)
Start-Process -FilePath $vcInstaller -ArgumentList "/install /norestart" -Wait -Verb RunAs


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

# Open WebUI - Enable Direct Connections
# Open WebUI - Connect to Foundry Local

# Add module to Open WebUI
foundry cache list
foundry model download phi-4-mini-reasoning
foundry cache list





### Workshop 3 - Ollama and Open WebUI###
# Stop Foundry service
foundry service status
foundry service stop

# Install Ollama latest version (take a few minutes)
winget search ollama
winget install ollama.ollama

# Check if port 11434 is listening (Ollama default port)
Get-NetTCPConnection -LocalPort 11434 -State Listen

# Running Open WebUI if not running (run inside PowerShell 7)
open-webui serve

# Check if port 8080 is listening
Get-NetTCPConnection -LocalPort 8080 -State Listen

# Open Microsoft Edge and navigate to Open WebUI
Start-Process "msedge.exe" "http://localhost:8080"

# Open Microsoft Edge and navigate to Ollama model library page
Start-Process "msedge.exe" "https://github.com/ollama/ollama?WT.mc_id=AZ-MVP-4039747"
Start-Process "msedge.exe" "https://ollama.com/search"