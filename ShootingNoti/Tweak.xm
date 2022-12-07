#import <SpringBoard/SpringBoard.h>
#import <UIKit/UIKit.h>
#import "src/STNWindow.h"
#import <MediaRemote/MediaRemote.h>

// main window
STNWindow *_myWindow;

NSString * stringWithKey(NSString *key)
{
	NSBundle *tweakBundle = [NSBundle bundleWithPath:@"/Library/Application Support/Local.bundle"];
    NSString *value = [tweakBundle localizedStringForKey:key value:@"" table:nil];
    return value;
} 

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
				
				[_myWindow showText:[NSString stringWithFormat:@"%@: %f%%", stringWithKey(@"Airpods connected"), batteryLevel*100]];
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
		[_myWindow showText:[NSString stringWithFormat:@"%@: %f%%", stringWithKey(@"Charing"), batteryLevel*100]];
	}
}


// music

@interface SBMediaController : NSObject
+ (id)sharedInstance;
- (id)nowPlayingApplication;
-(BOOL)_sendMediaCommand:(unsigned)arg1 options:(id)arg2;
@end

@interface SBUIController : NSObject
+ (id)sharedInstanceIfExists;
- (void)_activateApplicationFromAccessibility:(id)arg;
@end

typedef void (^MRMediaRemoteGetNowPlayingInfoCompletion)(CFDictionaryRef information);
typedef void (^MRMediaRemoteGetNowPlayingApplicationPIDCompletion)(int PID);
typedef void (^MRMediaRemoteGetNowPlayingApplicationIsPlayingCompletion)(Boolean isPlaying);

void MRMediaRemoteGetNowPlayingApplicationPID(dispatch_queue_t queue, MRMediaRemoteGetNowPlayingApplicationPIDCompletion completion);
void MRMediaRemoteGetNowPlayingInfo(dispatch_queue_t queue, MRMediaRemoteGetNowPlayingInfoCompletion completion);
void MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_queue_t queue, MRMediaRemoteGetNowPlayingApplicationIsPlayingCompletion completion);

Boolean MRMediaRemoteSendCommand(MRCommand command, id userInfo);

// music noti
void musicNotification(CFNotificationCenterRef center,
              void *observer,
              CFStringRef name,
              const void *object,
              CFDictionaryRef userInfo)
{
	// NSString *nameStr = (__bridge NSString *)name;
	// NSDictionary *dict = (__bridge NSDictionary *)object;
	MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {
		NSDictionary *dict = (__bridge NSDictionary *)information;
        if ([dict isKindOfClass:[NSDictionary class]]) {
            NSData *imageData = dict[@"kMRMediaRemoteNowPlayingInfoArtworkData"];
			NSString *artId = dict[@"kMRMediaRemoteNowPlayingInfoArtworkIdentifier"];
            UIImage *image = [UIImage imageWithData:imageData];  
            [_myWindow showImage:image artId:artId];

			// NSNumber *duration = dict[@"kMRMediaRemoteNowPlayingInfoDuration"];
		 	NSString *title = dict[@"kMRMediaRemoteNowPlayingInfoTitle"];
			// NSNumber *identifier =  dict[@"kMRMediaRemoteNowPlayingInfoContentItemIdentifier"];
			// NSNumber *progressTime = dict[@"kMRMediaRemoteNowPlayingInfoElapsedTime"];

			[_myWindow showPermanentText:title];
        }
	});

	MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_get_main_queue(), ^(Boolean isPlaying) {
		[_myWindow hideImage:!isPlaying];
		[_myWindow hidePermanentText:!isPlaying];
	});

}

%hook SBRingerControl

// mute button
- (void)activateRingerHUDFromMuteSwitch:(int)arg1 
{	
	BOOL mute = arg1==0;
	[_myWindow showText:mute? stringWithKey(@"Silent"):stringWithKey(@"Ringer")];
}

%end


%hook SBAlertItemsController

// low power
- (void)activateAlertItem:(id)arg1
{
	if ([arg1 isKindOfClass:NSClassFromString(@"SBLowPowerAlertItem") ]) {

		float batteryLevel = [[UIDevice currentDevice] batteryLevel];
		[_myWindow showText:[NSString stringWithFormat:@"%@: %f%%", stringWithKey(@"low power"), batteryLevel*100]];

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
	_myWindow.tapAction = ^{
		SBApplication *nowPlayingApp = [[NSClassFromString(@"SBMediaController") sharedInstance] nowPlayingApplication];
		[[NSClassFromString(@"SBUIController") sharedInstanceIfExists] _activateApplicationFromAccessibility:nowPlayingApp];
	};
	_myWindow.leftBtnAction = ^{
		MRMediaRemoteSendCommand(kMRTogglePlayPause, nil);

	};
	_myWindow.rightBtnAction = ^{
		// kMRPreviousTrack
		MRMediaRemoteSendCommand(kMRNextTrack, nil);
	};

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
	
	// Music
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetLocalCenter(),
		NULL,
		musicNotification,
		CFSTR("kMRMediaRemoteNowPlayingInfoDidChangeNotification"),
		NULL,
		CFNotificationSuspensionBehaviorCoalesce
	);
}

%end
