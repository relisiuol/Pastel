ARCHS = arm64 arm64e
TARGET = iphone:clang:13.0:11.2

INSTALL_TARGET_PROCESSES = SpringBoard
GO_EASY_ON_ME=1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Pastel

$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -fms-extensions
$(TWEAK_NAME)_LIBRARIES += conorthedev sparkcolourpicker
$(TWEAK_NAME)_EXTRA_FRAMEWORKS += Cephei

include $(THEOS_MAKE_PATH)/tweak.mk
