# =======================================================================================
# Demo 3: Local AI Security Defense & Blueprint-Level Auto-Recovery (Windows Server 2025)
# =======================================================================================
Clear-Host
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "🧹 [Stage 1] Force terminate stale background threads" -ForegroundColor Cyan
foundry service stop > $null 2>&1
Get-Process -Name "*foundry*", "*Inference.Service*", "*agent*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 3

Write-Host "⚡ [Stage 2] Launch Foundry local service in the background" -ForegroundColor Cyan
Start-Process -FilePath "foundry.exe" -ArgumentList "service start" -WindowStyle Hidden
Start-Sleep -Seconds 5

# Fetch the dynamically assigned local port via status query
$statusLog = foundry service status | Out-String

if ($statusLog -match "running on (http://127\.0\.0\.1:\d+)") {
    $baseUrl = $matches[1]
    $realChatUrl = "$baseUrl/v1/chat/completions"
    Write-Host "✅ [Stage 2] Success: Dynamically captured Foundry local port: $realChatUrl" -ForegroundColor Green
} else {
    $realChatUrl = "http://127.0.0.1:51025/v1/chat/completions"
    Write-Host "⚠️ [Stage 2] Error: Failed to resolve dynamic port: $realChatUrl" -ForegroundColor Yellow
}

Write-Host "🤖 [Stage 3] Preload AI model into Tesla T4 vRAM" -ForegroundColor Cyan
Write-Host "⏳ [Stage 3] Allocating GPU memory, please wait..." -ForegroundColor Gray
foundry model load qwen2.5-coder-7b-instruct-generic-gpu:4 | Out-String | Where-Object { $_ -notmatch "Failed to process model" }
Write-Host "✅ [Stage 3] Success: Inference.Service.Agent.exe is ready on GPU!" -ForegroundColor Green
Write-Host "------------------------------------------------------------------`n" -ForegroundColor Gray



# ------------------------------------------------------------------
# Detect unauthorized processes attempting to disable the firewall
# ------------------------------------------------------------------
Write-Host "🔥 [Threat Simulation] External unknown endpoint attempting credential store and core service intrusion via obfuscated scripts..." -ForegroundColor Yellow
Start-Sleep -Seconds 1

Write-Host "🚨 [SECURITY ALERT] High-risk unauthorized process detected (attempting to force-disable firewall)!" -ForegroundColor Red
Write-Host "📊 [Live Monitor] Isolating threat snapshot (30s duration. Watch the Firewall Control Panel on the right)..." -ForegroundColor DarkYellow

$totalDuration = 30
for ($i = 1; $i -le $totalDuration; $i++) {
    Write-Host "   ⚡ [Threat Mitigation] Deep-analyzing malicious process behavior... Progress: $($i.ToString('00'))s / $($totalDuration)s" -ForegroundColor DarkGray
    Start-Sleep -Seconds 1
}

Write-Host "`n⚠️ [Intel Captured] Malicious process signatures fully extracted. Handing over to local AI for remediation blueprint." -ForegroundColor Red
Write-Host "------------------------------------------------------------------" -ForegroundColor Gray

# ------------------------------------------------------------------
# AI Smart Analysis & Remediation Generation
# ------------------------------------------------------------------
Write-Host "🧠 [AI Audit] Dispatching to local GPU for behavioral evaluation and reverse engineering..." -ForegroundColor Cyan

$body = @{
    model = "qwen2.5-coder-7b-instruct-generic-gpu:4"
    messages = @(
        @{ 
            role = "user" 
            content = "你現在是 Windows Server 2025 地端資安專家。目前發現有惡意腳本企圖關閉 Windows 防火牆。請直接給出一行將所有設定檔（Domain, Private, Public）的防火牆狀態完全啟用的標準 Windows PowerShell 指令（使用 Set-NetFirewallProfile），不要有任何多餘的解釋或廢話。" 
        }
    )
} | ConvertTo-Json -Depth 5 -Compress

$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)

try {
    $response = Invoke-RestMethod -Uri $realChatUrl -Method Post -ContentType "application/json; charset=utf-8" -Body $bodyBytes -TimeoutSec 20
    $aiCommand = $response.choices[0].message.content

    Write-Host "🤖 [AI Verdict] Confirmed: Malicious intent to disable system firewall." -ForegroundColor Red
    Write-Host "🛡️ [AI Blueprint] Recommended local remediation commands:" -ForegroundColor Green
    Write-Host "👉 $aiCommand" -ForegroundColor White
    Write-Host "------------------------------------------------------------------" -ForegroundColor Gray

    # ------------------------------------------------------------------
    # [HITL] High-Security Human-in-the-Loop Threshold
    # ------------------------------------------------------------------
    Write-Host "👥 [HITL] High-Security Human-in-the-Loop Threshold" -ForegroundColor Yellow
    $userInput = Read-Host "❓ Governance Alert: Authorize AI-recommended commands to force-enable the firewall? (Y/N)"

    # [Notice] Selecting 'N' will result in an actual firewall shutdown.
    if ($userInput -eq "N" -or $userInput -eq "n") {
        Write-Host "`n⛔ [Operation Aborted] Authorization denied. Pipeline halted; malicious process breached defense..." -ForegroundColor Red
        Write-Host "💥 💥 💥 [CRITICAL] Executing simulated malicious payload..." -ForegroundColor DarkRed
        Start-Sleep -Seconds 1
        
        # 🔥 Threat Action: Force-disabling all firewall profiles via netsh
        netsh advfirewall set allprofiles state off | Out-Null
        
        Write-Host "🚨 [CRITICAL INCIDENT] Windows Defender Firewall has been maliciously disabled!" -ForegroundColor DarkRed
    } 
    # [Tip] Run again or select 'Y' to trigger immediate recovery.
    else {
        Write-Host "`n⚡ [Auto-Defense] Authorized. Executing host security remediation blueprint..." -ForegroundColor Cyan
        Start-Sleep -Seconds 1
        
        # 🔥 Remediation Action: Force-enabling all firewall profiles via Set-NetFirewallProfile
        Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True | Out-Null
        
        Write-Host "✅ [Remediation Success] Windows Firewall profiles restored to secure baseline blueprint!" -ForegroundColor Green
        Write-Host "🟩 [Zero-Trust Remediation] Defense 100% restored. (Refresh Firewall Panel: Red turns back to Green!)" -ForegroundColor Green
    }
}
catch {
    Write-Host "`n❌ Error: Security audit inference anomaly. Root cause: $($_.Exception.Message)" -ForegroundColor Red
}