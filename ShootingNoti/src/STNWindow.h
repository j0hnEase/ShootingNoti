#import <UIKit/UIKit.h>


@interface STNWindow : UIWindow

/*
    type

    1: answerCall
    2: disconnectCall
    3: play next music
    4: play previous music
    5: music playOrPause
*/ 
@property (nonatomic, copy) void (^buttonAction) (int type);

@property (nonatomic, copy) void (^tapAction) (void);

@property (nonatomic, copy) BOOL (^checkLockScreenVisible) (void);

@property (nonatomic, copy) NSString * (^checkIncomingName) (void);

/// To show text
- (void)showText:(NSString *)text;

- (void)showImage:(UIImage *)image artId:(NSString*)artId;
- (void)hideImage:(BOOL)hide;

- (void)showPermanentText:(NSString *)text;
- (void)hidePermanentText:(BOOL)hide;


@end

