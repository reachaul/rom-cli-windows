# Changelog

## Unreleased — installer safety update
- Build in a unique staging directory before touching the current installation.
- Preserve the previous installation as a timestamped backup after a successful build.
- Restore the previous installation if activation of the new build fails.
- Check exit codes for Python, pip, and PyInstaller commands.
- Clean temporary download and extraction files on exit.

This update has not yet been validated on a clean Windows machine. Treat it as a test build until verified.
