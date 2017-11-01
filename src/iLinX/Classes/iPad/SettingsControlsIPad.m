//
//  SettingsControlsIPad.m
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "SettingsControlsIPad.h"
#import "ColouredRoundedRect.h"
#import "DeprecationHelper.h"
#import "NLRenderer.h"
#import "SettingsControlsNNPIPad.h"
#import "SettingsControlsSL220IPad.h"
#import "SettingsControlsSL250IPad.h"
#import "SettingsControlsSN1000IPad.h"
#import "SettingsControlsTH100IPad.h"
#import "SettingsControlsVLIPad.h"
#import "StandardPalette.h"

#define BUTTON_WIDTH ((282 - (8 * (BUTTONS_PER_ROW - 1))) / BUTTONS_PER_ROW)

@interface SettingsControlsIPad ()

+ (Class) settingsControlsClassForRenderer: (NLRenderer *) renderer;
- (id) initWithRenderer: (NLRenderer *) renderer;

@end

@implementation SettingsControlsIPad

+ (Class) settingsControlsClassForRenderer: (NLRenderer *) renderer
{
  NSString *permId = renderer.permId;
  Class settingsClass;
  
  if (permId == nil)
    settingsClass = [SettingsControlsIPad class];
  else if ([permId hasPrefix: @"SL220"])
    settingsClass = [SettingsControlsSL220IPad class];
  else if ([permId hasPrefix: @"SL250"] || [permId hasPrefix: @"SL254"] || [permId hasPrefix: @"SL9250-CS"] ||
           [permId hasPrefix: @"SL251"])
    settingsClass = [SettingsControlsSL250IPad class];
  else if ([permId hasPrefix: @"SN1000"] || [permId hasPrefix: @"SN1001"])
    settingsClass = [SettingsControlsSN1000IPad class];
  else if ([permId hasPrefix: @"TH100"])
    settingsClass = [SettingsControlsTH100IPad class];
  else if ([permId hasPrefix: @"VL"])
    settingsClass = [SettingsControlsVLIPad class];
  else if ([permId hasPrefix: @"NNP"])
    settingsClass = [SettingsControlsNNPIPad class];
  else
    settingsClass = [SettingsControlsIPad class];

  return settingsClass;
}

+ (SettingsControlsIPad *) allocSettingsControlsForRenderer: (NLRenderer *) renderer
{
  return [[[SettingsControlsIPad settingsControlsClassForRenderer: renderer] alloc] 
          initWithRenderer: renderer];
}

- (id) initWithRenderer: (NLRenderer *) renderer
{
  if (self = [super init])
  {
    _renderer = [renderer retain];
  }
  
  return self;
}

- (BOOL) rightSettingsForRenderer
{
  return ([SettingsControlsIPad settingsControlsClassForRenderer: _renderer] == [self class]);
}

- (NSUInteger) numberOfSections
{
  if (_renderer.videoControls != nil && [_renderer.videoControls count] > 0)
    return 2;
  else
    return 1;
}

-(void)hideAllAudioViewsFromView:(UIView*)view
{
	for(UIView *subview in view.subviews)
		if([subview isMemberOfClass:[UIView class]] || (subview.tag == NoControlsLabel))
			subview.hidden = YES;
}

- (void) addControlsForSection: (NSUInteger) section toView: (UIView *) view  atYOffset:(NSInteger*)yOffset
{
  if (section == 0)
  {
	  UILabel *noControlsLabel = (UILabel*)[view viewWithTag:NoControlsLabel];
	  if(noControlsLabel == nil)
		  return;

	  [self hideAllAudioViewsFromView:view];
	  noControlsLabel.hidden = NO;
  }
}

- (BOOL) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags
{
  return NO;
}

+ (void) addButton: (UIButton *) button to: (UIView *) view frame: (CGRect) frame
{
  button.frame = frame;
  if (button.buttonType == UIButtonTypeCustom)
  {
    UIColor *tint = button.backgroundColor;

    if (tint != nil && ![tint isEqual: [UIColor clearColor]])
    {
      ColouredRoundedRect *backdrop = [[ColouredRoundedRect alloc] initWithFrame: frame fillColour: tint radius: 8.0];
      
      [view addSubview: backdrop];
      [backdrop release];
      button.backgroundColor = [UIColor clearColor];
    }
  }

  [view addSubview: button];
}

+ (UIButton *) standardButtonWithStyle: (UIBarStyle) style
{
  UIButton *button;
  
  UIColor *normalColour;
  UIColor *highlightColour;
  UIColor *shadowColour;
  UIColor *tintColour;

  if (style == UIBarStyleDefault)
  {
    normalColour = [StandardPalette buttonTitleColour];
    highlightColour = [StandardPalette highlightedButtonTitleColour];
    shadowColour = [StandardPalette buttonTitleShadowColour];
    tintColour = [StandardPalette buttonColour];
  }
  else
  {
    normalColour = [UIColor lightGrayColor];
    highlightColour = [UIColor whiteColor];
    shadowColour = [UIColor darkGrayColor];
    tintColour = [UIColor blackColor];
  }

  button = [UIButton buttonWithType: UIButtonTypeCustom];
  
  [button setTitleColor: normalColour forState: UIControlStateNormal];
  [button setTitleColor: highlightColour forState: UIControlStateHighlighted];
  [button setTitleShadowColor: shadowColour forState: UIControlStateNormal];
  [button setTitleLabelFont: [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]]];
  //[button setTitleLabelShadowOffset: CGSizeMake( 0, 1 )];
  button.backgroundColor = tintColour;
  
  [button setBackgroundImage: [[UIImage imageNamed: @"SettingsButtonReleased.png"]
                               stretchableImageWithLeftCapWidth: 10 topCapHeight: 0]
                    forState: UIControlStateNormal];
  [button setBackgroundImage: [[UIImage imageNamed: @"SettingsButtonPressed.png"]
                               stretchableImageWithLeftCapWidth: 10 topCapHeight: 0]
                    forState: UIControlStateHighlighted];
  
  return button;
}

- (void) dealloc
{
  [_renderer release];
  [super dealloc];
}

@end
