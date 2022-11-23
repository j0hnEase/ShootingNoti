# ShootingNoti : 

[English](https://github.com/j0hnEase/ShootingNoti/blob/main/README.md). [Русский]().  [中文](https://github.com/j0hnEase/ShootingNoti/blob/main/README_CN.md).
###  It's a tweak that displays all kinds of cool notifications in the phone. ### 

***
### Including: ### 
  
  - Airpods connection  
  ```
  // Monitor the airpods status
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetLocalCenter(),
		NULL,
		airpodsNotification,
		CFSTR("BluetoothAccessoryInEarStatusNotification"),
		NULL,
		CFNotificationSuspensionBehaviorCoalesce
	);
  
  // call back
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
			
			// 0in ear; 1 in hand 
			if ([left intValue]==0 && [right intValue]==0) {
				
				float batteryLevel = 0;
        
				NSArray *arr = [[NSClassFromString(@"BluetoothManager") sharedInstance] connectedDevices];
				for (BluetoothDevice *device in arr) {
					if ([device supportsBatteryLevel]) { // no work in iOS14
						batteryLevel = [device batteryLevel];
					}
				}	
				
				// two devices all in ear
        
				// To do sth ...
        
			}
		}
	}

}  
  ```
  
  - Low power alert
  ```
 // hook SBAlertItemsController
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
  
  - Battery charging notity
  ```
   // Monitor the notification
   CFNotificationCenterAddObserver(
		CFNotificationCenterGetLocalCenter(),
		NULL,
		chargeNotification,
		CFSTR("UIDeviceBatteryStateDidChangeNotification"),
		NULL,
		CFNotificationSuspensionBehaviorCoalesce
	);
  
  // call back
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
  
  - Mute button
  ```
 // hook SBRingerControl
%hook SBRingerControl

- (void)activateRingerHUDFromMuteSwitch:(int)arg1 
{
	BOOL mute = arg1==0;
	
	// To do sth ..
  
}

%end
  
  ```
  
  
  - Music play
   ```
   // To be continue ...
   
   ```
  
  - App Notification
   ```
   // To be continue ...

   ```
  
  - Incoming call
   ```
   // To be continue ...
   
   ```
  
  - Recording
   ```
   // To be continue ...
   
   ```

***
### How to use: ###

  - Logos language basics
  
  - Theos installed
  
  - Objective-C language basics
  
  

***
### Apache-2.0 license ###
[LICENSE](https://github.com/j0hnEase/ShootingNoti/blob/main/LICENSE)
  
  
  

