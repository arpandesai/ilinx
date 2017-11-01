//
//  SettingsControlsTH100IPad.m
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "SettingsControlsTH100IPad.h"
#import "DeprecationHelper.h"
#import "NLRenderer.h"
#import "StandardPalette.h"

#define BUTTONS_PER_ROW 3
#define BUTTON_WIDTH ((282 - (8 * (BUTTONS_PER_ROW - 1))) / BUTTONS_PER_ROW)

@interface SettingsControlsTH100IPad ()

- (void) addAudioControlsToView: (UIView *) view  atYOffset:(NSInteger*)yOffset;
- (void) pressedAVRPreset: (UIButton *) control;

@end

@implementation SettingsControlsTH100IPad

- (void) addControlsForSection: (NSUInteger) section toView: (UIView *) view  atYOffset:(NSInteger*)yOffset
{
  if (section == 0 && [_renderer.audioControls count] > 0)
    [self addAudioControlsToView: view  atYOffset:yOffset];
  else
    [super addControlsForSection: section toView: view atYOffset:yOffset];
}

- (void) addAudioControlsToView: (UIView *) view  atYOffset:(NSInteger*)yOffset;
{
  UIView *innerView = [view viewWithTag:TH100ViewTag];
  if(innerView == nil)
    return;
  
  [self hideAllAudioViewsFromView:view];
  innerView.hidden = NO;
  
  UIView *presetView = [innerView viewWithTag:TH1000PresetViewTag];
  if(presetView == 0)
    return;
  
  UIButton *exemplar = [UIButton buttonWithType: UIButtonTypeRoundedRect];
  NSUInteger count = [_renderer.audioControls count];
  NSUInteger i;
  CGSize notionalMaxArea = CGSizeMake( 1000, 50 );
  CGFloat maxWidth = 0;
  CGFloat fontSize = exemplar.titleLabel.font.pointSize;
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
  
  NSInteger buttonHeight = 50;
  NSInteger viewHeight = 20 + (((count / BUTTONS_PER_ROW) + 1) * (buttonHeight + 9));
  presetView.frame = CGRectMake(presetView.frame.origin.x, presetView.frame.origin.y, presetView.frame.size.width, viewHeight);
  
  NSInteger buttonWidth = ((presetView.frame.size.width - (12 * (BUTTONS_PER_ROW - 1))) / BUTTONS_PER_ROW);
  
  while (maxWidth > (buttonWidth - 8) && fontSize > 0)
  {
    fontSize -= 0.5;
    textFont = [UIFont boldSystemFontOfSize: fontSize];
    maxWidth = [maxString sizeWithFont: textFont constrainedToSize: notionalMaxArea
                         lineBreakMode: UILineBreakModeWordWrap].width;
  }
  
  for (i = 0; i < count; ++i)
  {
    UIButton *template = (UIButton*)[presetView viewWithTag:TH1000PresetButtonTemplateTag];
    if(template == nil)
      return;
    
    UIButton *preset = [UIButton buttonWithType:template.buttonType];
    preset.backgroundColor = template.backgroundColor;
    [preset setBackgroundImage:[template backgroundImageForState:UIControlStateNormal] forState:UIControlStateNormal];
    [preset setBackgroundImage:[template backgroundImageForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
    [preset setTitleColor:[template titleColorForState:UIControlStateNormal] forState:UIControlStateNormal];
    
    CGRect frame = CGRectMake( 9 + ((i % BUTTONS_PER_ROW) * (buttonWidth + 8)), 10 + ((i / BUTTONS_PER_ROW) * (buttonHeight + 9)),
                              buttonWidth, buttonHeight );
    
    preset.tag = i;
    preset.titleLabel.font = textFont;
    [preset setTitle: [[_renderer.audioControls objectAtIndex: i] objectForKey: @"display"] forState: UIControlStateNormal];
    [preset addTarget: self action: @selector(pressedAVRPreset:) forControlEvents: UIControlEventTouchDown];
    [SettingsControlsIPad addButton: preset to: presetView frame: frame];
  }
  
  view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, presetView.frame.origin.y + presetView.frame.size.height + 40);
  (*yOffset) += view.frame.size.height;	
}

- (void) pressedAVRPreset: (UIButton *) control
{
  [_renderer sendAudioControl: control.tag];
}

@end
