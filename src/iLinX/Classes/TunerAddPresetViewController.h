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

@interface TunerAddPresetViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate,
                                                            ListDataDelegate, UITextFieldDelegate>
{
@private
  IBOutlet UITextField *_presetTitle;
  IBOutlet UIPickerView *_presetChoice;
  IBOutlet UINavigationBar *_navBar;
  IBOutlet UINavigationItem *_navItem;
  NLSourceTuner *_tuner;
  NLBrowseList *_presetList;
  NSString *_presetName;
  NSInteger _savedPresetIndex;
  
}

- (id) initWithTuner: (NLSourceTuner *) tuner presetName: (NSString *) presetName;
- (IBAction) savePreset;
- (IBAction) cancel;

@end
