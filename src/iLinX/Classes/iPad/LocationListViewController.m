//
//  LocationListViewController.m
//  iLinX
//
//  Created by mcf on 04/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "LocationListViewController.h"
#import "RootViewControllerIPad.h"
#import "NLRoomList.h"

@implementation LocationListViewController

- (void) viewDidLoad
{
  [super viewDidLoad];
  _dataSource = [_delegate.roomList retain];
}

- (void) resetDataSource
{
  id newLocations = _delegate.roomList;
  
  if (newLocations != _dataSource)
  {
    [_dataSource release];
    _dataSource = [newLocations retain];
    [self.tableView reloadData];
  }
  
  [super resetDataSource];
}

- (NSString *) titleForItem: (id) item atIndexPath: (NSIndexPath *) indexPath
{
  NSString *title = [[_dataSource itemAtOffset: indexPath.row inSection: indexPath.section] displayName];
  
  if (title == nil)
    title = NSLocalizedString( @"Discovering...", @"Short message to display when discovering rooms" );
  
  return title;
}

- (UIImage *) iconForItem: (id) item atIndexPath: (NSIndexPath *) indexPath
{
  return [UIImage imageNamed: @"singleRoom.png"];
}

- (UIImage *) selectedIconForItem: (id) item atIndexPath: (NSIndexPath *) indexPath
{
  return [UIImage imageNamed: @"singleRoom-selected.png"];
}

@end

