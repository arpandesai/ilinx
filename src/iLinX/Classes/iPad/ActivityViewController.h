//  ActivityViewController.h

#import <UIKit/UIKit.h>

@protocol ActivityViewDelegate

-(void)activityViewCancelled;

@end

@interface BaseActivityView : UIView
{
	UIView *background;
	UIView *overlayView;
	id<ActivityViewDelegate> delegate;
	UILabel *activityLabel;
	UIButton *cancelButton;
}

-(void)overlayOnView:(UIView*)view;
-(void)cancelPressed;

@property(nonatomic,retain) id<ActivityViewDelegate> delegate;
@property (nonatomic, retain) UILabel *activityLabel;
@property (nonatomic, retain) UIButton *cancelButton;

@end

@interface ActivityView : BaseActivityView
{
	UIProgressView *activityProgress;
	UIActivityIndicatorView *activityIndicator;
	NSInteger limit;
}

+(ActivityView*)instance;

-(void)overlayOnView:(UIView*)view;
-(void)updateActivityProgress:(id)progressDetails;

@property (nonatomic, retain) UIProgressView *activityProgress;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property NSInteger limit;

@end
