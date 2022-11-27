#import <UIKit/UIKit.h>


@interface STNWindow : UIWindow

@property (nonatomic, copy) void (^tapAction) (void);
@property (nonatomic, copy) void (^leftBtnAction) (void);
@property (nonatomic, copy) void (^rightBtnAction) (void);

/// To show text
- (void)showText:(NSString *)text;

- (void)showImage:(UIImage *)image artId:(NSString*)artId;
- (void)hideImage:(BOOL)hide;

- (void)showPermanentText:(NSString *)text;
- (void)hidePermanentText:(BOOL)hide;


@end

