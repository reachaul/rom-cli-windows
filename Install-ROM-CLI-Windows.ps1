$ErrorActionPreference = 'Stop'
$Repo = 'https://github.com/danisiber/rom-cli/archive/refs/heads/main.zip'
$Root = Join-Path $env:LOCALAPPDATA 'rom-cli'
$Zip = Join-Path $env:TEMP 'rom-cli-main.zip'
$Extract = Join-Path $env:TEMP 'rom-cli-extract'

Write-Host '== ROM CLI Windows installer ==' -ForegroundColor Cyan
Write-Host 'This installs the upstream danisiber/rom-cli source and its Python dependencies.'

# Find Python 3.10+ (the upstream project requires Python 3.8+).
$Py = Get-Command py -ErrorAction SilentlyContinue
if ($Py) { $Python = 'py'; $PyArgs = @('-3') }
else {
  $Py = Get-Command python -ErrorAction SilentlyContinue
  if (-not $Py) {
    throw 'Python was not found. Install Python 3.10+ from https://www.python.org/downloads/windows/ and enable Add Python to PATH, then rerun this script.'
  }
  $Python = 'python'; $PyArgs = @()
}

Write-Host '[1/5] Downloading upstream source...'
Invoke-WebRequest -Uri $Repo -OutFile $Zip
if (Test-Path $Extract) { Remove-Item $Extract -Recurse -Force }
New-Item -ItemType Directory -Path $Extract | Out-Null
Expand-Archive -Path $Zip -DestinationPath $Extract -Force
$Source = Get-ChildItem $Extract -Directory | Select-Object -First 1
if (-not $Source -or -not (Test-Path (Join-Path $Source.FullName 'bin/rom'))) {
  throw 'Could not locate upstream bin/rom entry point. The upstream repository layout may have changed.'
}

Write-Host '[2/5] Preparing application folder...'
if (Test-Path $Root) { Remove-Item $Root -Recurse -Force }
New-Item -ItemType Directory -Path $Root | Out-Null
Copy-Item (Join-Path $Source.FullName '*') $Root -Recurse -Force

Write-Host '[3/5] Creating isolated Python environment...'
& $Python @PyArgs -m venv (Join-Path $Root '.venv')
$VenvPython = Join-Path $Root '.venv/Scripts/python.exe'
& $VenvPython -m pip install --upgrade pip
& $VenvPython -m pip install textual pyinstaller

Write-Host '[4/5] Building Windows executable...'
$Entry = Join-Path $Root 'bin/rom'
Push-Location $Root
try {
  & $VenvPython -m PyInstaller --noconfirm --clean --onefile --name rom --collect-all textual $Entry
  if ($LASTEXITCODE -ne 0) { throw 'PyInstaller build failed. See the output above.' }
} finally { Pop-Location }

Write-Host '[5/5] Creating launchers...'
$Exe = Join-Path $Root 'dist/rom.exe'
if (-not (Test-Path $Exe)) { throw 'Build completed but dist/rom.exe was not produced.' }
$Desktop = [Environment]::GetFolderPath('Desktop')
$ShortcutPath = Join-Path $Desktop 'ROM CLI.lnk'
$Wsh = New-Object -ComObject WScript.Shell
$Shortcut = $Wsh.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $Exe
$Shortcut.WorkingDirectory = $Root
$Shortcut.Save()

Write-Host ''
Write-Host "SUCCESS: $Exe" -ForegroundColor Green
Write-Host "Desktop shortcut created: $ShortcutPath"
Write-Host 'Run from PowerShell, for example:'
Write-Host "  & `"$Exe`" -p gba pokemon"
Write-Host 'ROM downloads default to the upstream default location unless you pass -o.'
