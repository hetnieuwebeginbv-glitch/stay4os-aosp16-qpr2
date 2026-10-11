# Stay4OS AOSP 16 QPR2 (Baklava) — Pixel 9a (tegu)

Custom Android 16 QPR2 build met Stay4S branding, gebaseerd op `android-16.0.0_r4`.

## Build Info
- **BUILD_ID**: BP4A.251205.006
- **PLATFORM_VERSION**: 16 (Baklava)
- **Device**: Google Pixel 9a (tegu)
- **Chipset**: Google Tensor G4 (zumapro)
- **Security Patch**: 2025-10-05

## Strategie
Hybrid flash: **Custom QPR2 system** + **Stock BP41 vendor**
- system.img, system_ext.img, product.img, system_dlkm.img: Custom QPR2 build
- vendor.img, vendor_boot.img, vendor_kernel_boot.img, vendor_dlkm.img: Stock BP41 (HALs, drivers)
- boot.img, init_boot.img, dtbo.img: Stock BP41 (kernel)
- vbmeta*.img: Custom QPR2 (AVB)

## Flash
```bash
fastboot -w update stay4os_qpr2_flash.zip
```

## SELinux Fixes
17 vendor types toegevoegd aan `device/google/tegu/sepolicy/vendor/pixel_missing_types.te`:
- sysfs_scsi_devices_0000, sysfs_chip_id, sysfs_display, sysfs_soc
- sysfs_pixelstats, sysfs_irq, sysfs_pixel_stat, sysfs_vendor_mm
- pixelstats_vendor, pixelstats_vendor_exec, battery_history_device
- hal_wifi_ext, hal_wifi_ext_hwservice, hal_wifi_ext_service
- proc_irq, rebalance_interrupts_vendor, turbo_adapter, pixelsystemservice_app

## cgroup Fix
AOSP source `system/core/libprocessgroup/profiles/cgroups.json` gepatcht:
- Optional: true op blkio, cpu, memory

## Build Stats
- Targets: 35,229
- Errors: 0
- Build time: 2u 8m (64 cores)
- Flash zip: 2.5GB (21 files)

## Files
- `build_stay4os.sh` — Build script
- `flash-all.sh` — Flash script
- `pixel_missing_types.te` — SELinux vendor types
- `stay4os_tegu.mk` — Product config
- `BoardConfig.mk` — Board config

## Structuur
```
vendor/stay4s/services/stay4s_agentd.cpp    # Native C++ daemon (UNIX socket)
vendor/stay4s/init.stay4os.rc               # Init service definition
device/google/tegu/sepolicy/.../stay4s_agentd.te  # SELinux policy
scripts/smoke_test.ps1                       # 10-point post-flash test
scripts/opencode_prompt.md                   # OpenCode deployment prompt
STRATEGY.md                                  # 2-year roadmap
```

## Links
- [Stay4S Hub](http://localhost:8090/hub) — Centrale hub (lokaal)
- [Stay4S Agent](http://localhost:8090) — Compute Agent v3
- [GitHub](https://github.com/hetnieuwebeginbv-glitch/stay4os-aosp16-qpr2)

## License
AOSP — Apache 2.0

