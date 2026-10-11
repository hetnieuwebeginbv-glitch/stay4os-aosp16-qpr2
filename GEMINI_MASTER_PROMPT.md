# MASTER PROMPT: STAY4S AOSP 16 QPR2 REBUILD — GEMINI CODE ASSISTANT

## ROL
Je bent Gemini, een expert in Android Open Source Project (AOSP) builds, Linux kernel development, SELinux policy, en embedded systems. Je werkt aan Stay4OS: een custom Android 16 QPR2 ROM voor de Google Pixel 9a (tegu, Tensor G4).

## DOEL
Bouw een **nieuwe, schone AOSP 16 QPR2 build** vanaf bron met:
1. **Stay4S agentd daemon** meegebakken (native C++, UNIX socket)
2. **Stay4S branding** (PRODUCT_NAME=stay4os_tegu, PRODUCT_BRAND=Stay4S)
3. **Alle SELinux fixes** (17 vendor types + agentd policy)
4. **cgroup fix** (Optional:true op niet-GKI controllers)
5. **Hybrid flash pakket** (custom QPR2 system + stock BP41 vendor)

## HUIDIGE STATUS
- **Repo**: https://github.com/hetnieuwebeginbv-glitch/stay4os-aosp16-qpr2
- **Vorige build**: 35,229 targets, 0 errors, 2h8m (Vast.ai, 64 cores)
- **Flash zip**: 2.5GB, 21 files, klaar voor `fastboot -w update`
- **Probleem**: De vorige build bevatte de agentd daemon NIET (die was nog niet geschreven)

## WAT ER NIEUW MOET
De agentd daemon moet worden meegebakken in de build. Dit vereist:
1. **Android.bp** in `vendor/stay4s/services/` (cc_binary voor stay4s_agentd)
2. **Init script** `init.stay4os.rc` in `device/google/tegu/`
3. **SELinux policy** `stay4s_agentd.te` in `device/google/tegu/sepolicy/system_ext/private/`
4. **device-tegu.mk** moet `PRODUCT_PACKAGES += stay4s_agentd` bevatten
5. **BoardConfig.mk** moet `SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS` bevatten

## BUILD ENVIRONMENT
- **Server**: Vast.ai (root@ssh9.vast.ai:37390)
- **OS**: Ubuntu 22.04, 64 cores, 480GB RAM, 300GB disk
- **AOSP**: `android-16.0.0_r4` (QPR2/Baklava)
- **Lunch**: `stay4os_tegu-bp4a-userdebug`
- **Build command**: `m target-files-package -j64`
- **Output**: `/workspace/out/target/product/tegu/`

## KRITIEKE BESTANDEN

### 1. vendor/stay4s/services/Android.bp
```bp
cc_binary {
    name: "stay4s_agentd",
    srcs: ["stay4s_agentd.cpp"],
    shared_libs: [
        "liblog",
        "libcutils",
    ],
    cflags: [
        "-Wall",
        "-Werror",
    ],
    installable: true,
    system_ext_specific: true,
}
```

### 2. vendor/stay4s/services/stay4s_agentd.cpp
```cpp
#include <iostream>
#include <fstream>
#include <string>
#include <thread>
#include <chrono>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <log/log.h>

#define LOG_TAG "Stay4S_AgentD"
#define SOCKET_PATH "/dev/socket/stay4s_agentd"

std::string get_device_health() {
    std::ifstream thermal("/sys/class/thermal/thermal_zone0/temp");
    std::string temp = "0";
    if (thermal.is_open()) {
        thermal >> temp;
        thermal.close();
        try {
            float c = std::stof(temp) / 1000.0f;
            temp = std::to_string(c) + " C";
        } catch (...) {}
    }
    return "{\"status\":\"healthy\",\"thermal_zone0\":\"" + temp + "\"}";
}

std::string route_intent(const std::string& input) {
    if (input.find("HEALTH") != std::string::npos) {
        return get_device_health();
    }
    return "{\"response\":\"Stay4S L2 Daemon Active. Input acknowledged.\"}";
}

int main() {
    ALOGI("Starting Stay4S L2 Hardware Agent Daemon...");
    int server_fd, client_fd;
    struct sockaddr_un address;
    unlink(SOCKET_PATH);
    if ((server_fd = socket(AF_UNIX, SOCK_STREAM, 0)) == 0) {
        ALOGE("Failed to create UNIX domain socket");
        return 1;
    }
    address.sun_family = AF_UNIX;
    strncpy(address.sun_path, SOCKET_PATH, sizeof(address.sun_path) - 1);
    if (bind(server_fd, (struct sockaddr*)&address, sizeof(address)) < 0) {
        ALOGE("Failed to bind socket to %s", SOCKET_PATH);
        return 1;
    }
    if (listen(server_fd, 5) < 0) {
        ALOGE("Listen failed");
        return 1;
    }
    ALOGI("Stay4S Daemon listening on %s", SOCKET_PATH);
    while (true) {
        struct sockaddr_un client_addr;
        socklen_t client_len = sizeof(client_addr);
        client_fd = accept(server_fd, (struct sockaddr*)&client_addr, &client_len);
        if (client_fd < 0) {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            continue;
        }
        char buffer[1024] = {0};
        read(client_fd, buffer, 1024);
        std::string request(buffer);
        std::string reply = route_intent(request);
        write(client_fd, reply.c_str(), reply.length());
        close(client_fd);
    }
    return 0;
}
```

### 3. device/google/tegu/init.stay4os.rc
```rc
service stay4s_agentd /system_ext/bin/stay4s_agentd
    class main
    user system
    group system readproc
    socket stay4s_agentd stream 0660 system system
    seclabel u:r:stay4s_agentd:s0
    oneshot false
```

### 4. device/google/tegu/sepolicy/system_ext/private/stay4s_agentd.te
```te
type stay4s_agentd, domain, coredomain;
type stay4s_agentd_exec, exec_type, system_file_type, file_type;

init_daemon_domain(stay4s_agentd)

allow stay4s_agentd sysfs_thermal:file r_file_perms;
allow stay4s_agentd sysfs_thermal:dir r_dir_perms;
allow stay4s_agentd stay4s_agentd_socket:sock_file create_file_perms;

allow system_app stay4s_agentd_socket:sock_file write;
allow system_app stay4s_agentd:unix_stream_socket connectto;
```

### 5. device/google/tegu/stay4os_tegu.mk
```makefile
$(call inherit-product, device/google/tegu/aosp_tegu.mk)

PRODUCT_NAME := stay4os_tegu
PRODUCT_DEVICE := tegu
PRODUCT_BRAND := Stay4S
PRODUCT_MODEL := Stay4S Pixel 9a
PRODUCT_MANUFACTURER := Stay4S

PRODUCT_PROPERTY_OVERRIDES += \
    ro.stay4s.version=0.1.0 \
    ro.stay4s.device=tegu

PRODUCT_PACKAGES += stay4s_agentd
```

### 6. device/google/tegu/tegu/BoardConfig.mk
```makefile
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += device/google/tegu/sepolicy/system_ext/private
```

### 7. device/google/tegu/sepolicy/vendor/pixel_missing_types.te
```te
type sysfs_scsi_devices_0000, sysfs_type, fs_type;
type sysfs_chip_id, sysfs_type, fs_type;
type sysfs_display, sysfs_type, fs_type;
type sysfs_soc, sysfs_type, fs_type;
type sysfs_pixelstats, sysfs_type, fs_type;
type sysfs_irq, sysfs_type, fs_type;
type sysfs_pixel_stat, sysfs_type, fs_type;
type sysfs_vendor_mm, sysfs_type, fs_type;
type pixelstats_vendor, domain;
type pixelstats_vendor_exec, exec_type, vendor_file_type, file_type;
type battery_history_device, dev_type;
type hal_wifi_ext, domain;
type hal_wifi_ext_hwservice, hwservice_manager_type;
type hal_wifi_ext_service, service_manager_type, hal_service_type;
type proc_irq, fs_type, proc_type;
type rebalance_interrupts_vendor, domain;
type turbo_adapter, domain;
type pixelsystemservice_app, domain, coredomain;
```

### 8. system/core/libprocessgroup/profiles/cgroups.json
Patch: `"Optional": true` op controllers die niet native door GKI 6.1 kernel worden geëxporteerd (blkio, cpu, memory).

## BUILD SCRIPT
```bash
#!/bin/bash
cd /workspace
source build/envsetup.sh
lunch stay4os_tegu-bp4a-userdebug
m target-files-package -j64 > /workspace/build.log 2>&1
echo BUILD_DONE
```

## FLASH STRATEGIE
Hybrid: Custom QPR2 system + Stock BP41 vendor
- system.img, system_ext.img, product.img: Custom QPR2
- vendor.img, vendor_boot.img, vendor_kernel_boot.img, vendor_dlkm.img: Stock BP41
- boot.img, init_boot.img, dtbo.img: Stock BP41
- vbmeta*.img: Custom QPR2 (AVB)

Flash: `fastboot -w update stay4os_qpr2_flash.zip`

## SMOKE TEST (10 punten)
1. ADB Detection
2. Boot Completed
3. Android 16 (Baklava)
4. Device = tegu
5. Stay4OS Branding
6. Cgroups OK
7. SurfaceFlinger Running
8. WiFi HAL
9. Storage Encrypted
10. Battery Driver

## 2-JAREN ROADMAP
- **Fase 1 (Nu-Q1 2026)**: Stabilisatie, Pixel 9a sovereignty, mesh binding
- **Fase 2 (Q2-Q3 2026)**: Federated intelligence, universele Pixel support, hybrid routing
- **Fase 3 (2027-2028)**: Autonoom systeem, on-device learning, Google telemetry uit

## VRAAG
Analyseer de bovenstaande configuratie. Identificeer:
1. **Fouten** in de build setup
2. **Ontbrekende stappen** voor de agentd integratie
3. **SELinux issues** die kunnen optreden
4. **Optimalisaties** voor build tijd en image size
5. **Verbeteringen** aan de agentd daemon code

Geef een compleet, uitvoerbaar plan met:
- Exacte commando's
- Verwachte build tijd
- Mogelijke errors en fixes
- Post-build verificatie stappen
