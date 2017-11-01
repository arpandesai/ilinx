//
//  GenericViewController.h
//  iLinX
//
//  Created by James Stamp on 24/08/2010.
//  Copyright 2010 Janus Technology. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "ServiceViewControllerIPad.h"
#import "NLServiceGeneric.h"
#import "PagedScrollViewController.h"

@interface GenericViewControllerIPad : ServiceViewControllerIPad <PagedScrollViewDelegate, NLServiceGenericDelegate>
{
@private
  IBOutlet PagedScrollViewController *_pageController;
  IBOutlet UILabel *_serviceName;

  NLServiceGeneric *_genericService;
  NSUInteger _buttonCount;
  NSUInteger _buttonsOnPage;
  NSUInteger _numberOfColumns;
  BOOL _flash;
}

@end
 