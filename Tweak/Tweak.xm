#import "Pastel.h"
#import "SparkColourPickerUtils.h"
#import <Cephei/HBPreferences.h>

BOOL kEnabled;
BOOL kCustomColorEnabled;
HBPreferences *preferences;
NSMutableDictionary *iconDictionary = [[NSMutableDictionary alloc] init];

%hook SBIconBadgeView

-(void)configureForIcon:(SBApplicationIcon*)arg1 infoProvider:(SBIconView*)arg2 {
  %orig;
  SBIconImageView *iconImageView = MSHookIvar<SBIconImageView *>(arg2, "_iconImageView");
  UIImage *image = [iconImageView contentsImage];

  if(image && ![iconDictionary objectForKey:[self description]]) {
    [iconDictionary setObject:UIImagePNGRepresentation(image) forKey:[self description]];
  }
}

-(void)layoutSubviews {
  %orig;
  [self colourizeNotificationBadge];
}

%new
-(void)colourizeNotificationBadge {
  UIColor *color;

  if(!kEnabled) {
    color = [UIColor redColor];
  } else {
      if(!kCustomColorEnabled) {
        CTDColorUtils *colorUtils = [[CTDColorUtils alloc] init];
        color = [colorUtils getAverageColorFrom:[[UIImage alloc] initWithData:[iconDictionary objectForKey:[self description]]]
                                withAlpha:1.0];
      } else {
        NSString* colourString = NULL;
        NSDictionary* preferencesDictionary = [NSDictionary dictionaryWithContentsOfFile: @"/var/mobile/Library/Preferences/me.conorthedev.pastel.colorprefs.plist"];

        if(preferencesDictionary)
        {
            colourString = [preferencesDictionary objectForKey: @"kCustomColor"];
        }

        color = [SparkColourPickerUtils colourWithString: colourString withFallback: @"#ffffff"];
    }
  }

  [self setupPastelBadge:color];
}

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
  [self colourizeNotificationBadge];
}

%new
-(void)colourizeNotificationBadge {
  UIColor *color;

  if(!kEnabled) {
    color = [UIColor redColor];
  } else {
      if(!kCustomColorEnabled) {
        SBIconImageView *iconImageView = MSHookIvar<SBIconImageView *>(self, "_iconImageView");
        UIImage *image = [iconImageView contentsImage];

        CTDColorUtils *colorUtils = [[CTDColorUtils alloc] init];
        color = [colorUtils getAverageColorFrom:image
                                withAlpha:1.0];
      } else {
        NSString* colourString = NULL;
        NSDictionary* preferencesDictionary = [NSDictionary dictionaryWithContentsOfFile: @"/var/mobile/Library/Preferences/me.conorthedev.pastel.colorprefs.plist"];

        if(preferencesDictionary)
        {
            colourString = [preferencesDictionary objectForKey: @"kCustomColor"];
        }

        color = [SparkColourPickerUtils colourWithString: colourString withFallback: @"#ffffff"];
    }
  }

  UIView *_accessoryView = MSHookIvar<UIView *>(self, "_accessoryView");
  if (_accessoryView != nil && [_accessoryView isKindOfClass: %c(SBIconBadgeView)])
    [(SBIconBadgeView *)_accessoryView setupPastelBadge:color];
}

%end

void reloadPrefs() {
	NSLog(@"[Pastel] (reloadPrefs) (DEBUG) Reloading Preferences...");

	preferences = [[HBPreferences alloc] initWithIdentifier:@"me.conorthedev.pastel.prefs"];

  [preferences registerDefaults:@{
        @"kEnabled": @YES,
        @"kCustomColorEnabled": @NO
  }];

	[preferences registerBool:&kEnabled default:YES forKey:@"kEnabled"];
	[preferences registerBool:&kCustomColorEnabled default:NO forKey:@"kCustomColorEnabled"];

	NSLog(@"[Pastel] (reloadPrefs) (DEBUG) Current Enabled State: %i", kEnabled);
	NSLog(@"[Pastel] (reloadPrefs) (DEBUG) Current Custom Color Enabled State: %i", kCustomColorEnabled);
}

%ctor {
	reloadPrefs();
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, CFSTR("me.conorthedev.pastel.prefs/ReloadPrefs"), NULL, kNilOptions);
  
  %init;
}
