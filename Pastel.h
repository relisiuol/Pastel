#import <ConorTheDev/libconorthedev.h>
#import <UIKit/UIKit.h>

@interface SBIconBadgeView : UIView
// Used to set the badge color to any UIColor
- (void)setupPastelBadge:(UIColor *)badgeTintColor;
@end

@interface SBIconImageView : UIView
- (id)contentsImage;
@end

@interface SBIconView : UIView
@end