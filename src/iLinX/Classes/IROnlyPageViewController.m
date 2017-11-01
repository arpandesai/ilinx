//
//  IROnlyPageViewController.m
//  iLinX
//
//  Created by mcf on 24/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "IROnlyPageViewController.h"
#import "NLSourceIROnly.h"

@implementation IROnlyPageViewController

- (id) initWithNibName: (NSString *) nibName irOnlySource: (NLSourceIROnly *) irOnlySource
{
  if (self = [super initWithNibName: nibName bundle: nil])
    _irOnlySource = irOnlySource;
  
  return self;
}

- (void) viewDidLoad
{
  [super viewDidLoad];

  NSString *redText = _irOnlySource.redText;
  NSString *yellowText = _irOnlySource.yellowText;
  NSString *blueText = _irOnlySource.blueText;
  NSString *greenText = _irOnlySource.greenText;
  
  if (_redButton != nil && redText != nil)
  {
    [_redButton setTitle: redText forState: UIControlStateNormal];
    [_redButton setTitle: redText forState: UIControlStateHighlighted];
  }
  
  if (_yellowButton != nil && yellowText != nil)
  {
    [_yellowButton setTitle: yellowText forState: UIControlStateNormal];
    [_yellowButton setTitle: yellowText forState: UIControlStateHighlighted];
  }
  
  if (_blueButton != nil && blueText != nil)
  {
    [_blueButton setTitle: blueText forState: UIControlStateNormal];
    [_blueButton setTitle: blueText forState: UIControlStateHighlighted];
  }
  
  if (_greenButton != nil && greenText != nil)
  {
    [_greenButton setTitle: greenText forState: UIControlStateNormal];
    [_greenButton setTitle: greenText forState: UIControlStateHighlighted];
  }
}

- (IBAction) pressedButton: (UIButton *) button
{
  [_irOnlySource sendKey: button.tag];
}

- (IBAction) releasedButton: (UIButton *) button
{
}

- (void) dealloc
{
  [_redButton release];
  [_yellowButton release];
  [_blueButton release];
  [_greenButton release];
  [super dealloc];
}

@end
