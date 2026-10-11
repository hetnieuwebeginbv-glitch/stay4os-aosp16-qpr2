#!/bin/bash
cd /workspace
source build/envsetup.sh
lunch stay4os_tegu-bp4a-userdebug
m target-files-package -j64 > /workspace/build.log 2>&1
echo BUILD_DONE
