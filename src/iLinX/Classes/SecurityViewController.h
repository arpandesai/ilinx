//
//  SecurityViewController.h
//  iLinX
//
//  Created by mcf on 18/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServiceViewController.h"
#import "NLServiceSecurity.h"

@interface SecurityViewController : ServiceViewController <NLServiceSecurityDelegate>
{
@private
  NLServiceSecurity *_securityService;
  NSArray *_subViews;
  UIToolbar *_controlBar;
  UISegmentedControl *_segmentedSelector;
  NSUInteger _currentSegment;
  BOOL _onScreen;
}

@end
