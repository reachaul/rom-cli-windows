ROM CLI untuk Windows
=====================

Paket ini menyiapkan build Windows dari proyek upstream dananisiber/rom-cli.
Installer mengunduh source resmi dari GitHub saat dijalankan, memasang dependensi
ke virtual environment lokal, lalu membangun rom.exe menggunakan PyInstaller.

PERSYARATAN
- Windows 10/11 64-bit
- Python 3.8+ (disarankan Python 3.10+)
- Koneksi internet saat instalasi

CARA INSTALL
1. Ekstrak ZIP ini ke folder biasa.
2. Jika Python belum ada, pasang dari https://www.python.org/downloads/windows/
   dan aktifkan opsi "Add Python to PATH".
3. Klik kanan Install-ROM-CLI-Windows.ps1 > Run with PowerShell,
   atau jalankan Install.bat.
4. Tunggu proses download source, pemasangan dependensi, dan build selesai.
5. File hasil ada di %LOCALAPPDATA%\rom-cli\dist\rom.exe.
   Shortcut "ROM CLI" dibuat di Desktop.

CONTOH
rom.exe
rom.exe -l
rom.exe -p gba pokemon
rom.exe --list metroid
rom.exe --print-url -p switch "zelda"
rom.exe -o D:\ROMs -p ps2 "gran turismo"

CATATAN
- Ini adalah bootstrap/build package, bukan binary .exe yang sudah dikompilasi.
  PyInstaller perlu dijalankan pada Windows untuk menghasilkan executable Windows.
- Source diambil langsung dari https://github.com/danisiber/rom-cli (branch main).
- Fitur, sumber katalog, dan dukungan platform mengikuti proyek upstream.
- Gunakan hanya file game yang memang berhak Anda unduh/miliki. Paket ini tidak
  menyertakan ROM atau game apa pun.
- Repositori upstream tidak mencantumkan lisensi yang jelas pada saat paket ini dibuat;
  paket ini tidak mengklaim kepemilikan atau lisensi atas source upstream.
