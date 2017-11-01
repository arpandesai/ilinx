//
//  FavouritesViewController.h
//  iLinX
//
//  Created by mcf on 06/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServiceViewController.h"

@class CustomViewController;
@class ExecutingMacroAlert;
@class NLServiceFavourites;

@interface FavouritesViewController : ServiceViewController <UIScrollViewDelegate> 
{
@private
  NLServiceFavourites *_favouritesService;
  UIPageControl *_pager;
  UIScrollView *_scroller;
  NSMutableArray *_pageControllers;
  UIViewController *_visiblePage;
  ExecutingMacroAlert *_executingMacroAlert;
  CustomViewController *_customPage;
}

- (void) selectNewService: (NLService *) service afterDelay: (NSTimeInterval) delay;

@end
