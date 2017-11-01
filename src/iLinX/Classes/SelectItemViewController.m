//
//  SelectItemViewController.m
//  iLinX
//
//  Created by mcf on 30/12/2008.
//  Copyright 2008 Micropraxis Ltd. All rights reserved.
//

#import "SelectItemViewController.h"
#import "BorderedTableViewCell.h"
#import "CustomViewController.h"
#import "DiscoveryFailureAlert.h"
#import "DeprecationHelper.h"
#import "MainNavigationController.h"
#import "NLRoomList.h"
#import "NLSource.h"
#import "NLSourceList.h"
#import "StandardPalette.h"

@interface SelectItemViewController ()

- (void) tableView: (UITableView *) tableView selectFeedbackAtIndexPath: (NSIndexPath *) indexPath;
- (void) reloadData;

@end

@implementation SelectItemViewController

@synthesize 
  dataSource = _dataSource,
  headerView = _headerView;

- (id) initWithTitle: (NSString *) title dataSource: (id<ListDataSource>) aDataSource
      overController: (UINavigationController *) controller
{
  return [self initWithTitle: title dataSource: aDataSource headerView: nil overController: controller];
}

- (id) initWithTitle: (NSString *) title dataSource: (id<ListDataSource>) aDataSource headerView: (UIView *) view
      overController: (UINavigationController *) controller
{
  if (self = [super initWithStyle: UITableViewStylePlain])
  {
    self.dataSource = aDataSource;
    self.headerView = view;
    _customPage = [[CustomViewController alloc] initWithController: self dataSource: aDataSource];
    if ([controller isKindOfClass: [MainNavigationController class]])
      [_customPage setMacroHandler: ((MainNavigationController *) controller).executingMacroAlert];
    if (![_customPage isValid])
    {
      self.title = title;
      [_customPage release];
      _customPage = nil;
    }
    else if ([_customPage.title length] == 0)
    {
      self.title = title;
    }
    else
    {
      self.title = _customPage.title;
    }
  }

  return self;
}

- (id) initWithCustomViewController: (CustomViewController *) customViewController
{
  if (self = [super initWithStyle: UITableViewStylePlain])
  {
    _customPage = [customViewController retain];
    self.title = _customPage.title;
  }

  return self;
  
}

- (void) viewDidLoad
{
  [super viewDidLoad];

  // add our custom buttons - Refresh on left, if required and Done on right.
  
  UIBarButtonItem *addButton = [[[UIBarButtonItem alloc]
                                 initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                 target: self
                                 action: @selector(pressedDone:)] autorelease];
  self.navigationItem.rightBarButtonItem = addButton;
  
  if (_customPage == nil)
    self.tableView.backgroundColor = [StandardPalette tableCellColour];
  else
  {
    self.tableView.hidden = YES;
    [_customPage loadViewWithFrame: self.view.bounds];
    self.view = _customPage.view;
  }
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];

  [self.dataSource addDelegate: self];
  
  self.navigationController.navigationBarHidden = [_customPage hidesNavigationBar];
  if (_customPage != nil)
    self.view.window.backgroundColor = [StandardPalette customPageBackgroundColour];

  if ([_dataSource canBeRefreshed] && [_dataSource refreshIsComplete])
  {
    UIBarButtonItem *addButton = [[[UIBarButtonItem alloc]
                  initWithBarButtonSystemItem: UIBarButtonSystemItemRefresh
                  target: self
                  action: @selector(pressedRefresh:)] autorelease];
    self.navigationItem.leftBarButtonItem = addButton;
  }
  else
    self.navigationItem.leftBarButtonItem = nil;

  self.tableView.tableHeaderView = _headerView;
  _selectionFinished = NO;
  self.navigationItem.rightBarButtonItem.enabled = YES;
  [_customPage viewWillAppear: animated];
  [self reloadData];
}

- (void) viewWillDisappear: (BOOL) animated
{
  self.navigationController.navigationBarHidden = [_customPage hidesNavigationBar];
  [_customPage viewWillDisappear: animated];
  [_dataSource removeDelegate: self];
  [_selectedIndex release];
  _selectedIndex = nil;

  [super viewWillDisappear: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
  [super viewDidDisappear: animated];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  if (_customPage != nil)
    self.view.window.backgroundColor = [StandardPalette customPageBackgroundColour];
  self.navigationController.navigationBarHidden = [_customPage hidesNavigationBar];
}

- (void) pressedRefresh: (id) button
{
  [_selectedIndex release];
  _selectedIndex = nil;
  self.navigationItem.leftBarButtonItem = nil;
  self.tableView.tableHeaderView = nil;
  [self reloadData];
  [_dataSource refresh];
}

// Megahack - can we fix this?
- (void) delayDismissTimerFired: (id) timer
{
  if (_delay > 0)
  {
    if (![_dataSource isKindOfClass: [NLSourceList class]])
      _delay = 0;
    else
    {
      NLSourceList *sourceList = (NLSourceList *) _dataSource;
    
      if (sourceList.currentSource.controlState != nil)
        _delay = 0;
      else
      {
        [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector(delayDismissTimerFired:) 
                                       userInfo: nil repeats: NO];
      }
    }
  }
  
  if (_delay > 0)
  {
    --_delay;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  }
  else
  {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self dismissModalViewControllerAnimated: YES];
  }
}

- (void) pressedDone: (id) button
{
  _selectionFinished = YES;
  if (self.navigationItem.leftBarButtonItem != nil)
    self.navigationItem.leftBarButtonItem.enabled = NO;
  if (self.navigationItem.rightBarButtonItem != nil)
    self.navigationItem.rightBarButtonItem.enabled = NO;
  _delay = 5;
  [self delayDismissTimerFired: nil];
}

// Standard table view data source and delegate methods

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
  return [_dataSource countOfSections];
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  // Only one section so return the number of items in the list
  
  return [_dataSource countOfListInSection: section];
}

- (NSString *) tableView: (UITableView *) tableView titleForFooterInSection: (NSInteger) section
{
  NSUInteger count = [_dataSource countOfListInSection: 0];

  if (section == 0 && count > 0 && [_dataSource countOfSections] > 0 && count < [_dataSource countOfList])
    return @" ";
  else
    return nil;
}

- (CGFloat) tableView: (UITableView *) tableView heightForFooterInSection: (NSInteger) section
{
  if (section == 0)
    return 1;
  else
    return 0;
}

- (void) listDataRefreshDidStart: (id<ListDataSource>) listDataSource
{
  self.navigationItem.leftBarButtonItem = nil;
  self.tableView.tableHeaderView = nil;
}

- (void) listDataRefreshDidEnd: (id<ListDataSource>) listDataSource
{
  if ([_dataSource canBeRefreshed])
  {
    UIBarButtonItem *addButton = [[[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem: UIBarButtonSystemItemRefresh
                                   target: self
                                   action: @selector(pressedRefresh:)] autorelease];
    
    self.navigationItem.leftBarButtonItem = addButton;
  }
  else
    self.navigationItem.leftBarButtonItem = nil;

  self.tableView.tableHeaderView = _headerView;
  
  // Not nice putting it here, but quick...
  if ([listDataSource isKindOfClass: [NLRoomList class]] && [listDataSource countOfListInSection: 1] == 0)
    [DiscoveryFailureAlert showAlertWithError: ((NLRoomList *) listDataSource).lastError];
}

- (void) itemsInsertedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [self reloadData];
}

- (void) itemsChangedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [self reloadData];
}

- (void) itemsRemovedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [self reloadData];
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"MyIdentifier"];
  
  if (cell == nil)
    cell = [[[BorderedTableViewCell alloc] initDefaultWithFrame: CGRectZero reuseIdentifier: @"MyIdentifier"
                                                          table: tableView] autorelease];
  
  if ([_dataSource itemIsSelectedAtOffset: indexPath.row inSection: indexPath.section])
  {
    _selectedIndex = [indexPath retain];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  }
  else
    cell.accessoryType = UITableViewCellAccessoryNone;
  
  if ([_dataSource itemIsSelectableAtOffset: indexPath.row inSection: indexPath.section])
    [cell setLabelTextColor: [StandardPalette tableTextColour]];
  else
    [cell setLabelTextColor: [StandardPalette disabledTableTextColour]];
  
  // Get the object to display and set the value in the cell
  [cell setLabelText: [_dataSource titleForItemAtOffset: indexPath.row inSection: indexPath.section]];
  
  return cell;
}

- (NSIndexPath *) tableView: (UITableView *) tableView willSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  if (!_selectionFinished && [_dataSource refreshIsComplete] &&
      [_dataSource itemIsSelectableAtOffset: indexPath.row inSection: indexPath.section])
    return indexPath;
  else
    return nil;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  [tableView deselectRowAtIndexPath: indexPath animated: YES];
  [_dataSource selectItemAtOffset: indexPath.row inSection: indexPath.section];
  [self tableView: tableView selectFeedbackAtIndexPath: indexPath];
  [self pressedDone: nil];
}

- (void) tableView: (UITableView *) tableView selectFeedbackAtIndexPath: (NSIndexPath *) indexPath
{
  if (_selectedIndex != nil)
    [tableView cellForRowAtIndexPath: _selectedIndex].accessoryType = UITableViewCellAccessoryNone;
  [tableView cellForRowAtIndexPath: indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
  [_selectedIndex release];
  _selectedIndex = [indexPath retain];
}

- (void) reloadData
{
  if (_customPage == nil)
    [self.tableView reloadData];
  else
    [_customPage reloadData];
}

- (void) dealloc
{
  [_headerView release];
  [_selectedIndex release];
  [_customPage release];
  [super dealloc];
}

@end
