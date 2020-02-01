#include "PastelPrefsRootListController.h"
#import <CepheiPrefs/HBAppearanceSettings.h>

#define THEME_COLOR                                                            \
  [UIColor colorWithRed:242.0 / 255.0                                          \
                  green:203.0 / 255.0                                          \
                   blue:206.0 / 255.0                                          \
                  alpha:1.0];

@implementation PastelPrefsRootListController

- (instancetype)init {
  self = [super init];

  if (self) {
    HBAppearanceSettings *appearanceSettings =
        [[HBAppearanceSettings alloc] init];

    appearanceSettings.tintColor = THEME_COLOR;
    appearanceSettings.tableViewCellSeparatorColor = [UIColor clearColor];

    self.hb_appearanceSettings = appearanceSettings;
  }

  return self;
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

- (id)specifiers {
  if (_specifiers == nil) {
    _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
  }
  return _specifiers;
}

@end