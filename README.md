# ROM CLI for Windows

[![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-blue)](https://www.microsoft.com/windows)
[![Build method](https://img.shields.io/badge/build-PyInstaller-green)](https://pyinstaller.org/)
[![Windows build](https://github.com/reachaul/rom-cli-windows/actions/workflows/build-windows.yml/badge.svg)](https://github.com/reachaul/rom-cli-windows/actions/workflows/build-windows.yml)

An **unofficial Windows installer and executable builder** for [`danisiber/rom-cli`](https://github.com/danisiber/rom-cli).

The upstream project is a Python terminal application with an interactive Textual interface. Its documented installer targets macOS and Linux. This companion project provides a PowerShell installer that downloads the upstream source and builds a Windows executable (`rom.exe`).

> This is a community-made Windows build helper. It is not affiliated with, endorsed by, or an official release of the upstream project.

## Features

- Downloads the upstream source from the `main` branch.
- Creates an isolated Python virtual environment.
- Builds `rom.exe` with PyInstaller.
- Creates a `ROM CLI` desktop shortcut (when Windows permits it).
- Builds in a temporary staging directory before replacing an existing installation.
- Includes a GitHub Actions workflow for building and publishing a downloadable CI artifact.
- Preserves the previous installation in a timestamped backup if an update succeeds.
- Leaves the existing installation untouched if downloading or building fails.

## Requirements

- Windows 10 or Windows 11 (64-bit recommended).
- Python 3.10 or newer.
- Internet connection during installation.
- PowerShell (included with Windows).

Python is not bundled. Install it from [python.org](https://www.python.org/downloads/windows/) and enable **Add Python to PATH** during setup. The installer checks the detected Python version before continuing.

## Installation

1. Download this repository using **Code → Download ZIP**, then extract it.
2. Double-click `Build-ROM-CLI-Windows.bat`.
3. Wait while the installer downloads the upstream source, creates a virtual environment, installs dependencies, and builds the executable.
4. Launch **ROM CLI** using the desktop shortcut, or run it from PowerShell:

   ```powershell
   & "$env:LOCALAPPDATA\rom-cli\dist\rom.exe"
   ```

The executable is installed at:

```text
%LOCALAPPDATA%\rom-cli\dist\rom.exe
```

## Usage examples

Run these commands in PowerShell:

```powershell
$rom = "$env:LOCALAPPDATA\rom-cli\dist\rom.exe"

# Open the interactive platform picker
& $rom

# List supported platforms
& $rom -l

# Browse a platform catalog
& $rom -p gba

# Search for a title on a platform
& $rom -p gba "pokemon"

# List matching results without downloading
& $rom --list "metroid"

# Choose a download destination
& $rom -o "D:\ROMs" -p ps2 "gran turismo"
```

For the complete command reference and supported platform list, see the [upstream README](https://github.com/danisiber/rom-cli#readme). Upstream features and catalog sources may change independently of this project.

## Automated build (GitHub Actions)

The **Build Windows executable** workflow can be started manually from the repository Actions tab or by pushing a version tag such as `v0.1.0`. A successful run uploads `rom.exe` as a workflow artifact for 14 days. This is a CI test artifact, not yet a signed installer or a permanent GitHub Release asset.

## Updating / rebuilding

Run `Build-ROM-CLI-Windows.bat` again. The installer builds the new version in a temporary staging folder first. It does **not** remove the current installation before the build succeeds.

When replacing an existing installation, the previous folder is renamed to a timestamped backup beside the new installation, for example:

```text
%LOCALAPPDATA%\rom-cli.backup-20261101-120000
```

After confirming the new version works, you may delete that backup manually. Keep downloaded files outside the application folder; the upstream default download directory is in your user Downloads folder unless you set another destination with `-o` or `ROM_DIR`.

## Troubleshooting

- **Python not found:** install Python 3.10+ and enable **Add Python to PATH**, then open a new terminal and retry.
- **Python version too old:** install a current Python 3 release and ensure the Python launcher (`py`) or `python` command points to it.
- **Build fails:** check your internet connection and confirm the upstream repository is available. The build relies on the upstream repository layout and may need changes if that layout changes.
- **Shortcut does not appear:** run the executable directly from `%LOCALAPPDATA%\rom-cli\dist\rom.exe`.
- **SmartScreen warning:** this community-built executable is not code-signed. Only run it if you have reviewed and trust the installer and upstream source.

## Legal and responsible use

This project does not include, host, or distribute game ROMs, BIOS files, keys, or copyrighted game content. It only builds the upstream command-line application. Users are responsible for complying with the laws and terms that apply to files and services they access. Only download content they are legally entitled to obtain.

## Credits

- Upstream application: [`danisiber/rom-cli`](https://github.com/danisiber/rom-cli)
- Executable packaging: [PyInstaller](https://pyinstaller.org/)
- Terminal interface: [Textual](https://textual.textualize.io/)

This repository contains the Windows installer/build scripts and documentation. The upstream application's code remains the work of its respective author(s) and is downloaded from the upstream repository at installation time. Review the upstream repository for its current licensing information before redistributing or modifying upstream code.

## Contributing

Windows-specific installation and build reports are welcome. When opening an issue, include your Windows version, Python version, the command you ran, and the relevant error output. Do not include personal data or access tokens in logs.
