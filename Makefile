ARCHS = armv7 arm64
CFLAGS = -fobjc-arc
THEOS_PACKAGE_DIR_NAME = debs
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AAAACycriptLoader
AAAACycriptLoader_FILES = Tweak.xm
AAAACycriptLoader_FRAMEWORKS = JavaScriptCore
AAAACycriptLoader_LIBRARIES = cycript

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
