#!/bin/bash
# Stay4OS QPR2 + Stock BP41 Hybrid Flash
# fastboot -w update <zip>
set -e

echo "Stay4OS QPR2 Flash Script"
echo "========================="

# Flash bootloader/radio from stock (keep BP41)
echo "[1/4] Bootloader + Radio (stock BP41)"
fastboot flash bootloader /tmp/tegu_bp41_factory/tegu_beta-bp41.250916.015.a1/bootloader-tegu_beta-tegu-16.4-14097580.img
fastboot reboot-bootloader
sleep 5
fastboot flash radio /tmp/tegu_bp41_factory/tegu_beta-bp41.250916.015.a1/radio-tegu_beta-g5300t-250909-251024-b-14326967.img
fastboot reboot-bootloader
sleep 5

# Flash boot partitions (stock BP41)
echo "[2/4] Boot partitions (stock BP41)"
fastboot flash boot boot.img
fastboot flash init_boot init_boot.img
fastboot flash dtbo dtbo.img
fastboot flash vendor_boot vendor_boot.img
fastboot flash vendor_kernel_boot vendor_kernel_boot.img
fastboot flash pvmfw pvmfw.img

# Flash vbmeta (custom QPR2)
echo "[3/4] VBMeta (custom QPR2)"
fastboot flash vbmeta vbmeta.img
fastboot flash vbmeta_system vbmeta_system.img
fastboot flash vbmeta_vendor vbmeta_vendor.img

# Flash super (system + vendor)
echo "[4/4] Super partition (system + vendor)"
fastboot flash super_empty super_empty.img
fastboot flash system system.img
fastboot flash system_ext system_ext.img
fastboot flash product product.img
fastboot flash system_dlkm system_dlkm.img
fastboot flash system_other system_other.img
fastboot flash vendor vendor.img
fastboot flash vendor_dlkm vendor_dlkm.img

# Wipe userdata
echo "Wiping userdata..."
fastboot -w

echo "Flash complete! Rebooting..."
fastboot reboot
