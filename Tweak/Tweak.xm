#import "Pastel.h"
#import <SparkDev97/SparkColourPickerUtils.h>
#import <Cephei/HBPreferences.h>

BOOL kEnabled;
BOOL kCustomColorEnabled;
BOOL kCustomTextColorEnabled;
BOOL kBadgeBorderColorEnabled;
BOOL kCustomBadgeBorderColorEnabled;
BOOL kNotificationBannerEnabled;
BOOL kNotificationBadgeEnabled;
BOOL kCustomNotificationBgColourEnabled;

HBPreferences *preferences;
NSMutableDictionary *colourCache;
NSDictionary* colourPreferencesDictionary;

%group badges

static UIColor *colorShiftedBy(UIColor *color, CGFloat shift) {
  CGFloat red, green, blue, alpha;
  [color getRed:&red green:&green blue:&blue alpha:&alpha];
  return [UIColor colorWithRed:red + shift green:green + shift blue:blue + shift alpha:alpha];
}

%hook SBIconBadgeView

- (void)configureForIcon:(SBApplicationIcon*)arg1 infoProvider:(SBIconView*)arg2 {
  %orig;

  if([arg1 isKindOfClass:%c(SBFolderIcon)] || [arg2 isKindOfClass:%c(SBForceTouchAppIconInfoProvider)]) {
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

  // Add our colour to the badge
  [self colourizeNotificationBadge];
}

- (void)layoutSubviews {
  %orig;
  // Add our colour to the badge
  [self colourizeNotificationBadge];
}

- (void)drawRect:(CGRect)rect {
  %orig(rect);
  // Add our colour to the badge
  [self colourizeNotificationBadge];
}

%new
- (void)colourizeNotificationBadge {
  // Initial Varaibles
  UIColor *color = NULL;
  NSString* colourString = NULL;
  NSString* textColourString = NULL;
  NSString* borderColourString = NULL;

  UIColor *textColor = [UIColor whiteColor];
  UIColor *borderColor = NULL;

  if(!kEnabled || !kNotificationBadgeEnabled) {
    // If the tweak is disabled, use the system red colour as the colour
    color = [UIColor systemRedColor];
  } else {
    // Set the variables from preferences
    if(colourPreferencesDictionary) {
      colourString = [colourPreferencesDictionary objectForKey:@"kCustomColor"];
      textColourString = [colourPreferencesDictionary objectForKey:@"kCustomTextColor"];
      borderColourString = [colourPreferencesDictionary objectForKey:@"kCustomBadgeBorderColor"];
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

  // Set border colour
  if(kEnabled && kNotificationBadgeEnabled && kBadgeBorderColorEnabled) {
    if(kCustomBadgeBorderColorEnabled && borderColourString) {
      borderColor = [SparkColourPickerUtils colourWithString:borderColourString withFallback:@"#000000"];
    } else {
      borderColor = colorShiftedBy(color, 0.25);
    }
  	backgroundView.layer.cornerRadius = 13;
  	backgroundView.layer.borderWidth = 2;
  	backgroundView.layer.borderColor = borderColor.CGColor;
  } else {
    backgroundView.layer.cornerRadius = 0;
    backgroundView.layer.borderWidth = 0;
    backgroundView.layer.borderColor = [UIColor clearColor].CGColor;
  }
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
  self.layer.cornerRadius = 13;
}

%new
- (void)resetColour {
  if (!self) return;

  // Reset the background colour
  self.clipsToBounds = YES;
  self.backgroundColor = nil;
  self.layer.cornerRadius = 13;
}

%end

%hook NCNotificationListCellActionButtonsView
- (void)layoutSubviews {
  %orig;
  if (!self) return;

  if(kEnabled && kNotificationBannerEnabled) {
    NCNotificationListCell *cell = (NCNotificationListCell *)self.superview.superview.superview;
    NCNotificationViewController *contentViewController = cell.contentViewController;
    NCNotificationShortLookViewController *shortlookViewContoller = (NCNotificationShortLookViewController*)contentViewController;
    NCNotificationViewControllerView *view = (NCNotificationViewControllerView*) shortlookViewContoller.view;
    NCNotificationShortLookView *shortlookView = (NCNotificationShortLookView*) view.contentView;

    // Get the background colour
    UIButton *iconButton = [shortlookView.iconButtons objectAtIndex:0];
    UIColor *colour = [[[CTDColorUtils alloc] init] getAverageColorFrom:iconButton.currentImage withAlpha:1.0];

    if(kCustomNotificationBgColourEnabled) {
      NSString *colourString = NULL;
      if(colourPreferencesDictionary) {
        colourString = [colourPreferencesDictionary objectForKey:@"kCustomNotificationBgColour"];
      }

      if(colourString) {
        colour = [SparkColourPickerUtils colourWithString:colourString withFallback:@"#ffffff"];
      }
    }

    for (NCNotificationListCellActionButton *button in self.buttonsStackView.arrangedSubviews) {
      [((MTMaterialView *)button.backgroundView) applyColour:colour];
    }
  } else {
    for (NCNotificationListCellActionButton *button in self.buttonsStackView.arrangedSubviews) {
      [((MTMaterialView *)button.backgroundView) resetColour];
    }
  }
}

%end

%hook NCNotificationLongLookView
- (void)drawRect:(CGRect)rect {
  %orig(rect);

  if(kEnabled && kNotificationBannerEnabled) {
    UIButton *iconButton = [self.iconButtons objectAtIndex:0];
    UIView *headerContentView = MSHookIvar<UIView *>(self, "_headerContentView");
    UIView *notificationContentView = MSHookIvar<UIView *>(self, "_notificationContentView");
    
    UIColor *colour = [[[CTDColorUtils alloc] init] getAverageColorFrom:iconButton.currentImage withAlpha:1.0];

    if(kCustomNotificationBgColourEnabled) {
      NSString *colourString = NULL;
      if(colourPreferencesDictionary) {
        colourString = [colourPreferencesDictionary objectForKey:@"kCustomNotificationBgColour"];
      }

      if(colourString) {
        colour = [SparkColourPickerUtils colourWithString:colourString withFallback:@"#ffffff"];
      }
    }

    [headerContentView setBackgroundColor:colour];
    [notificationContentView setBackgroundColor:colour];
  }
}

%end

%hook NCNotificationShortLookView
- (void)drawRect:(CGRect)rect {
  %orig(rect);

  for (UIView *subview in [self subviews]) {
    // Check if the current subview is MTMaterialView (the blurred background view)
    if ([subview isKindOfClass:%c(MTMaterialView)]) {
      if(kNotificationBannerEnabled && kEnabled) {
        if(kCustomNotificationBgColourEnabled) {
          NSString *colourString = NULL;
          if(colourPreferencesDictionary) {
            colourString = [colourPreferencesDictionary objectForKey:@"kCustomNotificationBgColour"];
          }

          if(colourString) {
            [((MTMaterialView *)subview) applyColour:[SparkColourPickerUtils colourWithString:colourString withFallback:@"#ffffff"]];
          }
        } else {
          // Get the button that contains the icon image
          UIButton *iconButton = [self.iconButtons objectAtIndex:0];

          // Set the material view background colour to the average colour of the button's icon
          [((MTMaterialView *)subview) applyColour:[[[CTDColorUtils alloc] init] getAverageColorFrom:iconButton.currentImage withAlpha:1.0]];
        }
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

  // Reload the colour preferences dictionary if not already set
  colourPreferencesDictionary = [NSDictionary dictionaryWithContentsOfFile: @"/var/mobile/Library/Preferences/me.conorthedev.pastel.colorprefs.plist"];

  // Set the preferences variable
  if(!preferences)
	  preferences = [[HBPreferences alloc] initWithIdentifier:@"me.conorthedev.pastel.prefs"];

  // Register default values
  [preferences registerDefaults:@{
        @"kEnabled": @YES,
        @"kNotificationBannerEnabled": @YES,
        @"kNotificationBadgeEnabled": @YES,
        @"kCustomNotificationBgColourEnabled": @NO,
        @"kBadgeBorderColorEnabled": @YES,
        @"kCustomBadgeBorderColorEnabled": @NO,
        @"kCustomColorEnabled": @NO,
        @"kCustomTextColorEnabled": @NO
  }];

  // Register booleans
	[preferences registerBool:&kEnabled default:YES forKey:@"kEnabled"];
  [preferences registerBool:&kNotificationBannerEnabled default:YES forKey:@"kNotificationBannerEnabled"];
  [preferences registerBool:&kNotificationBadgeEnabled default:YES forKey:@"kNotificationBadgeEnabled"];
	[preferences registerBool:&kCustomColorEnabled default:NO forKey:@"kCustomColorEnabled"];
	[preferences registerBool:&kCustomTextColorEnabled default:NO forKey:@"kCustomTextColorEnabled"];
  [preferences registerBool:&kCustomNotificationBgColourEnabled default:NO forKey:@"kCustomNotificationBgColourEnabled"];
  [preferences registerBool:&kBadgeBorderColorEnabled default:YES forKey:@"kBadgeBorderColorEnabled"];
  [preferences registerBool:&kCustomBadgeBorderColorEnabled default:NO forKey:@"kCustomBadgeBorderColorEnabled"];

	NSLog(@"[Pastel] (DEBUG) Current Enabled State: %i", kEnabled);
  NSLog(@"[Pastel] (DEBUG) Current Notification Banner Enabled State: %i", kNotificationBannerEnabled);
  NSLog(@"[Pastel] (DEBUG) Current Notification Badge Enabled State: %i", kNotificationBadgeEnabled);
  NSLog(@"[Pastel] (DEBUG) Current Notification Badge Border Enabled State: %i", kBadgeBorderColorEnabled);
	NSLog(@"[Pastel] (DEBUG) Current Custom Badge Color Enabled State: %i", kCustomColorEnabled);
  NSLog(@"[Pastel] (DEBUG) Current Custom Badge Text Color Enabled State: %i", kCustomTextColorEnabled);
  NSLog(@"[Pastel] (DEBUG) Current Custom Badge Border Color Enabled State: %i", kCustomBadgeBorderColorEnabled);
  NSLog(@"[Pastel] (DEBUG) Current Custom Notification Background Color Enabled State: %i", kCustomNotificationBgColourEnabled);
}

%ctor {
	reloadPrefs();
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, CFSTR("me.conorthedev.pastel.prefs/ReloadPrefs"), NULL, kNilOptions);
  
  colourCache = [[NSMutableDictionary alloc] init];
  
  %init(badges);
  %init(notifications)
}
