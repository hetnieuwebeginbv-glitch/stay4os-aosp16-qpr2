$(call inherit-product, device/google/tegu/aosp_tegu.mk)

PRODUCT_NAME := stay4os_tegu
PRODUCT_DEVICE := tegu
PRODUCT_BRAND := Stay4S
PRODUCT_MODEL := Stay4S Pixel 9a
PRODUCT_MANUFACTURER := Stay4S

PRODUCT_PROPERTY_OVERRIDES += \
    ro.stay4s.version=0.1.0 \
    ro.stay4s.device=tegu
