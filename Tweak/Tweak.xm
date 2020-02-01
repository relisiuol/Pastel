#import "Pastel.h"
#import "SparkColourPickerUtils.h"
#import <Cephei/HBPreferences.h>

BOOL kEnabled;
BOOL kCustomColorEnabled;
BOOL kCustomTextColorEnabled;

HBPreferences *preferences;
NSMutableDictionary *colourCache = [[NSMutableDictionary alloc] init];
NSDictionary* colorPreferencesDictionary = [NSDictionary dictionaryWithContentsOfFile: @"/var/mobile/Library/Preferences/me.conorthedev.pastel.colorprefs.plist"];

%hook SBIconBadgeView

-(void)configureForIcon:(SBApplicationIcon*)arg1 infoProvider:(SBIconView*)arg2 {
  %orig;

  if([arg2 isKindOfClass:%c(SBFolderIconView)]) {
    return;
  } else {
    // Get the icon from the image view
    SBIconImageView *iconImageView = MSHookIvar<SBIconImageView *>(arg2, "_iconImageView");
    UIImage *image = [iconImageView contentsImage];

    if(image) {
      // Put the average colour in the colour dictionary
      [colourCache setObject:[NSKeyedArchiver archivedDataWithRootObject:[[[CTDColorUtils alloc] init] getAverageColorFrom:image withAlpha:1.0] requiringSecureCoding:NO error:nil] forKey:[NSString stringWithFormat:@"%llu", self.hash]];
    }
  }

  // Add our colour to the badge
  [self colourizeNotificationBadge];
}

-(void)layoutSubviews {
  %orig;
  // Add our colour to the badge
  [self colourizeNotificationBadge];
}

/*-(void)drawRect:(CGRect)arg1 {
  %orig(arg1);
  [self colourizeNotificationBadge];
}*/

%new
-(void)colourizeNotificationBadge {
  // Initial Varaibles
  UIColor *color;
  NSString* colourString = NULL;
  NSString* textColourString = NULL;

  UIColor *textColor = [UIColor whiteColor];

  if(!kEnabled) {
    // If the tweak is disabled, use the system red colour as the colour
    color = [UIColor systemRedColor];
  } else {
    // Load preferences
    if(colorPreferencesDictionary) {
      colourString = [colorPreferencesDictionary objectForKey:@"kCustomColor"];
      textColourString = [colorPreferencesDictionary objectForKey:@"kCustomTextColor"];
    }

    if(!kCustomColorEnabled) {
      // Get the uicolor from the hash
      NSData *colorData = [colourCache objectForKey:[NSString stringWithFormat:@"%llu", self.hash]];

      if(colorData) {
        color = [NSKeyedUnarchiver unarchivedObjectOfClass:[UIColor class] fromData:colorData error:nil];
        if(!color) {
          // For some reason the colour wasn't set yet, default to the system colour
          color = [UIColor systemRedColor];
        }
      } else {
        // For some reason the colour wasn't set yet, default to the system colour
        color = [UIColor systemRedColor];
      }
    } else {
      // Use the colour specified by the user
      color = [SparkColourPickerUtils colourWithString:colourString withFallback:@"#ffffff"];
    }
  }

  if(kEnabled) {
    if(!kCustomTextColorEnabled) {
      // 'Dynamic' colours
      if(color == [UIColor blackColor]) {
        textColor = [UIColor whiteColor];
      }
    } else {
      // User has specified a text colour
      textColor = [SparkColourPickerUtils colourWithString:textColourString withFallback:@"#FFFFFF"];
    }
  }

  // Set text colour
  UIImageView *textView = MSHookIvar<UIImageView *>(self, "_textView");
  textView.image = [textView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  [textView setTintColor:textColor];

  // Set background colour
  UIImageView *backgroundView = MSHookIvar<UIImageView *>(self, "_backgroundView");
  backgroundView.image = [backgroundView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  [backgroundView setTintColor:color];
}

%end

void reloadPrefs() {
	NSLog(@"[Pastel] (DEBUG) Reloading Preferences...");

  // Set the preferences variable
  if(!preferences)
	  preferences = [[HBPreferences alloc] initWithIdentifier:@"me.conorthedev.pastel.prefs"];

  // Register default values
  [preferences registerDefaults:@{
        @"kEnabled": @YES,
        @"kCustomColorEnabled": @NO,
        @"kCustomTextColorEnabled": @NO
  }];

  // Register booleans
	[preferences registerBool:&kEnabled default:YES forKey:@"kEnabled"];
	[preferences registerBool:&kCustomColorEnabled default:NO forKey:@"kCustomColorEnabled"];
	[preferences registerBool:&kCustomTextColorEnabled default:NO forKey:@"kCustomTextColorEnabled"];

	NSLog(@"[Pastel] (DEBUG) Current Enabled State: %i", kEnabled);
	NSLog(@"[Pastel] (DEBUG) Current Custom Color Enabled State: %i", kCustomColorEnabled);
  NSLog(@"[Pastel] (DEBUG) Current Custom Text Color Enabled State: %i", kCustomTextColorEnabled);
}

%ctor {
	reloadPrefs();
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, CFSTR("me.conorthedev.pastel.prefs/ReloadPrefs"), NULL, kNilOptions);
  
  %init;
}
