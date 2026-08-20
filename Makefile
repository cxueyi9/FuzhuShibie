export THEOS = /opt/theos
export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FloatInject

FloatInject_FILES = FloatInject.m \
    UITouch-KIFAdditions.m \
    UIEvent+KIFAdditions.m \
    UIApplication-KIFAdditions.m \
    IOHIDEvent+KIF.m

FloatInject_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unguarded-availability -Wno-unused-function -I.
FloatInject_LDFLAGS = -framework UIKit -framework Foundation -framework QuartzCore -framework IOKit -framework AudioToolbox
FloatInject_CODESIGN = NO

include $(THEOS_MAKE_PATH)/tweak.mk