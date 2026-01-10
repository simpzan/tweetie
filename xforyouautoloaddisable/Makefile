TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = xforyouautoloaddisable

xforyouautoloaddisable_FILES = Tweak.x
xforyouautoloaddisable_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk


build: 
	cp ./.theos/obj/xforyouautoloaddisable.dylib .
	install_name_tool -id @rpath/CydiaSubstrate.framework/CydiaSubstrate xforyouautoloaddisable.dylib
	install_name_tool -change /Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate @rpath/CydiaSubstrate.framework/CydiaSubstrate xforyouautoloaddisable.dylib
	ls -alh xforyouautoloaddisable.dylib
	echo "done"