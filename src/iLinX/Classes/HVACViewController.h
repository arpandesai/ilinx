//
//  HVACViewController.h
//  iLinX
//
//  Created by mcf on 13/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServiceViewController.h"
#import "NLServiceHVAC.h"

@interface HVACViewController : ServiceViewController <NLServiceHVACDelegate>
{
@private
  NLServiceHVAC *_hvacService;
  NSArray *_subViews;
  UIToolbar *_controlBar;
  UISegmentedControl *_segmentedSelector;
  NSUInteger _currentSegment;
  BOOL _onScreen;
}

@end
