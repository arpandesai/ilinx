//  ActivityViewController.m

#import <QuartzCore/CALayer.h>
#import "ActivityViewController.h"

@implementation BaseActivityView

@synthesize activityLabel;
@synthesize cancelButton;
@synthesize delegate;

-(void)dealloc
{
	[super dealloc];
	[activityLabel release];
	[cancelButton release];
}

-(id)init
{
	self = [super init];
	if(self != nil)
	{
		background = [[UIView alloc] init];
		background.backgroundColor = [UIColor clearColor];
		[self addSubview:background];
		[background release];
		
		overlayView = [[UIView alloc] init];
		overlayView.alpha = 1.0;
		overlayView.backgroundColor = [UIColor blackColor];
		CALayer *layer = [overlayView layer];
		layer.masksToBounds = YES;
		layer.cornerRadius = 10.0;
		layer.borderWidth = 1.0;
		layer.borderColor = [[UIColor grayColor] CGColor];
		[self addSubview:overlayView];
		[overlayView release];
		
		activityLabel = [[UILabel alloc] init];
		activityLabel.numberOfLines = 2;
		activityLabel.adjustsFontSizeToFitWidth = YES;
		activityLabel.backgroundColor = [UIColor clearColor];
		activityLabel.textAlignment = UITextAlignmentCenter;
		activityLabel.textColor = [UIColor whiteColor];
		[self addSubview:activityLabel];
		[activityLabel release];
		
		cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
		[cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:cancelButton];
	}
	return self;
}

-(void)cancelPressed
{
	[self removeFromSuperview];
	if(delegate != nil)
		[delegate activityViewCancelled];
}

-(void)overlayOnView:(UIView*)view
{
	if(delegate == nil)
		cancelButton.hidden = YES;
	else
		cancelButton.hidden = NO;
	
	self.frame = view.bounds;
	
	NSInteger midPointX = self.frame.size.width/2;
	NSInteger midPointY = self.frame.size.height/2;
	
	background.frame = self.frame;
	background.alpha = 0.4;
	background.backgroundColor = [UIColor blackColor];
	overlayView.frame = CGRectMake(midPointX - 120, midPointY - 93, 240, 185);
	activityLabel.frame = CGRectMake(midPointX - 115, midPointY - 68, 230, 30);
	cancelButton.frame = CGRectMake(midPointX + 30, midPointY + 40, 60, 25);

	[view addSubview:self];
}

@end

@implementation ActivityView

@synthesize activityProgress;
@synthesize activityIndicator;
@synthesize limit;

-(void)dealloc
{
	[super dealloc];	
	[activityProgress release];
	[activityIndicator release];
}

-(id)init
{
	self = [super init];
	if(self != nil)
	{
		activityProgress = [[UIProgressView alloc] init];
		[self addSubview:activityProgress];
		
		activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		[self addSubview:activityIndicator];
	}
	return self;
}

+(ActivityView*)instance
{
	static ActivityView *instance;
	
	@synchronized(self) 
	{
		if(!instance) 
			instance = [[ActivityView alloc] init];
	}
	return instance;
}

-(void)overlayOnView:(UIView*)view
{
	[super overlayOnView:view];
	NSInteger midPointX = self.frame.size.width/2;
	NSInteger midPointY = self.frame.size.height/2;
	activityProgress.frame = CGRectMake(midPointX - 90, midPointY + 10, 180, 20);
	activityIndicator.frame = CGRectMake(midPointX - 10, midPointY - 25, 20, 20);

	activityProgress.progress = 0.0;
	activityLabel.text = @"";
	[activityIndicator startAnimating];	
}

-(void)updateActivityProgress:(id)progressDetails
{
	NSDictionary *dict = progressDetails;
	
	float progressAsFloat = [(NSNumber*)[dict objectForKey:@"Progress"] floatValue];
	float limitAsFloat = [[NSNumber numberWithInt:limit] floatValue];
	
	activityProgress.progress = progressAsFloat / limitAsFloat;
	activityLabel.text = [dict objectForKey:@"Label"];
}

@end

