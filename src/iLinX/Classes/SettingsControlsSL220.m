//
//  SettingsControlsSL220.m
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "SettingsControlsSL220.h"
#import "CustomSlider.h"
#import "NLRenderer.h"

#define LABEL_FONT_SIZE 12
#define ARROW_FONT_SIZE 20

@interface SettingsControlsSL220 ()

- (void) addAudioControlsToView: (UIView *) view;
- (void) movedBalance: (CustomSlider *) control;
- (void) movedBass: (CustomSlider *) control;
- (void) movedTreble: (CustomSlider *) control;
- (void) setBalanceTextForValue: (NSUInteger) value;
- (void) setTrebleTextForValue: (NSUInteger) value;
- (void) setBassTextForValue: (NSUInteger) value;
- (void) disableControlUpdates: (CustomSlider *) control;
- (void) enableControlUpdates: (CustomSlider *) control;

@end

@implementation SettingsControlsSL220

- (CGFloat) heightForSection: (NSUInteger) section
{
  if (section == 0)
    return 202.0;
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
  flags &= ~_ignoreFlags;

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

- (void) addAudioControlsToView: (UIView *) view
{
  CGRect mainViewBounds = view.bounds;
  CGFloat centre = CGRectGetWidth( mainViewBounds ) / 2;
  CGFloat verticalPos = 13;
  
  if (_bassLabel == nil)
  {
    _bassLabel = [UILabel new];
    _bass = [CustomSlider new];
    _trebleLabel = [UILabel new];
    _treble = [CustomSlider new];
    _balanceLabel = [UILabel new];
    _balance = [CustomSlider new];
  }
  
  UILabel *bassDown = [[UILabel new] autorelease];
  UILabel *bassUp = [[UILabel new] autorelease];
  UILabel *trebleDown = [[UILabel new] autorelease];
  UILabel *trebleUp = [[UILabel new] autorelease];
  UILabel *balanceDown = [[UILabel new] autorelease];
  UILabel *balanceUp = [[UILabel new] autorelease];
  UIColor *tint;
  
  if (_style == UIBarStyleDefault)
    tint = [UIColor whiteColor];
  else
    tint = nil;
  _bass.tint = tint;
  _treble.tint = tint;
  _balance.tint = tint;
    
  [self setBassTextForValue: 0];
  [self addLabel: _bassLabel to: view position: CGPointMake( centre, verticalPos ) fontSize: LABEL_FONT_SIZE];
  
  verticalPos += _bassLabel.frame.size.height + 7;
  bassDown.text = @"-";
  bassUp.text = @"+";
  [self addLabel: bassDown to: view position: CGPointMake( 20, verticalPos ) fontSize: ARROW_FONT_SIZE];
  [self addLabel: bassUp to: view position: CGPointMake( 280, verticalPos ) fontSize: ARROW_FONT_SIZE];
  
  verticalPos += 3;
  [_bass addTarget: self action: @selector(movedBass:) forControlEvents: UIControlEventValueChanged];
  [_bass addTarget: self action: @selector(disableControlUpdates:) forControlEvents: UIControlEventTouchDown];
  [_bass addTarget: self action: @selector(enableControlUpdates:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
  [self addSlider: _bass to: view position: CGPointMake( centre, verticalPos )];
  _bass.value = _renderer.bass;
  _bass.tag = NLRENDERER_BASS_CHANGED;
  [self setBassTextForValue: _renderer.bass];
  
  verticalPos += _bass.frame.size.height + 20;
  [self setTrebleTextForValue: 0];
  [self addLabel: _trebleLabel to: view position: CGPointMake( centre, verticalPos ) fontSize: LABEL_FONT_SIZE];
  
  verticalPos += _trebleLabel.frame.size.height + 7;
  trebleDown.text = @"-";
  trebleUp.text = @"+";
  [self addLabel: trebleDown to: view position: CGPointMake( 20, verticalPos ) fontSize: ARROW_FONT_SIZE];
  [self addLabel: trebleUp to: view position: CGPointMake( 280, verticalPos ) fontSize: ARROW_FONT_SIZE];
  
  verticalPos += 3;
  [_treble addTarget: self action: @selector(movedTreble:) forControlEvents: UIControlEventValueChanged];
  [_treble addTarget: self action: @selector(disableControlUpdates:) forControlEvents: UIControlEventTouchDown];
  [_treble addTarget: self action: @selector(enableControlUpdates:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
  [self addSlider: _treble to: view
         position: CGPointMake( centre, _trebleLabel.frame.origin.y + _trebleLabel.frame.size.height + 10 )];
  _treble.value = _renderer.treble;
  _treble.tag = NLRENDERER_TREBLE_CHANGED;
  [self setTrebleTextForValue: _renderer.treble];
  
  verticalPos += _treble.frame.size.height + 20;
  [self setBalanceTextForValue: 0];
  [self addLabel: _balanceLabel to: view position: CGPointMake( centre, verticalPos ) fontSize: LABEL_FONT_SIZE];
  
  verticalPos += _balanceLabel.frame.size.height + 2;
  balanceDown.text = @"\u25c2";
  balanceUp.text = @"\u25b8";
  [self addLabel: balanceDown to: view position: CGPointMake( 20, verticalPos ) fontSize: ARROW_FONT_SIZE + 10];
  [self addLabel: balanceUp to: view position: CGPointMake( 280, verticalPos ) fontSize: ARROW_FONT_SIZE + 10];
  
  verticalPos += 8;
  [_balance addTarget: self action: @selector(movedBalance:) forControlEvents: UIControlEventValueChanged];
  [_balance addTarget: self action: @selector(disableControlUpdates:) forControlEvents: UIControlEventTouchDown];
  [_balance addTarget: self action: @selector(enableControlUpdates:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
  [self addSlider: _balance to: view position: CGPointMake( centre, verticalPos )];
  _balance.value = _renderer.balance;
  _balance.tag = NLRENDERER_BALANCE_CHANGED;
  [self setBalanceTextForValue: _renderer.balance];
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
  _ignoreFlags |= control.tag;
}

- (void) enableControlUpdates: (CustomSlider *) control
{
  _ignoreFlags &= ~control.tag;
  [self renderer: _renderer stateChanged: control.tag];
}

- (void) dealloc
{
  [_bassLabel release];
  [_bass release];
  [_trebleLabel release];
  [_treble release];
  [_balanceLabel release];
  [_balance release];
  [super dealloc];
}

@end
