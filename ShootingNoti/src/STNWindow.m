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
        
        [UIView animateWithDuration:0.24 animations:^{
            self.constantBgView.transform = CGAffineTransformMakeScale(1.2, 1.2);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.25 animations:^{
                self.constantBgView.transform = CGAffineTransformIdentity;
            }];
        }];
        
    }
    return nil;
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        CGSize size = [UIScreen mainScreen].bounds.size;
        
        _constantBgView = [[UIView alloc] initWithFrame:CGRectMake(size.width-60, size.height-120, kConstantBgSize.width, kConstantBgSize.height)];
        _constantBgView.backgroundColor = [UIColor blackColor];
        _constantBgView.layer.cornerRadius = 10;
        _constantBgView.layer.masksToBounds = YES;
        [self addSubview:_constantBgView];
        
        _label = [[UILabel alloc] initWithFrame:CGRectMake(10, size.height-120, size.width-10-70, kConstantBgSize.height)];
        _label.backgroundColor = [UIColor blackColor];
        _label.layer.cornerRadius = 10;
        _label.layer.masksToBounds = YES;
        _label.textColor = [UIColor whiteColor];
        _label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_label];
        _label.hidden = YES;
    }
    return self;
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


@end
