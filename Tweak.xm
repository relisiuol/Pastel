#import <UIKit/UIKit.h>

@interface SBIconBadgeView : UIView
// Used to set the badge color to any UIColor
-(void)setBadgeColor:(UIColor *)color;
@end 

@interface SBIconImageView : UIView
-(id)contentsImage;
@end

@interface SBIconView : UIView
@end

%hook SBIconBadgeView

%new
-(void)setBadgeColor:(UIColor *)color {
	UIImageView *accessoryImage = MSHookIvar<UIImageView*>(self, "_backgroundView");
	accessoryImage.image = [accessoryImage.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[accessoryImage setTintColor:color];
}

%end

%hook SBIconView

-(void)drawRect:(CGRect)rect {
	%orig(rect);

	SBIconImageView *iconImageView = MSHookIvar<SBIconImageView*>(self, "_iconImageView");
	UIImage *image = [iconImageView contentsImage];

	CGSize size = {1, 1};
    UIGraphicsBeginImageContext(size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(ctx, kCGInterpolationMedium);
    [image drawInRect:(CGRect){.size = size} blendMode:kCGBlendModeCopy alpha:1];
    uint8_t *data = (uint8_t *) CGBitmapContextGetData(ctx);

    UIColor *color = [UIColor colorWithRed:data[2] / 255.0f
                                     green:data[1] / 255.0f
                                      blue:data[0] / 255.0f
                                     alpha:1];
    UIGraphicsEndImageContext();

	UIView *_accessoryView = MSHookIvar<UIView *>(self, "_accessoryView");
	if ( _accessoryView != nil && [_accessoryView isKindOfClass:%c(SBIconBadgeView)])
		[(SBIconBadgeView *)_accessoryView setBadgeColor:color];
}

%end