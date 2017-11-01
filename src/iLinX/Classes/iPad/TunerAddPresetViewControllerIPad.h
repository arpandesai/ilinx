//
//  TunerAddPresetViewController.h
//  iLinX
//
//  Created by mcf on 23/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ListDataSource.h"

@class NLSourceTuner;
@class NLBrowseList;
@class TunerViewControllerIPad;

@interface TunerAddPresetViewControllerIPad : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate,
                                                            ListDataDelegate, UITextFieldDelegate>
{
@private
  TunerViewControllerIPad *_parentController;
  IBOutlet UITextField *_presetTitle;
  IBOutlet UIPickerView *_presetChoice;
  IBOutlet UINavigationBar *_navBar;
  IBOutlet UINavigationItem *_navItem;
  NLSourceTuner *_tuner;
  NLBrowseList *_presetList;
  NSString *_presetName;
  NSInteger _savedPresetIndex;
  
}

- (id) initWithTuner: (NLSourceTuner *) tuner parentController:(TunerViewControllerIPad*)parentController presetName: (NSString *) presetName;
- (IBAction) savePreset;
- (IBAction) cancel;

@end
