# Connect-SharedDrive.ps1
# Connects to \\mvulan-s1\shared and maps it as Z: visible in File Explorer

$SharePath   = "\\mvulan-s1\shared"
$DriveLetter = "Z"   # Letter only, no colon

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Shared Drive Connection Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Connecting to: $SharePath" -ForegroundColor Yellow
Write-Host ""

# Prompt for credentials securely
$Credential = Get-Credential -Message "Enter your credentials to connect to $SharePath"

if ($null -eq $Credential) {
    Write-Host "No credentials provided. Aborting." -ForegroundColor Red
    exit 1
}

$Username = $Credential.UserName
$Password = $Credential.GetNetworkCredential().Password

# --- Clean up any existing mapping on Z: ---
Write-Host "Cleaning up any existing Z: mapping..." -ForegroundColor Yellow
Remove-PSDrive -Name $DriveLetter -Force -ErrorAction SilentlyContinue
net use "${DriveLetter}:" /delete /yes 2>&1 | Out-Null
Remove-SmbMapping -LocalPath "${DriveLetter}:" -Force -UpdateProfile -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# --- Method 1: New-SmbMapping (most reliable for Explorer visibility) ---
Write-Host "Mapping drive Z: ..." -ForegroundColor Yellow
try {
    $mapping = New-SmbMapping -LocalPath "${DriveLetter}:" `
                              -RemotePath $SharePath `
                              -UserName $Username `
                              -Password $Password `
                              -Persistent $true `
                              -ErrorAction Stop

    Write-Host ""
    Write-Host "Successfully mapped $SharePath to Z:!" -ForegroundColor Green
    Write-Host "  Drive  : Z:" -ForegroundColor Green
    Write-Host "  Share  : $SharePath" -ForegroundColor Green
    Write-Host "  User   : $Username" -ForegroundColor Green

} catch {
    Write-Host "New-SmbMapping failed, trying fallback method..." -ForegroundColor Yellow

    # --- Method 2: net use fallback ---
    $netOutput = net use "${DriveLetter}:" $SharePath $Password /user:$Username /persistent:yes 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Successfully mapped $SharePath to Z: (via net use)!" -ForegroundColor Green
        Write-Host "  Drive  : Z:" -ForegroundColor Green
        Write-Host "  Share  : $SharePath" -ForegroundColor Green
        Write-Host "  User   : $Username" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Both mapping methods failed." -ForegroundColor Red
        Write-Host $netOutput -ForegroundColor Red
        Write-Host ""
        Write-Host "Common causes:" -ForegroundColor Yellow
        Write-Host "  - Incorrect username or password" -ForegroundColor Yellow
        Write-Host "  - No network access to $SharePath" -ForegroundColor Yellow
        Write-Host "  - Account lacks permission to this share" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "NOTE: If running as Administrator, try running WITHOUT" -ForegroundColor Yellow
        Write-Host "      'Run as Administrator' - elevation can hide mapped drives." -ForegroundColor Yellow
        exit 1
    }
}

# Refresh File Explorer so the drive appears immediately
Write-Host ""
Write-Host "Refreshing File Explorer..." -ForegroundColor Cyan
$shell = New-Object -ComObject Shell.Application
$shell.Windows() | ForEach-Object { $_.Refresh() }

# Open Explorer at Z:
$Open = Read-Host "Open File Explorer at Z: now? (Y/N)"
if ($Open -match '^[Yy]') {
    Start-Process explorer.exe "${DriveLetter}:"
}