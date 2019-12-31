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

  if(image) {
    [iconDictionary setObject:UIImagePNGRepresentation(image) forKey:[NSString stringWithFormat:@"%llu", self.hash]];
  }

  [self colourizeNotificationBadge];
}

-(void)layoutSubviews {
  %orig;
  [self colourizeNotificationBadge];
}

-(void)drawRect:(CGRect)arg1 {
  %orig(arg1);
  [self colourizeNotificationBadge];
}

%new
-(void)colourizeNotificationBadge {
  UIColor *color;

  if(!kEnabled) {
    color = [UIColor systemRedColor];
  } else {
    if(!kCustomColorEnabled) {
      NSData *data = [iconDictionary objectForKey:[NSString stringWithFormat:@"%llu", self.hash]];

      if(data) {
        color = [[[CTDColorUtils alloc] init] getAverageColorFrom:[[UIImage alloc] initWithData:data] withAlpha:1.0];
      } else {
        color = [UIColor redColor];
      }
    } else {
      NSString* colourString = NULL;
      NSDictionary* preferencesDictionary = [NSDictionary dictionaryWithContentsOfFile: @"/var/mobile/Library/Preferences/me.conorthedev.pastel.colorprefs.plist"];

      if(preferencesDictionary) {
          colourString = [preferencesDictionary objectForKey: @"kCustomColor"];
      }

      color = [SparkColourPickerUtils colourWithString:colourString withFallback:@"#ffffff"];
    }
  }

  UIImageView *accessoryImage = MSHookIvar<UIImageView *>(self, "_backgroundView");
  accessoryImage.image = [accessoryImage.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

  [accessoryImage setTintColor:color];
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
