//
//  VideoControlsViewIPad.m
//  iLinX
//
//  Created by Tony Short on 27/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "DisplayControlsViewIPad.h"
#import "SettingsControlsIPad.h"

@implementation DisplayControlsViewIPad

- (void) pressedVideoPreset: (UIButton *) control
{
  [_renderer sendVideoControl: control.tag];
}

- (void) addNoControlsToView
{
  UILabel *noControlsLabel = (UILabel *) [self viewWithTag: 102];
  
  if (noControlsLabel != nil)
    noControlsLabel.hidden = NO;
}

- (void) addControlsToViewWithRenderer: (NLRenderer *) renderer
{
  [_renderer release];
  _renderer = [renderer retain];
  
  UILabel *noControlsLabel = (UILabel *) [self viewWithTag: 102];
  
  if (noControlsLabel != nil)
    noControlsLabel.hidden = YES;
  
  UIButton *exemplar = [UIButton buttonWithType: UIButtonTypeRoundedRect];
  NSUInteger count = [renderer.videoControls count];
  NSUInteger i;
  CGSize notionalMaxArea = CGSizeMake( 1000, 50 );
  CGFloat maxWidth = 0;
  CGFloat fontSize = exemplar.titleLabel.font.pointSize;
  UIFont *textFont = [UIFont boldSystemFontOfSize: fontSize];
  NSString *maxString = @"";
  
  for (i = 0; i < count; ++i)
  {
    NSString *string = [[renderer.videoControls objectAtIndex: i] objectForKey: @"display"];
    CGSize actualTextArea = [string sizeWithFont: textFont constrainedToSize: notionalMaxArea
                                   lineBreakMode: UILineBreakModeWordWrap];
    
    if (actualTextArea.width > maxWidth)
    {
      maxWidth = actualTextArea.width;
      maxString = string;
    }
  }
  
  UIView *enclosingControlView = [self viewWithTag: 100];
  
  if (enclosingControlView == nil)
    return;
  
  NSInteger buttonHeight = 50;
  NSInteger viewHeight = 20 + (((count / BUTTONS_PER_ROW) + 1) * (buttonHeight + 9));
  self.frame = CGRectMake( self.frame.origin.x, self.frame.origin.y, self.frame.size.width, viewHeight + 70 );
  enclosingControlView.frame = CGRectMake( enclosingControlView.frame.origin.x, enclosingControlView.frame.origin.y,
                                           enclosingControlView.frame.size.width, viewHeight);
  
  NSInteger buttonWidth = ((enclosingControlView.frame.size.width - (12 * (BUTTONS_PER_ROW - 1))) / BUTTONS_PER_ROW);
  
  while (maxWidth > (buttonWidth - 8) && fontSize > 0)
  {
    fontSize -= 0.5;
    textFont = [UIFont boldSystemFontOfSize: fontSize];
    maxWidth = [maxString sizeWithFont: textFont constrainedToSize: notionalMaxArea
                         lineBreakMode: UILineBreakModeWordWrap].width;
  }
  
  UIButton *template = (UIButton *) [self viewWithTag: 101];
  
  if (template == nil)
    return;
  
  for (i = 0; i < count; ++i)
  {
    UIButton *preset = [UIButton buttonWithType: template.buttonType];
    
    preset.backgroundColor = template.backgroundColor;
    [preset setBackgroundImage: [template backgroundImageForState: UIControlStateNormal] forState: UIControlStateNormal];
    [preset setBackgroundImage: [template backgroundImageForState: UIControlStateHighlighted] forState: UIControlStateHighlighted];
    [preset setTitleColor: [template titleColorForState: UIControlStateNormal] forState: UIControlStateNormal];
    
    CGRect frame = CGRectMake( 9 + ((i % BUTTONS_PER_ROW) * (buttonWidth + 8)), 10 + ((i / BUTTONS_PER_ROW) * (buttonHeight + 9)),
                              buttonWidth, buttonHeight );
    
    preset.tag = i;
    preset.titleLabel.font = textFont;
    [preset setTitle: [[_renderer.videoControls objectAtIndex: i] objectForKey: @"display"] forState: UIControlStateNormal];
    [preset addTarget: self action: @selector(pressedVideoPreset:) forControlEvents: UIControlEventTouchDown];
    [SettingsControlsIPad addButton: preset to: enclosingControlView frame: frame];
  }
}

- (void) dealloc
{
  [_renderer release];
  [super dealloc];
}

@end
