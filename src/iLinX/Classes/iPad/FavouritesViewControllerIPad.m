//
//  FavouritesViewControllerIPad.m
//  iLinX
//
//  Created by James Stamp on 06/09/2010.
//  Copyright 2010 Janus Technology. All rights reserved.
//

#import "ExecutingMacroAlertIPad.h"
#import "FavouritesViewControllerIPad.h"
#import "FavouritesPageViewControllerIPad.h"
#import "NLServiceFavourites.h"
#import "RootViewControllerIPad.h"
#import "ConfigProfile.h"
#import "ConfigManager.h"

@implementation FavouritesViewControllerIPad
- (id) initWithOwner: (RootViewControllerIPad *) owner service: (NLService *) service
{
  if (self = [super initWithOwner: owner service: service
			  nibName: @"FavouritesIPad" bundle: nil])
  {
    _numberOfColumns = [ConfigManager currentProfileData].buttonsPerRow;
    if (_numberOfColumns == 0)
    {
      _numberOfColumns = 2;
      _buttonsOnPage = 7;
      _flash = YES;
    }
    else
    {
      _buttonsOnPage = _numberOfColumns * [ConfigManager currentProfileData].buttonRows;
      _flash = NO;
    }

    //Cast here as a convenience to avoid having to cast every time its used
    _favouritesService = (NLServiceFavourites *) service;
    _executingMacroAlertIPad = [[ExecutingMacroAlertIPad alloc] initWithOwner: owner];    
  }

  return self;
}

- (void) viewDidLoad
{
  NSUInteger pageCount;
  
  _buttonCount = _favouritesService.favouriteCount;
  if (_buttonCount == 0)
  {  
    pageCount = 1;
  }
  else if (_flash)
  { 
    NSUInteger pageCounter = _buttonCount;
    pageCount = 1;
    while (pageCounter > 8) 
    {
      ++pageCount;
      pageCounter -= 7;
    }
  }
  else
  {  
    pageCount = ((_buttonCount - 1) / _buttonsOnPage) + 1;
  }
  
  _pageController.numberOfPages = pageCount;
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  [_owner showExecutingMacroBanner: NO];
  [_pageController viewWillAppear: animated];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  _serviceName.text = [_service displayName];
  [_pageController viewDidAppear: animated];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_pageController viewWillDisappear: animated];
  [_executingMacroAlertIPad cancelExecutingMacroTimer];
  [super viewWillDisappear: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
  [_pageController viewDidDisappear: animated];
  [_owner showExecutingMacroBanner: NO];
  [super viewDidDisappear: animated];
}

- (void) selectNewService: (NLService *) newService afterDelay: (NSTimeInterval) delay
{
  [_executingMacroAlertIPad  selectNewService: newService afterDelay: delay 
                                animated: _favouritesService.isDefaultScreen];
}

- (UIViewController *) pagedScrollView: (PagedScrollView *) pagedScrollView viewControllerForPage: (NSInteger) page
{
  return [[[FavouritesPageViewControllerIPad alloc]
           initWithService: _favouritesService offset: page * _buttonsOnPage buttonsPerRow: _numberOfColumns
           buttonsPerPage: _buttonsOnPage buttonTotal: _buttonCount flash: _flash parentController: self] autorelease]; 
}

- (void) dealloc
{
  [_serviceName release];
  [_pageController release];
  [_executingMacroAlertIPad cancelExecutingMacroTimer];
  [_executingMacroAlertIPad release];
  [super dealloc];
}


@end

