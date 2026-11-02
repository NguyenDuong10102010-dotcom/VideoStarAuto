TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = VideoStar

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PainuzzTool
PainuzzTool_FILES = Tweak.xm
PainuzzTool_CFLAGS = -fobjc-arc
PainuzzTool_FRAMEWORKS = UIKit QuartzCore AVFoundation Accelerate

include $(THEOS_MAKE_PATH)/tweak.mk
