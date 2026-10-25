# 自动安装模组到《杀戮尖塔 2》
# 用法：powershell -ExecutionPolicy Bypass -File tools/install-mods.ps1
#       powershell -ExecutionPolicy Bypass -File tools/install-mods.ps1 -GameDir "D:\SteamLibrary\steamapps\common\Slay the Spire 2"

param(
    [string]$GameDir = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

function Find-GameDir {
    # 1) 常见路径
    $candidates = @()
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root)) {
        $candidates += Join-Path $drive "SteamLibrary\steamapps\common\Slay the Spire 2"
        $candidates += Join-Path $drive "Steam\steamapps\common\Slay the Spire 2"
        $candidates += Join-Path $drive "Program Files (x86)\Steam\steamapps\common\Slay the Spire 2"
    }

    # 2) 从注册表拿 Steam 根目录
    foreach ($reg in @("HKCU:\Software\Valve\Steam", "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam")) {
        try {
            $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).SteamPath
            if ($p) { $candidates += (Join-Path $p "steamapps\common\Slay the Spire 2") }
        } catch {}
    }

    # 3) 解析 libraryfolders.vdf 找所有库
    $steamRoots = @()
    foreach ($reg in @("HKCU:\Software\Valve\Steam", "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam")) {
        try { $steamRoots += (Get-ItemProperty -Path $reg -ErrorAction Stop).SteamPath } catch {}
    }
    foreach ($root in $steamRoots) {
        if (-not $root) { continue }
        $vdf = Join-Path $root "steamapps\libraryfolders.vdf"
        if (Test-Path $vdf) {
            $content = Get-Content $vdf -Raw
            foreach ($m in [regex]::Matches($content, '"path"\s+"([^"]+)"')) {
                $lib = $m.Groups[1].Value -replace '\\\\', '\'
                $candidates += (Join-Path $lib "steamapps\common\Slay the Spire 2")
            }
        }
    }

    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { return $c }
    }
    return $null
}

if (-not $GameDir) {
    Write-Host "正在查找游戏目录…" -ForegroundColor Cyan
    $GameDir = Find-GameDir
}

if (-not $GameDir -or -not (Test-Path $GameDir)) {
    Write-Host "没找到《杀戮尖塔 2》的安装目录。" -ForegroundColor Red
    Write-Host "请手动指定：" -ForegroundColor Yellow
    Write-Host '  powershell -ExecutionPolicy Bypass -File tools/install-mods.ps1 -GameDir "你的游戏路径"'
    exit 1
}

Write-Host "游戏目录：$GameDir" -ForegroundColor Green

$modsDir = Join-Path $GameDir "mods"
New-Item -ItemType Directory -Path $modsDir -Force | Out-Null

$targets = @(
    @{ Name = "STS2AIAgent";     Src = Join-Path $RepoRoot "mods\STS2AIAgent" },
    @{ Name = "DirectConnectIP"; Src = Join-Path $RepoRoot "mods\DirectConnectIP" }
)

foreach ($t in $targets) {
    if (-not (Test-Path $t.Src)) {
        Write-Host "  缺少源目录：$($t.Src)" -ForegroundColor Red
        continue
    }
    $dest = Join-Path $modsDir $t.Name
    if (Test-Path $dest) {
        $backup = "$dest.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $dest $backup -Recurse -Force
        Write-Host "  已备份旧版本：$backup" -ForegroundColor Yellow
    }
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    Copy-Item (Join-Path $t.Src "*") $dest -Recurse -Force
    Write-Host "  已安装 $($t.Name) -> $dest" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== 完成 ===" -ForegroundColor Cyan
Write-Host "启动游戏，模组列表里应该能看到："
Write-Host "  STS2AIAgent"
Write-Host "  DirectConnectIP"
Write-Host ""
Write-Host "进游戏后按 F8 -> Connect -> 勾选启用 MCP 服务（默认 8081）"
