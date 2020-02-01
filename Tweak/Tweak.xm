#import "Pastel.h"
#import "SparkColourPickerUtils.h"
#import <Cephei/HBPreferences.h>

BOOL kEnabled;
BOOL kCustomColorEnabled;
BOOL kCustomTextColorEnabled;
BOOL kNotificationBannerEnabled;
BOOL kNotificationBadgeEnabled;

HBPreferences *preferences;
NSMutableDictionary *colourCache;
NSDictionary* colourPreferencesDictionary;

%group badges
%hook SBIconBadgeView

- (void)configureForIcon:(SBApplicationIcon*)arg1 infoProvider:(SBIconView*)arg2 {
  %orig;

  if([arg2 isKindOfClass:%c(SBForceTouchAppIconInfoProvider)]) {
    // Set the colour to red as arg2 doesn't have the _iconImageView ivar
    [colourCache setObject:[NSKeyedArchiver archivedDataWithRootObject:[UIColor systemRedColor] requiringSecureCoding:NO error:nil] forKey:[NSString stringWithFormat:@"%llu", self.hash]];
  } else {
    if([arg1 isKindOfClass:%c(SBFolderIcon)]) {
      // Set the colour to red
      [colourCache setObject:[NSKeyedArchiver archivedDataWithRootObject:[UIColor systemRedColor] requiringSecureCoding:NO error:nil] forKey:[NSString stringWithFormat:@"%llu", self.hash]];
    } else {
      // Get the icon from the image view
      SBIconImageView *iconImageView = MSHookIvar<SBIconImageView *>(arg2, "_iconImageView");
      UIImage *image = [iconImageView contentsImage];

      if(image) {
        // Put the average colour in the colour dictionary
        [colourCache setObject:[NSKeyedArchiver archivedDataWithRootObject:[[[CTDColorUtils alloc] init] getAverageColorFrom:image withAlpha:1.0] requiringSecureCoding:NO error:nil] forKey:[NSString stringWithFormat:@"%llu", self.hash]];
      }
    }
  }

  // Add our colour to the badge
  [self colourizeNotificationBadge];
}

- (void)layoutSubviews {
  %orig;
  // Add our colour to the badge
  [self colourizeNotificationBadge];
}

%new
- (void)colourizeNotificationBadge {
  // Initial Varaibles
  UIColor *color = NULL;
  NSString* colourString = NULL;
  NSString* textColourString = NULL;

  UIColor *textColor = [UIColor whiteColor];

  if(!kEnabled || !kNotificationBadgeEnabled) {
    // If the tweak is disabled, use the system red colour as the colour
    color = [UIColor systemRedColor];
  } else {
    // Load preferences
    if(colourPreferencesDictionary) {
      colourString = [colourPreferencesDictionary objectForKey:@"kCustomColor"];
      textColourString = [colourPreferencesDictionary objectForKey:@"kCustomTextColor"];
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

  if(kEnabled && kNotificationBadgeEnabled) {
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
%end

%group notifications
%hook MTMaterialView

%new
- (void)applyColour:(UIColor*)colour {
  if (!self || !colour) return;

  // Set the background colour
  self.clipsToBounds = YES;
  self.backgroundColor = colour;
}

%new
- (void)resetColour {
  if (!self) return;

  // Reset the background colour
  self.clipsToBounds = YES;
  self.backgroundColor = nil;
}

%end

%hook NCNotificationShortLookView
- (void)drawRect:(CGRect)rect {
  %orig(rect);

  for (UIView *subview in [self subviews]) {
    // Check if the current subview is MTMaterialView (the blurred background view)
    if ([subview isKindOfClass:%c(MTMaterialView)]) {
      if(kNotificationBannerEnabled && kEnabled) {
        // Get the button that contains the icon image
        UIButton *iconButton = [self.iconButtons objectAtIndex:0];

        // Set the material view background colour to the average colour of the button's icon
        [((MTMaterialView *)subview) applyColour:[[[CTDColorUtils alloc] init] getAverageColorFrom:iconButton.currentImage withAlpha:1.0]];
      } else {
        // Tweak was enabled / disabled, reset the colour
        [((MTMaterialView *)subview) resetColour];
      }
    }
  }
}

%end
%end

void reloadPrefs() {
	NSLog(@"[Pastel] (DEBUG) Reloading Preferences...");

  // Set the preferences variable
  if(!preferences)
	  preferences = [[HBPreferences alloc] initWithIdentifier:@"me.conorthedev.pastel.prefs"];

  // Register default values
  [preferences registerDefaults:@{
        @"kEnabled": @YES,
        @"kNotificationBannerEnabled": @YES,
        @"kNotificationBadgeEnabled": @YES,
        @"kCustomColorEnabled": @NO,
        @"kCustomTextColorEnabled": @NO
  }];

  // Register booleans
	[preferences registerBool:&kEnabled default:YES forKey:@"kEnabled"];
  [preferences registerBool:&kNotificationBannerEnabled default:YES forKey:@"kNotificationBannerEnabled"];
  [preferences registerBool:&kNotificationBadgeEnabled default:YES forKey:@"kNotificationBadgeEnabled"];
	[preferences registerBool:&kCustomColorEnabled default:NO forKey:@"kCustomColorEnabled"];
	[preferences registerBool:&kCustomTextColorEnabled default:NO forKey:@"kCustomTextColorEnabled"];

	NSLog(@"[Pastel] (DEBUG) Current Enabled State: %i", kEnabled);
	NSLog(@"[Pastel] (DEBUG) Current Custom Color Enabled State: %i", kCustomColorEnabled);
  NSLog(@"[Pastel] (DEBUG) Current Custom Text Color Enabled State: %i", kCustomTextColorEnabled);
}

%ctor {
	reloadPrefs();
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, CFSTR("me.conorthedev.pastel.prefs/ReloadPrefs"), NULL, kNilOptions);
  
  colourCache = [[NSMutableDictionary alloc] init];
  colourPreferencesDictionary = [NSDictionary dictionaryWithContentsOfFile: @"/var/mobile/Library/Preferences/me.conorthedev.pastel.colorprefs.plist"];
  
  %init(badges);
  %init(notifications)
}
