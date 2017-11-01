//
//  NoSourcePageViewControllerIPad.h
//  iLinX
//
//  Created by mcf on 11/11/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ButtonPageViewController.h"

@class NoSourceViewControllerIPad;
@class NLSourceList;

@interface NoSourcePageViewControllerIPad : ButtonPageViewController 
{
@private
  IBOutlet UIButton *_buttonTemplate;
  NLSourceList *_sources;
}

- (id) initWithOffset: (NSUInteger) offset buttonsPerRow: (NSUInteger) buttonsPerRow buttonsPerPage: (NSUInteger) buttonsPerPage 
          buttonTotal: (NSUInteger) buttonTotal flash: (BOOL) flash;

- (void) refreshButtonStatesWithSources: (NLSourceList *) sources;

@end
