# PANDUAN LENGKAP SINTESIS & IMPLEMENTASI FPGA SOC PULPINO

---

## 🛠️ BAGIAN 1: DAFTAR TOOL & REKOMENDASI INSTALASI

Sebelum memulai pengerjaan, instal dan siapkan perangkat lunak berikut pada sistem Windows Anda:

### 1. Python 2.7
* **Tujuan**: Kompatibilitas dengan skrip bawaan PULPino (seperti `update-ips.py` dan `generate-scripts.py` yang menggunakan sintaks Python lama).
* *Catatan*: Python 3.x+ sering kali memicu error sintaks pada repositori dasar PULPino.

### 2. Windows Subsystem for Linux (WSL 2 - Ubuntu 24.04 LTS)
* **Tujuan**: Melakukan kompilasi software aplikasi (folder `sw/`) karena proses build dalam lingkungan Linux jauh lebih cepat dibanding Windows murni.
* **Cara instalasi**: Buka PowerShell/Command Prompt sebagai Administrator dan jalankan:
  ```powershell
  wsl --install -d Ubuntu-24.04
  ```

### 3. MSYS2 (UCRT64)
* **Tujuan**: Menjalankan file skrip shell (.sh) di Windows, khususnya saat mengonfigurasi generator CMake di folder `sw/`.

### 4. Git for Windows
* **Tujuan**: Melakukan version control dan clone repositori.

### 5. Kompilator / Toolchain GNU
* **RISC-V GNU Toolchain (Official/ETH)**: `riscv64-unknown-elf-` untuk keperluan kompilasi umum RISC-V.
* **xPack GNU RISC-V Toolchain**: `riscv-none-elf-` (digunakan secara khusus saat melakukan kompilasi software bare-metal aplikasi PULPino).
* **Xilinx GNU Linux Toolchain**: `arm-xilinx-linux-gnueabi-` (atau toolchain GCC ARM SDK Xilinx) untuk mengompilasi sistem operasi Linux dan utility `spiload` yang akan dijalankan di sisi prosesor ARM Cortex-A9 Zynq.

---

## 📂 BAGIAN 2: PERSIAPAN REPOSITORI & ENVIRONMENT PATH

### 1. Git Clone Repositori PULPino
Langkah pertama sebelum memulai konfigurasi adalah mengunduh repositori utama PULPino:
```bash
git clone https://github.com/pulp-platform/pulpino.git
cd pulpino
```

### 2. Persiapan Dependensi pada WSL (Ubuntu 24.04)
Masuk ke terminal WSL Anda dan jalankan instalasi paket-paket yang diperlukan:
```bash
sudo apt update
sudo apt install build-essential tcsh cmake git make gcc-riscv64-unknown-elf gcc-arm-none-eabi python-yaml fakeroot bison flex libssl-dev bc u-boot-tools libncurses-dev rsync unzip wget cpio dos2unix
```
*(Catatan: Jika `python-yaml` tidak tersedia pada apt Ubuntu 24.04, gunakan `pip install pyyaml` di bawah Python 2.7).*

### 3. Pengunduhan & Inisialisasi IP Core
Jalankan proses persiapan file script PULPino dari host Windows menggunakan Python 2.7. 

1. Buka Command Prompt (CMD) Windows dan jalankan perintah untuk mengunduh seluruh IP Core:
   ```cmd
   "C:\Python27\python.exe" update-ips.py
   ```
2. Generasikan script build system menggunakan utilitas Python:
   ```cmd
   "C:\Python27\python.exe" generate-scripts.py
   ```

---

## ⚙️ BAGIAN 3: KONFIGURASI ENVIRONMENT VIVADO & TARGET HARDWARE

> [!IMPORTANT]
> Langkah-langkah pada Bagian 3 ini **WAJIB** dijalankan pada **Windows Command Prompt (CMD)** biasa, **BUKAN** di terminal WSL (Ubuntu) atau MSYS2.

Untuk mempermudah inisialisasi toolchain Vivado dan konfigurasi parameter board, Anda dapat membuat berkas skrip **`pulpino_env.bat`** pada host Windows Anda.

1. Buka editor teks (misal Notepad) dan buat berkas bernama `pulpino_env.bat`.
2. Salin baris konfigurasi berikut ke dalamnya (sesuaikan path direktori instalasi Vivado di komputer Anda):
   ```cmd
   @echo off
   call D:\Xilinx\2025.1\Vivado\settings64.bat
   :: Mengatur Environment Variables untuk Zybo
   set BOARD=zybo
   set XILINX_PART=xc7z010clg400-1
   set XILINX_BOARD=digilentinc.com:zybo:part0:1.0
   :: RI5CY
   set USE_ZERO_RISCY=0
   set RISCY_RV32F=0
   set ZERO_RV32M=0
   set ZERO_RV32E=0
   echo Environment successfully configured for Zybo FPGA ^& Software Build!
   ```
3. Buka **Command Prompt (CMD)** Windows biasa.
4. Jalankan berkas skrip tersebut untuk memuat environment ke terminal:
   ```cmd
   pulpino_env.bat
   ```
5. Verifikasi bahwa variabel lingkungan telah dimuat dengan benar di CMD:
   ```cmd
   set | findstr "BOARD XILINX RISCY ZERO"
   ```
6. Masuk ke direktori `fpga/` dan jalankan perintah build otomatis:
   ```cmd
   cd fpga
   make all
   ```
   
## 🚀 BAGIAN 4: MIGRASI LINUX BUILD (WSL UBUNTU)

> [!IMPORTANT]
> Langkah kompilasi kernel Linux, U-Boot, dan file rootfs pada Bagian 4 ini **WAJIB** dijalankan di dalam lingkungan **WSL (Ubuntu)** agar seluruh proses build berjalan dengan lancar, cepat, dan terhindar dari error restriksi path, symlink, atau kompatibilitas *case-sensitivity* berkas di Windows.

### 1. Migrasi Folder `fpga/sw` ke WSL (Ubuntu)
1. Pindahkan atau salin folder `fpga/sw/` ke dalam filesystem WSL Ubuntu (misalnya ke direktori home `~/linux_build_zybo/sw`).
2. Masuk ke WSL dan navigasikan ke folder tersebut.
   ```bash
   cd ~/linux_build_zybo/sw
   ```
4. **Konfigurasi Environment Variable via Script**:
   Buat skrip inisialisasi lingkungan pembantu `sourceme.sh` di dalam folder tersebut:
   ```bash
   nano sourceme.sh
   ```
   Masukkan kode konfigurasi berikut (sesuaikan path direktori compiler Xilinx GNU Linux Toolchain di sistem Anda):
   ```bash
   #!/bin/bash
   export BOARD=zybo
   export XILINX_PART=xc7z010clg400-1
   export XILINX_BOARD=digilentinc.com:zybo:part0:1.0
   export USE_ZERO_RISCY=0
   export RISCY_RV32F=0
   export ZERO_RV32M=0
   export ZERO_RV32E=0
   export PATH="/mnt/d/your/Sourcery_CodeBench_Lite_for_Xilinx_GNU_Linux/bin:$PATH"

   echo "Environment successfully configured for Zybo FPGA & Software Build!"
   ```
   Jalankan perintah berikut untuk mengaktifkan environment pada sesi terminal WSL Anda:
   ```bash
   source sourceme.sh
   ```
   Verifikasi bahwa variabel lingkungan telah dimuat dengan benar:
   ```bash
   printenv | grep -E "BOARD|XILINX|RISCY|ZERO"
   ```
5. **Catatan Build WSL**: Perintah build otomatis `make all` di WSL dapat berjalan sukses. Namun, proses kompilasi nantinya akan terhenti saat mencoba menjalankan target `make fsbl`. Hal ini normal dan memang diharapkan karena pembuatan file FSBL kini dialihkan secara manual melalui Vitis GUI pada **Bagian 5**. Lakukan kompilasi komponen secara bertahap:

   * **A. Kompilasi U-Boot**
     Jalankan kompilasi u-boot untuk mendapatkan `u-boot.elf`:
     ```bash
     make u-boot
     ```

   * **B. Kompilasi Linux Kernel**
     Jalankan perintah kompilasi kernel:
     ```bash
     make linux
     ```

   * **C. Kompilasi Root Filesystem (Buildroot)**
     Jalankan kompilasi root filesystem dengan perintah:
     ```bash
     make rootfs
     ```

   * **D. Kompilasi Device Tree Blob**
     Jalankan perintah berikut untuk mengompilasi Device Tree:
     ```bash
     make devtree
     ```

### 2. Build Host Utility spiload (ARM Host)
1. Sebelum mengompilasi utility spiload, pastikan Anda telah memuat environment variable terlebih dahulu di terminal WSL Anda (`source sourceme.sh`).
2. Masuk ke direktori [fpga/sw/apps/spiload/].
3. Jalankan `make` untuk menghasilkan binary `spiload`.
	```bash
 	make spiload
 	```

---

## 🏗️ BAGIAN 5: PEMBUATAN FSBL & BOOT IMAGE (BOOT.BIN) VIA GUI VITIS 2025.1

Setelah proses di Bagian 3 (`make all` Vivado) selesai dan berkas `u-boot.elf` telah digenerasi dari Bagian 4, lakukan langkah integrasi Vivado ke Vitis berikut untuk menghasilkan bootloader (`fsbl.elf`) dan file boot (`BOOT.BIN`):

### 1. Ekspor Hardware dari Vivado
1. Buka berkas proyek Vivado **`pulpemu.xpr`** yang tergenerasi di dalam subfolder `fpga/pulpemu/`.
2. Di menu Vivado Anda, buka **File > Export > Export Hardware**.
3. Pastikan Anda memilih/mencentang opsi **Include bitstream**.
4. Langkah ini akan menghasilkan berkas spesifikasi hardware berformat baru **`.xsa`** di folder proyek.

### 2. Membuka Vitis Unified IDE 2025.1 dari Vivado
> [!IMPORTANT]
> Jangan membuka aplikasi Vitis Unified IDE secara terpisah atau manual dari shortcut OS. Hal ini dapat memicu error koneksi (*error connection to vitis server*). Buka Vitis langsung dari dalam GUI Vivado yang sedang aktif melalui menu **Tools > Launch Vitis IDE**.

### 3. Membuat Platform Component
1. Di dalam Vitis Unified IDE, pilih menu **Create Platform Component**.
2. Atur dan tentukan nama platform component sesuai keinginan Anda terlebih dahulu pada kolom input nama, **sebelum** memilih berkas `.xsa`.
3. Setelah nama ditentukan, arahkan kolom *hardware design* ke berkas **`.xsa`** hasil ekspor Vivado sebelumnya.
4. Konfigurasikan target platform dengan memilih:
   - **Operating System**: `standalone`
   - **Processor**: `ps7_cortexa9_0`
   - **Compiler**: `gcc`
5. Lakukan **Build** pada komponen platform yang telah dibuat.
6. Setelah build selesai, berkas **`fsbl.elf`** secara otomatis tergenerasi di dalam workspace Vitis Anda pada direktori path:
   `<workspace-platform-anda>/export/<nama-platform-anda>/sw/boot/fsbl.elf`
7. **Pindahkan berkas `fsbl.elf`** tersebut secara manual ke direktori `sd_image/` Anda.

### 4. Pembuatan Boot Image (BOOT.BIN)
1. Di dalam Vitis Unified IDE, pilih tab **Vitis > Create Boot Image**.
2. Pastikan Anda telah menyalin berkas-berkas berikut ke direktori `sd_image/` untuk dipaketkan bersama:
   - `fsbl.elf` (Hasil build platform Vitis di langkah sebelumnya)
   - `pulpemu_top.bit` (File Bitstream dari direktori `pulpemu.runs/impl_1/`)
   - `u-boot.elf` (Hasil kompilasi U-Boot di WSL Bagian 4)
3. Arahkan konfigurasi pembuat boot image ke berkas **`boot.bif`** yang sudah tersedia di folder `fpga/sw/`.
4. Jalankan proses *Generate* hingga berkas **`BOOT.BIN`** berhasil digenerasi di folder keluaran Anda.
*(Petunjuk visual tambahan dapat dilihat pada gambar referensi step-by-step yang Anda miliki).*

---

## 💻 BAGIAN 6: KOMPILASI APLIKASI SOFTWARE (RISC-V BARE-METAL)

Tahap ini adalah mengompilasi program aplikasi C yang akan dieksekusi oleh core RISC-V PULPino di dalam fabric FPGA. Proses ini dapat dilakukan melalui terminal **MSYS2 (UCRT64)** Windows maupun **WSL (Ubuntu)**.

### 1. Persiapan Build Environment (MSYS2 UCRT64)
Jika Anda menggunakan MSYS2 UCRT64 di Windows, instal terlebih dahulu paket dependensi yang dibutuhkan:
```bash
# Update repository MSYS2
pacman -Syu

# Install paket esensial untuk CMake
pacman -S ucrt64/mingw-w64-ucrt-x86_64-cmake \
          ucrt64/mingw-w64-ucrt-x86_64-make \
          tcsh
```
> [!NOTE]
> Seperti halnya di Ubuntu Linux, paket `python2` sudah tidak tersedia lagi di repositori bawaan MSYS2 `pacman`. Anda tidak perlu menginstalnya dari pengelola paket; interpreter Python 2 akan dideklarasikan/dieksport secara manual di dalam konfigurasi CMake atau skrip build Anda.

*(Catatan: Dependensi untuk lingkungan WSL Ubuntu sudah diinstal sebelumnya di Bagian 2).*

### 2. Kompilasi Aplikasi C PULPino
Pilih salah satu metode terminal di bawah ini untuk menghasilkan file memori `spi_stim.txt`. Pastikan Anda menormalisasi baris *line-ending* skrip konfigurasi shell menggunakan `dos2unix` terlebih dahulu agar tidak memicu error interpreter di terminal:

* **Opsi A: Menggunakan MSYS2 UCRT64 (Windows)**:
  1. Buka terminal **MSYS2 UCRT64**.
  2. Masuk ke folder `sw/` di direktori proyek Anda:
     ```bash
     cd /f/UGM/Skripsi/Sword/pulpino-master/sw
     ```
  3. Konversikan berkas skrip konfigurasi agar kompatibel dengan lingkungan Unix:
     ```bash
     dos2unix cmake_configure.riscv.gcc.sh
     ```
  4. Buat folder *build*, masuk ke dalamnya, jalankan skrip konfigurasi dari direktori induk, lalu kompilasi:
     ```bash
     mkdir -p build && cd build
     ../cmake_configure.riscv.gcc.sh
     mingw32-make helloworld
     ```

* **Opsi B: Menggunakan WSL Ubuntu (Rekomendasi - Lebih Cepat)**:
  1. Buka terminal WSL Anda.
  2. Arahkan ke folder `sw/` di direktori proyek:
     ```bash
     cd /mnt/f/UGM/Skripsi/Sword/pulpino-master/sw
     ```
  3. Konversikan berkas skrip konfigurasi agar kompatibel dengan lingkungan Unix:
     ```bash
     dos2unix cmake_configure.riscv.gcc.sh
     ```
  4. Buat folder *build*, masuk ke dalamnya, jalankan skrip konfigurasi dari direktori induk, lalu kompilasi:
     ```bash
     mkdir -p build && cd build
     ../cmake_configure.riscv.gcc.sh
     make helloworld
     ```

### 3. Pemberesan Output (s19toslm.py)
Modifikasi script [s19toslm.py](file:///f:/UGM/Skripsi/Sword/pulpino-master/sw/utils/s19toslm.py) dengan menambahkan pembersihan `.strip()` pada baris pembaca teks. Hal ini penting untuk menormalisasi line-ending Windows CRLF (`\r\n`) agar hasil pemotongan string alamat instruksi di file output memori `.slm`/`spi_stim.txt` tidak meleset.

### 4. Device Tree (system.dts)
File device tree `system.dts` diatur agar konsol UART ARM Zynq diposisikan pada `ttyPS0` (Baud 115200) untuk mencegah interferensi dengan bus interface UART milik PULPino yang terpetakan ke pin I/O FPGA lainnya. Catatan: Terdapat penambahan konfigurasi node alias `serial1` di dalam `system.dts` agar port UART tambahan milik PULPino dapat dideteksi dan dikenali dengan benar oleh kernel Linux.

---

## 🚀 BAGIAN 7: BOOTING & PENGUJIAN HARDWARE

Setelah seluruh komponen software ARM (Linux, FSBL, BOOT.BIN) dan biner program RISC-V (`spi_stim.txt`) selesai dikompilasi, lakukan pengujian langsung pada hardware fisik board FPGA Zynq:

1. Salin berkas boot berikut ke partisi FAT32 SD Card:
   - `BOOT.BIN` (Hasil dari Vitis Bagian 5)
   - `uImage` (Kernel Linux Zynq dari WSL Bagian 4)
   - `devicetree.dtb` (Device tree terkompilasi dari WSL Bagian 4)
2. Ekstrak Rootfs Linux (`rootfs.tar` hasil WSL Bagian 4) ke partisi ext4 SD Card.
3. Pasang SD Card ke board Zynq, atur jumper boot mode ke **SD Boot**, lalu nyalakan board.
4. Hubungkan kabel UART/Serial ke PC, buka terminal serial (Baud 115200), lalu login sebagai `root` (password: `pulp`).
5. Transfer berkas program loader `spiload` dan image RISC-V program Anda `spi_stim.txt` ke Linux Zynq, lalu jalankan:
   ```bash
   ./spiload spi_stim.txt
   ```
6. **Verifikasi**: Lakukan penekanan pada switch fisik board (GPIO INPUT 0 s.d 7) dan pastikan LED fisik (GPIO OUTPUT 8 s.d 15) menyala bersesuaian, serta keluaran debugger serial memancarkan data switch di terminal console.

---

## 📄 LAMPIRAN: LAPORAN PERBANDINGAN KONFIGURASI FOLDER `sw`

Berdasarkan hasil analisis *diff* secara mendalam terhadap tiga folder yang ada saat ini (`sw` asli, `sw - riscv64`, dan `sw - xpack`), berikut adalah rincian perbedaan konfigurasinya untuk mempermudah pemahaman struktur build software RISC-V Anda.

*Catatan: Folder `sw` asli mengandung konfigurasi khusus untuk mengaktifkan **Newlib** dan **Arduino**, sedangkan folder `sw - riscv64` menonaktifkan fitur-fitur tersebut (mirip dengan repositori upstream standar PULPino).*

### 1. Konfigurasi `cmake_configure.riscv.gcc.sh`

| Parameter | `sw` (Source Asli) | `sw - riscv64` | `sw - xpack` |
| :--- | :--- | :--- | :--- |
| **Compiler Paths** | `riscv32-unknown-elf-gcc` | Deteksi dinamis `riscv-none-elf` / `riscv64-unknown-elf`. | Penambahan spesifik akhiran `.exe` untuk *toolchain* Windows + deteksi UCRT64. |
| **TARGET_C_FLAGS** | `-O3 -m32 -g` <br>*(Tanpa `-nostdlib`)* | `-O3 -mabi=ilp32 -march=rv32im_zicsr -g -D__riscv__ -nostdlib` <br>*(Menggunakan `-nostdlib`)* | `-O3 -mabi=ilp32 -march=rv32imc_zicsr -g -D__riscv__` |
| **GCC_MARCH** | `IMXpulpv2` | `rv32im_zicsr` | `rv32imc_zicsr` |
| **ARDUINO_LIB** | `1` (Aktif) | `0` (Mati) | `1` (Aktif) |
| **Generator & CXX** | Standar CMake | Standar CMake | `-G "Unix Makefiles"`, serta pendefinisian eksplisit `CXX_COMPILER` & `CXX_FLAGS`. |

### 2. File: `CMakeLists.txt` (Utama)

| Parameter | `sw` (Source Asli) | `sw - riscv64` | `sw - xpack` |
| :--- | :--- | :--- | :--- |
| **Minimum Version** | `2.8` | `2.8` | `3.5` (Dibutuhkan oleh CMake UCRT64 terbaru). |
| **System Name** | `Linux-CXX` | `Generic` | `Generic` |
| **C Flags (-m)** | `-m32 -march=...` | `-mabi=ilp32 -march=...` | `-mabi=ilp32 -march=...` |
| **CMAKE_EXE_LINKER_FLAGS** | **Tidak ada** `-nostdlib`. (Mendukung Newlib) | **Ada** `-nostdlib`. (Melarang Newlib) | **Ada** `-nostdlib`. (Masih tertinggal di file ini, namun dokumentasinya menyarankan untuk dihapus). |

### 3. Integrasi Newlib C Standard Library (`link.riscv.ld` & `crt0.riscv.S`)

| File / Baris | `sw` (Source Asli) | `sw - riscv64` | `sw - xpack` |
| :--- | :--- | :--- | :--- |
| **`link.riscv.ld`** | `GROUP( -lc -lgloss -lgcc -lsupc++ )` <br>*(Aktif / Tidak dikomentari)* | `/* GROUP( -lc -lgloss -lgcc -lsupc++ ) */` <br>*(Di-comment)* | `GROUP( -lc -lgloss -lgcc -lsupc++ )` <br>*(Aktif)* |
| **`crt0.riscv.S`** | `call __libc_init_array` <br>*(Aktif / Tidak dikomentari)* | `/* call __libc_init_array */` <br>*(Di-comment)* | `call __libc_init_array` <br>*(Aktif)* |

### 4. Konfigurasi Aplikasi (`apps/CMakeLists.txt` & `helloworld.c`)

| File | `sw` (Source Asli) | `sw - riscv64` | `sw - xpack` |
| :--- | :--- | :--- | :--- |
| **`apps/CMakeLists.txt`** | Mengikutsertakan flag `-lm` dan me-*link* library `m` (Math Library dari C). | **Tidak** me-*link* library `m`. | Mengikutsertakan library `m`. |
| **`helloworld.c`** | Menggunakan `#include <stdio.h>` | Menggunakan `#include "string_lib.h"` (Library mini bawaan PULPino). | Menggunakan `#include <stdio.h>` |

### 5. Solusi Khusus *Cross-Platform* (Windows vs Linux)

Ini adalah perbaikan yang **hanya ada di folder `sw - xpack`** karena sifat lingkungan Windows yang unik (*case-insensitive* dan *line-ending* `\r\n`):

1. **`SPI.cpp` & `SPI.h` (Arduino Lib)**: 
   - Di `sw - xpack`: Menggunakan relative path (`#include "../inc/SPI.h"`) untuk menghindari *error* tabrakan nama file `spi.h` dengan `sys_lib`.
   - Di `sw` & `sw - riscv64`: Masih menggunakan `#include "SPI.h"` (Aman di Linux, tapi bentrok di Windows).
2. **`s19toslm.py`**:
   - Di `sw - xpack`: Menggunakan `line = line.strip()` dan `line[-4:-2]` agar parsing file `helloworld.s19` ke `spi_stim.txt` kebal terhadap perbedaan format *newline* Windows (`\r\n`) vs Unix (`\n`).
   - Di `sw` & `sw - riscv64`: Tetap menggunakan versi rentan `line[-6:-4]`.

---

### Kesimpulan Karakteristik Folder:
1. **`sw` (Source Asli)**: Ini adalah *source* yang sudah dimodifikasi agar mengaktifkan **Arduino_lib**, me-*link* **Newlib** (melalui `link.riscv.ld` dan `crt0.riscv.S`), serta membersihkan `-nostdlib`. Optimal untuk arsitektur 32-bit bawaan jika menggunakan lingkungan Linux asli.
2. **`sw - riscv64`**: Ini adalah versi standar pabrikan PULPino (atau repo dasar). Versi ini **mematikan** Newlib, mematikan `ARDUINO_LIB`, dan menggunakan pustaka mini `string_lib.h` untuk printf.
3. **`sw - xpack`**: Versi hibrida. Mengaktifkan Arduino dan Newlib (seperti `sw` asli), tetapi dipersenjatai dengan modifikasi *path*, perlindungan *case-insensitivity*, *fix line-ending*, serta paksaan `-mabi=ilp32` agar *toolchain* Windows `.exe` tetap mampu melakukan tugasnya tanpa masalah.
