# 验证脚本：检查 DSH 能不能连上杀戮尖塔 2 的 MCP 服务
# 用法：powershell -ExecutionPolicy Bypass -File verify.ps1

$ErrorActionPreference = "Continue"
Write-Host "=== 1. 检查端口 ===" -ForegroundColor Cyan
foreach ($p in 8080, 8081) {
    $ok = (netstat -ano | Select-String ":$p\s+.*LISTENING")
    if ($ok) {
        Write-Host "  $p  在监听" -ForegroundColor Green
    } else {
        Write-Host "  $p  没有监听 —— 游戏里按 F8 -> Connect -> 勾选 MCP 服务" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== 2. 请求 MCP 接口 ===" -ForegroundColor Cyan
$body = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"verify","version":"1.0"}}}'
try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:8081/mcp" -Method POST `
        -ContentType "application/json" -Body $body -TimeoutSec 10 -UseBasicParsing
    Write-Host "  HTTP $($r.StatusCode)" -ForegroundColor Green
    $txt = $r.Content
    if ($txt.Length -gt 300) { $txt = $txt.Substring(0, 300) + "..." }
    Write-Host "  返回: $txt"
} catch {
    Write-Host "  请求失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  常见原因：游戏没开 MCP 服务 / 防火墙拦截 / 端口不是 8081" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== 3. 检查 DSH 配置 ===" -ForegroundColor Cyan
$cfg = Join-Path $env:USERPROFILE ".dsh\profiles\desktop\cordis.patch.yml"
if (Test-Path $cfg) {
    $hit = Select-String -Path $cfg -Pattern "mcp-sts2" -SimpleMatch
    if ($hit) {
        Write-Host "  已找到 mcp-sts2 配置" -ForegroundColor Green
    } else {
        Write-Host "  配置里没有 mcp-sts2 —— 把 dsh-sts2.patch.yml 追加进去" -ForegroundColor Yellow
    }
} else {
    Write-Host "  没找到 $cfg —— 你用的是别的 profile？" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== 完成 ===" -ForegroundColor Cyan
Write-Host "配置改完要重启 DSH 才生效。"
