#import "Pastel.h"

%hook SBIconBadgeView

// Used to set the badge color to any UIColor
%new 
-(void)setupPastelBadge:(UIColor *)badgeTintColor {
  UIImageView *accessoryImage = MSHookIvar<UIImageView *>(self, "_backgroundView");
  accessoryImage.image = [accessoryImage.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

  [accessoryImage setTintColor:badgeTintColor];
}

%end

%hook SBIconView

-(void)drawRect:(CGRect)rect {
  %orig(rect);

  SBIconImageView *iconImageView = MSHookIvar<SBIconImageView *>(self, "_iconImageView");
  UIImage *image = [iconImageView contentsImage];

  CTDColorUtils *colorUtils = [[CTDColorUtils alloc] init];
  UIColor *color = [colorUtils getAverageColorFrom:image
                                withAlpha:1.0];

  UIView *_accessoryView = MSHookIvar<UIView *>(self, "_accessoryView");
  if (_accessoryView != nil && [_accessoryView isKindOfClass: %c(SBIconBadgeView)])
    [(SBIconBadgeView *)_accessoryView setupPastelBadge:color];
}

%end