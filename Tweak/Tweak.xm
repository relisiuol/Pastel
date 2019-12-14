#import "Pastel.h"
#import <Cephei/HBPreferences.h>
#import "SparkColourPickerUtils.h"

BOOL kEnabled;
BOOL kCustomColorEnabled;
NSString *kCustomColor;
HBPreferences *preferences;

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

  UIColor *color;

  if(!kCustomColorEnabled) {
    SBIconImageView *iconImageView = MSHookIvar<SBIconImageView *>(self, "_iconImageView");
    UIImage *image = [iconImageView contentsImage];

    CTDColorUtils *colorUtils = [[CTDColorUtils alloc] init];
    color = [colorUtils getAverageColorFrom:image
                                withAlpha:1.0];
  } else {
    color = [SparkColourPickerUtils colourWithString: kCustomColor withFallback: @"#ffffff"];
  }

  UIView *_accessoryView = MSHookIvar<UIView *>(self, "_accessoryView");
  if (_accessoryView != nil && [_accessoryView isKindOfClass: %c(SBIconBadgeView)])
    [(SBIconBadgeView *)_accessoryView setupPastelBadge:color];
}

%end

void reloadPrefs() {
	NSLog(@"[Pastel] (DEBUG) Reloading Preferences...");

	preferences = [[HBPreferences alloc] initWithIdentifier:@"me.conorthedev.pastel.prefs"];

  [preferences registerDefaults:@{
        @"kEnabled": @YES,
        @"kCustomColorEnabled": @NO,
		    @"kCustomColor": @"#FFFFFF"
  }];

	[preferences registerBool:&kEnabled default:YES forKey:@"kEnabled"];
	[preferences registerBool:&kCustomColorEnabled default:NO forKey:@"kCustomColorEnabled"];
	[preferences registerObject:&kCustomColor default:@"#FFFFFF" forKey:@"kCustomColor"];

	NSLog(@"[Pastel] (DEBUG) Current Enabled State: %i", kEnabled);
	NSLog(@"[Pastel] (DEBUG) Current Custom Color Enabled State: %i", kCustomColorEnabled);
	NSLog(@"[Pastel] (DEBUG) Current Custom Color: %@", kCustomColor);
}

%ctor {
	reloadPrefs();
  %init;
}
