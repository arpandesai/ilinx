
//  SecurityPageViewControllerIPad.h
//  iLinX
//
//  Created by James Stamp on 29/09/2010.
//  Copyright 2010 Janus Technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ButtonPageViewController.h"
#import "NLServiceSecurity.h"

@interface SecurityPageViewControllerIPad : ButtonPageViewController <NLServiceSecurityDelegate>
{
@private
  IBOutlet UIButton    	*_buttonTemplateOff;
  IBOutlet UIButton    	*_buttonTemplateOn;
  IBOutlet UIButton    	*_buttonTemplateNa;
  
  NLServiceSecurity *_securityService;
  NSUInteger _controlMode;
}

- (id) initWithService: (NLServiceSecurity *) securityService controlMode: (NSUInteger) controlMode
                offset: (NSUInteger) offset buttonsPerRow: (NSUInteger) buttonsPerRow 
        buttonsPerPage: (NSUInteger) buttonsPerPage buttonTotal: (NSUInteger) buttonTotal;

@end
