//
//  SelectItemViewController.h
//  iLinX
//
//  Created by mcf on 30/12/2008.
//  Copyright 2008 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ListDataSource.h"
#import "TintedTableViewController.h"

@class CustomViewController;

@interface SelectItemViewController : TintedTableViewController <ListDataDelegate>
{
  id<ListDataSource> _dataSource;
  NSIndexPath *_selectedIndex;
  UIView *_headerView;
  CustomViewController *_customPage;
  NSUInteger _delay;
  BOOL _selectionFinished;
}

- (id) initWithTitle: (NSString *) title dataSource: (id<ListDataSource>) aDataSource 
      overController: (UINavigationController *) controller;
- (id) initWithTitle: (NSString *) title dataSource: (id<ListDataSource>) aDataSource
          headerView: (UIView *) view overController: (UINavigationController *) controller;
- (id) initWithCustomViewController: (CustomViewController *) customViewController;

@property (assign) id<ListDataSource> dataSource;
@property (nonatomic, retain) UIView *headerView;

@end

