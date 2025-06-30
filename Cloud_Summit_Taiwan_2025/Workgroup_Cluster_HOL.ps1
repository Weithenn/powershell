# ==================================================================================
# Author:         Weithenn Wang (weithenn at weithenn.org)
# Version:        v0.1 - July 2, 2026
# IT event:       Cloud Summit Taiwan 2025
# Workshop Name:  雲端體驗營 - 擺脫 AD 網域，無痛打造 Windows WorkGroup Cluster
# Description:    Step-by-step to build up Workgroup Cluster on Windows Server 2025
# ==================================================================================

### Credential and Parent Host TrustedHosts
$user = "Administrator"
$securePass = Read-Host "Please enter $user password" -AsSecureString
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePass)

Set-Item WSMan:\localhost\Client\TrustedHosts -Value "smb,node01,node02" -Force





### Hyper-V Nested VMs Configure
$nested_hv_nodes = @("node01", "node02")

foreach ($vm in $nested_hv_nodes) {
    Write-Host "`nConfiguring nested virtualization for VM: $vm" -ForegroundColor Cyan

    # Stop VM before configuration (required)
    Stop-VM -Name $vm -Force

    # Enable MAC address spoofing on default NIC
    Set-VMNetworkAdapter -VMName $vm -Name "Network Adapter" -MacAddressSpoofing On

    # Enable virtualization extensions passthrough to guest
    Set-VMProcessor -VMName $vm -ExposeVirtualizationExtensions $true

    # Retrieve and display the current settings to verify
    $nic = Get-VMNetworkAdapter -VMName $vm -Name "Network Adapter"
    $cpu = Get-VMProcessor -VMName $vm

    # Verification output
    Write-Host "[$vm] Verification Results:" -ForegroundColor Yellow
    Write-Host " - MacAddressSpoofing : $($nic.MacAddressSpoofing)"
    Write-Host " - ExposeVirtualizationExtensions : $($cpu.ExposeVirtualizationExtensions)"
}





### Install Hyper-V role on cluster nodes
$hv_nodes = @("node01", "node02")

foreach ($vm in $hv_nodes) {
    Write-Host "`n[$vm] Installing roles and preparing to reboot..." -ForegroundColor Cyan

    Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
        # Install required roles
        Install-WindowsFeature -Name "Hyper-V", "Hyper-V-PowerShell" -IncludeAllSubFeature -IncludeManagementTools

        # Mark system for reboot
        Restart-Computer -Force
    }

    # Wait for reboot to finish
    Write-Host "Waiting for $vm to come back online..." -ForegroundColor Yellow
    Start-Sleep -Seconds 60
    $state = (Get-VM -Name $vm).State
    if ($state -ne "Running") {
        Write-Host "$vm is not running yet." -ForegroundColor Red
    }

    # Post-reboot: verify feature installation status
    Write-Host "[$vm] Verifying role installation after reboot..." -ForegroundColor Cyan
    Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
        $roles = Get-WindowsFeature -Name Hyper-V
        foreach ($r in $roles) {
            $color = if ($r.Installed) { "Green" } else { "Red" }
            Write-Host " - $($r.Name) : $($r.InstallState)" -ForegroundColor $color
        }
    }
}





### Check DNS Suffix
$dns_suffix_nodes = @("smb", "node01", "node02")

foreach ($vm in $dns_suffix_nodes) {
    Write-Host "`n[$vm]" -ForegroundColor Green
    Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
        $key = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        $nvDomain = Get-ItemPropertyValue -Path $key -Name "NV Domain" -ErrorAction SilentlyContinue
        $domain   = Get-ItemPropertyValue -Path $key -Name "Domain" -ErrorAction SilentlyContinue
        Write-Output "NV Domain : $nvDomain"
        Write-Output "Domain    : $domain"
    }
}





### Configure WinRM and TrustedHosts
$winrm_nodes = @("smb", "node01", "node02")

foreach ($vm in $winrm_nodes) {
    Write-Host "`n[$vm] Configuring WinRM and TrustedHosts..." -ForegroundColor Cyan
    Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
        # Enable PowerShell remoting
        Enable-PSRemoting -Force

        # Set trusted hosts (required in workgroup mode)
        Set-Item -Path 'WSMan:\localhost\Client\TrustedHosts' -Value 'smb,node01,node02' -Force

        # Restart WinRM service to apply the new setting
        Restart-Service WinRM

        # Output the result
        $trusted = Get-Item -Path 'WSMan:\localhost\Client\TrustedHosts'
        Write-Output "TrustedHosts set to: $($trusted.Value)"
    }
}





### Install and verify Failover Clustering
$cluster_nodes = @("node01", "node02")

foreach ($node in $cluster_nodes) {
    Write-Host "`n[$node] Installing Failover Clustering..." -ForegroundColor Cyan

    # Step 1: Install Failover Clustering and reboot
    Invoke-Command -VMName $node -Credential $cred -ScriptBlock {
        $result = Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools -Restart:$false
        Write-Host " - Install Result: $($result.Success)" -ForegroundColor Green
    }

    # Step 2: Verify cluster node and service
    Write-Host " - Verifying installation on $node..." -ForegroundColor Cyan
    Invoke-Command -VMName $node -Credential $cred -ScriptBlock {
        $feature = Get-WindowsFeature -Name Failover-Clustering
        $color = if ($feature.Installed) { "Green" } else { "Red" }
        Write-Host "✔ Feature Installed: $($feature.Installed)" -ForegroundColor $color
    }
}





### Cluster Readiness Check
$cluster_nodes = @("node01", "node02")

foreach ($node in $cluster_nodes) {
    Write-Host "`n=== [$node] Cluster Readiness Check ===" -ForegroundColor Cyan

    Invoke-Command -VMName $node -Credential $cred -ScriptBlock {
        param($nodeName)

        # 1️. Network check
        $ipList = Get-NetIPAddress -AddressFamily IPv4 |
                    Where-Object { $_.IPAddress -notmatch '^169\.254\.' -and $_.IPAddress -notmatch '^0\.' }

        if ($ipList.Count -gt 0) {
            Write-Host "✔ Network: Active IPv4 address detected" -ForegroundColor Green
        } else {
            Write-Host "✖ Network: No valid IPv4 address found" -ForegroundColor Red
        }

        # 2️. Trusted Root Certificate check
        $certFound = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object {
            $_.Subject -like "*$nodeName*" -or $_.Subject -like "*weithenn.org*"
        }

        if ($certFound) {
            Write-Host "✔ Trusted Root Cert: Found relevant certificate:" -ForegroundColor Green
            $certFound | Select-Object Subject | Format-Table
        } else {
            Write-Host "✖ Trusted Root Cert: No matching certificate found" -ForegroundColor Red
        }
    } -ArgumentList $node
}





### Switch to Node01 or Node02 console and execution
New-Cluster -Name wg-cluster -Node node01,node02 -NoStorage -AdministrativeAccessPoint DNS -StaticAddress 10.10.75.15





### Install File Server, Configure SMB share, and setting permissions
Invoke-Command -ComputerName smb -Credential $cred -ScriptBlock {
    Install-WindowsFeature -Name FS-FileServer | Out-Null
    Write-Host "✔ File Server role installed." -ForegroundColor Green
}





### Grant Workgroup Cluster Nodes Access to SMB Witness Share
$ShareName = "witness"
$SharePath = "C:\ClusterWitness"

# Create share folder
Invoke-Command -ComputerName smb -Credential $cred -ScriptBlock {
    param ($SharePath)
    if (-not (Test-Path $SharePath)) {
        New-Item -Path $SharePath -ItemType Directory -Force
    }
} -ArgumentList $SharePath

# Configure NTFS permission to Administrator
Invoke-Command -ComputerName smb -Credential $cred -ScriptBlock {
    param ($SharePath)
    $AccessAccount = "Administrator"
    icacls $SharePath /grant "${AccessAccount}:(OI)(CI)F"
} -ArgumentList $SharePath

# Create SMB share grant FullAccess to Administrator
Invoke-Command -ComputerName smb -Credential $cred -ScriptBlock {
    param ($ShareName, $SharePath)
    $AccessAccount = "Administrator"
    if (-not (Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue)) {
        New-SmbShare -Name $ShareName -Path $SharePath -FullAccess $AccessAccount
    }
} -ArgumentList $ShareName, $SharePath





### Switch to Node01 or Node02 console and execution
Set-ClusterQuorum -FileShareWitness "\\smb\witness" -Credential (Get-Credential)





### Grant Workgroup Cluster Nodes Access to SMB VMs Share
$ShareName = "vms"
$SharePath = "C:\ClusterVMs"
$AccessAccount = "Administrator"

# Create share folder
Invoke-Command -ComputerName smb -Credential $cred -ScriptBlock {
    param ($SharePath)
    if (-not (Test-Path $SharePath)) {
        New-Item -Path $SharePath -ItemType Directory -Force
    }
} -ArgumentList $SharePath

# Configure NTFS permission to Administrator
Invoke-Command -ComputerName smb -Credential $cred -ScriptBlock {
    param ($SharePath, $AccessAccount)
    icacls $SharePath /grant "${AccessAccount}:(OI)(CI)F"
} -ArgumentList $SharePath, $AccessAccount

# Create SMB share grant FullAccess to Administrator
Invoke-Command -ComputerName smb -Credential $cred -ScriptBlock {
    param ($ShareName, $SharePath, $AccessAccount)
    if (-not (Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue)) {
        New-SmbShare -Name $ShareName -Path $SharePath -FullAccess $AccessAccount
    }
} -ArgumentList $ShareName, $SharePath, $AccessAccount





# SMB Global Mapping - switch to Node01 and Node02 console and execution
New-SmbGlobalMapping -RemotePath "\\smb\vms" -Credential (New-Object System.Management.Automation.PSCredential ("smb\Administrator", (Read-Host "Please enter password" -AsSecureString)))
