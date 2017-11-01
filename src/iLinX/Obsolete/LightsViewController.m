//
//  LightsViewController.m
//  iLinX
//
//  Created by mcf on 29/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "LightsViewController.h"
#import "LightsPageViewController.h"
#import "MainNavigationController.h"
#import "NLServiceGeneric.h"

#define BUTTONS_PER_PAGE 8

@interface LightsViewController ()

- (void) initialisePages;
- (void) changePage: (id) sender;
- (void) loadScrollViewForPage: (NSUInteger) page;

@end

@implementation LightsViewController

- initWithRoomList: (NLRoomList *) roomList service: (NLService *) service
{
  if (self = [super initWithRoomList: roomList service: service])
  {
    // Convenience cast here
    _lightsService = (NLServiceGeneric *) service;
  }

  return self;
}


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void) loadView
{
  [super loadView];

  CGRect mainViewBounds = self.view.bounds;
  CGFloat barHeight = _toolBar.bounds.size.height;
  
  _pager = [[UIPageControl alloc] initWithFrame: 
            CGRectMake( 0, mainViewBounds.origin.y + mainViewBounds.size.height - (barHeight * 2) + 1,
                       mainViewBounds.size.width, 0 )];
  
  [_pager addTarget: self action: @selector(changePage:) forControlEvents: UIControlEventValueChanged];
  [self.view addSubview: _pager];

  _scroller = [[UIScrollView alloc] initWithFrame:
    CGRectMake( mainViewBounds.origin.x, mainViewBounds.origin.y + barHeight - 1,
               mainViewBounds.size.width, mainViewBounds.size.height - (barHeight * 3) - _pager.frame.size.height + 1 )];
  
  _scroller.pagingEnabled = YES;
  _scroller.showsHorizontalScrollIndicator = NO;
  _scroller.showsVerticalScrollIndicator = NO;
  _scroller.scrollsToTop = NO;
  _scroller.delegate = self;
  [self.view addSubview: _scroller];

  [self initialisePages];
}

- (void) viewWillAppear: (BOOL) animated
{
  MainNavigationController *mainController = (MainNavigationController *) self.navigationController;
  
  [super viewWillAppear: animated];
  
  [mainController setAudioControlsStyle: UIBarStyleBlackOpaque];
  mainController.navigationBar.barStyle = UIBarStyleBlackOpaque;
  [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque animated: YES];
  [_lightsService addDelegate: self];
  _visiblePage = [_pageControllers objectAtIndex: _pager.currentPage];
  [_visiblePage viewWillAppear: animated];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  
  if (_location != nil)
  {
    [(MainNavigationController *) self.navigationController showAudioControls: YES];
    [_visiblePage viewDidAppear: animated];
  }
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_lightsService removeDelegate: self];
  [_visiblePage viewWillDisappear: animated];
  [super viewWillDisappear: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
  [_visiblePage viewDidDisappear: animated];
  [super viewDidDisappear: animated];
}

- (void) scrollViewDidScroll: (UIScrollView *) sender
{
  // Switch the indicator when more than 50% of the previous/next page is visible
  CGFloat pageWidth = _scroller.frame.size.width;
  int page = floor( (_scroller.contentOffset.x - pageWidth / 2) / pageWidth ) + 1;
  
  if (_pager.currentPage != page)
    _pager.currentPage = page;
  
  // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
  [self loadScrollViewForPage: page - 1];
  [self loadScrollViewForPage: page];
  [self loadScrollViewForPage: page + 1];
  
  // We have to do this bit by hand because we're adding the views into the scroll view directly
  // so their respective controllers are out of the loop
  UIViewController *currentController = [_pageControllers objectAtIndex: page];
  
  if (currentController != _visiblePage)
  {
    [currentController viewWillAppear: YES];
    [_visiblePage viewWillDisappear: YES];
    [_visiblePage viewDidDisappear: YES];
    [currentController viewDidAppear: YES];
    _visiblePage = currentController;
  }
}

- (void) service: (NLServiceGeneric *) service button: (NSUInteger) buttonIndex changed: (NSUInteger) changed
{
  if (buttonIndex >= _buttonCount)
  {
    [_visiblePage viewWillDisappear: NO];
    
    NSArray *subViews = [_scroller.subviews copy];
    NSUInteger count = [subViews count];
    NSUInteger i;
    
    for (i = 0; i < count; ++i)
      [[subViews objectAtIndex: i] removeFromSuperview];
    
    [_visiblePage viewDidDisappear: NO];
    [subViews release];
    [self initialisePages];
  }
}

- (void) initialisePages
{
  NSUInteger pageCount;
  NSUInteger i;
  
  _buttonCount = _lightsService.buttonCount;
  if (_buttonCount == 0)
    pageCount = 1;
  else
    pageCount = ((_buttonCount - 1) / BUTTONS_PER_PAGE) + 1;
  _pager.numberOfPages = pageCount;
  //_pager.hidesForSinglePage = YES;
  _pager.currentPage = 0;
  [_pager sizeToFit];
  _pager.frame = CGRectOffset( _pager.frame,
                              (self.view.bounds.size.width - _pager.frame.size.width) / 2, -_pager.frame.size.height );
  _scroller.contentSize = CGSizeMake( _scroller.frame.size.width * pageCount, _scroller.frame.size.height );
 
  [_pageControllers release];
  _pageControllers = [[NSMutableArray arrayWithCapacity: pageCount] retain];
  for (i = 0; i < pageCount; ++i)
    [_pageControllers addObject: [NSNull null]];
  
  [self loadScrollViewForPage: 0];
  [self loadScrollViewForPage: 1];
}

- (void) loadScrollViewForPage: (NSUInteger) page
{
  if (page < _pager.numberOfPages)
  {
    // replace the placeholder if necessary
    LightsPageViewController *controller = [_pageControllers objectAtIndex: page];
    
    if ((NSNull *) controller == [NSNull null])
    {
      controller = [[LightsPageViewController alloc]
                    initWithService: _lightsService offset: page * BUTTONS_PER_PAGE count: BUTTONS_PER_PAGE];
      [_pageControllers replaceObjectAtIndex: page withObject: controller];
      [controller release];
    }
  
    // add the controller's view to the scroll view
    if (controller.view.superview == nil)
    {
      CGRect frame = _scroller.frame;
    
      frame.origin.x = frame.size.width * page;
      frame.origin.y = 0;
      controller.view.frame = frame;
      [_scroller addSubview: controller.view];
    }
  }
}

- (void) changePage: (id) sender
{
  int page = _pager.currentPage;
  
  // update the scroll view to the appropriate page
  CGRect frame = _scroller.frame;
  
  frame.origin.x = frame.size.width * page;
  frame.origin.y = 0;
  [_scroller scrollRectToVisible: frame animated: YES];
}

- (void) didReceiveMemoryWarning
{
  // A possible optimization would be to unload the views+controllers which are no longer visible

  [super didReceiveMemoryWarning];
}

- (void) dealloc
{
  [_pager release];
  [_scroller release];
  [_pageControllers release];
  [super dealloc];
}


@end
