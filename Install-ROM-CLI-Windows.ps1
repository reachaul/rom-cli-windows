[CmdletBinding()]
param(
    [switch]$SkipShortcut
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$RepoZip = 'https://github.com/danisiber/rom-cli/archive/refs/heads/main.zip'
$InstallRoot = Join-Path $env:LOCALAPPDATA 'rom-cli'
$WorkRoot = Join-Path $env:LOCALAPPDATA ('.rom-cli-build-' + [guid]::NewGuid().ToString('N'))
$StageRoot = Join-Path $WorkRoot 'staged-install'
$ExtractRoot = Join-Path $WorkRoot 'source'
$TempZip = Join-Path $WorkRoot 'upstream.zip'
$BackupRoot = Join-Path $env:LOCALAPPDATA ('rom-cli-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N'))
$MovedOld = $false
$ActivatedNew = $false

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$File,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    & $File @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$FailureMessage (exit code: $LASTEXITCODE)"
    }
}

function Get-PythonCommand {
    $launcher = Get-Command py -ErrorAction SilentlyContinue
    if ($launcher) {
        return [pscustomobject]@{ Path = $launcher.Source; Prefix = @('-3') }
    }

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        return [pscustomobject]@{ Path = $python.Source; Prefix = @() }
    }

    throw 'Python 3.8 or newer was not found. Install Python from https://www.python.org/downloads/windows/ and enable the Python launcher or Add Python to PATH.'
}

try {
    Write-Host '== ROM CLI for Windows ==' -ForegroundColor Cyan
    Write-Host 'Unofficial Windows build helper for danisiber/rom-cli.'
    Write-Host "Install location: $InstallRoot"

    $pythonCommand = Get-PythonCommand
$versionOutput = & $pythonCommand.Path @($pythonCommand.Prefix) --version 2>&1

if ($LASTEXITCODE -ne 0) {
    throw 'Could not determine the Python version.'
}

$versionMatch = [regex]::Match(
    ($versionOutput | Out-String).Trim(),
    'Python\s+(\d+)\.(\d+)'
)

if (-not $versionMatch.Success) {
    throw "Could not parse Python version: $versionOutput"
}

$major = [int]$versionMatch.Groups[1].Value
$minor = [int]$versionMatch.Groups[2].Value
    if (($major -lt 3) -or ($major -eq 3 -and $minor -lt 8)) {
        throw "Python 3.8 or newer is required by the upstream project. Detected: $versionOutput"
    }
    Write-Host "Using Python $versionOutput"

    New-Item -ItemType Directory -Path $WorkRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $ExtractRoot -Force | Out-Null

    Write-Host '[1/6] Downloading upstream source...'
    Invoke-WebRequest -Uri $RepoZip -OutFile $TempZip
    Expand-Archive -LiteralPath $TempZip -DestinationPath $ExtractRoot -Force

    $sourceFolder = Get-ChildItem -LiteralPath $ExtractRoot -Directory | Select-Object -First 1
    if (-not $sourceFolder) {
        throw 'The upstream archive was empty or had an unexpected structure.'
    }

    $entryPoint = Join-Path $sourceFolder.FullName 'bin\rom'
    if (-not (Test-Path -LiteralPath $entryPoint -PathType Leaf)) {
        throw 'Could not find upstream bin\rom. The upstream repository structure may have changed.'
    }

    Write-Host '[2/6] Preparing staging installation...'
    New-Item -ItemType Directory -Path $StageRoot -Force | Out-Null
    Get-ChildItem -LiteralPath $sourceFolder.FullName -Force |
        Copy-Item -Destination $StageRoot -Recurse -Force

    Write-Host '[3/6] Creating isolated Python environment...'
    $venvPath = Join-Path $StageRoot '.venv'
    Invoke-Checked -File $pythonCommand.Path `
        -Arguments (@($pythonCommand.Prefix) + @('-m', 'venv', $venvPath)) `
        -FailureMessage 'Could not create the virtual environment.'

    $venvPython = Join-Path $venvPath 'Scripts\python.exe'
    if (-not (Test-Path -LiteralPath $venvPython -PathType Leaf)) {
        throw 'The virtual environment Python executable was not created.'
    }

    Write-Host '[4/6] Installing build dependencies...'
    Invoke-Checked -File $venvPython -Arguments @('-m', 'pip', 'install', '--upgrade', 'pip') `
        -FailureMessage 'Could not upgrade pip.'
    Invoke-Checked -File $venvPython -Arguments @('-m', 'pip', 'install', 'textual', 'pyinstaller') `
        -FailureMessage 'Could not install Textual and PyInstaller.'

    Write-Host '[5/6] Building rom.exe...'
    Push-Location $StageRoot
    try {
        Invoke-Checked -File $venvPython `
            -Arguments @('-m', 'PyInstaller', '--noconfirm', '--clean', '--onefile', '--name', 'rom', '--collect-all', 'textual', $entryPoint) `
            -FailureMessage 'PyInstaller build failed.'
    }
    finally {
        Pop-Location
    }

    $stagedExe = Join-Path $StageRoot 'dist\rom.exe'
    if (-not (Test-Path -LiteralPath $stagedExe -PathType Leaf)) {
        throw 'Build completed without producing dist\rom.exe.'
    }

    Write-Host '[6/6] Activating the new installation...'
    if (Test-Path -LiteralPath $InstallRoot) {
        Move-Item -LiteralPath $InstallRoot -Destination $BackupRoot
        $MovedOld = $true
    }

    try {
        Move-Item -LiteralPath $StageRoot -Destination $InstallRoot
        $ActivatedNew = $true
    }
    catch {
        if ($MovedOld -and (Test-Path -LiteralPath $BackupRoot) -and -not (Test-Path -LiteralPath $InstallRoot)) {
            Move-Item -LiteralPath $BackupRoot -Destination $InstallRoot
            $MovedOld = $false
        }
        throw
    }

    if (-not $SkipShortcut) {
        try {
            $desktop = [Environment]::GetFolderPath('Desktop')
            $shortcutPath = Join-Path $desktop 'ROM CLI.lnk'
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = Join-Path $InstallRoot 'dist\rom.exe'
            $shortcut.WorkingDirectory = $InstallRoot
            $shortcut.Save()
            Write-Host "Desktop shortcut created: $shortcutPath"
        }
        catch {
            Write-Warning "ROM CLI was installed, but the desktop shortcut could not be created: $($_.Exception.Message)"
        }
    }

    Write-Host ''
    Write-Host 'SUCCESS: ROM CLI was built and installed.' -ForegroundColor Green
    Write-Host "Executable: $(Join-Path $InstallRoot 'dist\rom.exe')"
    if ($MovedOld) {
        Write-Host "Previous installation preserved at: $BackupRoot" -ForegroundColor Yellow
        Write-Host 'After confirming the new version works, you may remove the backup manually.'
    }
    Write-Host 'Example: & "$env:LOCALAPPDATA\rom-cli\dist\rom.exe" -l'
}
catch {
    Write-Host "INSTALLATION FAILED: $($_.Exception.Message)" -ForegroundColor Red

    if ($ActivatedNew -and (Test-Path -LiteralPath $InstallRoot)) {
        Write-Warning 'The new installation was activated before a later step failed. Check the installation folder before retrying.'
    }
    elseif ($MovedOld -and (Test-Path -LiteralPath $BackupRoot) -and -not (Test-Path -LiteralPath $InstallRoot)) {
        try {
            Move-Item -LiteralPath $BackupRoot -Destination $InstallRoot
            Write-Host 'The previous installation has been restored.' -ForegroundColor Yellow
        }
        catch {
            Write-Warning "Automatic restoration failed. Your previous installation remains at: $BackupRoot"
        }
    }

    exit 1
}
finally {
    if (Test-Path -LiteralPath $WorkRoot) {
        Remove-Item -LiteralPath $WorkRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
