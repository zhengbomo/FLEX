THEOS_DEVICE_IP = 10.10.10.3
THEOS_DEVICE_PORT = 22

ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FLEXLoader
FLEXLoader_FILES = Tweak.xm

FLEXLoader_FRAMEWORKS = Foundation UIKit CoreGraphics QuartzCore ImageIO WebKit Security SceneKit 
FLEXLoader_LDFLAGS = -lz -lsqlite3 

include $(THEOS_MAKE_PATH)/tweak.mk

before-package::
	@echo "run FLEX build script..."
	./pack.sh

after-install::
	install.exec "killall -9 SpringBoard"
