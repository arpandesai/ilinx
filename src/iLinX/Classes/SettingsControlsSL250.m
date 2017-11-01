//
//  SettingsControlsSL250.m
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "SettingsControlsSL250.h"
#import "CustomSlider.h"
#import "NLRenderer.h"
#import "StandardPalette.h"

#define LABEL_FONT_SIZE 12
#define ARROW_FONT_SIZE 20

static NSInteger PRESET_COMMANDS[] =
{
  16, -1, 0, 1, 2,
  3, 4, 5, 6, 7,
  8, 9, 10, 11, 12
};
static NSString *PRESET_NAMES[] =
{
  @"Loudness", @"Custom", @"Flat", @"Rock", @"Soft Rock",
  @"Jazz", @"Classical", @"Dance", @"Pop", @"Soft",
  @"Hard", @"Party", @"Vocal", @"Hip-Hop", @"Dialog"
};

@interface SettingsControlsSL250 ()

- (void) addAudioControlsToView: (UIView *) view;
- (void) movedBalance: (CustomSlider *) control;
- (void) movedBand1: (CustomSlider *) control;
- (void) movedBand2: (CustomSlider *) control;
- (void) movedBand3: (CustomSlider *) control;
- (void) movedBand4: (CustomSlider *) control;
- (void) pressedRestore: (UIButton *) control;
- (void) pressedPreset: (UIButton *) control;
- (void) setBalanceTextForValue: (NSUInteger) value;
- (void) disableControlUpdates: (CustomSlider *) control;
- (void) enableControlUpdates: (CustomSlider *) control;

@end

@implementation SettingsControlsSL250

- (CGFloat) heightForSection: (NSUInteger) section
{
  if (section == 0)
    return 495.0;
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

  if ((flags & NLRENDERER_BALANCE_CHANGED) != 0)
  {
    _balance.value = renderer.balance;
    [self setBalanceTextForValue: renderer.balance];
  }
  if ((flags & NLRENDERER_BAND1_CHANGED) != 0)
  {
    _band1.value = renderer.band1;
    _band1Label.text = [NSString stringWithFormat: @"%d", renderer.band1 - 50];
  }
  if ((flags & NLRENDERER_BAND2_CHANGED) != 0)
  {
    _band2.value = renderer.band2;
    _band2Label.text = [NSString stringWithFormat: @"%d", renderer.band2 - 50];
  }
  if ((flags & NLRENDERER_BAND3_CHANGED) != 0)
  {
    _band3.value = renderer.band3;
    _band3Label.text = [NSString stringWithFormat: @"%d", renderer.band3 - 50];
  }
  if ((flags & NLRENDERER_BAND4_CHANGED) != 0)
  {
    _band4.value = renderer.band4;
    _band4Label.text = [NSString stringWithFormat: @"%d", renderer.band4 - 50];
  }
  
  return NO;
}

- (void) addAudioControlsToView: (UIView *) view
{
  CGRect mainViewBounds = view.bounds;
  CGFloat centre = CGRectGetWidth( mainViewBounds ) / 2;
  CGFloat verticalPos = 13;
  NSUInteger i;
  
  if (_balanceLabel == nil)
  {
    _balanceLabel = [UILabel new];
    _balance = [CustomSlider new];
    _band1Label = [UILabel new];
    _band1 = [CustomSlider new];
    _band2Label = [UILabel new];
    _band2 = [CustomSlider new];
    _band3Label = [UILabel new];
    _band3 = [CustomSlider new];
    _band4Label = [UILabel new];
    _band4 = [CustomSlider new];
  }
  
  UILabel *balanceDown = [[UILabel new] autorelease];
  UILabel *balanceUp = [[UILabel new] autorelease];
  UILabel *band1Title = [[UILabel new] autorelease];
  UILabel *band2Title = [[UILabel new] autorelease];
  UILabel *band3Title = [[UILabel new] autorelease];
  UILabel *band4Title = [[UILabel new] autorelease];
  UIColor *tint;
  
  if (_style == UIBarStyleDefault)
    tint = [UIColor whiteColor];
  else
    tint = nil;

  _band1.tint = tint;
  _band2.tint = tint;
  _band3.tint = tint;
  _band4.tint = tint;
  _balance.tint = tint;
  
  // Restore default settings button
  UIButton *restore = [SettingsControls standardButtonWithStyle: _style];
  
  [restore setTitle: NSLocalizedString( @"Restore", @"Title of button to restore default audio settings" ) forState: UIControlStateNormal]; 
  [restore addTarget: self action: @selector(pressedRestore:) forControlEvents: UIControlEventTouchDown];
  [SettingsControls addButton: restore to: view frame: CGRectMake( 9, 10, 89, 37 )];
  
  balanceDown.text = @"\u25c2";
  balanceUp.text = @"\u25b8";
  [self addLabel: balanceDown to: view position: CGPointMake( 118, verticalPos ) fontSize: ARROW_FONT_SIZE + 10];
  [self addLabel: balanceUp to: view position: CGPointMake( 285, verticalPos ) fontSize: ARROW_FONT_SIZE + 10];

  verticalPos += 8;
  [_balance addTarget: self action: @selector(movedBalance:) forControlEvents: UIControlEventValueChanged];
  [_balance addTarget: self action: @selector(disableControlUpdates:) forControlEvents: UIControlEventTouchDown];
  [_balance addTarget: self action: @selector(enableControlUpdates:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
  [self addSlider: _balance to: view position: CGPointMake( centre + 54, verticalPos )];
  _balance.frame = CGRectMake( 130, verticalPos, 142, _balance.frame.size.height );

  verticalPos += _balance.frame.size.height + 5;
  [self setBalanceTextForValue: 0];
  [self addLabel: _balanceLabel to: view position: CGPointMake( 199, verticalPos ) fontSize: LABEL_FONT_SIZE];
  _balance.value = _renderer.balance;
  _balance.tag = NLRENDERER_BALANCE_CHANGED;
  [self setBalanceTextForValue: _renderer.balance];
  
  verticalPos += _balanceLabel.frame.size.height + 10;
  band1Title.text = NSLocalizedString( @"80Hz", @"Title of 80Hz equalizer band slider" );
  [self addLabel: band1Title to: view position: CGPointMake( 39, verticalPos ) fontSize: LABEL_FONT_SIZE];
  band2Title.text = NSLocalizedString( @"400Hz", @"Title of 400Hz equalizer band slider" );
  [self addLabel: band2Title to: view position: CGPointMake( 113, verticalPos ) fontSize: LABEL_FONT_SIZE];
  band3Title.text = NSLocalizedString( @"2KHz", @"Title of 2KHz equalizer band slider" );
  [self addLabel: band3Title to: view position: CGPointMake( 187, verticalPos ) fontSize: LABEL_FONT_SIZE];
  band4Title.text = NSLocalizedString( @"8KHz", @"Title of 8KHz equalizer band slider" );
  [self addLabel: band4Title to: view position: CGPointMake( 261, verticalPos ) fontSize: LABEL_FONT_SIZE];
  
  verticalPos += band4Title.frame.size.height + 3;
  [_band1 addTarget: self action: @selector(movedBand1:) forControlEvents: UIControlEventValueChanged];
  [_band1 addTarget: self action: @selector(disableControlUpdates:) forControlEvents: UIControlEventTouchDown];
  [_band1 addTarget: self action: @selector(enableControlUpdates:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
  [self addVerticalSlider: _band1 to: view frame: CGRectMake( 29, verticalPos, 120, 20 )];
  _band1.value = _renderer.band1;
  _band1.tag = NLRENDERER_BAND1_CHANGED;

  [_band2 addTarget: self action: @selector(movedBand2:) forControlEvents: UIControlEventValueChanged];
  [_band2 addTarget: self action: @selector(disableControlUpdates:) forControlEvents: UIControlEventTouchDown];
  [_band2 addTarget: self action: @selector(enableControlUpdates:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
  [self addVerticalSlider: _band2 to: view frame: CGRectMake( 103, verticalPos, 120, 20 )];
  _band2.value = _renderer.band2;
  _band2.tag = NLRENDERER_BAND2_CHANGED;
  
  [_band3 addTarget: self action: @selector(movedBand3:) forControlEvents: UIControlEventValueChanged];
  [_band3 addTarget: self action: @selector(disableControlUpdates:) forControlEvents: UIControlEventTouchDown];
  [_band3 addTarget: self action: @selector(enableControlUpdates:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
  [self addVerticalSlider: _band3 to: view frame: CGRectMake( 177, verticalPos, 120, 20 )];
  _band3.value = _renderer.band3;
  _band3.tag = NLRENDERER_BAND3_CHANGED;
  
  [_band4 addTarget: self action: @selector(movedBand4:) forControlEvents: UIControlEventValueChanged];
  [_band4 addTarget: self action: @selector(disableControlUpdates:) forControlEvents: UIControlEventTouchDown];
  [_band4 addTarget: self action: @selector(enableControlUpdates:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
  [self addVerticalSlider: _band4 to: view frame: CGRectMake( 251, verticalPos, 120, 20 )];
  _band4.value = _renderer.band4;
  _band4.tag = NLRENDERER_BAND4_CHANGED;

  verticalPos += 123;
  _band1Label.text = @"888";
  [self addLabel: _band1Label to: view position: CGPointMake( 39, verticalPos ) fontSize: LABEL_FONT_SIZE];
  _band1Label.text = [NSString stringWithFormat: @"%d", (int) _renderer.band1 - 50];
  _band2Label.text = @"888";
  [self addLabel: _band2Label to: view position: CGPointMake( 113, verticalPos ) fontSize: LABEL_FONT_SIZE];
  _band2Label.text = [NSString stringWithFormat: @"%d", (int) _renderer.band2 - 50];
  _band3Label.text = @"888";
  [self addLabel: _band3Label to: view position: CGPointMake( 187, verticalPos ) fontSize: LABEL_FONT_SIZE];
  _band3Label.text = [NSString stringWithFormat: @"%d", (int) _renderer.band3 - 50];
  _band4Label.text = @"888";
  [self addLabel: _band4Label to: view position: CGPointMake( 261, verticalPos ) fontSize: LABEL_FONT_SIZE];
  _band4Label.text = [NSString stringWithFormat: @"%d", (int) _renderer.band4 - 50];
  
  verticalPos += _band4Label.frame.size.height + 9;
  
  UILabel *presetsTitle = [[UILabel new] autorelease];
  
  presetsTitle.text = NSLocalizedString( @"Presets", @"Title of presets section of SL250 audio settings" );
  [self addLabel: presetsTitle to: view position: CGPointMake( 150, verticalPos ) fontSize: [UIFont buttonFontSize]];
  
  verticalPos += presetsTitle.frame.size.height + 5;
  
  for (i = 0; i < sizeof(PRESET_COMMANDS)/sizeof(PRESET_COMMANDS[0]); ++i)
  {
    UIButton *preset = [SettingsControls standardButtonWithStyle: _style];
    
    preset.tag = PRESET_COMMANDS[i];
    [preset setTitle: NSLocalizedString( PRESET_NAMES[i], @"Name of SL250 preset" ) forState: UIControlStateNormal];
    [preset addTarget: self action: @selector(pressedPreset:) forControlEvents: UIControlEventTouchDown];
    [SettingsControls addButton: preset to: view 
                          frame: CGRectMake( 9 + ((i % 3) * 96) + (((i % 3) == 1) ? 1 : 0), 
                                            verticalPos + ((i / 3) * 46), ((i % 3) == 1) ? 88 : 89, 37 )];
  }
}

- (void) movedBalance: (CustomSlider *) control
{
  _renderer.balance = (NSUInteger) control.value;
  [self setBalanceTextForValue: _renderer.balance];
}

- (void) movedBand1: (CustomSlider *) control
{
  _renderer.band1 = (NSUInteger) control.value;
  _band1Label.text = [NSString stringWithFormat: @"%d", (int) _renderer.band1 - 50];
}

- (void) movedBand2: (CustomSlider *) control
{
  _renderer.band2 = (NSUInteger) control.value;
  _band2Label.text = [NSString stringWithFormat: @"%d", (int) _renderer.band2 - 50];
}

- (void) movedBand3: (CustomSlider *) control
{
  _renderer.band3 = (NSUInteger) control.value;
  _band3Label.text = [NSString stringWithFormat: @"%d", (int) _renderer.band3 - 50];
}

- (void) movedBand4: (CustomSlider *) control
{
  _renderer.band4 = (NSUInteger) control.value;
  _band4Label.text = [NSString stringWithFormat: @"%d", (int) _renderer.band4 - 50];
}

- (void) pressedRestore: (UIButton *) control
{
  _renderer.band1 = NLRENDERER_DEFAULT_VALUE;
  _renderer.band2 = NLRENDERER_DEFAULT_VALUE;
  _renderer.band3 = NLRENDERER_DEFAULT_VALUE;
  _renderer.band4 = NLRENDERER_DEFAULT_VALUE;
}

- (void) pressedPreset: (UIButton *) control
{
  _renderer.loud = control.tag;
}

- (void) setBalanceTextForValue: (NSUInteger) value
{
  _balanceLabel.text = [NSString stringWithFormat:
                        NSLocalizedString( @"Balance: %d", @"Title of balance audio control" ), (int) value - 50];
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
  [_balanceLabel release];
  [_balance release];
  [_band1Label release];
  [_band1 release];
  [_band2Label release];
  [_band2 release];
  [_band3Label release];
  [_band3 release];
  [_band4Label release];
  [_band4 release];
  [super dealloc];
}

@end
