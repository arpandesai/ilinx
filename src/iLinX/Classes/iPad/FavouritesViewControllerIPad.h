//
//  FavouritesViewControllerIPad.h
//  iLinX
//
//  Created by James Stamp on 06/09/2010.
//  Copyright 2010 Janus Technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServiceViewControllerIPad.h"
#import "NLServiceFavourites.h"
#import "ExecutingMacroAlertIPad.h"
#import "PagedScrollViewController.h"

@class ExecutingMacroAlertIPad;
@class NLServiceFavourites;

@interface FavouritesViewControllerIPad : ServiceViewControllerIPad <PagedScrollViewDelegate, UITextFieldDelegate, UIWebViewDelegate>
{
@private
  IBOutlet UILabel *_serviceName;
  IBOutlet PagedScrollViewController *_pageController;

  NLServiceFavourites *_favouritesService;
  NSUInteger _buttonCount;
  NSUInteger _buttonsOnPage;
  NSUInteger _numberOfColumns;
  BOOL _flash;
  ExecutingMacroAlertIPad *_executingMacroAlertIPad;
}

- (void) selectNewService: (NLService *) service afterDelay: (NSTimeInterval) delay;

@end
