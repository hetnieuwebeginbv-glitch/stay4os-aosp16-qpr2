DEVICE_PATH := device/google/tegu
VENDOR_PATH := device/google/tegu/tegu-vendor
#
# SPDX-FileCopyrightText: 2020 The Android Open-Source Project
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-FileCopyrightText: The Calyx Institute
# SPDX-License-Identifier: Apache-2.0
#

TARGET_BOARD_INFO_FILE := $(DEVICE_PATH)/board-info.txt
TARGET_BOOTLOADER_BOARD_NAME := $(DEVICE_CODENAME)
TARGET_SCREEN_DENSITY := 420

# Security - must be defined before including BoardConfig-common.mk
BOOT_SECURITY_PATCH := 2026-02-05
VENDOR_SECURITY_PATCH := $(BOOT_SECURITY_PATCH)

include device/google/zumapro/BoardConfig-common.mk

# Kernel modules
BOARD_VENDOR_KERNEL_RAMDISK_KERNEL_MODULES_BLOCKLIST_FILE := $(DEVICE_PATH)/recovery/modules.blocklist.vendor_kernel_boot
BOARD_VENDOR_KERNEL_RAMDISK_KERNEL_MODULES_LOAD_RAW := $(strip $(shell cat $(DEVICE_PATH)/recovery/modules.load.vendor_kernel_boot))
BOARD_VENDOR_KERNEL_RAMDISK_KERNEL_MODULES_LOAD += $(BOARD_VENDOR_KERNEL_RAMDISK_KERNEL_MODULES_LOAD_RAW)
BOARD_VENDOR_KERNEL_RAMDISK_KERNEL_MODULES += $(addprefix $(KERNEL_MODULE_DIR)/, $(notdir $(BOARD_VENDOR_KERNEL_RAMDISK_KERNEL_MODULES_LOAD_RAW)))

# SEPolicy
BOARD_VENDOR_SEPOLICY_DIRS += \
    $(DEVICE_PATH)/sepolicy/vendor \
    hardware/google/pixel-sepolicy/common/vendor \

# WiFi
include $(DEVICE_PATH)/wifi/BoardConfig-wifi.mk

include $(VENDOR_PATH)/BoardConfigVendor.mk

# Stay4OS custom system_ext sepolicy
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += device/google/tegu/sepolicy/system_ext/private
