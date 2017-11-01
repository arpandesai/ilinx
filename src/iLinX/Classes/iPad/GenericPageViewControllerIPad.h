
//  GenericPageViewControllerIPad.h
//  iLinX
//
//  Created by James Stamp on 24/08/2010.
//  Copyright 2010 Janus Technology. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "ButtonPageViewController.h"
#import "NLServiceGeneric.h"

@interface GenericPageViewControllerIPad : ButtonPageViewController <NLServiceGenericDelegate>
{
@private
  IBOutlet UIButton *_buttonTemplateOff;
  IBOutlet UIButton *_buttonTemplateOn;
  IBOutlet UIButton *_buttonTemplateNa;
  NLServiceGeneric *_genericService;
}

- (id) initWithService: (NLServiceGeneric *) genericService offset: (NSUInteger) offset
         buttonsPerRow: (NSUInteger) buttonsPerRow buttonsPerPage: (NSUInteger) buttonsPerPage 
           buttonTotal: (NSUInteger) buttonTotal flash: (BOOL) flash;

@end
