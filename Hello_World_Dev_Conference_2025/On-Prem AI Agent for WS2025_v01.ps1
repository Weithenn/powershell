# ==================================================================================================
# Author:         Weithenn Wang (weithenn at weithenn.org)
# Version:        v0.1 - October 14, 2025
# IT event:       Hello World Dev Conference 2025
# Workshop Name:  Building an On-Prem AI Agent for Windows Server 2025: Hands-on System Maintenance
# Description:    Step-by-step to build up AI Agents on Windows Server 2025
# ==================================================================================================



### Check PowerShell and PSReadLine version
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

# Install using msiexec
Start-Process msiexec.exe -ArgumentList "/i `"$PowerShell7_MSI`"" -Wait -Verb RunAs

# === IMPORTANT: From here, open a PowerShell 7 (pwsh.exe) window to continue ===
# Check PowerShell 7 version (must be executed inside PowerShell 7 console, not ISE)
$pwsh = "C:\Program Files\PowerShell\7\pwsh.exe"

if (Test-Path $pwsh) {
    Write-Host "✅ PowerShell 7 executable found: $pwsh"
    & $pwsh -NoLogo -Command "[string]`$PSVersionTable.PSVersion"
} else {
    Write-Host "❌ PowerShell 7 not found, please check installation."
}

# Update PowerShellGet and PSReadLine with PowerShell 7 (run inside PowerShell 7)
Install-Module -Name PowerShellGet -AllowClobber -Force
Install-Module -Name Microsoft.PowerShell.PSResourceGet -AllowClobber -Force
Install-PSResource -Name PSReadLine -Prerelease -Reinstall -TrustRepository
Get-InstalledPSResource -Name PSReadLine

# Install AI Shell with PowerShell 7 (PowerShell ISE is 5.1 and not supported)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-aishell.ps1') }"

# Start AI Shell with PowerShell 7
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

Connect-AzAccount -TenantId $TenantId
Get-AzContext
Get-AzSubscription

# Copilot in Azure Agent chat example (run inside AI Shell in PowerShell 7)
# Example prompt in Traditional Chinese:
你可以看得懂正體中文嗎？ 可以的話，後續都回答我正體中文。
如何一次建立 10 台 Windows Server 2025 的 VM，參數隨便幫我填即可。

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