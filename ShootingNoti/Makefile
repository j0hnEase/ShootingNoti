
THEOS_DEVICE_IP = (yourip)
ARCHS = arm64
TARGET = iphone:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ShootingNoti
ShootingNoti_CFLAGS = -fobjc-arc
ShootingNoti_FILES = Tweak.xm src/*.m
ShootingNoti_FRAMEWORKS = UIKit Foundation UserNotifications 
ShootingNoti_PRIVATE_FRAMEWORKS = Sharing BatteryCenter BluetoothManager MediaRemote SpringBoard

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
