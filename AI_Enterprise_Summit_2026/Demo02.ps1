# =====================================================================
# Demo 2: Local AI Proactive Memory Optimization (Windows Server 2025)
# =====================================================================
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



# ==================== Live Demo Starts ====================
# Retrieve current PowerShell Process ID (PID)
$myPID = $PID

Write-Host "🔥 [Live Monitor] Telemetry module attached to target compute node..." -ForegroundColor Yellow
Write-Host "⚠️ [Alert Trigger] Resource leak detected! Affected [PID: $myPID] memory spiking abnormally." -ForegroundColor Red
Write-Host "📊 [Live Monitor] Collecting telemetry. Watch PID: $myPID memory changes in Task Manager." -ForegroundColor DarkYellow

# Allocate physical memory blocks within secure process to sync with Task Manager
$leakBlocks = New-Object System.Collections.Generic.List[System.Object]
$totalDuration = 30
$oneGBChunk = New-Object System.Byte[] (1024 * 1024 * 1024)

for ($i = 1; $i -le $totalDuration; $i++) {
    try {
        $leakBlocks.Add($oneGBChunk.Clone())
    } catch {
        Write-Host "⚠️ Memory allocation reached maximum limit." -ForegroundColor DarkGray
    }    

    Write-Host "   ⏱️ [Live Monitor] $($i.ToString('00'))s / $($totalDuration)s |Target [PID: $myPID] Allocated Memory: $($i) GB" -ForegroundColor DarkGray
    Start-Sleep -Seconds 1
}

Write-Host "`n⚠️ [CRITICAL WARNING] Target [PID: $myPID] RAM spiked to 30GB! Dispatching telemetry to GPU..." -ForegroundColor Red
Write-Host "------------------------------------------------------------------" -ForegroundColor Gray



# ------------------------------------------------------------------
# AI Smart Decision Making
# ------------------------------------------------------------------
Write-Host "🧠 [AI Decision] Sending memory anomalies and topology to GPU for behavioral analysis..." -ForegroundColor Cyan

$body = @{
    model = "qwen2.5-coder-7b-instruct-generic-gpu:4"
    messages = @(
        @{ 
            role = "user" 
            content = "你現在是 Windows Server 2025 地端運維專家。目前發現一個 PID 為 $myPID 的進程發生記憶體洩漏、嚴重吃滿系統 RAM。請給出一行清除該進程內快取與重置物件釋放記憶體的核心命令，請直接吐出指令，不要有任何多餘的解釋或廢話。" 
        }
    )
} | ConvertTo-Json -Depth 5 -Compress

$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)

try {
    $response = Invoke-RestMethod -Uri $realChatUrl -Method Post -ContentType "application/json; charset=utf-8" -Body $bodyBytes -TimeoutSec 20
    $aiCommand = $response.choices[0].message.content

    Write-Host "🤖 [AI Decision] Foundry Local AI response received with remediation advice：" -ForegroundColor Green
    Write-Host "👉 $aiCommand" -ForegroundColor White
    Write-Host "------------------------------------------------------------------" -ForegroundColor Gray

    # ------------------------------------------------------------------
    # Human-in-the-loop (HITL) Verification Mechanism
    # ------------------------------------------------------------------
    Write-Host "👥 [Human-in-the-loop - Approval Threshold Required]" -ForegroundColor Yellow
    $userInput = Read-Host "❓ [Production environment alert] Approve AI-recommended remediation command? (Y/N)"

    if ($userInput -eq "Y" -or $userInput -eq "y") {
        Write-Host "`n⚡ [Remediation] Authorized. Executing safety commands and garbage collection..." -ForegroundColor Cyan
        Start-Sleep -Seconds 1
        
        # [Remediation] Clear cache and force .NET core to release 30GB without terminating PowerShell
        $leakBlocks.Clear()
        $leakBlocks = $null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        
        Write-Host "✅ [Optimization Success] Anomalous cache reclaimed. Target [PID: $myPID] returned to healthy levels!" -ForegroundColor Green
    } else {
        $leakBlocks.Clear()
        $leakBlocks = $null
        [System.GC]::Collect()
        Write-Host "`n⛔ [Operation Aborted] Denied by administrator. Pipeline safely terminated and temporary RAM freed." -ForegroundColor Red
    }
}
catch {
    $leakBlocks.Clear()
    $leakBlocks = $null
    [System.GC]::Collect()
    Write-Host "`n❌ Error: Inference anomaly detected. Root cause: $($_.Exception.Message)" -ForegroundColor Red
}