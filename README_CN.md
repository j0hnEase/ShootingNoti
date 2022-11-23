
# ShootingNoti :
[English](https://github.com/j0hnEase/ShootingNoti/blob/main/README.md). [Русский](). [中文](https://github.com/j0hnEase/ShootingNoti/blob/main/README_CN.md).

###  这是一个Tweak，可以在手机中显示各种很酷的通知。 ### 

***
### 包含: ### 
  
  - Airpods 连接  
  ```
  // 监听连接状态
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetLocalCenter(),
		NULL,
		airpodsNotification,
		CFSTR("BluetoothAccessoryInEarStatusNotification"),
		NULL,
		CFNotificationSuspensionBehaviorCoalesce
	);
  
  // 通知回调
  void airpodsNotification(CFNotificationCenterRef center,
              void *observer,
              CFStringRef name,
              const void *object,
              CFDictionaryRef userInfo)
{
	NSDictionary *dict = (__bridge NSDictionary *)object;
	if ([dict isKindOfClass:[NSDictionary class]]) {
		NSNumber *left = dict[@"secondaryInEarStatus"];
		NSNumber *right = dict[@"primaryInEarStatus"];
		if ([left isKindOfClass:[NSNumber class]] && [right isKindOfClass:[NSNumber class]]) {
			
			// 0入耳; 1 手中 
			if ([left intValue]==0 && [right intValue]==0) {
				
				float batteryLevel = 0;
        
				NSArray *arr = [[NSClassFromString(@"BluetoothManager") sharedInstance] connectedDevices];
				for (BluetoothDevice *device in arr) {
					if ([device supportsBatteryLevel]) { // 无效 in iOS14
						batteryLevel = [device batteryLevel];
					}
				}	
				
				// 两个耳机都在耳朵上
        
				// To do sth ...
        
			}
		}
	}

}  
  ```
  
  - 低电量警报
  ```
// 勾住 SBAlertItemsController
%hook SBAlertItemsController

- (void)activateAlertItem:(id)arg1
{
	if ([arg1 isKindOfClass:NSClassFromString(@"SBLowPowerAlertItem") ]) {

		float batteryLevel = [[UIDevice currentDevice] batteryLevel];
		
		// To do sth ..

	} else {
		%orig;
	}
}

%end
  
  ```
  
  - 电池充电通知
  ```
   // 监听通知
   CFNotificationCenterAddObserver(
		CFNotificationCenterGetLocalCenter(),
		NULL,
		chargeNotification,
		CFSTR("UIDeviceBatteryStateDidChangeNotification"),
		NULL,
		CFNotificationSuspensionBehaviorCoalesce
	);
  
  // 通知回调
  void chargeNotification(CFNotificationCenterRef center,
              void *observer,
              CFStringRef name,
              const void *object,
              CFDictionaryRef userInfo)
{
	if ([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateCharging) {
		float batteryLevel = [[UIDevice currentDevice] batteryLevel];

		// To do sth ..
		
	}
}
  
  ```
  
  - 静音按钮
  ```
// 勾住 SBRingerControl
%hook SBRingerControl

- (void)activateRingerHUDFromMuteSwitch:(int)arg1 
{
	BOOL mute = arg1==0;
	
	// To do sth ..
  
}

%end
  
  ```
  
  
  - 音乐播放
   ```
   // To be continue ...
   
   ```
  
  - 应用通知
   ```
   // To be continue ...

   ```
  
  - 来电
   ```
   // To be continue ...
   
   ```
  
  - 录音
   ```
   // To be continue ...
   
   ```
  
***
### 如何使用: ###

  - Logos 基础语言
  
  - Theos 已安装
  
  - Objective-C 基础语言



***
### Apache-2.0 license ###
[使用协议](https://github.com/j0hnEase/ShootingNoti/blob/main/LICENSE)
