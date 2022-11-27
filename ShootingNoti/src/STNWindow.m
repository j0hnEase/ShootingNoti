#import "STNWindow.h"

#define kConstantBgSize CGSizeMake(50, 50)


@interface STNWindow ()

@property (nonatomic, strong) UIView *constantBgView;
@property (nonatomic, strong) UILabel *label;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation STNWindow


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (_constantBgView && view == _constantBgView) {
        [self p_animations];
        return view;
    }

    if (view == _permanentLabel || view == _leftBtn || view == _rightBtn) {
        return view;
    }
    return nil;
}

- (void)p_animations
{
    if (self.isAnimationing) return;
    self.isAnimationing = YES;

    if (self.tapAction) {
        self.tapAction();
    }

    [UIView animateWithDuration:0.24 animations:^{
        self.constantBgView.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 animations:^{
            self.constantBgView.transform = CGAffineTransformIdentity;
            self.isAnimationing = NO;
        }];
    }];
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
        [leftBtn addTarget:self action:@selector(leftBtnPress) forControlEvents:UIControlEventTouchUpInside];
        [_permanentLabel addSubview:leftBtn];
        leftBtn.backgroundColor = [UIColor blackColor];
        self.leftBtn = leftBtn;

        UIButton *rightBtn = [[UIButton alloc] initWithFrame:CGRectMake(_permanentLabel.frame.size.width-kConstantBgSize.width, 0, kConstantBgSize.width, kConstantBgSize.height)];
        [rightBtn addTarget:self action:@selector(rightBtnPress) forControlEvents:UIControlEventTouchUpInside];
        [_permanentLabel addSubview:rightBtn];
        rightBtn.backgroundColor = [UIColor blackColor];
        self.rightBtn = rightBtn;
    }
    return self;
}


- (void)leftBtnPress
{
    if (self.leftBtnAction) {
        self.leftBtnAction();
    }

}

- (void)rightBtnPress
{
    if (self.rightBtnAction) {
        self.rightBtnAction();
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


@end
