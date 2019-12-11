INSTALL_TARGET_PROCESSES = SpringBoard

GO_EASY_ON_ME=1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Pastel

Pastel_FILES = Tweak.xm
Pastel_CFLAGS = -fobjc-arc -fms-extensions
Pastel_LIBRARIES += conorthedev

include $(THEOS_MAKE_PATH)/tweak.mk
