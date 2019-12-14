#include "PastelPrefsRootListController.h"
#import <CepheiPrefs/HBAppearanceSettings.h>

#define THEME_COLOR                                                            \
  [UIColor colorWithRed:242.0 / 255.0                                          \
                  green:203.0 / 255.0                                          \
                   blue:206.0 / 255.0                                          \
                  alpha:1.0];

@implementation PastelPrefsRootListController

+ (UIColor *)hb_tintColor {
  return THEME_COLOR;
}

- (void)loadView {
  [super loadView];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  if (@available(iOS 11, *)) {
    self.navigationController.navigationBar.prefersLargeTitles = false;
    self.navigationController.navigationItem.largeTitleDisplayMode =
        UINavigationItemLargeTitleDisplayModeNever;
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  if (@available(iOS 11, *)) {
    self.navigationController.navigationBar.prefersLargeTitles = false;
    self.navigationController.navigationItem.largeTitleDisplayMode =
        UINavigationItemLargeTitleDisplayModeNever;
  }
}

+ (NSString *)hb_specifierPlist {
  return @"Root";
}

@end