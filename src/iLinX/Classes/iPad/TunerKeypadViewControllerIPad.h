//
//  TunerKeypadViewController.h
//  iLinX
//
//  Created by mcf on 20/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NLSourceTuner;
@class TunerViewControllerIPad;

@interface TunerKeypadViewControllerIPad : UIViewController
{
@private
  IBOutlet UITextField *_numberDisplay;
  NLSourceTuner *_tuner;
  TunerViewControllerIPad *_parentController;
  BOOL _clearNextTime;
}

- (id) initWithTuner: (NLSourceTuner *) tuner parentController: (TunerViewControllerIPad *) parentController;
- (void) clearDisplay;

- (IBAction) pressedButton: (UIButton *) button;

@end
