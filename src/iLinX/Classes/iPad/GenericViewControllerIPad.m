//
//  GenericViewControllerIPad.m
//  iLinX
//
//  Created by mcf on 29/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "GenericViewControllerIPad.h"
#import "GenericPageViewControllerIPad.h"
#import "ConfigManager.h"
#import "ConfigProfile.h"
#import "MainNavigationController.h"
#import "NLServiceGeneric.h"
#import "CustomLightButtonHelper.h"

@interface GenericViewControllerIPad ()

- (void) initialisePages;

@end

@implementation GenericViewControllerIPad

- (id) initWithOwner: (RootViewControllerIPad *) owner service: (NLService *) service
{
  if (self = [super initWithOwner: owner service: service
		  nibName: @"GenericIPad" bundle: nil])
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
    _genericService = (NLServiceGeneric *) service;
  }

  return self;
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  [self initialisePages];
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  if (_genericService.buttonCount > _buttonCount)
    [self initialisePages];
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
  [_genericService removeDelegate: self];
  [_pageController viewWillDisappear: animated];
  [super viewWillDisappear: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
  [_pageController viewDidDisappear: animated];
  [super viewDidDisappear: animated];
}

- (void) service: (NLServiceGeneric *) service button: (NSUInteger) buttonIndex changed: (NSUInteger) changed
{
  if (buttonIndex >= _buttonCount)
    [self initialisePages];
}

- (void) initialisePages
{
  NSUInteger pageCount;
  NSUInteger pageCounter;

  _buttonCount = _genericService.buttonCount;
  if (_buttonCount == 0)
  {  
    pageCount = 1;
  }
  else if (_flash)
  { 
    pageCounter = _buttonCount;
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

- (UIViewController *) pagedScrollView: (PagedScrollView *) pagedScrollView viewControllerForPage: (NSInteger) page
{
  return [[[GenericPageViewControllerIPad alloc]
           initWithService: _genericService offset: page * _buttonsOnPage buttonsPerRow: _numberOfColumns
           buttonsPerPage: _buttonsOnPage buttonTotal: _buttonCount flash: _flash] autorelease];
}

- (void) dealloc
{
  [_pageController release];
  [_serviceName release];
  [super dealloc];
}

@end

