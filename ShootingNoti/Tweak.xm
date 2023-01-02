#import <SpringBoard/SpringBoard.h>
#import <UIKit/UIKit.h>
#import "src/STNWindow.h"
#import <MediaRemote/MediaRemote.h>
#import <AudioToolbox/AudioToolbox.h>
#import <notify.h>

// main window
STNWindow *_myWindow;

NSString * stringWithKey(NSString *key)
{
	NSBundle *tweakBundle = [NSBundle bundleWithPath:@"/Library/Application Support/Local.bundle"];
    NSString *value = [tweakBundle localizedStringForKey:key value:@"" table:nil];
    return value;
} 


// --- --- --- --- --- airpods --- --- --- --- ---

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

// --- --- --- --- --- charging --- --- --- --- ---

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


// --- --- --- --- --- music --- --- --- --- ---

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

// --- --- --- --- ---  mute  --- --- --- --- --- 

@interface SBRingerControl : NSObject
- (void)activateRingerHUDFromMuteSwitch:(int)arg1 ;
@end

%hook SBRingerControl

// mute button
- (void)activateRingerHUDFromMuteSwitch:(int)arg1 
{	
	BOOL mute = arg1==0;
	if (mute) {
		AudioServicesPlaySystemSound(1521);
	}
	[_myWindow showText:mute? stringWithKey(@"Silent"):stringWithKey(@"Ringer")];
}

%end

// --- --- --- --- ---  low power  --- --- --- --- --- 

@interface SBAlertItemsController : NSObject
-(void)activateAlertItem:(id)arg1;
@end

%hook SBAlertItemsController


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

// --- --- --- --- --- Incoming call --- --- --- --- ---

@interface TUCall
-(NSString *)displayName;
@end

@interface TUCallCenter : NSObject
+(id)sharedInstance;

-(TUCall *)incomingCall;
-(void)answerCall:(id)arg1 ;
-(void)disconnectCall:(id)arg1;
@end


@interface SBSceneHandle : NSObject
@property (nonatomic,copy,readonly) NSString * sceneIdentifier; 
@end

@interface SBDeviceApplicationSceneView : UIView
@end

%hook SBDeviceApplicationSceneView

-(void)layoutSubviews
{
	%orig;
  	id sceneHandle = [self performSelector:@selector(sceneHandle)];
  	NSString *sceneID = [sceneHandle performSelector:@selector(sceneIdentifier)];
	if (sceneID.length) {
		if ([sceneID containsString:@"com.apple.InCallService"]) {
			[self performSelector:@selector(p_for:) withObject:self];
		}
	} 
}

%new
- (void)p_for:(UIView *)view
{
	if ([view isKindOfClass:NSClassFromString(@"_UIScenePresentationView")]) {
		if (view.frame.size.height <= 150) {
			view.hidden = YES;
		} else {
			view.hidden = NO;
		}
	}

	if (view.subviews.count) {
		for (UIView *v in view.subviews) {
			[self performSelector:@selector(p_for:) withObject:v];
		}
	}
}

%end

@interface SBInCallBannerSceneBackgroundView : UIView
-(void)layoutSubviews;
@end

%hook SBInCallBannerSceneBackgroundView
-(void)layoutSubviews
{
	%orig;
    self.hidden = YES;
}
%end

@interface SBLockScreenManager : NSObject
+(id)sharedInstance;
-(BOOL)isLockScreenVisible;
-(void)_authenticationStateChanged:(id)arg1;
@end

// --- --- --- --- --- Lock State --- --- --- --- ---

UIView *_fakeCircleView;
 
%hook SBLockScreenManager
- (void)_authenticationStateChanged:(id)arg1 
{
	if ([arg1 isKindOfClass:NSClassFromString(@"NSConcreteNotification")]) {
        id userInfo = [arg1 valueForKey:@"userInfo"];
        if ([userInfo isKindOfClass:[NSDictionary class]]) {
			id t = userInfo[@"SBFUserAuthenticationStateWasAuthenticatedKey"];
			if ([t isEqual:@(0)]) {
				// unlock
				_fakeCircleView.hidden = YES;
				[_myWindow showText:@"unlock"];

			} else {
				// lock
				_fakeCircleView.hidden = NO;
				[_myWindow showText:@"lock"];
			}
        }
    }

	%orig;
}

%end

@interface CSCoverSheetViewController : UIViewController

@end
%hook CSCoverSheetViewController

- (void)loadView
{
	%orig;
    
	if (!_fakeCircleView) {
		CGSize size = [UIScreen mainScreen].bounds.size;
        
        UIView *circleView = [[UIView alloc] initWithFrame:CGRectMake(size.width-61, size.height-150, 50, 50)];
		circleView.backgroundColor = [UIColor yellowColor];
		circleView.layer.cornerRadius = 4;
		circleView.layer.masksToBounds = YES;
		[self.view addSubview:circleView];
		_fakeCircleView = circleView;
	}
}
%end

// --- --- --- --- --- Camera Using --- --- --- --- ---

// camera using
void closeCameraNotification(CFNotificationCenterRef center,
              void *observer,
              CFStringRef name,
              const void *object,
              CFDictionaryRef userInfo)
{
	[_myWindow showCircleView:NO];
}
void openCameraNotification(CFNotificationCenterRef center,
              void *observer,
              CFStringRef name,
              const void *object,
              CFDictionaryRef userInfo)
{
	[_myWindow showCircleView:YES];
}

%hook AVCaptureSession

-(void)startRunning {
	// open camera
	notify_post("com.test.open.camera");
	%orig;
}

-(void)stopRunning {
	// close camera
	notify_post("com.test.close.camera");
	%orig;
}

-(void)_setInterrupted:(BOOL)arg1 withReason:(int)arg2 
{
	if (arg1) {
		// close camera
		notify_post("com.test.close.camera");
	} else 
	{
		notify_post("com.test.open.camera");
	}
	%orig;
}

%end

@interface RCAnalyticsUtilities : NSObject

+(void)sendDidCaptureNewRecording;
+(void)sendNewRecordingDuration:(double)arg1;
@end
%hook RCAnalyticsUtilities

+(void)sendDidCaptureNewRecording
{
	// start record
	notify_post("com.test.open.camera");
	%orig;
}

+(void)sendNewRecordingDuration:(double)arg1 
{
	// end record
	notify_post("com.test.close.camera");
	%orig;
}

%end

@interface SBMainSwitcherViewController : NSObject
-(void)_applicationDidExit:(id)arg1 ;
@end

%hook SBMainSwitcherViewController
-(void)_applicationDidExit:(id)arg1 
{
    if ([arg1 isKindOfClass:NSClassFromString(@"NSConcreteNotification")]) {
        id object = [arg1 valueForKey:@"object"];
        if ([object isKindOfClass:NSClassFromString(@"SBApplication")]) {
            if ([object respondsToSelector:@selector(bundleIdentifier)]) {
                NSString *str = [object performSelector:@selector(bundleIdentifier)];
                if (str.length) {
                    if ([str isEqualToString:@"com.apple.VoiceMemos"] || [str isEqualToString:@"com.apple.camera"]) {
						// kill a app
						notify_post("com.test.close.camera");
                    }
                }
            }
        }
    }

    %orig;
}
%end

// --- --- --- --- --- SpringBoard --- --- --- --- ---

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
	%orig;

	// window init
	_myWindow = [[STNWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[_myWindow setWindowLevel:UIWindowLevelAlert+1]; // window level
	[_myWindow makeKeyAndVisible];	
	_myWindow.tapAction = ^{
		SBApplication *nowPlayingApp = [[NSClassFromString(@"SBMediaController") sharedInstance] nowPlayingApplication];
		if (nowPlayingApp) {
			[[NSClassFromString(@"SBUIController") sharedInstanceIfExists] _activateApplicationFromAccessibility:nowPlayingApp];
		}
	};
	
	/*
		type
		1: answerCall
		2: disconnectCall
		3: play next music
		4: play previous music
		5: music playOrPause
	*/ 
	_myWindow.buttonAction = ^(int type) {
		switch (type) {
			case 1:
			{
				id sh = [NSClassFromString(@"TUCallCenter") sharedInstance];
      			id call = [sh performSelector:@selector(incomingCall)];
      			if (sh && call) {
					[sh performSelector:@selector(answerCall:) withObject:call]; 
				}
			}
            	break;
			case 2:
			{
				id sh = [NSClassFromString(@"TUCallCenter") sharedInstance];
      			id call = [sh performSelector:@selector(incomingCall)];
      			if (sh && call) {
					[sh performSelector:@selector(disconnectCall:) withObject:call]; 
				}
			}
            	break;
			case 3:
			{
				MRMediaRemoteSendCommand(kMRPreviousTrack, nil);
			}
            	break;
			case 4:
			{
				MRMediaRemoteSendCommand(kMRNextTrack, nil);
			}
            	break;
			case 5:
			{
				MRMediaRemoteSendCommand(kMRTogglePlayPause, nil);
			}
            	break;
            
        	default:
            	break;
    	}
	};
	_myWindow.checkIncomingName = ^{
		id sh = [NSClassFromString(@"TUCallCenter") sharedInstance];
      	id call = [sh performSelector:@selector(incomingCall)];
      	if (sh && call) {
        	NSString *s = [call performSelector:@selector(displayName)]; 
			return s;
      	}
		return @"";
	};
	_myWindow.checkLockScreenVisible = ^{
		id sh = [NSClassFromString(@"SBLockScreenManager") sharedInstance];
		if (sh) {
			BOOL v = [sh performSelector:@selector(isLockScreenVisible)];
			return v;
		} else {
			return YES;
		}
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

	// Camera Using
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		openCameraNotification,
		CFSTR("com.test.open.camera"),
		NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately
	);
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		closeCameraNotification,
		CFSTR("com.test.close.camera"),
		NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately
	);
}

%end
