//
//  SecurityButtonsPageViewController.h
//  iLinX
//
//  Created by mcf on 26/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLServiceSecurity.h"
#import "XIBViewController.h"

@interface SecurityButtonsPageViewController : XIBViewController <NLServiceSecurityDelegate>
{
@private
  NLServiceSecurity *_securityService;
  NSUInteger _controlMode;
  NSUInteger _offset;
  NSUInteger _count;
  NSMutableArray *_buttonHelpers;
  
}

- (id) initWithService: (NLServiceSecurity *) securityService controlMode: (NSUInteger) controlMode
                offset: (NSUInteger) offset count: (NSUInteger) count;

@end
