//
//  TunerKeypadViewController.m
//  iLinX
//
//  Created by mcf on 20/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "TunerKeypadViewController.h"
#import "TunerViewController.h"
#import "NLSourceTuner.h"

@implementation TunerKeypadViewController


- (id) initWithTuner: (NLSourceTuner *) tuner parentController: (TunerViewController *) parentController
{
  if (self = [super initWithNibName: @"TunerKeypad" bundle: nil])
  {
    _tuner = [tuner retain];
    _parentController = parentController; // Not retained, because it retains us
    [self clearDisplay];
  }
  
  return self;
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  [self clearDisplay];
}

- (void) clearDisplay
{
  _numberDisplay.text = @"";
}

- (IBAction) pressedButton: (UIButton *) button
{
  if (_clearNextTime)
  {
    _numberDisplay.text = @"";
    _clearNextTime = NO;
  }
  if (button.tag < SOURCE_TUNER_KEY_ENTER)
    _numberDisplay.text = [NSString stringWithFormat: @"%@%c", _numberDisplay.text, (char) (button.tag + '0')];
  else if (button.tag == SOURCE_TUNER_KEY_CLEAR)
    _numberDisplay.text = @"";
  else
  {
    if ((_tuner.capabilities & SOURCE_TUNER_HAS_FEEDBACK) == 0)
    {
      NSString *text = _numberDisplay.text;
    
      if ([_tuner.band isEqualToString: @"FM"])
        text = [NSString stringWithFormat: @"%@.%@", [text substringToIndex: [text length] - 1],
                [text substringFromIndex: [text length] - 1]];
      [_tuner setCaption: text];
    }
    _clearNextTime = YES;
  }

  [_tuner sendKey: button.tag];
  if (button.tag == SOURCE_TUNER_KEY_ENTER)
    [_parentController flipCurrentView: button];
}

- (void) dealloc
{
  [_tuner release];
  [_numberDisplay release];
  [super dealloc];
}


@end
