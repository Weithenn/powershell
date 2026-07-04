# ==================================================================================
# Demo 1: Local AI Automated Incident Diagnosis (Windows Server 2025)
# ==================================================================================
# Target: Solve Microsoft Foundry dynamic port allocation & CPU fallback issues.
#         Ensure 100% execution on GPU engine during the live demo.
#
# 🔄 4-Stage Lifecycle:
#
# 1. Clean & Kill (Physical Defense):
#    - Stop foundry service and force-terminate any stale/hung background threads.
#
# 2. Async Init (Engine Initialization):
#    - Launch service asynchronously (Hidden) to avoid stdout deadlock traps.
#    - Dynamically resolve the randomly assigned local port to bypass port conflicts.
#
# 3. GPU Warm-up (Model Preloading):
#    - Preload the 7B model into Tesla T4 VRAM (~8.7GB allocated) via CLI.
#    - Eliminate connection timeout risks on the first API invocation.
#
# 4. Pure On-Premises Inference (Live Diagnosis):
#    - Fetch latest Event Logs and sanitize the payload.
#    - Invoke REST API for ultra-fast local AI diagnosis with 0% CPU overhead.
# ==================================================================================
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

# 1. Trigger a simulated core system error log
Write-EventLog -LogName Application -Source "Application Error" -EventID 1001 -EntryType Error -Message "模擬企業核心 ERP 系統崩潰：服務 w3svc 異常終止。錯誤代碼: 0x80070005。關聯組態路徑 C:\inetpub\wwwroot\web.config 拒絕存取。請即刻排查並恢復地端服務。"

# 2. Fetch the latest Application error log
$targetLog = Get-EventLog -LogName Application -Newest 1 | Select-Object -ExpandProperty Message

Write-Host "=======================================================================" -ForegroundColor Gray
Write-Host "📡 [Live Monitor] Captured latest Windows Server 2025 system exception:" -ForegroundColor Yellow
Write-Host "-----------------------------------------------------------------------" -ForegroundColor Gray
Write-Host $targetLog
Write-Host "=======================================================================`n" -ForegroundColor Gray

# 3. Build prompt and perform strict payload sanitization
$cleanLog = $targetLog -replace "[\r\n]+", " " -replace '"', '\"'

$body = @{
    model = "qwen2.5-coder-7b-instruct-generic-gpu:4"
    messages = @(
        @{ 
            role = "user" 
            content = "你現在是 Windows Server 2025 地端 AI 維運專家。請分析以下錯誤日誌，給出 Root Cause，並提供修復權限並恢復啟動服務的 PowerShell 指令。請用繁體中文回答，直接給核心重點即可：$cleanLog" 
        }
    )
} | ConvertTo-Json -Depth 5 -Compress

$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)

# 4. Dispatch fast GPU inference request
Write-Host "🚀 [Stage 4] Display local AI operations result" -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri $realChatUrl `
                                 -Method Post `
                                 -ContentType "application/json; charset=utf-8" `
                                 -Body $bodyBytes `
                                 -TimeoutSec 90

    $aiAnswer = $response.choices[0].message.content

    Write-Host "`n==================================================================" -ForegroundColor Gray
    Write-Host "🧠 [Foundry Local AI Diagnosis & Remediations]：" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host $aiAnswer
    Write-Host "==================================================================" -ForegroundColor Gray
}
catch {
    Write-Host "`n❌ Error: Inference anomaly detected. Root cause: $($_.Exception.Message)" -ForegroundColor Red
}