//
//  LightsPageViewController.h
//  iLinX
//
//  Created by mcf on 29/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLServiceGeneric.h"

@interface LightsPageViewController : UIViewController <NLServiceGenericDelegate>
{
@private
  NLServiceGeneric *_lightsService;
  NSUInteger _offset;
  NSUInteger _count;
}

- (id) initWithService: (NLServiceGeneric *) lightsService offset: (NSUInteger) offset count: (NSUInteger) count;

@end
