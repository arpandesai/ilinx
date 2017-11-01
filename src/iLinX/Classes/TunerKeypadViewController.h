//
//  TunerKeypadViewController.h
//  iLinX
//
//  Created by mcf on 20/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XIBViewController.h"

@class NLSourceTuner;
@class TunerViewController;

@interface TunerKeypadViewController : XIBViewController
{
@private
  IBOutlet UITextField *_numberDisplay;
  NLSourceTuner *_tuner;
  TunerViewController *_parentController;
  BOOL _clearNextTime;
}

- (id) initWithTuner: (NLSourceTuner *) tuner parentController: (TunerViewController *) parentController;
- (void) clearDisplay;

- (IBAction) pressedButton: (UIButton *) button;

@end
