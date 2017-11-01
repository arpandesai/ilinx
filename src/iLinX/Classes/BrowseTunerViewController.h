//
//  BrowseTunerViewController.h
//  iLinX
//
//  Created by mcf on 23/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BrowseViewController.h"
#import "NLSourceTuner.h"

@interface BrowseTunerViewController : BrowseViewController <UIActionSheetDelegate, NLSourceTunerDelegate>
{
@private
  NLSourceTuner *_tuner;
  NSArray *_basicButtonSet;
  BOOL _cancelPresetsAlert;
  BOOL _wasVisible;
}

@end
