//
//  GenericPageViewController.h
//  iLinX
//
//  Created by mcf on 29/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLServiceGeneric.h"
#import "XIBViewController.h"

@interface GenericPageViewController : XIBViewController <NLServiceGenericDelegate>
{
@private
  NLServiceGeneric *_genericService;
  NSUInteger _offset;
  NSUInteger _count;
  NSMutableArray *_buttonHelpers;
}

- (id) initWithService: (NLServiceGeneric *) genericService offset: (NSUInteger) offset count: (NSUInteger) count;

@end
