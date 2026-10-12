# SUPER MASTER PROMPT: STAY4OS AOSP 16 QPR2 BUILD — GEMINI EXPERT ANALYSE

## ROL
Je bent Gemini, een expert in AOSP builds, Linux kernel development, SELinux, en embedded Android systems. Je werkt aan Stay4OS: een custom Android 16 QPR2 ROM voor de Google Pixel 9a (tegu, Tensor G4).

## MISSIE
Bouw een **100% complete, flash-klare AOSP 16 QPR2 build** met Stay4S agentd daemon, klaar voor investor demo. Geen tussenstappen, geen "als dit dan dat", alleen 100% werkende oplossing.

## HUIDIGE STATUS (KRITIEK)
- **Repo**: https://github.com/hetnieuwebeginbv-glitch/stay4os-aosp16-qpr2
- **Vorige build**: 35,229 targets, 0 errors, 2h8m (Vast.ai, 64 cores)
- **Flash zip**: 2.5GB, 21 files, MAAR zonder agentd
- **Agentd**: Gecompileerd (51K binary) maar NIET in system.img geïntegreerd
- **Probleem**: `m target-files-package` bouwt wel, maar agentd komt niet in de image

## WAT ER FOUT GAAT
1. `m stay4s_agentd` bouwt de binary, maar `m target-files-package` pakt hem niet in
2. `PRODUCT_PACKAGES += stay4s_agentd` staat in stay4os_tegu.mk, maar wordt genegeerd
3. Build output gaat naar `generic_arm64` in plaats van `tegu` (lunch werkt niet correct)
4. LineageOS dependencies (lineage_health, touch, mm) missen en veroorzaken errors

## KRITIEKE BESTANDEN

### 1. vendor/stay4s/services/Android.bp
```bp
cc_binary {
    name: "stay4s_agentd",
    srcs: ["stay4s_agentd.cpp"],
    shared_libs: ["liblog", "libcutils"],
    cflags: ["-Wall", "-Werror"],
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
#include <cutils/sockets.h>
#include <log/log.h>

#undef LOG_TAG
#define LOG_TAG "Stay4S_AgentD"

std::string get_device_health() {
    std::ifstream thermal("/sys/class/thermal/thermal_zone0/temp");
    std::string temp = "0";
    if (thermal.is_open()) {
        thermal >> temp;
        thermal.close();
        float c = std::stof(temp) / 1000.0f;
        temp = std::to_string(c) + " C";
    }
    return "{\"status\":\"healthy\",\"thermal_zone0\":\"" + temp + "\"}";
}

std::string route_intent(const std::string& input) {
    if (input.find("HEALTH") != std::string::npos) {
        return get_device_health();
    }
    return "{\"response\":\"Stay4S L2 Daemon Active.\"}";
}

int main() {
    ALOGI("Starting Stay4S L2 Hardware Agent Daemon...");
    int server_fd = android_get_control_socket("stay4s_agentd");
    if (server_fd < 0) {
        ALOGE("Failed to get control socket");
        return 1;
    }
    if (listen(server_fd, 5) < 0) {
        ALOGE("Listen failed");
        return 1;
    }
    ALOGI("Stay4S Daemon listening");
    while (true) {
        int client_fd = accept(server_fd, nullptr, nullptr);
        if (client_fd < 0) {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            continue;
        }
        char buffer[1024] = {0};
        read(client_fd, buffer, 1024);
        std::string reply = route_intent(std::string(buffer));
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
```

### 4. device/google/tegu/sepolicy/system_ext/private/stay4s_agentd.te
```te
type stay4s_agentd, domain, coredomain;
type stay4s_agentd_exec, exec_type, system_file_type, file_type;

init_daemon_domain(stay4s_agentd)
permissive stay4s_agentd;

allow stay4s_agentd sysfs_thermal:file r_file_perms;
allow stay4s_agentd sysfs_thermal:dir r_dir_perms;
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

PRODUCT_COPY_FILES += \
    device/google/tegu/init.stay4os.rc:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/init/init.stay4os.rc
```

### 6. device/google/tegu/AndroidProducts.mk
```makefile
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/aosp_tegu.mk \
    $(LOCAL_DIR)/stay4os_tegu.mk

COMMON_LUNCH_CHOICES := \
    aosp_tegu-userdebug \
    stay4os_tegu-bp4a-userdebug
```

## BUILD ENVIRONMENT
- **Server**: Vast.ai (root@ssh9.vast.ai:39578)
- **Specs**: 128 cores, 512GB RAM, 1TB disk
- **AOSP**: android-16.0.0_r4 (QPR2/Baklava)
- **Lunch**: stay4os_tegu-bp4a-userdebug
- **Build**: m target-files-package -j32

## OPLOSSINGEN DIE AL ZIJN PROBEERD
1. ✅ Android.bp correct geconfigureerd (cc_binary, system_ext_specific)
2. ✅ PRODUCT_PACKAGES += stay4s_agentd toegevoegd
3. ✅ PRODUCT_COPY_FILES voor init.stay4os.rc
4. ✅ SELinux permissive mode voor agentd
5. ✅ android_get_control_socket() voor socket
6. ❌ Build gaat naar generic_arm64 ipv tegu
7. ❌ target-files-package pakt agentd niet

## VRAAG AAN GEMINI
Analyseer waarom `m target-files-package` de agentd niet in de system.img stopt. Geef een 100% werkende oplossing met:

1. **Exacte commando's** om de build te fixen
2. **Waarom** de huidige setup faalt
3. **Hoe** te verifiëren dat agentd in de image zit
4. **Complete build script** dat gegarandeerd werkt
5. **Flash package script** dat alle benodigde images bevat

Geen conditionals, geen "als dit dan dat", alleen een compleet werkend plan.

## DEADLINE
Investor demo is morgen. De build moet VANDAAG compleet zijn.
