//
//  HVACButtonsPageViewController.h
//  iLinX
//
//  Created by mcf on 13/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLServiceHVAC.h"
#import "XIBViewController.h"

@interface HVACButtonsPageViewController : XIBViewController <NLServiceHVACDelegate>
{
@private
  NLServiceHVAC *_hvacService;
  NSUInteger _controlMode;
  NSUInteger _offset;
  NSUInteger _count;
  NSMutableArray *_buttonHelpers;
  
}

- (id) initWithService: (NLServiceHVAC *) hvacService controlMode: (NSUInteger) controlMode
                offset: (NSUInteger) offset count: (NSUInteger) count;

@end
