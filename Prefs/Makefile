ARCHS = arm64 arm64e
TARGET = iphone:clang:13.0:12.1.2

GO_EASY_ON_ME=1

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = PastelPrefs

PastelPrefs_FILES = PastelPrefsRootListController.m
PastelPrefs_INSTALL_PATH = /Library/PreferenceBundles
PastelPrefs_LIBRARIES += sparkcolourpicker
PastelPrefs_FRAMEWORKS = UIKit
PastelPrefs_PRIVATE_FRAMEWORKS = Preferences
PastelPrefs_CFLAGS = -fobjc-arc
PastelPrefs_EXTRA_FRAMEWORKS += Cephei CepheiPrefs

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PastelPrefs.plist$(ECHO_END)
