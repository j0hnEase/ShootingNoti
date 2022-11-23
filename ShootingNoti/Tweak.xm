#import <SpringBoard/SpringBoard.h>
#import <UIKit/UIKit.h>
#import "src/STNWindow.h"


@interface SBAlertItemsController : NSObject
-(void)activateAlertItem:(id)arg1;
@end

@interface SBRingerControl : NSObject
- (void)activateRingerHUDFromMuteSwitch:(int)arg1 ;
@end

@interface BluetoothManager : NSObject
+(id)sharedInstance;
-(id)connectedDevices;
@end

@interface BluetoothDevice : NSObject
+(id)sharedInstance;
-(float)batteryLevel;
-(BOOL)supportsBatteryLevel;
@end

// main window
STNWindow *_myWindow;

// airpods call back
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
			

			if ([left intValue]==0 && [right intValue]==0) {
				float batteryLevel = 0;

				NSArray *arr = [[NSClassFromString(@"BluetoothManager") sharedInstance] connectedDevices];
				for (BluetoothDevice *device in arr) {

					if ([device supportsBatteryLevel]) { // no work in iOS14
						batteryLevel = [device batteryLevel];
					}
				}	
				
				[_myWindow showText:[NSString stringWithFormat:@"Airpods connected: %f%%", batteryLevel*100]];
			}
		}
	}

}

// charging
void chargeNotification(CFNotificationCenterRef center,
              void *observer,
              CFStringRef name,
              const void *object,
              CFDictionaryRef userInfo)
{
	if ([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateCharging) {
		float batteryLevel = [[UIDevice currentDevice] batteryLevel];
		[_myWindow showText:[NSString stringWithFormat:@"charing: %f%%", batteryLevel*100]];
	}
}

%hook SBRingerControl

// mute button
- (void)activateRingerHUDFromMuteSwitch:(int)arg1 
{	
	BOOL mute = arg1==0;
	[_myWindow showText:mute?@"It's Silent":@"Ringer"];
}

%end


%hook SBAlertItemsController

// low power
- (void)activateAlertItem:(id)arg1
{
	if ([arg1 isKindOfClass:NSClassFromString(@"SBLowPowerAlertItem") ]) {

		float batteryLevel = [[UIDevice currentDevice] batteryLevel];
		[_myWindow showText:[NSString stringWithFormat:@"low power: %f%%", batteryLevel*100]];

	} else {
		%orig;
	}
}

%end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
	%orig;

	// window init
	_myWindow = [[STNWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[_myWindow setWindowLevel:UIWindowLevelAlert+1]; // window level
	[_myWindow makeKeyAndVisible];	


	// Airpods
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetLocalCenter(),
		NULL,
		airpodsNotification,
		CFSTR("BluetoothAccessoryInEarStatusNotification"),
		NULL,
		CFNotificationSuspensionBehaviorCoalesce
	);

	// charging
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetLocalCenter(),
		NULL,
		chargeNotification,
		CFSTR("UIDeviceBatteryStateDidChangeNotification"),
		NULL,
		CFNotificationSuspensionBehaviorCoalesce
	);

}

%end
