//
//  SettingsControlsTH100.m
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "SettingsControlsTH100.h"
#import "DeprecationHelper.h"
#import "NLRenderer.h"
#import "StandardPalette.h"

#define BUTTONS_PER_ROW 2
#define BUTTON_WIDTH ((282 - (8 * (BUTTONS_PER_ROW - 1))) / BUTTONS_PER_ROW)

@interface SettingsControlsTH100 ()

- (void) addAudioControlsToView: (UIView *) view;
- (void) pressedAVRPreset: (UIButton *) control;

@end

@implementation SettingsControlsTH100

- (CGFloat) heightForSection: (NSUInteger) section
{
  CGFloat height;
  
  if (section > 0)
    height = [super heightForSection: section];
  else
  {
     NSUInteger count = [_renderer.audioControls count];
      
    if (count == 0)
      count = 1;
    height = 57.0 + (((count - 1) / BUTTONS_PER_ROW) * 46.0);
  }
  
  return height;
}

- (void) addControlsForSection: (NSUInteger) section toView: (UIView *) view
{
  if (section == 0 && [_renderer.audioControls count] > 0)
    [self addAudioControlsToView: view];
  else
    [super addControlsForSection: section toView: view];
}

- (void) addAudioControlsToView: (UIView *) view
{
  NSUInteger count = [_renderer.audioControls count];
  UIButton *exemplar = [UIButton buttonWithType: UIButtonTypeRoundedRect];
  NSUInteger i;
  CGSize notionalMaxArea = CGSizeMake( 1000, 50 );
  CGFloat maxWidth = 0;
  CGFloat fontSize = [exemplar titleLabelFont].pointSize;
  UIFont *textFont = [UIFont boldSystemFontOfSize: fontSize];
  NSString *maxString = @"";
  
  for (i = 0; i < count; ++i)
  {
    NSString *string = [[_renderer.audioControls objectAtIndex: i] objectForKey: @"display"];
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
    [preset setTitle: [[_renderer.audioControls objectAtIndex: i] objectForKey: @"display"] forState: UIControlStateNormal];
    [preset addTarget: self action: @selector(pressedAVRPreset:) forControlEvents: UIControlEventTouchDown];
    [SettingsControls addButton: preset to: view frame: frame];
  }
}

- (void) pressedAVRPreset: (UIButton *) control
{
  [_renderer sendAudioControl: control.tag];
}

@end
