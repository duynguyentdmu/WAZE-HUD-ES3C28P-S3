# Build the ES3C28P/ES3N28P (ESP32-S3) firmware and merge it into one factory
# image that is flashed at offset 0x0.
#
#   .\build_es3c28p.ps1            -> dist\waze_hud_es3c28p_factory.bin
#   .\build_es3c28p.ps1 -Mock      -> dist\waze_hud_es3c28p_mock_factory.bin (no phone needed)
#   .\build_es3c28p.ps1 -Port COM5 -> also flashes the merged image
#
# dependencies.lock stores a single target, so the S3 lock file is swapped in
# for the build and the CYD lock file is restored afterwards.
param(
    [switch]$Mock,
    [string]$Port = '',
    [string]$IdfProfile = 'C:\Espressif\tools\Microsoft.v5.5.5.PowerShell_profile.ps1'
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

# Kiem tra idf.py da co san chua, neu chua thi tu dong tim va kich hoat moi truong ESP-IDF
if (-not (Get-Command idf.py -ErrorAction SilentlyContinue)) {
    $initialized = $false

    # 1. Thu kich hoat bang Initialize-Idf.ps1 mac dinh cua bo cai Espressif
    if (Test-Path "C:\Espressif\Initialize-Idf.ps1") {
        $idfId = "esp-idf-c8b597983fb75feed08f99e44d31e20e"
        $shortcut = Get-ChildItem -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\ESP-IDF", "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\ESP-IDF" -Filter "*PowerShell*.lnk" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($shortcut) {
            try {
                $sh = New-Object -ComObject WScript.Shell
                $lnkArgs = $sh.CreateShortcut($shortcut.FullName).Arguments
                if ($lnkArgs -match '-IdfId\s+([^\s]+)') {
                    $idfId = $Matches[1]
                }
            } catch {}
        }
        Write-Host "Dang tu dong kich hoat moi truong ESP-IDF 5.5..." -ForegroundColor Cyan
        . "C:\Espressif\Initialize-Idf.ps1" -IdfId $idfId | Out-Null
        if (Get-Command idf.py -ErrorAction SilentlyContinue) {
            $initialized = $true
        }
    }

    # 2. Thu file profile duoc truyen hoac tim trong C:\Espressif\tools
    if (-not $initialized) {
        if (Test-Path $IdfProfile) {
            . $IdfProfile | Out-Null
            $initialized = (Get-Command idf.py -ErrorAction SilentlyContinue)
        } else {
            $autoProfile = Get-ChildItem "C:\Espressif\tools\Microsoft.*.PowerShell_profile.ps1" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($autoProfile -and (Test-Path $autoProfile.FullName)) {
                . $autoProfile.FullName | Out-Null
                $initialized = (Get-Command idf.py -ErrorAction SilentlyContinue)
            }
        }
    }

    if (-not (Get-Command idf.py -ErrorAction SilentlyContinue)) {
        Write-Host "`n[THONG BAO] Khong tim thay lenh 'idf.py' tren he thong!" -ForegroundColor Yellow
        Write-Host "Vui long mo Start Menu -> chay ung dung 'ESP-IDF 5.5 PowerShell' de build firmware." -ForegroundColor Cyan
        throw "Chua kich hoat duoc moi truong ESP-IDF."
    }
}

$suffix = if ($Mock) { '-mock' } else { '' }
$buildDir = "build-s3$suffix"
$sdkconfig = "sdkconfig.es3c28p$($suffix -replace '-', '.')"
$defaults = 'sdkconfig.es3c28p.defaults'
if ($Mock) { $defaults += ';sdkconfig.mock.defaults' }
$output = "dist\waze_hud_es3c28p$($suffix -replace '-', '_')_factory.bin"
$cydLock = Join-Path $PSScriptRoot 'dependencies.lock.cyd.tmp'

if (Test-Path "$PSScriptRoot\dependencies.lock") {
    Copy-Item "$PSScriptRoot\dependencies.lock" $cydLock -Force
}
if (Test-Path "$PSScriptRoot\dependencies.es3c28p.lock") {
    Copy-Item "$PSScriptRoot\dependencies.es3c28p.lock" "$PSScriptRoot\dependencies.lock" -Force
}

try {
    $common = @('-B', $buildDir, '-D', "SDKCONFIG=$sdkconfig", '-D', "SDKCONFIG_DEFAULTS=$defaults")
    if (-not (Test-Path "$buildDir\CMakeCache.txt")) {
        idf.py @common set-target esp32s3
        if ($LASTEXITCODE -ne 0) { throw 'set-target failed' }
    }
    idf.py @common build
    if ($LASTEXITCODE -ne 0) { throw 'build failed' }

    Push-Location $buildDir
    try {
        python -m esptool --chip esp32s3 merge_bin -o "..\$output" --flash_mode dio `
            --flash_size 16MB --flash_freq 80m '@flash_args'
        if ($LASTEXITCODE -ne 0) { throw 'merge_bin failed' }
    } finally { Pop-Location }
    Write-Host "Factory image: $output (flash at 0x0)"

    if ($Port) {
        python -m esptool --chip esp32s3 -p $Port -b 460800 write_flash 0x0 $output
        if ($LASTEXITCODE -ne 0) { throw 'flash failed' }
    }
} finally {
    if (Test-Path "$PSScriptRoot\dependencies.lock") {
        Copy-Item "$PSScriptRoot\dependencies.lock" "$PSScriptRoot\dependencies.es3c28p.lock" -Force
    }
    if (Test-Path $cydLock) {
        Copy-Item $cydLock "$PSScriptRoot\dependencies.lock" -Force
        Remove-Item $cydLock -Force -ErrorAction SilentlyContinue
    }
}
