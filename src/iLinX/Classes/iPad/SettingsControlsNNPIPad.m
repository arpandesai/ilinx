//
//  SettingsControlsNNPIPad.m
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "SettingsControlsNNPIPad.h"
#import "CustomSlider.h"
#import "NLRenderer.h"

#define LABEL_FONT_SIZE 12
#define ARROW_FONT_SIZE 20

@interface SettingsControlsNNPIPad ()

- (void) addAudioControlsToView: (UIView *) view  atYOffset:(NSInteger*)yOffset;
- (void) movedBalance: (CustomSlider *) control;
- (void) setBalanceTextForValue: (NSUInteger) value;

@end

@implementation SettingsControlsNNPIPad

- (void) addControlsForSection: (NSUInteger) section toView: (UIView *) view  atYOffset:(NSInteger*)yOffset
{
  if (section == 0)
    [self addAudioControlsToView: view atYOffset:yOffset];
  else
    [super addControlsForSection: section toView: view atYOffset:yOffset];
}

- (BOOL) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags
{
  if ((flags & NLRENDERER_BALANCE_CHANGED) != 0)
  {
    _balance.value = renderer.balance;
    [self setBalanceTextForValue: renderer.balance];
  }
  
  return NO;
}

- (void) addAudioControlsToView: (UIView *) view  atYOffset:(NSInteger*)yOffset
{
  UIView *innerView = [view viewWithTag: NNPViewTag];
  if(innerView == nil)
    return;
  
  [self hideAllAudioViewsFromView:view];
  innerView.hidden = NO;
  
  _balance = (CustomSlider *) [innerView viewWithTag: NNPBalanceSliderTag];
  
  if (_balance != nil)
    [_balance addTarget: self action: @selector(movedBalance:) forControlEvents: UIControlEventValueChanged];
  
  _balanceLabel = (UILabel *) [innerView viewWithTag: NNPBalanceLabelTag];
  if (_balanceLabel != nil)
  {
    [self setBalanceTextForValue: 0];
    _balance.value = _renderer.balance;
    [self setBalanceTextForValue: _renderer.balance];
  }
  
  UILabel *balanceDown = (UILabel *) [innerView viewWithTag: NNPBalanceDownTag];
  UILabel *balanceUp = (UILabel *) [innerView viewWithTag: NNPBalanceUpTag];

  if (balanceDown != nil)
    balanceDown.text = @"\u25c2";
  if (balanceUp != nil)
    balanceUp.text = @"\u25b8";
  
  view.frame = CGRectMake( view.frame.origin.x, view.frame.origin.y, view.frame.size.width, 
                          innerView.frame.origin.y + innerView.frame.size.height + 20 );
  (*yOffset) += view.frame.size.height;
}

- (void) movedBalance: (CustomSlider *) control
{
  _renderer.balance = (NSUInteger) control.value;
  [self setBalanceTextForValue: _renderer.balance];
}

- (void) setBalanceTextForValue: (NSUInteger) value
{
  _balanceLabel.text = [NSString stringWithFormat:
                        NSLocalizedString( @"Balance: %d", @"Title of balance audio control" ), (int) value - 50];
}

- (void) dealloc
{
  // Doesn't deallocate controls as it doesn't allocate them - they are just pointers to
  // controls in the parent view
  [super dealloc];
}

@end
