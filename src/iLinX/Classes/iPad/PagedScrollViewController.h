//
//  PagedScrollViewController.h
//  iLinX
//
//  Created by mcf on 12/11/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PagedScrollView;

@protocol PagedScrollViewDelegate <NSObject>

- (UIViewController *) pagedScrollView: (PagedScrollView *) pagedScrollView viewControllerForPage: (NSInteger) page;

@end

@interface PagedScrollViewController : UIViewController <UIScrollViewDelegate>
{
@private
  id<PagedScrollViewDelegate> _pagedViewDelegate;
  NSMutableArray *_pageControllers;
  UIViewController *_visiblePage;
  BOOL _hasAppeared;
}

@property (assign) IBOutlet id<PagedScrollViewDelegate> pagedViewDelegate;
@property (assign) NSInteger numberOfPages;
@property (readonly) PagedScrollView *pagedView;
@property (readonly) NSArray *pageControllers;

- (void) reloadPages;

@end
