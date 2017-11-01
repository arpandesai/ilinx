    //
//  MediaRootMenuViewController.m
//  iLinX
//
//  Created by mcf on 09/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "MediaRootMenuViewController.h"
#import "Icons.h"
#import "NLBrowseList.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLSource.h"
#import "NLSourceList.h"
#ifdef DEBUG
#import "DebugTracing.h"
#define TRACE_RETAIN 0
#endif

static NSString *kFirstChoiceMediaKey = @"MediaRootFirstChoice";

@interface MediaRootMenuViewController ()

- (void) handleInitialSelection;
- (BOOL) selectInitialSelection;

@end

@implementation MediaRootMenuViewController

#if TRACE_RETAIN
- (id) initWithCoder: (NSCoder *) aDecoder
{
  NSLog( @"%@ initWithCoder\n%@", self, [self stackTraceToDepth: 10] );

  return [super initWithCoder: aDecoder];
}

- (id) retain
{
  NSLog( @"%@ retain\n%@", self, [self stackTraceToDepth: 10] );
  return [super retain];
}

- (void) release
{
  NSLog( @"%@ release\n%@", self, [self stackTraceToDepth: 10] );
  [super release];
}
#endif

- (void) viewDidLoad
{
  [super viewDidLoad];
  _dataSource = [_delegate.roomList.currentRoom.sources.currentSource.browseMenu retain];
  [self handleInitialSelection];
}

- (void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation) fromInterfaceOrientation
{
  [super didRotateFromInterfaceOrientation: fromInterfaceOrientation];
  
  NSIndexPath *selected = [self.tableView indexPathForSelectedRow];
  
  if (selected != nil)
    [self.tableView scrollToRowAtIndexPath: selected atScrollPosition: UITableViewScrollPositionNone animated: NO];
}

- (void) resetDataSource
{
  id newMenu = _delegate.roomList.currentRoom.sources.currentSource.browseMenu;
  
 //**/NSLog( @"MediaRoot resetDataSource" );
  if (newMenu != _dataSource)
  {
   //**/NSLog( @"MediaRoot resetDataSource changed list, count: %u", [newMenu countOfList] );
    [_dataSource release];
    _dataSource = [newMenu retain];
    [self.tableView reloadData];
    [self handleInitialSelection];
  }

  [super resetDataSource];
}

- (void) listDataRefreshDidEnd: (id<ListDataSource>) listDataSource
{
 //**/NSLog( @"MediaRoot listDataRefreshDidEnd, count: %u", [listDataSource countOfList] );
  if ([listDataSource countOfList] > 0)
    [super listDataRefreshDidEnd: listDataSource];  
}

- (void) itemsInsertedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
 //**/NSLog( @"MediaRoot itemsInsertedInListData, count: %u", [listDataSource countOfList] );
  if ([listDataSource countOfList] > 0)
    [super itemsInsertedInListData: listDataSource range: range];  
}

- (void) itemsRemovedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
 //**/NSLog( @"MediaRoot itemsRemovedInListData, count: %u", [listDataSource countOfList] );
  if ([listDataSource countOfList] > 0)
    [super itemsRemovedInListData: listDataSource range: range];  
}

- (void) itemsChangedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
 //**/NSLog( @"MediaRoot itemsChangedInListData, count: %u", [listDataSource countOfList] );
  if ([listDataSource countOfList] > 0)
  {
    if (_selectInitialSelection)
      [self selectInitialSelection];
    _selectInitialSelection = [[listDataSource titleForItemAtIndex: 0] isEqualToString: @"Media"];
    [super itemsChangedInListData: listDataSource range: range];
  }
}

- (void) currentItemForListData: (id<ListDataSource>) listDataSource
                    changedFrom: (id) old to: (id) new at: (NSUInteger) index
{
 //**/NSLog( @"MediaRoot currentItemForListData, count: %u", [listDataSource countOfList] );
  if ([listDataSource countOfList] > 0)
  {
    NSString *title = [_dataSource titleForItemAtIndex: index];
    
    if ([title length] > 0 && ![title isEqualToString: [_initialSelection objectAtIndex: 0]] && 
        ![title isEqualToString: @"Media"])
    {
      NSInteger arrayIndex = [_genericInitialSelection indexOfObject: title];
      
      [_initialSelection release];
      _initialSelection = [[NSArray arrayWithObject: title] retain];
      
      if (arrayIndex != 0)
      {
        NSMutableArray *newArray = [NSMutableArray arrayWithObject: title];
        
        if (arrayIndex == NSNotFound)
          [newArray addObjectsFromArray: _genericInitialSelection];
        else
        {
          NSUInteger count = [_genericInitialSelection count];
          
          [newArray addObjectsFromArray: [_genericInitialSelection subarrayWithRange: NSMakeRange( 0, arrayIndex )]];
          if (arrayIndex < count - 1)
            [newArray addObjectsFromArray:
             [_genericInitialSelection subarrayWithRange: NSMakeRange( arrayIndex + 1, count - arrayIndex - 1 )]];
        }
        
        [newArray retain];
        [_genericInitialSelection release];
        _genericInitialSelection = newArray;
      }
      
      [[NSUserDefaults standardUserDefaults] setObject: _initialSelection forKey: _initialSelectionKey];
      [[NSUserDefaults standardUserDefaults] setObject: _genericInitialSelection forKey: kFirstChoiceMediaKey];
    }
    
    [super currentItemForListData: listDataSource changedFrom: old to: new at: index];
  }
}

- (NSString *) titleForItem: (id) item atIndexPath: (NSIndexPath *) indexPath
{
  NSString *title = [_dataSource titleForItemAtOffset: indexPath.row inSection: indexPath.section];
  NSString *localisedTitle;
  BOOL abbreviated = YES;
  
  if (title == nil)
    localisedTitle = nil;
  else
  {
    NSString *titleResource;
    
    if (abbreviated)
    {
      titleResource = [NSString stringWithFormat: @"1000%@", title];    
      localisedTitle = NSLocalizedString( titleResource, @"Short localised version of top level menu item" );
    }
    else
    {
      titleResource = [NSString stringWithFormat: @"1001%@", title];    
      localisedTitle = NSLocalizedString( titleResource, @"Long localised version of top level menu item" );
    }
    
    if (localisedTitle == nil || [localisedTitle isEqualToString: titleResource])
      localisedTitle = title;
  }
  
 //**/NSLog( @"MediaRoot titleForItemAtPath: %d, %d: %@", indexPath.section, indexPath.row, localisedTitle );

  return localisedTitle;
}

- (UIImage *) iconForItem: (id) item atIndexPath: (NSIndexPath *) indexPath
{
  NSString *title;
  
  if ([item isKindOfClass: [NSDictionary class]])
    title = [(NSDictionary *) item objectForKey: @"listType"];
  else
    title = nil;

  if ([title length] == 0)
    title = [_dataSource titleForItemAtOffset: indexPath.row inSection: indexPath.section];

  if ([title length] == 0)
    return nil;
  else
    return [Icons browseIconForItemName: title];
}

- (UIImage *) selectedIconForItem: (id) item atIndexPath: (NSIndexPath *) indexPath
{
  NSString *title;
  
  if ([item isKindOfClass: [NSDictionary class]])
    title = [(NSDictionary *) item objectForKey: @"listType"];
  else
    title = nil;
  
  if ([title length] == 0)
    title = [_dataSource titleForItemAtOffset: indexPath.row inSection: indexPath.section];
  
  if ([title length] == 0)
    return nil;
  else
    return [Icons selectedBrowseIconForItemName: title];
}

- (void) handleInitialSelection
{
  _initialSelectionKey = [[NSString stringWithFormat: @"%@:%@", kFirstChoiceMediaKey,
                           _delegate.roomList.currentRoom.sources.currentSource.serviceName] retain];
  
  _initialSelection = [[NSUserDefaults standardUserDefaults] objectForKey: _initialSelectionKey];
  _genericInitialSelection = [[NSUserDefaults standardUserDefaults] objectForKey: kFirstChoiceMediaKey];
  if (_initialSelection == nil)
  {
    if (_genericInitialSelection == nil)
    {
      _genericInitialSelection = [NSArray arrayWithObjects: @"Current Play Queue", @"Albums", @"Album", nil];
      
      [[NSUserDefaults standardUserDefaults] setObject: _genericInitialSelection forKey: kFirstChoiceMediaKey];
    }

    _initialSelection = _genericInitialSelection;
    [[NSUserDefaults standardUserDefaults] setObject: _initialSelection forKey: _initialSelectionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }

  [_initialSelection retain];
  [_genericInitialSelection retain];

  _selectInitialSelection = ![self selectInitialSelection];
}

- (BOOL) selectInitialSelection
{
  NSUInteger count = [_dataSource countOfList];
  BOOL found = NO;

  // Special case of an undocked iPod.
  if (count > 0 && [[_dataSource titleForItemAtIndex: 0] isEqualToString: @"Media"])
    [_dataSource selectItemAtIndex: 0 executeAction: NO];
  else if (count >= 2)
  {
    NSUInteger selectionCount = [_initialSelection count];
    
    for (NSUInteger i = 0; i < selectionCount; ++i)
    {
      for (NSUInteger j = 0; j < count; ++j)
      {
        NSString *title = [_dataSource titleForItemAtIndex: j];
        
        if (title == nil)
        {
          selectionCount = 0;
          break;
        }
        else if ([[_initialSelection objectAtIndex: i] isEqualToString: title])
        {
          [_dataSource selectItemAtIndex: j executeAction: NO];
          selectionCount = 0;
          found = YES;
          break;
        }
      }
    }
  }

  return found;
}

- (void) dealloc
{
#if TRACE_RETAIN
  NSLog( @"%@ dealloc\n%@", self, [self stackTraceToDepth: 10] );
#endif
  [_initialSelectionKey release];
  [_initialSelection release];
  [_genericInitialSelection release];
  [super dealloc];
}

@end
