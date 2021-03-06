#import <ConorTheDev/libconorthedev.h>
#import <UIKit/UIKit.h>

@interface MTMaterialView : UIView
@property(nonatomic, retain) NSString *groupNameBase;
- (void)applyColour:(UIColor *)colour;
- (void)resetColour;
@end

@interface NCNotificationShortLookView : UIView
@property(nonatomic, copy) NSArray *iconButtons;
@end

@interface NCNotificationLongLookView : UIView
@property(nonatomic, copy) NSArray *iconButtons;
@property(nonatomic, copy) UIView *customContentView;
@end

@interface NCNotificationViewController : UIViewController
@end

@interface NCNotificationListCellActionButton : UIControl
@property(nonatomic, retain) MTMaterialView *backgroundView;
@end

@interface NCNotificationListCellActionButtonsView : UIView
@property(nonatomic, retain) UIStackView *buttonsStackView;
@end

@class PLPlatterView;
@interface NCNotificationViewControllerView : UIView
@property(assign, nonatomic) PLPlatterView *contentView;
@end

@interface NCNotificationShortLookViewController : UIViewController
@end

@interface NCNotificationListCell : UICollectionViewCell
@property(nonatomic, retain)
    NCNotificationViewController *contentViewController;
@property(nonatomic, retain)
    NCNotificationListCellActionButtonsView *leftActionButtonsView;
@end

@interface SBIconImageView : UIView
- (id)contentsImage;
@end

@class SBFolder;
@interface SBIcon : NSObject
@property(nonatomic, retain) SBFolder *folder;
@end

@interface SBLeafIcon : SBIcon
@end

@interface SBApplicationIcon : SBLeafIcon
@end

@interface SBIconView : UIView
@property(nonatomic, retain) SBIcon *icon;

- (void)colourizeNotificationBadge;
- (id)initWithContentType:(unsigned long long)arg1;
- (id)initWithConfigurationOptions:(unsigned long long)arg1;
@end

@interface SBIconBadgeView : UIView
@property(readonly) unsigned long long hash;

+ (id)_createImageForText:(id)arg1 font:(id)arg2 highlighted:(BOOL)arg3;

// Used to set the badge color to the UIColor of the Icon's Image
- (void)colourizeNotificationBadge;
@end