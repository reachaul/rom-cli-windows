# ROM CLI for Windows

[![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-blue)](https://www.microsoft.com/windows)
[![Build method](https://img.shields.io/badge/build-PyInstaller-green)](https://pyinstaller.org/)

An **unofficial Windows installer and executable builder** for [`danisiber/rom-cli`](https://github.com/danisiber/rom-cli).

The upstream project provides a terminal-based tool for searching and downloading ROMs and game images. Its installation script targets macOS and Linux. This companion project provides a Windows PowerShell installer that downloads the upstream source, creates an isolated Python environment, and builds a Windows executable (`rom.exe`).

> This is a community-made Windows build helper. It is not affiliated with, endorsed by, or an official release of the upstream project.

## Features

- Installs the upstream project from its GitHub `main` branch.
- Creates an isolated Python virtual environment under `%LOCALAPPDATA%\rom-cli`.
- Installs the Python dependencies and builds `rom.exe` with PyInstaller.
- Creates a `ROM CLI` shortcut on the Windows desktop.
- Keeps the upstream application source separate from this installer project.

## Requirements

- Windows 10 or Windows 11 (64-bit recommended).
- Python 3.10 or newer recommended.
- Internet connection during installation.
- PowerShell (included with Windows).

Python is not bundled. If it is not installed, download it from [python.org](https://www.python.org/downloads/windows/) and enable **Add Python to PATH** during setup.

## Installation

1. Download this repository as a ZIP and extract it to a normal folder.
2. Make sure Python is installed and available from the command line (`py --version` or `python --version`).
3. Double-click `Build-ROM-CLI-Windows.bat`.
4. Allow the installer to finish. It downloads the upstream source, installs dependencies, and builds the executable.
5. Launch **ROM CLI** from the desktop shortcut, or run the executable directly:

   ```powershell
   & "$env:LOCALAPPDATA\rom-cli\dist\rom.exe"
   ```

The executable is created at:

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

# Search across sources
& $rom "metroid"

# Browse a platform catalog
& $rom -p gba

# Search for a title on a platform
& $rom -p gba "pokemon"

# List matching results without downloading
& $rom --list "metroid"

# Print a direct download URL, where supported
& $rom --print-url -p switch "zelda"

# Choose a download destination
& $rom -o "D:\ROMs" -p ps2 "gran turismo"
```

For the full command reference, supported platforms, and interactive controls, see the [upstream README](https://github.com/danisiber/rom-cli#readme). Upstream features and catalog sources may change independently of this project.

## Updating / rebuilding

Run `Build-ROM-CLI-Windows.bat` again to rebuild using the latest source on the upstream `main` branch. **Important:** the current installer removes the existing `%LOCALAPPDATA%\rom-cli` installation folder before copying and rebuilding the application. Back up anything you have saved inside that folder first. Downloaded game files should be stored outside that folder.

## Troubleshooting

- **Python not found:** install Python 3.10+ and enable **Add Python to PATH**, then open a new terminal and retry.
- **Build fails:** check your internet connection and confirm that the upstream repository is available. The build depends on the upstream repository structure and may need updating if that structure changes.
- **Windows SmartScreen warning:** this community-built executable is not code-signed. Only run it if you have reviewed and trust the scripts and the source they download.
- **Shortcut does not appear:** run the executable directly from the path shown above.

## Legal and responsible use

This project does not include, host, or distribute game ROMs, BIOS files, keys, or copyrighted game content. It only builds the upstream command-line application. Users are responsible for complying with the laws and terms that apply to the files and services they access. Only download content you are legally entitled to obtain.

## Credits

- Upstream application: [`danisiber/rom-cli`](https://github.com/danisiber/rom-cli)
- Executable packaging: [PyInstaller](https://pyinstaller.org/)
- Terminal interface dependency: [Textual](https://textual.textualize.io/)

This repository contains the Windows installer/build scripts and documentation. The upstream application's code remains the work of its respective author(s) and is downloaded from the upstream repository at installation time. Please review the upstream repository for its current licensing information before redistributing or modifying upstream code.

## Contributing

Issues and pull requests for Windows-specific installation and build problems are welcome. Please include your Windows version, Python version, and the relevant error output when reporting a problem.
