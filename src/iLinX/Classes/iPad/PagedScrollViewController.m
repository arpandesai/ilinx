    //
//  PagedScrollViewController.m
//  iLinX
//
//  Created by mcf on 12/11/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "PagedScrollViewController.h"
#import "PagedScrollView.h"

@interface PagedScrollViewController ()

- (void) loadPagesAroundCurrentPage;
- (void) loadScrollViewForPage: (NSInteger) page;

@end


@implementation PagedScrollViewController

@synthesize
  pagedViewDelegate = _pagedViewDelegate,
  pageControllers = _pageControllers;

- (NSInteger) numberOfPages
{
  return self.pagedView.pager.numberOfPages;
}

- (PagedScrollView *) pagedView
{
  return (PagedScrollView *) self.view;
}

- (void) setNumberOfPages: (NSInteger) numberOfPages
{
  self.pagedView.pager.currentPage = 0;
  self.pagedView.pager.numberOfPages = numberOfPages;
  [self reloadPages];
}

- (void) viewDidUnload
{
  self.pagedView.delegate = nil;
  [_pageControllers release];
  _pageControllers = nil;
  _visiblePage = nil;
  [super viewDidUnload];
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];

  if (_pageControllers == nil)
    [self reloadPages];

  NSInteger page = self.pagedView.pager.currentPage;
  
  if (page < [_pageControllers count])
    _visiblePage = [_pageControllers objectAtIndex: page];
  else
    _visiblePage = nil;

  [_visiblePage viewWillAppear: animated];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  [_visiblePage viewDidAppear: animated];
  _hasAppeared = YES;
}

- (void) viewWillDisappear: (BOOL) animated
{
  _hasAppeared = NO;
  [_visiblePage viewWillDisappear: animated];
  [super viewWillDisappear: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
  [_visiblePage viewDidDisappear: animated];
  [super viewDidDisappear: animated];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
  // Overriden to allow any orientation.
  return YES;
}

- (void) willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation 
                                          duration: (NSTimeInterval) duration
{
  [_visiblePage willAnimateRotationToInterfaceOrientation: interfaceOrientation duration: duration];
}

- (void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation) fromInterfaceOrientation
{
  [_visiblePage didRotateFromInterfaceOrientation: fromInterfaceOrientation];
}

- (void) didReceiveMemoryWarning 
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
}

- (void) reloadPages
{
  UIPageControl *pager = self.pagedView.pager;

  if (_visiblePage != nil)
  {
    if (_hasAppeared)
      [_visiblePage viewWillDisappear: NO];
    [_visiblePage.view removeFromSuperview];
    if (_hasAppeared)
      [_visiblePage viewDidDisappear: NO];
    _visiblePage = nil;
  }
  [_pageControllers release];
  _pageControllers = [[NSMutableArray arrayWithCapacity: pager.numberOfPages] retain];

  for (NSUInteger i = 0; i < pager.numberOfPages; ++i)
    [_pageControllers addObject: [NSNull null]]; 
  
  self.pagedView.contentSize = CGSizeMake( self.pagedView.frame.size.width * pager.numberOfPages, self.pagedView.frame.size.height );
  if (pager.numberOfPages > 0)
    [self loadPagesAroundCurrentPage];
}

- (void) scrollViewDidScroll: (UIScrollView *) sender
{
  // Switch the indicator when more than 50% of the previous/next page is visible
  CGFloat pageWidth = self.pagedView.frame.size.width;
  int page = floor( (self.pagedView.contentOffset.x - pageWidth / 2) / pageWidth ) + 1;
  UIPageControl *pager = self.pagedView.pager;
  
  if (pager.currentPage != page)
    pager.currentPage = page;
  
  [self loadPagesAroundCurrentPage];
}

- (void) loadPagesAroundCurrentPage
{
  int page = self.pagedView.pager.currentPage;

  // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
  [self loadScrollViewForPage: page - 1];
  [self loadScrollViewForPage: page];
  [self loadScrollViewForPage: page + 1];
  
  // We have to do this bit by hand because we're adding the views into the scroll view directly
  // so their respective controllers are out of the loop
  UIViewController *currentController = [_pageControllers objectAtIndex: page];

  if (_hasAppeared && currentController != _visiblePage)
  {
    [currentController viewWillAppear: YES];
    [_visiblePage viewWillDisappear: YES];
    [_visiblePage viewDidDisappear: YES];
    [currentController viewDidAppear: YES];
    _visiblePage = currentController;
  }
}

- (void) loadScrollViewForPage: (NSInteger) page
{
  if (page >= 0 && page < self.pagedView.pager.numberOfPages && 
      [_pageControllers objectAtIndex: page] == [NSNull null])
  {
    UIViewController *controller = [_pagedViewDelegate pagedScrollView: self.pagedView viewControllerForPage: page];
    
    if (controller != nil)
    {
      [_pageControllers replaceObjectAtIndex: page withObject: controller];
      
      // add the controller's view to the scroll view
      if (controller.view.superview == nil)
      {
        CGRect frame = self.pagedView.bounds;
        
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0;
        controller.view.frame = frame;
        [self.pagedView addSubview: controller.view];
      }
    }
  }
}

- (void) dealloc
{
  [_pageControllers release];
  [super dealloc];
}

@end
