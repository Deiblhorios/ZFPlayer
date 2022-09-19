//
//  ZFLandscapeRotationManager_iOS16.m
//  ZFPlayer
//
//  Created by renzifeng on 2022/9/16.
//

#import "ZFLandscapeRotationManager_iOS16.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000

@implementation ZFLandscapeRotationManager_iOS16
@synthesize landscapeViewController = _landscapeViewController;

- (ZFLandscapeViewController *)landscapeViewController {
    if (!_landscapeViewController) {
        _landscapeViewController = [[ZFLandscapeViewController alloc] init];
    }
    return _landscapeViewController;
}

- (void)setNeedsUpdateOfSupportedInterfaceOrientations {
    if (@available(iOS 16.0, *)) {
        [UIApplication.sharedApplication.keyWindow.rootViewController setNeedsUpdateOfSupportedInterfaceOrientations];
        [self.window.rootViewController setNeedsUpdateOfSupportedInterfaceOrientations];
    }
}

- (void)interfaceOrientation:(UIInterfaceOrientation)orientation completion:(void(^ __nullable)(void))completion {
    [super interfaceOrientation:orientation completion:completion];
    UIInterfaceOrientation fromOrientation = [self getCurrentOrientation];
    UIInterfaceOrientation toOrientation = orientation;
    
    UIWindow *sourceWindow = self.containerView.window;
    CGRect sourceFrame = [self.containerView convertRect:self.containerView.bounds toView:sourceWindow];
    CGRect screenBounds = UIScreen.mainScreen.bounds;
    CGFloat maxSize = MAX(screenBounds.size.width, screenBounds.size.height);
    CGFloat minSize = MIN(screenBounds.size.width, screenBounds.size.height);
  
    self.contentView.autoresizingMask = UIViewAutoresizingNone;
    if (fromOrientation == UIInterfaceOrientationPortrait) {
        self.contentView.frame = sourceFrame;
        [sourceWindow addSubview:self.contentView];
        [self.contentView layoutIfNeeded];
        if (!self.window.isKeyWindow) {
            self.window.hidden = NO;
            [self.window makeKeyAndVisible];
        }
    } else if (toOrientation == UIInterfaceOrientationPortrait) {
        self.contentView.bounds = CGRectMake(0, 0, maxSize, minSize);
        self.contentView.center = CGPointMake(minSize * 0.5, maxSize * 0.5);
        self.contentView.transform = [self getRotationTransform:fromOrientation];
        [sourceWindow addSubview:self.contentView];
        [sourceWindow makeKeyAndVisible];
        [self.contentView layoutIfNeeded];
        self.window.hidden = YES;
    }
    [self setNeedsUpdateOfSupportedInterfaceOrientations];

    CGRect rotationBounds = CGRectZero;
    CGPoint rotationCenter = CGPointZero;
    
    if (UIInterfaceOrientationIsLandscape(toOrientation)) {
        rotationBounds = CGRectMake(0, 0, maxSize, minSize);
        rotationCenter = fromOrientation == UIInterfaceOrientationPortrait ? CGPointMake(minSize * 0.5,  maxSize * 0.5): CGPointMake(maxSize * 0.5, minSize * 0.5);
    }
    
    // transform
    CGAffineTransform rotationTransform = CGAffineTransformIdentity;
    if (fromOrientation == UIInterfaceOrientationPortrait) {
        rotationTransform = [self getRotationTransform:toOrientation];
    }
    
    self.currentOrientation = toOrientation;
    if (self.orientationWillChange) self.orientationWillChange(toOrientation);
    if (self.disableAnimations) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
    }
    [UIView animateWithDuration:0.3 animations:^{
        if (toOrientation == UIInterfaceOrientationPortrait) {
            [self.contentView setTransform:rotationTransform];
            self.contentView.frame = sourceFrame;
        } else {
            [self.contentView setTransform:rotationTransform];
            [self.contentView setBounds:rotationBounds];
            [self.contentView setCenter:rotationCenter];
        }
        [self.contentView layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (self.disableAnimations) {
            [CATransaction commit];
        }
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        if (toOrientation == UIInterfaceOrientationPortrait) {
            [self.containerView addSubview:self.contentView];
            self.contentView.frame = self.containerView.bounds;
        } else {
            [self setNeedsUpdateOfSupportedInterfaceOrientations];
            self.contentView.transform = CGAffineTransformIdentity;
            [self.landscapeViewController.view addSubview:self.contentView];
            self.contentView.frame = self.window.bounds;
            [self.contentView layoutIfNeeded];
        }
        if (self.orientationDidChanged) self.orientationDidChanged(toOrientation);
        if (completion) completion();
    }];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window {
    if (window == self.window) {
        return 1 << self.currentOrientation;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (CGAffineTransform)getRotationTransform:(UIInterfaceOrientation)orientation {
    CGAffineTransform rotationTransform = CGAffineTransformIdentity;
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        rotationTransform = CGAffineTransformMakeRotation(-M_PI_2);
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        rotationTransform = CGAffineTransformMakeRotation(M_PI_2);
    }
    return rotationTransform;
}

@end
#endif