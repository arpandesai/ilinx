//
//  SecurityButtonsViewController.h
//  iLinX
//
//  Created by mcf on 26/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLServiceSecurity.h"

@interface SecurityButtonsViewController : UIViewController <NLServiceSecurityDelegate, UIScrollViewDelegate>
{
@private
  NLServiceSecurity *_securityService;
  NSUInteger _controlMode;
  NSUInteger _buttonCount;
  UIPageControl *_pager;
  UIScrollView *_scroller;
  NSMutableArray *_pageControllers;
  UIViewController *_visiblePage;  
}

- initWithSecurityService: (NLServiceSecurity *) securityService controlMode: (NSUInteger) controlMode;

@end
