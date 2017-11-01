//
//  SettingsControlsNNP.m
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "SettingsControlsNNP.h"
#import "CustomSlider.h"
#import "NLRenderer.h"

#define LABEL_FONT_SIZE 12
#define ARROW_FONT_SIZE 20

@interface SettingsControlsNNP ()

- (void) addAudioControlsToView: (UIView *) view;
- (void) movedBalance: (CustomSlider *) control;
- (void) setBalanceTextForValue: (NSUInteger) value;

@end

@implementation SettingsControlsNNP

- (CGFloat) heightForSection: (NSUInteger) section
{
  if (section == 0)
    return 68.0;
  else
    return [super heightForSection: section];
}

- (void) addControlsForSection: (NSUInteger) section toView: (UIView *) view
{
  if (section == 0)
    [self addAudioControlsToView: view];
  else
    [super addControlsForSection: section toView: view];
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

- (void) addAudioControlsToView: (UIView *) view
{
  CGRect mainViewBounds = view.bounds;
  CGFloat centre = CGRectGetWidth( mainViewBounds ) / 2;
  CGFloat verticalPos = 13;
  
  if (_balanceLabel == nil)
  {
    _balanceLabel = [UILabel new];
    _balance = [CustomSlider new];
  }
  
  UILabel *balanceDown = [[UILabel new] autorelease];
  UILabel *balanceUp = [[UILabel new] autorelease];
  
  [self setBalanceTextForValue: 0];
  [self addLabel: _balanceLabel to: view position: CGPointMake( centre, verticalPos ) fontSize: LABEL_FONT_SIZE];
  
  verticalPos += _balanceLabel.frame.size.height + 2;
  balanceDown.text = @"\u25c2";
  balanceUp.text = @"\u25b8";
  [self addLabel: balanceDown to: view position: CGPointMake( 20, verticalPos ) fontSize: ARROW_FONT_SIZE + 10];
  [self addLabel: balanceUp to: view position: CGPointMake( 280, verticalPos ) fontSize: ARROW_FONT_SIZE + 10];
  
  verticalPos += 8;
  [_balance addTarget: self action: @selector(movedBalance:) forControlEvents: UIControlEventValueChanged];
  [self addSlider: _balance to: view position: CGPointMake( centre, verticalPos )];
  _balance.value = _renderer.balance;
  [self setBalanceTextForValue: _renderer.balance];
  if (_style == UIBarStyleDefault)
    _balance.tint = [UIColor whiteColor];
  else
    _balance.tint = nil;
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
  [_balanceLabel release];
  [_balance release];
  [super dealloc];
}

@end
