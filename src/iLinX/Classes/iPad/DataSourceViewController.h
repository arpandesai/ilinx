//
//  DataSourceViewController.h
//  iLinX
//
//  Created by mcf on 07/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ListDataSource.h"

@class DataSourceViewController;
@class NLRoomList;

@protocol DataSourceViewControllerDelegate <NSObject>

- (NLRoomList *) roomList;

@optional
- (void) dataSource: (DataSourceViewController *) dataSource userSelectedItem: (id) item;
- (void) dataSource: (DataSourceViewController *) dataSource selectedItemChanged: (id) item;
- (void) dataSourceRefreshed: (DataSourceViewController *) dataSource;

@end

@interface DataSourceViewController : UITableViewController <ListDataDelegate>
{
@protected
  id<DataSourceViewControllerDelegate> _delegate;
  id<ListDataSource> _dataSource;
  id _currentItem;
  int _viewState;
}

@property (nonatomic, assign) IBOutlet id<DataSourceViewControllerDelegate> delegate;

- (void) resetDataSource;
- (NSString *) titleForItem: (id) item atIndexPath: (NSIndexPath *) indexPath;
- (UIImage *) iconForItem: (id) item atIndexPath: (NSIndexPath *) indexPath;
- (UIImage *) selectedIconForItem: (id) item atIndexPath: (NSIndexPath *) indexPath;

@end
