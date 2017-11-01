//
//  DataSourceViewController.m
//  iLinX
//
//  Created by mcf on 07/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "DataSourceViewController.h"
#import "DeprecationHelper.h"
#import "Icons.h"
#import "RootViewControllerIPad.h"

#ifdef DEBUG
#define DEBUG_LIST_ITEMS 0
#endif

@interface DataSourceViewController ()

- (void) refreshCurrentItemAndUpdateSelection: (BOOL) updateSelection;
- (void) updateSelection;
@end


@implementation DataSourceViewController

@synthesize
  delegate = _delegate;

- (void) viewDidLoad
{
  [super viewDidLoad];

  // Uncomment the following line to preserve selection between presentations.
  self.clearsSelectionOnViewWillAppear = NO;
}

- (void) viewWillAppear: (BOOL) animated 
{
  if (_viewState < 1)
  {
    _viewState = 1;
    [super viewWillAppear: animated];
  }
}

- (void) viewDidAppear: (BOOL) animated
{
  if (_viewState < 2)
  {
    _viewState = 2;
    [super viewDidAppear: animated];
    [_dataSource addDelegate: self];
    if ([_dataSource refreshIsComplete])
      [self listDataRefreshDidEnd: _dataSource];
    [self refreshCurrentItemAndUpdateSelection: YES];
  
    [self performSelector: @selector(updateSelection) withObject: nil afterDelay: 0];
  }
}

- (void) viewWillDisappear: (BOOL) animated 
{
  if (_viewState > -1)
  {
    _viewState = -1;
    [_dataSource removeDelegate: self];
    [super viewWillDisappear: animated];
  }
}

- (void) viewDidDisappear: (BOOL) animated
{
  if (_viewState > -2)
  {
    _viewState = -2;
    [super viewDidDisappear: animated];
  }
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
  // Override to allow orientations other than the default portrait orientation.
  return YES;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
  // Return the number of sections.
  return [_dataSource countOfSections];
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  // Return the number of rows in the section.
  return [_dataSource countOfListInSection: section];
}

// Customize the appearance of table view cells.
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  static NSString *CellIdentifier = @"Cell";
    
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  id item = [_dataSource itemAtOffset: indexPath.row inSection: indexPath.section];

  if (cell == nil)
    cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier] autorelease];
    
  cell.textLabel.text = [self titleForItem: item atIndexPath: indexPath];
#if DEBUG_LIST_ITEMS
  NSLog( @"%@: Data source: %@, Row count: %u, Row %d: %@", self, _dataSource, [_dataSource countOfList], indexPath.row, cell.textLabel.text );
  if (indexPath.row == 0 && [_dataSource countOfList] == 1)
  {
       if ([cell.textLabel.text isEqualToString: @"Discovering..."])
         cell.textLabel.text = cell.textLabel.text;
  }
#endif
  cell.imageView.image = [self iconForItem: item atIndexPath: indexPath];
  cell.imageView.highlightedImage = [self selectedIconForItem: item atIndexPath: indexPath];
  if ([_dataSource itemIsSelectableAtOffset: indexPath.row inSection: indexPath.section])
  {
    [cell setLabelTextColor: [UIColor blackColor]];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
  }
  else
  {
    [cell setLabelTextColor: [UIColor grayColor]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }

  return cell;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  [_dataSource selectItemAtOffset: indexPath.row inSection: indexPath.section];
  [self refreshCurrentItemAndUpdateSelection: NO];
  if ([_delegate respondsToSelector: @selector(dataSource:userSelectedItem:)])
    [_delegate dataSource: self userSelectedItem: _currentItem];
}

- (NSIndexPath *) tableView: (UITableView *) tableView willSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  if ([_dataSource itemIsSelectableAtOffset: indexPath.row inSection: indexPath.section])
    return indexPath;
  else
    return nil;
}

- (void) listDataRefreshDidEnd: (id<ListDataSource>) listDataSource
{
#if DEBUG_LIST_ITEMS
  NSLog( @"%@: listDataRefreshDidEnd", self );
#endif
  [self.tableView reloadData];
  [self performSelector: @selector(refreshAfterTableReloadComplete) withObject: nil afterDelay: 0];
  if ([_delegate respondsToSelector: @selector(dataSourceRefreshed:)])
    [_delegate dataSourceRefreshed: self];
}

- (void) itemsInsertedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
#if DEBUG_LIST_ITEMS
  NSLog( @"%@: itemsInsertedInListData", self );
#endif
  [self.tableView reloadData];
  [self performSelector: @selector(refreshAfterTableReloadComplete) withObject: nil afterDelay: 0];
}

- (void) itemsChangedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
#if DEBUG_LIST_ITEMS
  NSLog( @"%@: itemsChangedInListData", self );
#endif
  [self.tableView reloadData];
  [self performSelector: @selector(refreshAfterTableReloadComplete) withObject: nil afterDelay: 0];
}

- (void) itemsRemovedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
#if DEBUG_LIST_ITEMS
  NSLog( @"%@: itemsRemovedInListData", self );
#endif
  [self.tableView reloadData];
  [self performSelector: @selector(refreshAfterTableReloadComplete) withObject: nil afterDelay: 0];
}

- (void) currentItemForListData: (id<ListDataSource>) listDataSource
                    changedFrom: (id) old to: (id) new at: (NSUInteger) index
{
  [self refreshCurrentItemAndUpdateSelection: YES];
}

- (void) refreshAfterTableReloadComplete
{
  [self refreshCurrentItemAndUpdateSelection: YES];
}

- (void) resetDataSource
{
  [self refreshCurrentItemAndUpdateSelection: YES];
  // For child classes to override
}

- (NSString *) titleForItem: (id) item atIndexPath: (NSIndexPath *) indexPath
{
  return [_dataSource titleForItemAtOffset: indexPath.row inSection: indexPath.section];
}

- (UIImage *) iconForItem: (id) item atIndexPath: (NSIndexPath *) indexPath
{
  return nil;
}

- (UIImage *) selectedIconForItem: (id) item atIndexPath: (NSIndexPath *) indexPath
{
  return nil;
}

- (void) refreshCurrentItemAndUpdateSelection: (BOOL) updateSelection
{
  NSUInteger count = [_dataSource countOfList];

  if (count < NSUIntegerMax)
  {
    id oldCurrentItem = _currentItem;
    
    _currentItem = [_dataSource.listDataCurrentItem retain];

    if (_currentItem == nil)
    {
      for (NSInteger i = 0; i < count; ++i)
      {
        if ([_dataSource itemIsSelectableAtIndex: i])
        {
          [_dataSource selectItemAtIndex: i];
          _currentItem = [_dataSource.listDataCurrentItem retain];
          break;
        }
      }
    }
  
    if (oldCurrentItem != _currentItem)
    {
      if ([_delegate respondsToSelector: @selector(dataSource:selectedItemChanged:)])
        [_delegate dataSource: self selectedItemChanged: _currentItem];
    }
  
    if (updateSelection)
      [self updateSelection];
    
    [oldCurrentItem release];
  }
}

- (void) updateSelection
{
  NSIndexPath *selectedItemIndex = [self.tableView indexPathForSelectedRow];
  NSIndexPath *newItemIndex = [_dataSource listDataCurrentItemIndexPath];
  
  @try
  {
    if (![selectedItemIndex isEqual: newItemIndex])
    {
      if (selectedItemIndex != nil)
        [self.tableView deselectRowAtIndexPath: selectedItemIndex animated: NO];
      if (newItemIndex != nil)
        [self.tableView selectRowAtIndexPath: newItemIndex animated: NO scrollPosition: UITableViewScrollPositionNone];
    }
    else if (newItemIndex != nil)
    {
      //**/NSLog( @"%@: Trying to scroll to row %d of section %d", self, newItemIndex.row, newItemIndex.section );
      // Commented out because this causes a bad access crash for no obvious reason every now and again.  We can usually
      // live without it...
      //[self.tableView scrollToRowAtIndexPath: newItemIndex atScrollPosition: UITableViewScrollPositionNone animated: NO];
    }
  }
  @catch (id exception)
  {
  }
}
  
- (void) dealloc
{
  [_dataSource removeDelegate: self];
  [_dataSource release];
  [_currentItem release];
  [super dealloc];
}


@end

