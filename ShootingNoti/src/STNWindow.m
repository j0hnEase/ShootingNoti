#import "STNWindow.h"
#import <CallKit/CXCallObserver.h>
#import <CallKit/CXCall.h>
#import <AudioToolbox/AudioToolbox.h>

#define kConstantBgSize CGSizeMake(50, 50)


@interface STNWindow ()  <CXCallObserverDelegate>

@property (nonatomic, assign) BOOL isAnimationing;
@property (nonatomic, strong) UIImageView *constantBgView;
@property (nonatomic, strong) UIView *circleView;

@property (nonatomic, copy) NSString *artId;

@property (nonatomic, strong) UILabel *label;

@property (nonatomic, strong) UILabel *permanentLabel;
@property (nonatomic, strong) UIButton *leftBtn;
@property (nonatomic, strong) UIButton *rightBtn;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSTimer *timer2;
@property (nonatomic, assign) int callTime;

@property (nonatomic, assign) BOOL isIncoming;
@property (nonatomic,strong) CXCallObserver *callObserber;

@end

@implementation STNWindow

- (void)callObserver:(CXCallObserver *)callObserver callChanged:(CXCall *)call {
    
    if (!call.outgoing && !call.onHold && !call.hasConnected && !call.hasEnded) {
        // 来电
        self.isIncoming = YES;
        if (self.checkLockScreenVisible) {
            BOOL visible = self.checkLockScreenVisible();
            if (!visible) {
                _callTime = 0;
                [_timer2 invalidate];
                _timer2 = [NSTimer timerWithTimeInterval:1.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
                    self.callTime ++;
                    [self showPermanentText:[NSString stringWithFormat:@"%d", self.callTime]];
                    [self hidePermanentText:NO];
                }];
                [[NSRunLoop currentRunLoop] addTimer:_timer2 forMode:NSRunLoopCommonModes];

                // if (self.checkIncomingName) {
                //     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //         NSString *name = self.checkIncomingName();
                //         [self showPermanentText:name];
                //         [self hidePermanentText:NO];
                //     });
                // }   
            }
        }
    } else if (!call.outgoing && !call.onHold && !call.hasConnected && call.hasEnded) {
        // 来电-挂掉(未接通)
        self.isIncoming = NO;
        [self hidePermanentText:YES];
        _callTime = 0;
        [_timer2 invalidate];
    } else if (!call.outgoing && !call.onHold && call.hasConnected && !call.hasEnded) {
        // 来电-接通
        self.isIncoming = NO;
        [self hidePermanentText:YES];
        _callTime = 0;
        [_timer2 invalidate];
    } else if (!call.outgoing && !call.onHold && call.hasConnected && call.hasEnded) {
        // 来电-接通-挂掉
        self.isIncoming = NO;
        [self hidePermanentText:YES];
        _callTime = 0;
        [_timer2 invalidate];
    } else if (call.outgoing && !call.onHold && !call.hasConnected && !call.hasEnded) {
        // 拨出

    } else if (call.outgoing && !call.onHold && !call.hasConnected && call.hasEnded) {
        // 拨出-挂掉(未接通)

    } else if (call.outgoing && !call.onHold && call.hasConnected && !call.hasEnded) {
        // 拨出-接通

    } else if (call.outgoing && !call.onHold && call.hasConnected && call.hasEnded) {
        // 拨出-接通-挂掉

    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (_constantBgView && view == _constantBgView) {
        return view;
    }

    if (view == _permanentLabel || view == _leftBtn || view == _rightBtn) {
        return view;
    }
    return nil;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        CGSize size = [UIScreen mainScreen].bounds.size;
        
        _constantBgView = [[UIImageView alloc] initWithFrame:CGRectMake(size.width-60, size.height-150, kConstantBgSize.width, kConstantBgSize.height)];
        _constantBgView.backgroundColor = [UIColor blackColor];
        _constantBgView.layer.cornerRadius = 10;
        _constantBgView.layer.masksToBounds = YES;
        _constantBgView.userInteractionEnabled = YES;
        _constantBgView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_constantBgView];

        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap)];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [_constantBgView addGestureRecognizer:singleTap];
        [_constantBgView addGestureRecognizer:longPress];


        _circleView = [[UIView alloc] initWithFrame:CGRectMake(23, 0, 4, 4)];
        _circleView.backgroundColor = [UIColor whiteColor];
        _circleView.layer.cornerRadius = 2;
        _circleView.layer.masksToBounds = YES;
        [_constantBgView addSubview:_circleView];
        _circleView.hidden = YES;

        _label = [[UILabel alloc] initWithFrame:CGRectMake(10, size.height-150, size.width-10-70, kConstantBgSize.height)];
        _label.backgroundColor = [UIColor blackColor];
        _label.layer.cornerRadius = 10;
        _label.layer.masksToBounds = YES;
        _label.textColor = [UIColor whiteColor];
        _label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_label];
        _label.hidden = YES;

        _permanentLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, size.height-150+kConstantBgSize.height+2, size.width-20, kConstantBgSize.height)];
        _permanentLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        _permanentLabel.layer.cornerRadius = 10;
        _permanentLabel.layer.masksToBounds = YES;
        _permanentLabel.textColor = [UIColor whiteColor];
        _permanentLabel.textAlignment = NSTextAlignmentCenter;
        _permanentLabel.userInteractionEnabled = YES;
        [self addSubview:_permanentLabel];
        _permanentLabel.hidden = YES;

        UIButton *leftBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kConstantBgSize.width, kConstantBgSize.height)];
        [leftBtn setImage:[UIImage imageWithContentsOfFile:@"icon_laught.png"] forState:UIControlStateNormal];
        [leftBtn addTarget:self action:@selector(leftBtnPress) forControlEvents:UIControlEventTouchUpInside];
        [_permanentLabel addSubview:leftBtn];
        leftBtn.backgroundColor = [UIColor blackColor];
        self.leftBtn = leftBtn;

        UIButton *rightBtn = [[UIButton alloc] initWithFrame:CGRectMake(_permanentLabel.frame.size.width-kConstantBgSize.width, 0, kConstantBgSize.width, kConstantBgSize.height)];
        [rightBtn setImage:[UIImage imageWithContentsOfFile:@"icon_laught.png"] forState:UIControlStateNormal];
        [rightBtn addTarget:self action:@selector(rightBtnPress) forControlEvents:UIControlEventTouchUpInside];
        [_permanentLabel addSubview:rightBtn];
        rightBtn.backgroundColor = [UIColor blackColor];
        self.rightBtn = rightBtn;

        self.callObserber = [[CXCallObserver alloc] init];
        [self.callObserber setDelegate:self queue:dispatch_get_main_queue()];
    }
    return self;
}

- (void)p_animations
{
    if (self.isAnimationing) return;
    self.isAnimationing = YES;
    AudioServicesPlaySystemSound(1519);

    [UIView animateWithDuration:0.24 animations:^{
        self.constantBgView.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 animations:^{
            self.constantBgView.transform = CGAffineTransformIdentity;
            self.isAnimationing = NO;
        }];
    }];
}

- (void)singleTap
{
    [self p_animations];

    if (self.tapAction) {
        self.tapAction();
    }

}

- (void)longPress:(UILongPressGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateBegan){
        [self p_animations];



    }
}

- (void)leftBtnPress
{
    if (self.buttonAction) {
        if (self.isIncoming) {
            self.buttonAction(1);
        } else {
            self.buttonAction(5);
        }
    }
}

- (void)rightBtnPress
{
    if (self.buttonAction) {
        if (self.isIncoming) {
            self.buttonAction(2);
        } else {
            self.buttonAction(3);
        }
    }
}

//MARK: -- -- --

/// To show text
- (void)showText:(NSString *)text
{   
    [UIView animateWithDuration:0.5 animations:^{
        self.label.hidden = NO;
        self.label.text = text;
    }];
    
    [_timer invalidate];
    _timer = [NSTimer timerWithTimeInterval:2.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [UIView animateWithDuration:0.5 animations:^{
            self.label.hidden = YES;
            self.label.text = @"";
        }];
    }];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)showImage:(UIImage *)image artId:(NSString*)artId
{
    if ([image isKindOfClass:[UIImage class]]) {
        if (_constantBgView.image != image && ![artId isEqualToString:self.artId]) {
            self.artId = artId;
            _constantBgView.image = image;
        }
    }
}

- (void)hideImage:(BOOL)hide
{
    if (hide) {
        self.artId = @"";
        _constantBgView.image = nil;
    }   
}

- (void)showPermanentText:(NSString *)text
{
    if (text.length) {
        _permanentLabel.text = text;
    }
}

- (void)hidePermanentText:(BOOL)hide
{
    _permanentLabel.hidden = hide;
}

- (void)showCircleView:(BOOL)show
{
    _circleView.hidden = !show;
}

@end
