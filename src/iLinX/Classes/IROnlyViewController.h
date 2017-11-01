//
//  IROnlyViewController.h
//  iLinX
//
//  Created by mcf on 24/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVViewController.h"
#import "NLSourceIROnly.h"

@interface IROnlyViewController : AVViewController <NLSourceIROnlyDelegate>
{
@private
  NLSourceIROnly *_irOnlySource;
  NSArray *_subViews;
  UIToolbar *_controlBar;
  UISegmentedControl *_segmentedSelector;
  NSUInteger _currentSegment;
}

@end
