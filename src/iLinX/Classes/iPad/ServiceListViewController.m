//
//  ServiceListViewController.m
//  iLinX
//
//  Created by mcf on 04/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "ServiceListViewController.h"
#import "Icons.h"
#import "RootViewControllerIPad.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLService.h"
#import "NLServiceList.h"

@implementation ServiceListViewController

- (void) viewDidLoad
{
  [super viewDidLoad];
  _dataSource = [[_delegate.roomList.currentRoom services] retain];
}

- (void) resetDataSource
{
  id newServices = [_delegate.roomList.currentRoom services];
  
  if (newServices != _dataSource)
  {
    NSString *oldService = [[[_dataSource listDataCurrentItem] displayName] retain];

    [_dataSource release];
    _dataSource = [newServices retain];
    if (oldService != nil)
    {
      NSUInteger count = [_dataSource countOfList];
      NSUInteger i;

      for (i = 0; i < count; ++i)
      {
        if ([[_dataSource titleForItemAtIndex: i] isEqualToString: oldService])
        {
          [_dataSource selectItemAtIndex: i];
          break;
        }
      }
      if (i == count && count > 0)
        [_dataSource selectItemAtIndex: 0];
    }

    [oldService release];
    [self.tableView reloadData];
  }

  [super resetDataSource];
}

- (UIImage *) iconForItem: (id) item atIndexPath: (NSIndexPath *) indexPath
{
  return [Icons homeIconForServiceName: (NSString *) [(NLService *) item serviceType]];
}

- (UIImage *) selectedIconForItem: (id) item atIndexPath: (NSIndexPath *) indexPath
{
  return [Icons selectedHomeIconForServiceName: (NSString *) [(NLService *) item serviceType]];
}

@end

