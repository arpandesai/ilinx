//
//  TunerPresetTableView.m
//  iLinX
//
//  Created by Tony Short on 07/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "TunerPresetView.h"
#import "NLBrowseList.h"

@implementation TunerPresetView

@synthesize tuner = _tuner;

- (void) dealloc
{
  [_presetTableView release];
  [_listBarButton release];
  [_deleteRefreshButton release];
  [_tuner release];
  [_listPopover release];
  [_listNavigationController release];
  [_currentBrowseList release];
  [_branchBrowseList release];
  [_leafBrowseList release];
  [_deletePresetsAlertView release];
  [_refreshPresetsAlertView release];
  [super dealloc];
}

- (void) reAssignList: (id<ListDataSource> *) list toNewList: (id<ListDataSource>) newList
{
  id<ListDataSource> oldList = *list;

  if (oldList != newList)
  {
    *list = nil;
    if (oldList != nil)
    {
      if (oldList != _currentBrowseList && oldList != _branchBrowseList && 
          oldList != _leafBrowseList)
        [oldList removeDelegate: self];
      [oldList release];
    }
    
    if (newList != _currentBrowseList && newList != _branchBrowseList && 
        newList != _leafBrowseList)
      [newList addDelegate: self];
    *list = [newList retain];
  }
}

- (void) reassignBrowseList
{
  [self reAssignList: &_currentBrowseList toNewList: _tuner.browseMenu];
}

- (void) delayedSetup
{
  [self reassignBrowseList];
  [_presetTableView reloadData];
  [self performSelector: @selector(updateLists) withObject: nil afterDelay: 1.5];
  [self performSelector: @selector(setStartingList) withObject: nil afterDelay: 1.5];
}

- (void) setupOnViewWillAppear
{
  if (_tuner.browseMenu == nil)
    self.hidden = YES;
  else
    self.hidden = NO;
  
  // Cannot always rely on a callback from source tuner
  [self performSelector: @selector(delayedSetup) withObject: nil afterDelay: 2];
}

-(void)updateDeleteRefreshButtonWithTitle:(NSString*)title
{
  _listBarButton.title = title;
  
  if([_listBarButton.title isEqualToString:@"Presets"])
    _deleteRefreshButton.title = NSLocalizedString(@"Remove All", @"Title for delete preset button");
  else
    _deleteRefreshButton.title = NSLocalizedString(@"Refresh", @"Title for refresh preset button");
}

-(void)updateLeafTable
{
  [_leafBrowseList release];
  _leafBrowseList = [_currentBrowseList retain];
  [self updateDeleteRefreshButtonWithTitle:[_currentBrowseList listTitle]];
  [_presetTableView reloadData];
  
  if(_listPopover.popoverVisible)
    [_listPopover dismissPopoverAnimated:YES];
}

-(void)setButtonEnabledStates
{
  NSInteger numLists = [_branchBrowseList countOfList];	
  _listBarButton.enabled = (numLists > 1) ? YES : NO;			// Only let users press list button if more than one list
  _deleteRefreshButton.enabled = ([_tuner capabilities] & SOURCE_TUNER_HAS_DYNAMIC_PRESETS) ? YES : NO; // Only enable delete/refresh button if dab/fm/am
}

-(void)setStartingList
{	
  //	NSLog(@"***Set starting list");
  
  NSInteger numLists = [_currentBrowseList countOfList];
  
  // Set Starting List to be Presets
  BOOL foundPresets = NO;
  int startingListID = 0;
  for(int i = 0; i < numLists; i++)
    if([((NSString*)[_currentBrowseList titleForItemAtIndex:i]) isEqual: @"Presets"])
    {
      startingListID = i;
      foundPresets = YES;
      break;
    }
  
  if(foundPresets)
  {
    [_branchBrowseList release];
    _branchBrowseList = [_currentBrowseList retain];
    
    // Reassign current browse list, set leaf to it and reload preset table
    [self reAssignList:&_currentBrowseList toNewList:[_tuner.browseMenu selectItemAtIndex:startingListID executeAction:NO]];
    [self updateLeafTable];
  }
  
  [self setButtonEnabledStates];
}

- (void) updateLists
{
  //	NSLog(@"***Update Lists");
  
  NSUInteger count = [_currentBrowseList countOfListInSection: 0];
  BOOL listHasChildren = NO;
  
  // Find if any of current menu has children (if the list is ready to be read)
  if (count != NSUIntegerMax)
  {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];

    for (int i = 0; i < count; i++)
    {
      NSString *childrenStr = [[_currentBrowseList itemAtOffset: i inSection: 0] objectForKey: @"children"];
      if ((childrenStr != nil) && ([[formatter numberFromString: childrenStr] intValue] > 0))
      {
        listHasChildren = YES;
        break;
      }
    }

    [formatter release];
  }
  
  if (listHasChildren)
  {
    // Show a new menu in the popover
    
    BranchTableViewController *childTableViewController = [[[BranchTableViewController alloc] initWithStyle: UITableViewStylePlain] autorelease];
    childTableViewController.tableView.delegate = self;
    childTableViewController.tableView.dataSource = self;
    childTableViewController.browseList = _currentBrowseList;	// Used for reference later
    //		for(int i =0; i < [_currentBrowseList countOfList]; i++)
    //			NSLog(@"%@", [_currentBrowseList itemAtIndex:i]);
    
    CGSize tableSize = CGSizeMake( 320, ([_currentBrowseList countOfList] * 44) );
    childTableViewController.view.frame = CGRectMake(0, 0, tableSize.width, tableSize.height);
    childTableViewController.contentSizeForViewInPopover = tableSize;
    //		NSLog(@"Setting vc %@ to %@", childTableViewController, NSStringFromCGSize(tableSize));
    
    if (_listPopover.popoverVisible)
      _listPopover.popoverContentSize = CGSizeMake( tableSize.width, tableSize.height + 40 );
    
    if (_listNavigationController == nil)
    {
      _listNavigationController = [[UINavigationController alloc] initWithRootViewController: childTableViewController];
      _listNavigationController.navigationBar.topItem.title = @"Lists";
      _listNavigationController.delegate = self;
    }
    else if (((BranchTableViewController *) (_listNavigationController.topViewController)).browseList != _currentBrowseList)
    {
      // The condition for this block avoids pushing same vc onto navigation controller
      [_listNavigationController pushViewController: childTableViewController animated: YES];
      _listNavigationController.navigationBar.topItem.title = [_currentBrowseList listTitle];
    }
    
    [_branchBrowseList release];
    _branchBrowseList = [_currentBrowseList retain];
  }
  else
  {
    // Update the preset view
    [self updateLeafTable];
  }

  [((BranchTableViewController *) [_listNavigationController topViewController]).tableView reloadData];	
}

- (void) cleanupOnViewDidDisappear
{
  [self reAssignList: &_currentBrowseList toNewList: nil];
  [self reAssignList: &_branchBrowseList toNewList: nil];
  [self reAssignList: &_leafBrowseList toNewList: nil];
}

-(void)deselectPreset
{
  [_presetTableView deselectRowAtIndexPath:[_presetTableView indexPathForSelectedRow] animated:NO];
}

-(void)reloadTableView
{
  [_presetTableView performSelector:@selector(reloadData) withObject:nil afterDelay:2];
}

-(IBAction)listBarButtonPressed:(id)control
{
  if(_listPopover == nil)
  {
    if(_listNavigationController == nil)
    {
      //			[self reAssignList:&_currentBrowseList toNewList:_tuner.browseMenu];
      //			[self updateLists];
      return;
    }
    _listPopover = [[UIPopoverController alloc] initWithContentViewController:_listNavigationController];
  }
  
  if(_listPopover.popoverVisible)
    [_listPopover dismissPopoverAnimated:YES];
  else
  {
    if(_listNavigationController.topViewController != nil)	// Should never be non-nil
      _listPopover.popoverContentSize = CGSizeMake(320, _listNavigationController.topViewController.contentSizeForViewInPopover.height + 40);
    [_listPopover presentPopoverFromBarButtonItem:_listBarButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];	
  }
}

-(IBAction)deleteRefreshButtonPressed:(id)control
{
  if([_deleteRefreshButton.title isEqualToString:@"Refresh"])
  {
    [_refreshPresetsAlertView release];
    _refreshPresetsAlertView = [[UIAlertView alloc] 
                                initWithTitle: nil message:NSLocalizedString( @"Refresh Channels", @"Title for refresh channels dialog" )
                                delegate: self
                                cancelButtonTitle: NSLocalizedString( @"No", @"" )
                                otherButtonTitles: NSLocalizedString( @"Yes", @""), nil];
    [_refreshPresetsAlertView show];
  }
  else
  {
    [_deletePresetsAlertView release];
    _deletePresetsAlertView =  [[UIAlertView alloc] 
                                initWithTitle: nil message:NSLocalizedString( @"Delete All Presets", @"Title for clear all presets dialog" )
                                delegate: self
                                cancelButtonTitle: NSLocalizedString( @"No", @"" )
                                otherButtonTitles: NSLocalizedString(@"Yes", @""), nil];
    
    [_deletePresetsAlertView show];
  }	
}

- (void) listDataRefreshDidStart: (id<ListDataSource>) listDataSource
{	
  //	NSLog(@"List of presets refresh start.....");
}

- (void) listDataRefreshDidEnd: (id<ListDataSource>) listDataSource
{
  //	NSLog(@"List of presets refresh end.....");
}

- (void) itemsChangedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  //	NSLog(@"Item changed in list %@", [listDataSource listTitle]);
  [self updateLists];
}

- (void) itemsInsertedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  //	NSLog(@"Item inserted....");
}

- (void) itemsRemovedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  //	NSLog(@"Item removed in list %@", [listDataSource listTitle]);
}

- (void) currentItemForListData: (id<ListDataSource>) listDataSource
                    changedFrom: (id) old to: (id) new at: (NSUInteger) index
{
  //	NSLog(@"Current Item in list %@ changed", [listDataSource listTitle]);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
  if(tableView == _presetTableView)
  {
    NSInteger numSections = [_leafBrowseList countOfSections];
    if(numSections == 0)
      numSections = 1;
    return numSections;
  }
  else
    return 1;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  if(tableView == _presetTableView)
  {
    NSInteger numLists = [_leafBrowseList countOfListInSection:section ];
    return numLists;
  }
  else
  {
    NSInteger numLists = [_branchBrowseList countOfList ];
    return numLists;
  }
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];	
  if (cell == nil)
    cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier] autorelease];
  
  if(tableView == _presetTableView)
  {
    NSDictionary *presetEntry = [_leafBrowseList itemAtOffset:indexPath.row inSection:indexPath.section];
    cell.textLabel.text = [presetEntry objectForKey:@"display"];
    
    if([_leafBrowseList itemIsSelectableAtOffset:indexPath.row inSection:indexPath.section])
    {
      cell.textLabel.textColor = [UIColor blackColor];
      cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    else
    {
      cell.textLabel.textColor = [UIColor grayColor];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
  }
  else
  {
    NSDictionary *presetEntry = [_branchBrowseList itemAtOffset:indexPath.row inSection:indexPath.section];
    cell.textLabel.text = [presetEntry objectForKey:@"display"];
    if([cell.textLabel.text isEqualToString:[_leafBrowseList listTitle]])
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
      cell.accessoryType = UITableViewCellAccessoryNone;
  }
  
  return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if(tableView == _presetTableView)
  {
    if([_leafBrowseList itemIsSelectableAtOffset:indexPath.row inSection:indexPath.section])
      return indexPath;
    else
      return nil;
  }
  else
    return indexPath;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  if(tableView == _presetTableView)
  {
    [_leafBrowseList selectItemAtOffset: indexPath.row inSection: indexPath.section];
  }
  else
  {
    [self reAssignList:&_currentBrowseList toNewList:[_branchBrowseList selectItemAtOffset: indexPath.row inSection: indexPath.section]];
    
    if([[_currentBrowseList listTitle] isEqualToString:@"Presets"])
    {
      [self updateLeafTable];
      
      [((UITableViewController*)(_listNavigationController.topViewController)).tableView reloadData];
    }		
  }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if(alertView == _deletePresetsAlertView)
  {
    if(buttonIndex == 1)
    {
      [_tuner clearAllPresets];
      [_presetTableView performSelector:@selector(reloadData) withObject:nil afterDelay:4];	// Feedback is missing from the tuner when presets are cleared and it can take a while
    }
  }
  else if (alertView == _refreshPresetsAlertView)
  {
    if(buttonIndex == 1)
      [_tuner rescanChannels];
  }
}

// Needed in order to track the current browse list when user moves back using the navigation controller
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  BranchTableViewController *vc = (BranchTableViewController*)viewController;
  [self reAssignList:&_currentBrowseList toNewList:vc.browseList];
  [_branchBrowseList release];
  _branchBrowseList = [_currentBrowseList retain];
  [vc.tableView reloadData];
  
  vc.contentSizeForViewInPopover = CGSizeMake(320, [_branchBrowseList countOfList] * 44);
  //	NSLog(@"Setting vc %@ to %@", vc, NSStringFromCGSize(vc.contentSizeForViewInPopover));
  
  if(_listPopover.popoverVisible)
    _listPopover.popoverContentSize = CGSizeMake(320, ([_branchBrowseList countOfList] * 44) + 40);
}

-(void)rotated
{
  if(_listPopover.popoverVisible)
  {
    [_listPopover dismissPopoverAnimated:NO];		// Need to dismiss it due to a strange system bug where the navigation bar disappears.
    [_listPopover presentPopoverFromBarButtonItem:_listBarButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
  }
}
@end

@implementation BranchTableViewController

@synthesize browseList = _browseList;

@end
