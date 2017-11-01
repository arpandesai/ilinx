//
//  SettingsControlsSL220IPad.m
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "SettingsControlsSL220IPad.h"
#import "CustomSlider.h"
#import "NLRenderer.h"

#define LABEL_FONT_SIZE 12
#define ARROW_FONT_SIZE 20

@interface SettingsControlsSL220IPad ()

- (void) addAudioControlsToView: (UIView *) view  atYOffset:(NSInteger*)yOffset;
- (void) movedBalance: (CustomSlider *) control;
- (void) movedBass: (CustomSlider *) control;
- (void) movedTreble: (CustomSlider *) control;
- (void) setBalanceTextForValue: (NSUInteger) value;
- (void) setTrebleTextForValue: (NSUInteger) value;
- (void) setBassTextForValue: (NSUInteger) value;
- (void) disableControlUpdates: (CustomSlider *) control;
- (void) enableControlUpdates: (CustomSlider *) control;

@end

@implementation SettingsControlsSL220IPad

- (void) addControlsForSection: (NSUInteger) section toView: (UIView *) view  atYOffset:(NSInteger*)yOffset
{
  if (section == 0)
    [self addAudioControlsToView: view atYOffset:yOffset];
  else
    [super addControlsForSection: section toView: view atYOffset:yOffset];
}

- (BOOL) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags
{
  if(_ignoreUpdates)
    return NO;
  
  if ((flags & NLRENDERER_TREBLE_CHANGED) != 0)
  {
    _treble.value = renderer.treble;
    [self setTrebleTextForValue: renderer.treble];
  }
  if ((flags & NLRENDERER_BASS_CHANGED) != 0)
  {
    _bass.value = renderer.bass;
    [self setBassTextForValue: renderer.bass];
  }
  if ((flags & NLRENDERER_BALANCE_CHANGED) != 0)
  {
    _balance.value = renderer.balance;
    [self setBalanceTextForValue: renderer.balance];
  }
  
  return NO;
}

- (void) addAudioControlsToView: (UIView *) view  atYOffset:(NSInteger*)yOffset;
{
  UIView *innerView = [view viewWithTag:SL220ViewTag];
  if(innerView == nil)
    return;
  
  [self hideAllAudioViewsFromView:view];
  innerView.hidden = NO;
  
  _bass = (CustomSlider*)[innerView viewWithTag:SL220BassSliderTag];
  
  if(_bass != nil)
    [_bass addTarget: self action: @selector(movedBass:) forControlEvents: UIControlEventValueChanged];
  
  _bassLabel = (UILabel*)[innerView viewWithTag:SL220BassLabelTag];
  if(_bassLabel != nil)
  {
    [self setBassTextForValue: 0];
    _bass.value = _renderer.bass;
    [self setBassTextForValue: _renderer.bass];
  }
  
  _treble = (CustomSlider*)[innerView viewWithTag:SL220TrebleSliderTag];
  
  if(_treble != nil)
    [_treble addTarget: self action: @selector(movedTreble:) forControlEvents: UIControlEventValueChanged];
  
  _trebleLabel = (UILabel*)[innerView viewWithTag:SL220TrebleLabelTag];
  if(_trebleLabel != nil)
  {
    [self setTrebleTextForValue: 0];
    _treble.value = _renderer.treble;
    [self setTrebleTextForValue: _renderer.treble];
  }
  
  _balance = (CustomSlider*)[innerView viewWithTag:SL220BalanceSliderTag];
  
  if(_balance != nil)
    [_balance addTarget: self action: @selector(movedBalance:) forControlEvents: UIControlEventValueChanged];
  
  _balanceLabel = (UILabel*)[innerView viewWithTag:SL220BalanceLabelTag];
  if(_balanceLabel != nil)
  {
    [self setBalanceTextForValue: 0];
    _balance.value = _renderer.balance;
    [self setBalanceTextForValue: _renderer.balance];
  }
  
  UILabel *balanceDown = (UILabel*)[innerView viewWithTag:SL220BalanceDownTag];
  if(balanceDown != nil)
    balanceDown.text = @"\u25c2";
  
  UILabel *balanceUp = (UILabel*)[innerView viewWithTag:SL220BalanceUpTag];
  if(balanceUp != nil)
    balanceUp.text = @"\u25b8";
  
  view.frame = CGRectMake(view.frame.origin.x,  view.frame.origin.y, view.frame.size.width, innerView.frame.origin.y + innerView.frame.size.height + 20);
  (*yOffset) += view.frame.size.height;
  
}

- (void) movedBalance: (CustomSlider *) control
{
  _renderer.balance = (NSUInteger) control.value;
  [self setBalanceTextForValue: _renderer.balance];
}

- (void) movedBass: (CustomSlider *) control
{
  _renderer.bass = (NSUInteger) control.value;
  [self setBassTextForValue: _renderer.bass];
}

- (void) movedTreble: (CustomSlider *) control
{
  _renderer.treble = (NSUInteger) control.value;
  [self setTrebleTextForValue: _renderer.treble];
}

- (void) setBalanceTextForValue: (NSUInteger) value
{
  _balanceLabel.text = [NSString stringWithFormat:
                        NSLocalizedString( @"Balance: %d", @"Title of balance audio control" ), (int) value - 50];
}

- (void) setTrebleTextForValue: (NSUInteger) value
{
  _trebleLabel.text = [NSString stringWithFormat:
                       NSLocalizedString( @"Treble: %d", @"Title of treble level audio control" ), (int) value - 50];
}

- (void) setBassTextForValue: (NSUInteger) value
{
  _bassLabel.text = [NSString stringWithFormat:
                     NSLocalizedString( @"Bass: %d", @"Title of bass level audio control" ), (int) value - 50];
}

- (void) disableControlUpdates: (CustomSlider *) control
{
  _ignoreUpdates = YES;
}

- (void) enableControlUpdates: (CustomSlider *) control
{
  _ignoreUpdates = NO;
  [self renderer: _renderer stateChanged: 0xFFFFFFFF];
}

- (void) dealloc
{
  // Doesn't deallocate controls as it doesn't allocate them - they are just pointers to
  // controls in the parent view
  [super dealloc];
}

@end
