# Stay4OS Pixel 9a Automated Smoke Test
# Run after: fastboot -w update stay4os_qpr2_flash.zip

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " STAY4OS PIXEL 9A AUTOMATED SMOKE TEST   " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$adb = "adb"

function Check-Item($testName, $command, $expectedRegex) {
    Write-Host -NoNewline "[ ] Test: $testName ... "
    $out = Invoke-Expression "$command" 2>&1 | Out-String
    if ($out -match $expectedRegex) {
        Write-Host "PASS" -ForegroundColor Green
        return $true
    } else {
        Write-Host "FAIL" -ForegroundColor Red
        Write-Host "    Got: $($out.Trim().Substring(0, [Math]::Min(100, $out.Trim().Length)))" -ForegroundColor DarkGray
        return $false
    }
}

$pass = 0; $fail = 0

# 1. ADB Detection
if (Check-Item "1. ADB Detection" "$adb get-state" "device") { $pass++ } else { $fail++ }

# 2. Boot Status
if (Check-Item "2. Boot Completed" "$adb shell getprop sys.boot_completed" "1") { $pass++ } else { $fail++ }

# 3. Android Version
if (Check-Item "3. Android 16 (Baklava)" "$adb shell getprop ro.build.version.release" "16") { $pass++ } else { $fail++ }

# 4. Device Codename
if (Check-Item "4. Device = tegu" "$adb shell getprop ro.product.device" "tegu") { $pass++ } else { $fail++ }

# 5. Stay4OS Branding
if (Check-Item "5. Stay4OS Branding" "$adb shell getprop ro.product.brand" "(Stay4S|google)") { $pass++ } else { $fail++ }

# 6. Cgroups
if (Check-Item "6. Cgroups OK" "$adb shell cat /proc/cgroups" "(cpu|memory|uid)") { $pass++ } else { $fail++ }

# 7. SurfaceFlinger
if (Check-Item "7. SurfaceFlinger Running" "$adb shell pgrep -f surfaceflinger" "\d+") { $pass++ } else { $fail++ }

# 8. WiFi HAL
if (Check-Item "8. WiFi HAL" "$adb shell dumpsys wifi | grep -i 'Wi-Fi is'" "(enabled|disabled)") { $pass++ } else { $fail++ }

# 9. Encryption
if (Check-Item "9. Storage Encrypted" "$adb shell getprop ro.crypto.state" "encrypted") { $pass++ } else { $fail++ }

# 10. Battery
if (Check-Item "10. Battery Driver" "$adb shell dumpsys battery | grep -i 'level'" "level:\s+\d+") { $pass++ } else { $fail++ }

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Results: $pass PASS, $fail FAIL" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Yellow" })
Write-Host "==========================================" -ForegroundColor Cyan
