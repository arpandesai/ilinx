//
//  SettingsControlsSL250IPad.m
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "SettingsControlsSL250IPad.h"
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

@interface SettingsControlsSL250IPad ()

- (void) addAudioControlsToView: (UIView *) view  atYOffset:(NSInteger*)yOffset;
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

@implementation SettingsControlsSL250IPad

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

- (void) addAudioControlsToView: (UIView *) view atYOffset:(NSInteger*)yOffset
{	
	UIView *innerView = [view viewWithTag:SL250ViewTag];
	if(innerView == nil)
		return;

	[self hideAllAudioViewsFromView:view];
	innerView.hidden = NO;

	UIButton *restore = (UIButton*)[innerView viewWithTag:restoreButtonTag];
	if(restore != nil)
	{
		[restore setTitle: NSLocalizedString( @"Restore", @"Title of button to restore default audio settings" ) forState: UIControlStateNormal]; 
		[restore addTarget: self action: @selector(pressedRestore:) forControlEvents: UIControlEventTouchDown];
		[restore setBackgroundImage:[restore backgroundImageForState:UIControlStateNormal] forState:UIControlStateNormal];
		[restore setBackgroundImage:[restore backgroundImageForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
	}
	
	_balance = (CustomSlider*)[innerView viewWithTag:balanceSliderTag];
	if(_balance != nil)
	{
		[_balance addTarget: self action: @selector(movedBalance:) forControlEvents: UIControlEventValueChanged];
		[_balance addTarget: self action: @selector(disableControlUpdates:) forControlEvents: UIControlEventTouchDown];
		[_balance addTarget: self action: @selector(enableControlUpdates:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
	}

	_balanceLabel = (UILabel*)[innerView viewWithTag:balanceLabelTag];
	if(_balanceLabel != nil)
	{
		[self setBalanceTextForValue: 0];
		_balance.value = _renderer.balance;
		[self setBalanceTextForValue: _renderer.balance];
	}
	
	UILabel *balanceDown = (UILabel*)[innerView viewWithTag:balanceDownTag];
	if(balanceDown != nil)
		balanceDown.text = @"\u25c2";

	UILabel *balanceUp = (UILabel*)[innerView viewWithTag:balanceUpTag];
	if(balanceUp != nil)
		balanceUp.text = @"\u25b8";

	UILabel *band1Title = (UILabel*)[innerView viewWithTag:band1TitleTag];
	if(band1Title != nil)
		band1Title.text = NSLocalizedString( @"80Hz", @"Title of 80Hz equalizer band slider" );
	UILabel *band2Title = (UILabel*)[innerView viewWithTag:band2TitleTag];
	if(band2Title != nil)
		band2Title.text = NSLocalizedString( @"400Hz", @"Title of 400Hz equalizer band slider" );
	UILabel *band3Title = (UILabel*)[innerView viewWithTag:band3TitleTag];
	if(band3Title != nil)
		band3Title.text = NSLocalizedString( @"2KHz", @"Title of 2KHz equalizer band slider" );
	UILabel *band4Title = (UILabel*)[innerView viewWithTag:band4TitleTag];
	if(band4Title != nil)
		band4Title.text = NSLocalizedString( @"8KHz", @"Title of 8KHz equalizer band slider" );
	
	_band1 = (CustomSlider*)[innerView viewWithTag:band1SliderTag];
	if(_band1 != nil)
	{
		[_band1 addTarget: self action: @selector(movedBand1:) forControlEvents: UIControlEventValueChanged];
		[_band1 addTarget: self action: @selector(disableControlUpdates:) forControlEvents: UIControlEventTouchDown];
		[_band1 addTarget: self action: @selector(enableControlUpdates:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
		_band1.value = _renderer.band1;

		_band1.transform = CGAffineTransformIdentity;
		CGRect frame = _band1.frame;
		_band1.transform = CGAffineTransformMake( 0, -1, 1, 0,
												 (frame.size.height - frame.size.width) / 2,
												 (frame.size.width - frame.size.height) / 2 );
		
		_band1.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	}		

	_band2 = (CustomSlider*)[innerView viewWithTag:band2SliderTag];
	if(_band2 != nil)
	{
		[_band2 addTarget: self action: @selector(movedBand2:) forControlEvents: UIControlEventValueChanged];
		[_band2 addTarget: self action: @selector(disableControlUpdates:) forControlEvents: UIControlEventTouchDown];
		[_band2 addTarget: self action: @selector(enableControlUpdates:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
		_band2.value = _renderer.band2;
		
		_band2.transform = CGAffineTransformIdentity;
		CGRect frame = _band2.frame;
		_band2.transform = CGAffineTransformMake( 0, -1, 1, 0,
												 (frame.size.height - frame.size.width) / 2,
												 (frame.size.width - frame.size.height) / 2 );
		
		_band2.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	}		

	_band3 = (CustomSlider*)[innerView viewWithTag:band3SliderTag];
	if(_band3 != nil)
	{
		[_band3 addTarget: self action: @selector(movedBand3:) forControlEvents: UIControlEventValueChanged];
		[_band3 addTarget: self action: @selector(disableControlUpdates:) forControlEvents: UIControlEventTouchDown];
		[_band3 addTarget: self action: @selector(enableControlUpdates:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
		_band3.value = _renderer.band3;
		
		_band3.transform = CGAffineTransformIdentity;
		CGRect frame = _band3.frame;
		_band3.transform = CGAffineTransformMake( 0, -1, 1, 0,
												 (frame.size.height - frame.size.width) / 2,
												 (frame.size.width - frame.size.height) / 2 );
		
		_band3.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	}		

	_band4 = (CustomSlider*)[innerView viewWithTag:band4SliderTag];
	if(_band4 != nil)
	{
		[_band4 addTarget: self action: @selector(movedBand4:) forControlEvents: UIControlEventValueChanged];
		[_band4 addTarget: self action: @selector(disableControlUpdates:) forControlEvents: UIControlEventTouchDown];
		[_band4 addTarget: self action: @selector(enableControlUpdates:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
		_band4.value = _renderer.band4;
		
		_band4.transform = CGAffineTransformIdentity;
		CGRect frame = _band4.frame;
		_band4.transform = CGAffineTransformMake( 0, -1, 1, 0,
												 (frame.size.height - frame.size.width) / 2,
												 (frame.size.width - frame.size.height) / 2 );
		
		_band4.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	}		

	_band1Label = (UILabel*)[innerView viewWithTag:band1ValueTag];
	if(_band1Label != nil)
		_band1Label.text = [NSString stringWithFormat: @"%d", (int) _renderer.band1 - 50];
	_band2Label = (UILabel*)[innerView viewWithTag:band2ValueTag];
	if(_band2Label != nil)
		_band2Label.text = [NSString stringWithFormat: @"%d", (int) _renderer.band2 - 50];
	_band3Label = (UILabel*)[innerView viewWithTag:band3ValueTag];
	if(_band3Label != nil)
		_band3Label.text = [NSString stringWithFormat: @"%d", (int) _renderer.band3 - 50];
	_band4Label = (UILabel*)[innerView viewWithTag:band4ValueTag];
	if(_band4Label != nil)
		_band4Label.text = [NSString stringWithFormat: @"%d", (int) _renderer.band4 - 50];
	
	UIView *presetView = [innerView viewWithTag:presetViewTag];
	if(presetView == 0)
		return;

	NSInteger buttonHeight = 50;
	NSInteger buttonWidth = ((presetView.frame.size.width - (12 * (BUTTONS_PER_ROW - 1))) / BUTTONS_PER_ROW);
	int i;
	for (i = 0; i < sizeof(PRESET_COMMANDS)/sizeof(PRESET_COMMANDS[0]); ++i)
	{
		UIButton *template = (UIButton*)[innerView viewWithTag:presetButtonTemplateTag];
		if(template == nil)
			break;
		
		UIButton *preset = [UIButton buttonWithType:template.buttonType];
		preset.backgroundColor = template.backgroundColor;
		preset.titleLabel.font = template.titleLabel.font;
		[preset setBackgroundImage:[template backgroundImageForState:UIControlStateNormal] forState:UIControlStateNormal];
		[preset setBackgroundImage:[template backgroundImageForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
		[preset setTitleColor:[template titleColorForState:UIControlStateNormal] forState:UIControlStateNormal];
		
		CGRect frame = CGRectMake( 9 + ((i % BUTTONS_PER_ROW) * (buttonWidth + 8)), 10 + ((i / BUTTONS_PER_ROW) * (buttonHeight + 9)),
								  buttonWidth, buttonHeight );
		
		preset.tag = PRESET_COMMANDS[i];
		[preset setTitle: NSLocalizedString( PRESET_NAMES[i], @"Name of SL250 preset" ) forState: UIControlStateNormal];
		[preset addTarget: self action: @selector(pressedPreset:) forControlEvents: UIControlEventTouchDown];
		[SettingsControlsIPad addButton: preset to: presetView frame: frame];
  }
	
	presetView.frame = CGRectMake(presetView.frame.origin.x, presetView.frame.origin.y, presetView.frame.size.width, ((buttonHeight + 9) * ((i/BUTTONS_PER_ROW) + 1)) + 20);
	view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, presetView.frame.origin.y + presetView.frame.size.height);
	(*yOffset) += view.frame.size.height;
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
