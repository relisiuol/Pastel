#import <UIKit/UIKit.h>

@interface SBIconBadgeView : UIView
// Used to set the badge color to any UIColor
- (void)setupPastelBadge:(UIColor *)badgeTintColor;
@end

@interface SBIconImageView : UIView
- (id)contentsImage;
@end

@interface SBIconView : UIView
@end

%hook SBIconBadgeView

// Used to set the badge color to any UIColor
%new 
-(void)setupPastelBadge:(UIColor *)badgeTintColor {
  UIImageView *accessoryImage = MSHookIvar<UIImageView *>(self, "_backgroundView");
  accessoryImage.image = [accessoryImage.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

  [accessoryImage setTintColor:badgeTintColor];

  self.layer.shadowRadius = 1.5f;
  self.layer.shadowColor = [UIColor whiteColor].CGColor;
  self.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
  self.layer.shadowOpacity = 1.0f;
  self.layer.masksToBounds = NO;

  UIEdgeInsets shadowInsets = UIEdgeInsetsMake(0, 0, -1.5f, 0);
  UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:UIEdgeInsetsInsetRect(self.bounds, shadowInsets)];
  self.layer.shadowPath = shadowPath.CGPath;
}

%end

%hook SBIconView

-(void)drawRect:(CGRect)rect {
  %orig(rect);

  SBIconImageView *iconImageView = MSHookIvar<SBIconImageView *>(self, "_iconImageView");
  UIImage *image = [iconImageView contentsImage];

  CGSize size = {1, 1};
  UIGraphicsBeginImageContext(size);
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGContextSetInterpolationQuality(ctx, kCGInterpolationMedium);
  [image drawInRect:(CGRect){.size = size} blendMode:kCGBlendModeCopy alpha:1];
  uint8_t *data = (uint8_t *)CGBitmapContextGetData(ctx);

  UIColor *color = [UIColor colorWithRed:data[2] / 255.0f
                                   green:data[1] / 255.0f
                                    blue:data[0] / 255.0f
                                   alpha:1];
  UIGraphicsEndImageContext();

  UIView *_accessoryView = MSHookIvar<UIView *>(self, "_accessoryView");
  if (_accessoryView != nil && [_accessoryView isKindOfClass: %c(SBIconBadgeView)])
    [(SBIconBadgeView *)_accessoryView setupPastelBadge:color];
}

%end