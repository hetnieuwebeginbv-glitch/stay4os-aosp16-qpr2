# Technisch Master Dossier & Flash-Draaiboek: Google Pixel 9a (tegu)

## Deel 1: Hardware & Firmware Baseline (tegu)

- **Codename & Platform:** tegu (SoC: Google Tensor G4 / zumapro)
- **Bootloader:** tegu-16.4-14097580 (QPR2 / Baklava branch)
- **Baseband (Radio):** g5300t-250909-251024-B-14326967
- **Hardware Revisie:** tegu MP1.0 A1, 8 GB LPDDR5, 128 GB Samsung UFS 3.1
- **Bootloader Status:** Device state: unlocked

### Partitie-Architectuur (A/B Slots & Dynamic Partitions)

**Boot Partities (Fysieke GPT Partities):**
- boot (GKI 6.1 kernel)
- init_boot (Core init ramdisk)
- vendor_boot & vendor_kernel_boot (Vendor ramdisk en kernel modules)
- dtbo (Device Tree Blob Overlay)
- pvmfw (Protected Virtual Machine firmware)
- vbmeta, vbmeta_system, vbmeta_vendor (Android Verified Boot metadata)

**Dynamische / Logische Partities (Binnen super):**
- system, system_ext, product, vendor, vendor_dlkm, system_dlkm

## Deel 2: Root-Cause Analyse van Eerdere Flashfouten

| Foutmechanisme | Technische Oorzaak | Definitieve Oplossing |
|---|---|---|
| Bootloop / FastbootD weigering | Kernel mismatch: CP21 kernel (QPR1) vs BP41 bootloader (QPR2) | Gebruik uitsluitend BP41 kernel prebuilts |
| Hangend Google "G"-logo | Treble AIDL/HIDL mismatch: QPR1 system.img vs BP41 vendor.img | Volledige AOSP rebuild op android-16.0.0_r4 (QPR2) |
| AVB_MAGIC fout | --disable-verity brak op stock vbmeta structuur | Flash stock BP41 vbmeta.img ZONDER --disable-verity |
| Windows FastbootD timeouts | USB-driver timing fouten bij overschakeling naar FastbootD | Gebruik atomic packaging via fastboot -w update |
| SELinux Duplicate Types | pixel_missing_types.te had types die al in QPR2 pixel-sepolicy zaten | Types opgeschoond, ontbrekende in vendor-sepolicy |

## Deel 3: Hybride Flash Package

### Benodigde bestanden (21 files)

**Uit AOSP Build:**
- system.img (Stay4OS core framework)
- system_ext.img (Stay4OS extensies & services)
- product.img (Stay4OS product apps)

**Uit Stock BP41:**
- boot.img, init_boot.img, dtbo.img, pvmfw.img
- vendor_boot.img, vendor_kernel_boot.img
- vbmeta.img, vbmeta_system.img, vbmeta_vendor.img
- super_empty.img, vendor.img, vendor_dlkm.img
- system_dlkm.img, system_other.img
- android-info.txt, fastboot-info.txt, userdata.img

### Packaging Script

```bash
mkdir -p /tmp/stay4os_v2_package
cd /tmp/stay4os_v2_package

# Stock BP41 basisbestanden
cp /tmp/bp41_images/{boot,init_boot,dtbo,pvmfw,vendor_boot,vendor_kernel_boot,vbmeta,vbmeta_system,vbmeta_vendor,super_empty,vendor,vendor_dlkm,system_dlkm,system_other}.img .
cp /tmp/bp41_images/{android-info.txt,fastboot-info.txt} .

# Custom QPR2 AOSP partities
cp /workspace/out/target/product/tegu/{system,system_ext,product}.img .

# Zip zonder compressie
zip -0 -r /workspace/stay4os_tegu_v2.zip *
sha256sum /workspace/stay4os_tegu_v2.zip > /workspace/stay4os_tegu_v2.zip.sha256
```

## Deel 4: Flash Draaiboek

### Stap 1: Voorbereiding
- Pixel 9a minimaal 60% batterij
- Directe USB 3.0/USB-C aansluiting (geen hubs)
- Download en verifieer zip:
  ```powershell
  Get-FileHash stay4os_tegu_v2.zip -Algorithm SHA256
  ```

### Stap 2: Fastboot Modus
1. Schakel Pixel 9a uit
2. Power + Volume Omlaag -> Fastboot scherm
3. Verifieer: `fastboot devices` -> `57261JEBF18463 fastboot`
4. Flash: `fastboot -w update stay4os_tegu_v2.zip`

### Stap 3: Proces
1. Fastboot valideert android-info.txt
2. Fysieke partities worden geflasht
3. Herstart naar FastbootD
4. Dynamische partities worden geschreven
5. userdata wordt gewist
6. Automatische reboot

### Stap 4: Eerste Boot
- 0-60s: Statisch Google "G"-logo
- 1-3min: Dynamische boot animatie
- 3-5min: Stay4OS launcher / Setup Wizard

## Deel 5: Noodherstel (Rollback)

```powershell
cd C:\Stay4S-Engineering\pixel9a\firmware\tegu_factory_bp41\tegu_beta-bp41.250916.015.a1
fastboot -w update image-tegu_beta-bp41.250916.015.a1.zip
```

## Deel 6: Smoke Test

```powershell
$serial = "57261JEBF18463"
adb -s $serial wait-for-device
adb -s $serial shell getprop sys.boot_completed
adb -s $serial shell getprop ro.build.version.release
adb -s $serial shell getprop ro.product.brand
adb -s $serial shell cat /proc/cgroups
adb -s $serial shell pidof surfaceflinger
adb -s $serial shell dumpsys battery | Select-String "level|temperature"
```
