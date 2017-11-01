//
//  SettingsControls.m
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "SettingsControls.h"
#import "ColouredRoundedRect.h"
#import "DeprecationHelper.h"
#import "NLRenderer.h"
#import "SettingsControlsNNP.h"
#import "SettingsControlsSL220.h"
#import "SettingsControlsSL250.h"
#import "SettingsControlsSN1000.h"
#import "SettingsControlsTH100.h"
#import "SettingsControlsVL.h"
#import "StandardPalette.h"

#define BUTTONS_PER_ROW 2
#define BUTTON_WIDTH ((282 - (8 * (BUTTONS_PER_ROW - 1))) / BUTTONS_PER_ROW)

@interface SettingsControls ()

+ (Class) settingsControlsClassForRenderer: (NLRenderer *) renderer;
- (id) initWithRenderer: (NLRenderer *) renderer style: (UIBarStyle) style;
- (void) pressedVideoPreset: (UIButton *) control;

@end

@implementation SettingsControls

+ (Class) settingsControlsClassForRenderer: (NLRenderer *) renderer
{
  NSString *permId = renderer.permId;
  Class settingsClass;
  
  if (permId == nil)
    settingsClass = [SettingsControls class];
  else if ([permId hasPrefix: @"SL220"])
    settingsClass = [SettingsControlsSL220 class];
  else if ([permId hasPrefix: @"SL250"] || [permId hasPrefix: @"SL254"] || [permId hasPrefix: @"SL9250-CS"] ||
           [permId hasPrefix: @"SL251"] || [permId hasPrefix: @"TLA250"])
    settingsClass = [SettingsControlsSL250 class];
  else if ([permId hasPrefix: @"SN1000"] || [permId hasPrefix: @"SN1001"])
    settingsClass = [SettingsControlsSN1000 class];
  else if ([permId hasPrefix: @"TH100"])
    settingsClass = [SettingsControlsTH100 class];
  else if ([permId hasPrefix: @"VL"])
    settingsClass = [SettingsControlsVL class];
  else if ([permId hasPrefix: @"NNP"])
    settingsClass = [SettingsControlsNNP class];
  else
    settingsClass = [SettingsControls class];

  return settingsClass;
}

+ (SettingsControls *) allocSettingsControlsForRenderer: (NLRenderer *) renderer style: (UIBarStyle) style
{
  return [[[SettingsControls settingsControlsClassForRenderer: renderer] alloc] 
          initWithRenderer: renderer style: style];
}

- (id) initWithRenderer: (NLRenderer *) renderer style: (UIBarStyle) style
{
  if (self = [super init])
  {
    _renderer = [renderer retain];
    _style = style;
  }
  
  return self;
}

- (BOOL) rightSettingsForRenderer
{
  return ([SettingsControls settingsControlsClassForRenderer: _renderer] == [self class]);
}

- (NSUInteger) numberOfSections
{
  if (_renderer.videoControls != nil && [_renderer.videoControls count] > 0)
    return 2;
  else
    return 1;
}

- (NSString *) titleForSection: (NSUInteger) section
{
  NSString *title;

  switch (section)
  {
    case 0:
      title = NSLocalizedString( @"Audio", @"Title for header of Audio section in settings view" );
      break;
    case 1:
      title = NSLocalizedString( @"Display", @"Title for header of Video section in settings view" );
      break;
    default:
      title = @"";
      break;
  }
  
  return title;
}

- (CGFloat) heightForSection: (NSUInteger) section
{
  CGFloat height;
  
  if (section == 0)
    height = 50.0;
  else
  {
    NSUInteger count = [_renderer.videoControls count];
    
    if (count == 0)
      count = 1;
    height = 57.0 + (((count - 1) / BUTTONS_PER_ROW) * 46.0);
  }
  
  return height;
}

- (void) addControlsForSection: (NSUInteger) section toView: (UIView *) view
{
  if (section == 0)
  {
    UILabel *noControls = [UILabel new];
    
    noControls.text = NSLocalizedString( @"No audio controls available",
                                        @"Message to show when there are no audio controls" );
    [self addLabel: noControls to: view position: CGPointMake( 150, 14 ) fontSize: [UIFont labelFontSize]];
    [noControls release];
  }
  else
  {
    UIButton *exemplar = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    NSUInteger count = [_renderer.videoControls count];
    NSUInteger i;
    CGSize notionalMaxArea = CGSizeMake( 1000, 50 );
    CGFloat maxWidth = 0;
    CGFloat fontSize = [exemplar titleLabelFont].pointSize;
    UIFont *textFont = [UIFont boldSystemFontOfSize: fontSize];
    NSString *maxString = @"";
    
    for (i = 0; i < count; ++i)
    {
      NSString *string = [[_renderer.videoControls objectAtIndex: i] objectForKey: @"display"];
      CGSize actualTextArea = [string sizeWithFont: textFont constrainedToSize: notionalMaxArea
                               lineBreakMode: UILineBreakModeWordWrap];
      
      if (actualTextArea.width > maxWidth)
      {
        maxWidth = actualTextArea.width;
        maxString = string;
      }
    }
    
    while (maxWidth > (BUTTON_WIDTH - 8) && fontSize > 0)
    {
      fontSize -= 0.5;
      textFont = [UIFont boldSystemFontOfSize: fontSize];
      maxWidth = [maxString sizeWithFont: textFont constrainedToSize: notionalMaxArea
                           lineBreakMode: UILineBreakModeWordWrap].width;
    }
    
    for (i = 0; i < count; ++i)
    {
      UIButton *preset = [SettingsControls standardButtonWithStyle: _style];
#if BUTTONS_PER_ROW == 3
     CGRect frame = CGRectMake( 9 + ((i % 3) * 96) + (((i % 3) == 1) ? 1 : 0), 10 + ((i / 3) * 46),
                                ((i % 3) == 1) ? 88 : 89, 37 );
#else
      CGRect frame = CGRectMake( 9 + ((i % BUTTONS_PER_ROW) * (BUTTON_WIDTH + 8)), 10 + ((i / BUTTONS_PER_ROW) * 46),
                                BUTTON_WIDTH, 37 );
#endif

      preset.tag = i;
      [preset setTitleLabelFont: textFont];
      [preset setTitle: [[_renderer.videoControls objectAtIndex: i] objectForKey: @"display"] forState: UIControlStateNormal];
      [preset addTarget: self action: @selector(pressedVideoPreset:) forControlEvents: UIControlEventTouchDown];
      [SettingsControls addButton: preset to: view frame: frame];
    }
  }
}

- (BOOL) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags
{
  return NO;
}


- (void) addLabel: (UILabel *) label to: (UIView *) view position: (CGPoint) position fontSize: (CGFloat) fontSize
{
  label.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  label.font = [UIFont boldSystemFontOfSize: fontSize];
  
  CGSize actualTextArea = [label.text sizeWithFont: label.font 
                                 constrainedToSize: CGSizeMake( 320, [label.font lineSpacing] )
                                     lineBreakMode: UILineBreakModeTailTruncation];
  
  [label setFrame: CGRectMake( position.x - (actualTextArea.width / 2), position.y,
                              actualTextArea.width, actualTextArea.height )];
  label.textAlignment = UITextAlignmentCenter;
  if (_style == UIBarStyleDefault)
    label.textColor = [StandardPalette alternativeTableTextColour];
  else
    label.textColor = [UIColor lightTextColor];
  label.backgroundColor = [UIColor clearColor];
  [view addSubview: label];
}

- (void) addSlider: (UISlider *) slider to: (UIView *) view position: (CGPoint) position
{
  CGFloat width = (position.x - view.bounds.origin.x - 40) * 2;
  
  slider.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  slider.minimumValue = 0;
  slider.maximumValue = 100;
  slider.value = 0;
  slider.continuous = YES;
  [slider setFrame: CGRectMake( position.x - (width / 2), position.y, width, 20 )];
  [view addSubview: slider];
}

- (void) addVerticalSlider: (UISlider *) slider to: (UIView *) view frame: (CGRect) frame
{
  slider.transform = CGAffineTransformIdentity;
  slider.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  slider.minimumValue = 0;
  slider.maximumValue = 100;
  slider.value = 0;
  slider.continuous = YES;
  slider.frame = frame;
  slider.transform = CGAffineTransformMake( 0, -1, 1, 0,
                                         (frame.size.height - frame.size.width) / 2,
                                         (frame.size.width - frame.size.height) / 2 );
  [view addSubview: slider];
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

- (void) pressedVideoPreset: (UIButton *) control
{
  [_renderer sendVideoControl: control.tag];
}

- (void) dealloc
{
  [_renderer release];
  [super dealloc];
}

@end
