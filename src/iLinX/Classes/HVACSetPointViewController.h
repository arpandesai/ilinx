//
//  HVACSetPointViewController.h
//  iLinX
//
//  Created by mcf on 16/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLServiceHVAC.h"

@interface HVACSetPointViewController : UIViewController  <UIPickerViewDataSource, UIPickerViewDelegate, NLServiceHVACDelegate>
{
@private
  IBOutlet UILabel *_coolLabel;
  IBOutlet UILabel *_heatScaleLabel;
  IBOutlet UILabel *_coolScaleLabel;
  IBOutlet UIPickerView *_setPointChoice;
  NLServiceHVAC *_hvacService;
  NSInteger _heatRows;
  NSInteger _coolRows;
  CGFloat _heatSetPoint;
  CGFloat _coolSetPoint;
}

- (id) initWithHvacService: (NLServiceHVAC *) hvacService;
- (IBAction) saveSetPoint;
- (IBAction) cancel;


@end
