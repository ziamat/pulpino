# PANDUAN LENGKAP SINTESIS & IMPLEMENTASI FPGA ZYBO SOC PULPINO

---

## 🛠️ BAGIAN 1: DAFTAR TOOL & REKOMENDASI INSTALASI

Sebelum memulai pengerjaan, instal dan siapkan perangkat lunak berikut pada sistem Windows Anda:

### 1. Python 2.7
* **Tujuan**: Kompatibilitas dengan skrip bawaan PULPino (seperti `update-ips.py` dan `generate-scripts.py` yang menggunakan sintaks Python lama).
* *Catatan*: Python 3.x+ sering kali memicu error sintaks pada repositori dasar PULPino.

### 2. Windows Subsystem for Linux (WSL 2 - Ubuntu)
* **Tujuan**: Melakukan kompilasi software aplikasi (folder `sw/`) karena proses build dalam lingkungan Linux jauh lebih cepat dibanding Windows murni.
* **Cara instalasi**: Buka PowerShell/Command Prompt sebagai Administrator dan jalankan:
  ```powershell
  wsl --install -d Ubuntu
  ```
* Lalu masuk ke terminal WSL Anda dan jalankan instalasi paket-paket yang diperlukan:
  ```bash
  sudo apt update
  sudo apt install build-essential tcsh cmake git make gcc-riscv64-unknown-elf fakeroot bison flex libssl-dev bc u-boot-tools libncurses-dev rsync unzip wget cpio dos2unix
  ```
### 3. Git for Windows
* **Tujuan**: Melakukan version control dan clone repositori.

### 4. Kompilator / Toolchain GNU
* **RISC-V GNU Toolchain (Official/ETH)**: `riscv64-unknown-elf-` untuk keperluan kompilasi umum RISC-V.
* [**Xilinx GNU Linux Toolchain**](https://github.com/SmartElec/Sourcery_CodeBench_Lite_for_Xilinx_GNU_Linux): `arm-xilinx-linux-gnueabi-` untuk mengompilasi sistem operasi Linux dan utility `spiload` yang akan dijalankan di sisi prosesor ARM Cortex-A9 Zynq.

---

## 📂 BAGIAN 2: PERSIAPAN REPOSITORI & ENVIRONMENT PATH

### Git Clone Repositori & Inisialisasi IP
Langkah pertama sebelum memulai konfigurasi adalah mengunduh repositori utama PULPino, lalu mengintegrasikan berkas-berkas modifikasi porting FPGA Zynq dari repositori `ziamat/pulpino`:
```bash
# Clone repositori utama PULPino
git clone https://github.com/pulp-platform/pulpino.git

# Clone repositori modifikasi
git clone https://github.com/ziamat/pulpino.git ziamat-pulpino

# Salin/timpa manual file modifikasi dari ziamat ke repositori utama

# Masuk ke folder proyek utama
cd pulpino
```

Jalankan proses persiapan file script PULPino dari host Windows menggunakan Python 2.7. 

Buka Command Prompt (CMD) Windows dan jalankan perintah untuk mengunduh seluruh IP Core:
   ```cmd
   "C:\Python27\python.exe" update-ips.py
   "C:\Python27\python.exe" generate-scripts.py
   ```

---

## ⚙️ BAGIAN 3: KONFIGURASI ENVIRONMENT VIVADO & TARGET HARDWARE

> [!IMPORTANT]
> Langkah-langkah pada Bagian 3 ini dijalankan pada **Windows Command Prompt (CMD)** biasa, **BUKAN** di terminal WSL (Ubuntu).

Untuk mempermudah inisialisasi toolchain Vivado dan konfigurasi parameter board, Anda dapat membuat berkas skrip **`pulpino_env.bat`** pada host Windows Anda.

1. Buka editor teks (misal Notepad) dan buat berkas bernama `pulpino_env.bat`.
2. Salin baris konfigurasi berikut ke dalamnya (sesuaikan path direktori instalasi Vivado di komputer Anda):
   ```cmd
   @echo off
   call "D:\Xilinx\2025.1\Vivado\settings64.bat"
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

### Migrasi Folder `fpga/sw` ke WSL (Ubuntu)
1. Pindahkan atau salin folder `fpga/sw/` ke dalam filesystem WSL Ubuntu (misalnya ke direktori home `~/linux_build/sw`):
   ```bash
   mkdir -p ~/linux_build
   cp -r /mnt/d/<your>/pulpino/fpga/sw ~/linux_build/
   ```
2. Masuk ke WSL dan navigasikan ke folder tersebut.
   ```bash
   cd ~/linux_build/sw
   ```
3. **Konfigurasi Environment Variable via Script**:
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
   export PATH="/mnt/d/<your>/Sourcery_CodeBench_Lite_for_Xilinx_GNU_Linux/bin:$PATH"

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
4. **Catatan Build WSL**: Perintah build otomatis `make all` di WSL dapat berjalan sukses. Namun, proses kompilasi nantinya akan terhenti saat mencoba menjalankan target `make fsbl`. Hal ini normal dan memang diharapkan karena pembuatan file FSBL kini dialihkan secara manual melalui Vitis GUI pada **Bagian 5**. Lakukan kompilasi komponen secara bertahap:

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

### Build Host Utility spiload (ARM Host)
1. Sebelum mengompilasi utility spiload, pastikan Anda telah memuat environment variable terlebih dahulu di terminal WSL Anda (`source sourceme.sh`).
2. Masuk ke direktori `fpga/sw/apps/spiload/`.
3. Jalankan `make` untuk menghasilkan binary `spiload`.
	```bash
 	make spiload
 	```

---

## 🏗️ BAGIAN 5: PEMBUATAN FSBL & BOOT IMAGE (BOOT.BIN) VIA GUI VITIS IDE

Setelah proses di Bagian 3 (`make all` Vivado) selesai dan berkas `u-boot.elf` telah digenerasi dari Bagian 4, lakukan langkah integrasi Vivado ke Vitis berikut untuk menghasilkan bootloader (`fsbl.elf`) dan file boot (`BOOT.BIN`):

### Ekspor Hardware dari Vivado
1. Buka berkas proyek Vivado **`pulpemu.xpr`** yang tergenerasi di dalam subfolder `fpga/pulpemu/`.
2. Di menu Vivado Anda, buka **File > Export > Export Hardware**.
3. Pastikan Anda memilih/mencentang opsi **Include bitstream**.
4. Langkah ini akan menghasilkan berkas spesifikasi hardware berformat baru **`.xsa`** di folder proyek.

### Membuka Vitis Unified IDE 2025.1 dari Vivado
> [!IMPORTANT]
> Jangan membuka aplikasi Vitis Unified IDE secara terpisah atau manual dari shortcut OS. Hal ini dapat memicu error koneksi (*error connection to vitis server*). Buka Vitis langsung dari dalam GUI Vivado yang sedang aktif melalui menu **Tools > Launch Vitis IDE**.

### Membuat Platform Component
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

### Pembuatan Boot Image (BOOT.BIN)
1. Di dalam Vitis Unified IDE, pilih tab **Vitis > Create Boot Image**.
2. Pastikan Anda telah menyalin berkas-berkas berikut ke direktori `sd_image/` untuk dipaketkan bersama:
   - `fsbl.elf` (Hasil build platform Vitis di langkah sebelumnya)
   - `pulpemu_top.bit` (File Bitstream dari direktori `pulpemu.runs/impl_1/`)
   - `u-boot.elf` (Hasil kompilasi U-Boot di WSL Bagian 4)
3. Arahkan konfigurasi pembuat boot image ke berkas **`boot.bif`** yang sudah tersedia di folder `fpga/sw/`.
4. Jalankan proses *Generate* hingga berkas **`BOOT.BIN`** berhasil digenerasi di folder keluaran Anda.

---

## 💻 BAGIAN 6: KOMPILASI APLIKASI SOFTWARE

Tahap ini adalah mengompilasi program aplikasi C yang akan dieksekusi oleh core RISC-V PULPino di dalam fabric FPGA. Sesuai dengan konfigurasi toolchain sebelumnya, kita akan sepenuhnya menggunakan lingkungan **WSL (Ubuntu)** yang sudah memiliki compiler `riscv64-unknown-elf-gcc`.

### Kompilasi Aplikasi C PULPino di WSL
Pastikan Anda menormalisasi baris *line-ending* skrip konfigurasi shell menggunakan `dos2unix` terlebih dahulu agar tidak memicu error interpreter di terminal:

1. Buka terminal WSL Anda.
2. Arahkan ke folder `sw/` di direktori proyek:
   ```bash
   cd /mnt/d/<your>/pulpino/sw
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
5. File memori biner hasil kompilasi program Anda (**`spi_stim.txt`**) kini dapat diakses dan disalin dari dalam direktori `sw/build/apps/helloworld/slm_files/`.

---

## 🚀 BAGIAN 7: BOOTING & PENGUJIAN HARDWARE

Setelah seluruh komponen software ARM (Linux, FSBL, BOOT.BIN) dan biner program RISC-V (`spi_stim.txt`) selesai dikompilasi, lakukan pengujian langsung pada hardware fisik board FPGA Zynq.

### Persiapan Partisi SD Card
Pastikan SD Card Anda telah dipartisi dan diformat dengan benar melalui Linux:
* **Format partisi 1 untuk BOOT (FAT32)**:
  ```bash
  sudo mkfs.vfat -F 32 -n BOOT /dev/mmclbk0p1
  ```
* **Format partisi 2 untuk ROOTFS (EXT4)**:
  *(Tanpa fitur 64bit & metadata_csum agar sistem file ext4 kompatibel dengan versi kernel/bootloader yang lebih lawas).*
  ```bash
  sudo mkfs.ext4 -O ^64bit,^metadata_csum -L rootfs /dev/mmcblk0p2
  ```

### Penyalinan Boot File & Rootfs
1. Salin berkas boot berikut ke partisi **BOOT (FAT32)** SD Card:
   - `uImage` (Kernel Linux Zynq dari WSL Bagian 4)
   - `devicetree.dtb` (Device tree terkompilasi dari WSL Bagian 4)
   - `spiload` (utility spiloader dari WSL Bagian 4)
   - `BOOT.BIN` (Hasil dari Vitis Bagian 5)
   - `spi_stim.txt` (Hasil kompilasi program Bagian 6)
3. Ekstrak Rootfs Linux (`rootfs.tar` hasil WSL Bagian 4) ke partisi ext4 SD Card.
   ```bash
   sudo mount /dev/mmclbk0p2 /mnt/sd_rootfs
   sudo tar -xvf /mnt/d/<your>/pulpino/fpga/sw/sd_image/rootfs.tar -C /mnt/sd_rootfs
   ```
5. Pasang SD Card ke board Zynq.
6. Hubungkan kabel UART/Serial ke PC, buka aplikasi serial (seperti PuTTY atau TerraTerm) dengan Baudrate 115200, lalu login sebagai `root` (password: `pulp`).
7. Pastikan  partisi **BOOT (FAT32)** sudah di-mount, lalu jalankan program loader `spiload`, atur timeout komunikasi (`--timeout=100` atau `-t100`), beserta image RISC-V program Anda `spi_stim.txt`:
   ```bash
   mount /dev/mmclbk0p1 /mnt/boot/
   /mnt/boot/spiload --timeout=100 /mnt/boot/spi_stim.txt
   ```
8. **Verifikasi**: Lakukan penekanan pada switch atau button fisik board dan pastikan LED fisik (GPIO OUTPUT 8 s.d 15) menyala bersesuaian, serta keluaran debugger serial memancarkan data feedback di terminal console.
