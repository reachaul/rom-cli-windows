[CmdletBinding()]
param(
    [switch]$SkipShortcut
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$UpstreamZip = 'https://github.com/danisiber/rom-cli/archive/refs/heads/main.zip'
$InstallRoot = Join-Path $env:LOCALAPPDATA 'rom-cli'
$WorkRoot = Join-Path $env:LOCALAPPDATA ('.rom-cli-build-' + [guid]::NewGuid().ToString('N'))
$ArchivePath = Join-Path $WorkRoot 'upstream.zip'
$ExtractRoot = Join-Path $WorkRoot 'source'
$StageRoot = Join-Path $WorkRoot 'staged-install'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupRoot = "$InstallRoot.backup-$Timestamp"

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )
    & $FilePath @Arguments
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

    throw 'Python 3 was not found. Install Python 3.10+ from https://www.python.org/downloads/windows/ and enable Add Python to PATH.'
}

Write-Host '== ROM CLI for Windows ==' -ForegroundColor Cyan
Write-Host 'This installer downloads and builds the upstream danisiber/rom-cli project.'
Write-Host "Install location: $InstallRoot"

try {
    $pythonCommand = Get-PythonCommand
    $versionOutput = & $pythonCommand.Path @($pythonCommand.Prefix) -c 'import sys; print("%d.%d" % sys.version_info[:2])'
    if ($LASTEXITCODE -ne 0) { throw 'Unable to query the installed Python version.' }
    $versionParts = $versionOutput.Trim().Split('.')
    if ([int]$versionParts[0] -lt 3 -or ([int]$versionParts[0] -eq 3 -and [int]$versionParts[1] -lt 10)) {
        throw "Python 3.10 or newer is required. Detected: $versionOutput"
    }
    Write-Host "Using Python $versionOutput"

    New-Item -ItemType Directory -Path $WorkRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $ExtractRoot -Force | Out-Null

    Write-Host '[1/6] Downloading upstream source...'
    Invoke-WebRequest -Uri $UpstreamZip -OutFile $ArchivePath
    Expand-Archive -Path $ArchivePath -DestinationPath $ExtractRoot -Force

    $sourceFolder = Get-ChildItem -Path $ExtractRoot -Directory | Select-Object -First 1
    if (-not $sourceFolder) { throw 'The downloaded upstream archive is empty or has an unexpected structure.' }
    $entryPoint = Join-Path $sourceFolder.FullName 'bin/rom'
    if (-not (Test-Path -LiteralPath $entryPoint -PathType Leaf)) {
        throw 'Could not find upstream bin/rom. The upstream repository structure may have changed.'
    }

    Write-Host '[2/6] Preparing a clean staging installation...'
    New-Item -ItemType Directory -Path $StageRoot -Force | Out-Null
    Copy-Item -Path (Join-Path $sourceFolder.FullName '*') -Destination $StageRoot -Recurse -Force

    Write-Host '[3/6] Creating an isolated Python environment...'
    $venvPath = Join-Path $StageRoot '.venv'
    Invoke-Checked -FilePath $pythonCommand.Path -Arguments (@($pythonCommand.Prefix) + @('-m', 'venv', $venvPath)) -FailureMessage 'Could not create the virtual environment.'
    $venvPython = Join-Path $venvPath 'Scripts/python.exe'
    if (-not (Test-Path -LiteralPath $venvPython)) { throw 'The virtual environment Python executable was not created.' }

    Write-Host '[4/6] Installing build dependencies...'
    Invoke-Checked -FilePath $venvPython -Arguments @('-m', 'pip', 'install', '--upgrade', 'pip') -FailureMessage 'Could not upgrade pip.'
    Invoke-Checked -FilePath $venvPython -Arguments @('-m', 'pip', 'install', 'textual', 'pyinstaller') -FailureMessage 'Could not install Textual and PyInstaller.'

    Write-Host '[5/6] Building rom.exe...'
    Push-Location $StageRoot
    try {
        Invoke-Checked -FilePath $venvPython -Arguments @('-m', 'PyInstaller', '--noconfirm', '--clean', '--onefile', '--name', 'rom', '--collect-all', 'textual', $entryPoint) -FailureMessage 'PyInstaller build failed.'
    }
    finally {
        Pop-Location
    }

    $stagedExe = Join-Path $StageRoot 'dist/rom.exe'
    if (-not (Test-Path -LiteralPath $stagedExe -PathType Leaf)) {
        throw 'Build finished without producing dist/rom.exe.'
    }

    Write-Host '[6/6] Activating the new installation...'
    $hadPreviousInstall = Test-Path -LiteralPath $InstallRoot
    if ($hadPreviousInstall) {
        Move-Item -LiteralPath $InstallRoot -Destination $BackupRoot
    }

    try {
        Move-Item -LiteralPath $StageRoot -Destination $InstallRoot
    }
    catch {
        if ($hadPreviousInstall -and (Test-Path -LiteralPath $BackupRoot) -and -not (Test-Path -LiteralPath $InstallRoot)) {
            Move-Item -LiteralPath $BackupRoot -Destination $InstallRoot
        }
        throw
    }

    if (-not $SkipShortcut) {
        try {
            $desktop = [Environment]::GetFolderPath('Desktop')
            $shortcutPath = Join-Path $desktop 'ROM CLI.lnk'
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = Join-Path $InstallRoot 'dist/rom.exe'
            $shortcut.WorkingDirectory = $InstallRoot
            $shortcut.Save()
            Write-Host "Desktop shortcut created: $shortcutPath"
        }
        catch {
            Write-Warning "The application was installed, but the desktop shortcut could not be created: $($_.Exception.Message)"
        }
    }

    Write-Host ''
    Write-Host 'SUCCESS: ROM CLI was built and installed.' -ForegroundColor Green
    Write-Host "Executable: $(Join-Path $InstallRoot 'dist/rom.exe')"
    if ($hadPreviousInstall) {
        Write-Host "Previous installation preserved at: $BackupRoot" -ForegroundColor Yellow
        Write-Host 'You can delete that backup after confirming the new version works.'
    }
    Write-Host 'Tip: store downloaded files outside the application installation folder.'
}
catch {
    Write-Error $_
    exit 1
}
finally {
    if (Test-Path -LiteralPath $WorkRoot) {
        Remove-Item -LiteralPath $WorkRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
