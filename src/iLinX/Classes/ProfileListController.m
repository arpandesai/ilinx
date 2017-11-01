//
//  ProfileListController.m
//  iLinX
//
//  Created by mcf on 27/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "ProfileListController.h"
#import "BorderedTableViewCell.h"
#import "ConfigManager.h"
#import "ConfigProfile.h"
#import "ConfigRootController.h"
#import "CustomViewController.h"
#import "DeprecationHelper.h"
#import "ProfileViewController.h"
#import "StandardPalette.h"
#if !defined(IPAD_BUILD)
#import "CustomViewController.h"
#endif
#import "iLinXAppDelegate.h"

@interface ProfileListController ()

- (void) delayedSetEditing: (NSNumber *) flags;
- (void) editPressed;
- (void) donePressed;
- (void) dismissPressed;
- (void) saveChanges;

@end

@implementation ProfileListController

- (id) initWithStyle: (UITableViewStyle) style
{
  if (self = [super initWithStyle: style])
  {
#if !defined(IPAD_BUILD)
    _customPage = [[CustomViewController alloc] initWithController: self customPage: @"profiles.htm"];
    if (![_customPage isValid])
    {
      [_customPage release];
      _customPage = nil;
    }
#endif
  }
  
  return self;
}

- (void) viewDidLoad
{
  UIBarButtonItem *rightItem;

  [super viewDidLoad];
  
  if ([self.navigationController.viewControllers count] <= 1)
  {
    rightItem = [[UIBarButtonItem alloc]
                 initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                 target: self action: @selector(dismissPressed)];
    
#if !defined(IPAD_BUILD)
    if (_customPage != nil)
    {
      [_customPage loadViewWithFrame: self.view.bounds];
      self.tableView.hidden = YES;
      self.view = _customPage.view;
    } 
#endif
  }
  else
  {
    rightItem = [[UIBarButtonItem alloc] 
                 initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                 target: self action: @selector(editPressed)];
    
#if !defined(IPAD_BUILD)
    [_customPage release];
    _customPage = nil;
#endif
  }
  self.navigationItem.rightBarButtonItem = rightItem;
  [rightItem release];    
  self.tableView.allowsSelectionDuringEditing = YES;

#if !defined(IPAD_BUILD)
  if (_customPage == nil || [_customPage.title length] == 0)
#endif
    self.navigationItem.title = NSLocalizedString( @"Profiles", @"Title of profiles list view" );
#if !defined(IPAD_BUILD)
  else
    self.navigationItem.title = _customPage.title;
#endif
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
#if !defined(IPAD_BUILD)
  [_customPage viewWillAppear: animated];
#endif
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];

  [StandardPalette setTintForNavigationBar: self.navigationController.navigationBar];
  [_profileListCopy release];
  _profileListCopy = [[ConfigManager profileList] mutableCopy];
  _currentProfile = [ConfigManager currentProfile];
  if (_originalProfile == nil)
    _originalProfile = [[ConfigManager currentProfileData] mutableCopy];
  [self.tableView reloadData];
}

- (void) viewWillDisappear: (BOOL) animated
{
#if !defined(IPAD_BUILD)
  [_customPage viewWillDisappear: animated];
#endif
  [super viewWillDisappear: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
  [self saveChanges];
  [_profileListCopy release];
  _profileListCopy = nil;
  [super viewDidDisappear: animated];
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
  return 1;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  NSInteger count = [_profileListCopy count];

  if (tableView.editing)
    ++count;
  
  return count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  static NSString *CellIdentifier = @"ProfileCell";
  NSInteger count = [_profileListCopy count];

  BorderedTableViewCell *cell = (BorderedTableViewCell *) [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    
  if (cell == nil)
    cell = [[[BorderedTableViewCell alloc] initDefaultWithFrame: CGRectZero reuseIdentifier: CellIdentifier
                                                          table: tableView] autorelease];
  else 
    [cell refreshPaletteToVersion: _paletteVersion];

  if (_inEditMode)
    ++count;
  [cell setBorderTypeForIndex: indexPath.row totalItems: count];

  if (indexPath.row >= [_profileListCopy count])
  {
    [cell setLabelText: @""];
    [cell setHasAccessoryWhenEditing: NO];
    cell.accessoryType = UITableViewCellAccessoryNone;
    [cell setAccessoryWhenEditing: UITableViewCellAccessoryNone];
  }
  else
  {
    [cell setLabelText: [(ConfigProfile *) [_profileListCopy objectAtIndex: indexPath.row] name]];
    if (indexPath.row == _currentProfile)
      [cell setLabelTextColor: [StandardPalette highlightedTableTextColour]];
    else 
      [cell setLabelTextColor: [StandardPalette tableTextColour]];

    if (_inEditMode)
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    else if (indexPath.row == _currentProfile)
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
      cell.accessoryType = UITableViewCellAccessoryNone;
    [cell setAccessoryWhenEditing: UITableViewCellAccessoryDisclosureIndicator];
  }

  return cell;
}

// Set the editing state of the view controller. We pass this down to the table view and also modify the content
// of the table to insert a placeholder row for adding content when in editing mode.
- (void) setEditing: (BOOL) editing animated: (BOOL) animated
{
  NSNumber *flags = [NSNumber numberWithInteger: (editing?1:0) + (animated?2:0)];

  _inEditMode = editing;
  if (!editing)
  {
    // Copy the edited list back into the main list
    [self saveChanges];
  }
  [self.tableView reloadData];
  [self performSelector: @selector(delayedSetEditing:) withObject: flags afterDelay: 0];
}

- (void) delayedSetEditing: (NSNumber *) flags
{
  NSInteger intFlags = [flags integerValue];
  BOOL editing = ((intFlags & 1) != 0);
  BOOL animated = ((intFlags & 2) != 0);
  NSArray *indexPaths = [NSArray arrayWithObjects:
                         [NSIndexPath indexPathForRow: [_profileListCopy count] inSection: 0], nil];
  UITableViewRowAnimation rowAnimation;  
  
  [super setEditing: editing animated: animated];

  [self.tableView beginUpdates];
  [self.tableView setEditing: editing animated: animated];

  if (animated)
    rowAnimation = UITableViewRowAnimationTop;
  else
    rowAnimation = UITableViewRowAnimationNone;

  if (editing)
  {
    // Show the placeholder rows
    [self.tableView insertRowsAtIndexPaths: indexPaths withRowAnimation: rowAnimation];
  } 
  else
  {
    // Hide the placeholder rows.
    [self.tableView deleteRowsAtIndexPaths: indexPaths withRowAnimation: rowAnimation];
  }

  [self.tableView endUpdates];
}

- (BOOL) tableView: (UITableView *) tableView canEditRowAtIndexPath: (NSIndexPath *) indexPath
{
  BOOL canEdit = tableView.editing;
  
  if (canEdit)
  {
    NSInteger count = [_profileListCopy count];

    canEdit = (count > 1 || indexPath.row >= count);
  }
  
  return canEdit;
}

- (UITableViewCellEditingStyle) tableView: (UITableView *) tableView editingStyleForRowAtIndexPath: (NSIndexPath *) indexPath
{
  if (indexPath.row >= [_profileListCopy count])
    return UITableViewCellEditingStyleInsert;
  else
    return UITableViewCellEditingStyleDelete;
}

- (void) tableView: (UITableView *) tableView commitEditingStyle: (UITableViewCellEditingStyle) editingStyle
 forRowAtIndexPath: (NSIndexPath *) indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete)
  {
    if (indexPath.row == _currentProfile)
      _currentProfile = 0;
    [_profileListCopy removeObjectAtIndex: indexPath.row];
    [tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath] withRowAnimation: YES];
  }   
  else if (editingStyle == UITableViewCellEditingStyleInsert)
  {
    ConfigProfile *newProfile = [[ConfigProfile alloc] init];
    
    [_profileListCopy insertObject: newProfile atIndex: indexPath.row];
    [newProfile release];
    [tableView reloadData];
  }   
}

- (BOOL) tableView: (UITableView *) tableView canMoveRowAtIndexPath: (NSIndexPath *) indexPath
{
  return (indexPath.row < [_profileListCopy count]);
}

- (NSIndexPath *) tableView: (UITableView *) tableView targetIndexPathForMoveFromRowAtIndexPath: (NSIndexPath *) sourceIndexPath 
        toProposedIndexPath: (NSIndexPath *) proposedDestinationIndexPath
{
  NSInteger count = [_profileListCopy count];
  
  if (proposedDestinationIndexPath.row >= count)
    proposedDestinationIndexPath = [NSIndexPath indexPathForRow: count - 1 inSection: 0];
  
  return proposedDestinationIndexPath;
}

- (void) tableView: (UITableView *) tableView moveRowAtIndexPath: (NSIndexPath *) fromIndexPath toIndexPath: (NSIndexPath *) toIndexPath
{
  NSInteger fromRow = fromIndexPath.row;
  NSInteger toRow = toIndexPath.row;

  if (fromRow != toRow)
  {
    if (fromRow == _currentProfile)
      _currentProfile = toRow;
    else
    {
      if (fromRow < _currentProfile)
        --_currentProfile;
      if (toRow <= _currentProfile)
        ++_currentProfile;
    }
    
    if (toRow > fromRow)
      ++toRow;
    [_profileListCopy insertObject: [_profileListCopy objectAtIndex: fromRow] atIndex: toRow];
    if (toRow <= fromRow)
      ++fromRow;
    [_profileListCopy removeObjectAtIndex: fromRow];
  }
}

- (NSIndexPath *) tableView: (UITableView *) tableView willSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  if (indexPath.row < [_profileListCopy count])
    return indexPath;
  else
    return nil;
}

- (void) refreshPalette
{
  [super refreshPalette];
  [StandardPalette setTintForNavigationBar: self.navigationController.navigationBar];
  [self.navigationController.navigationBar setNeedsDisplay];
  for (UIView *view in self.navigationController.navigationBar.subviews)
    [view setNeedsDisplay];
  
  UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone target: nil action: nil];
  
  self.navigationItem.backBarButtonItem = backButton;
  [backButton release];
  self.navigationItem.backBarButtonItem = nil;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  if (tableView.editing)
  {
    ProfileViewController *profileViewController = [[ProfileViewController alloc]
                                                    initWithProfile: [_profileListCopy objectAtIndex: indexPath.row]];

    [self.navigationController pushViewController: profileViewController animated: YES];
    [profileViewController release];
  }
  else
  {
    if (_currentProfile != indexPath.row) 
    {
      [tableView cellForRowAtIndexPath: 
       [NSIndexPath indexPathForRow: _currentProfile inSection: 0]].accessoryType = UITableViewCellAccessoryNone;
      _currentProfile = indexPath.row;
      [tableView cellForRowAtIndexPath: indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
      [ConfigManager setCurrentProfile: _currentProfile];
#if !defined(IPAD_BUILD)
      [CustomViewController maybeFetchConfig];
#endif
      [self performSelector: @selector(refreshPalette) withObject: nil afterDelay: 0.5];
    }
  }

  [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

- (void) editPressed
{
  UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] 
                                  initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                  target: self action: @selector(donePressed)];

  [self setEditing: YES animated: YES];
  self.navigationItem.rightBarButtonItem = rightButton;
  [rightButton release];
}

- (void) donePressed
{
  UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] 
                                  initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                  target: self action: @selector(editPressed)];
  
  [self setEditing: NO animated: YES];
  self.navigationItem.rightBarButtonItem = rightButton;
  [rightButton release];
}

- (void) dismissPressed
{
  if (![_originalProfile isEqual: [ConfigManager currentProfileData]])
    [(ConfigRootController *) [self navigationController] setProfileRefresh];
  
  [_originalProfile release];
  _originalProfile = nil;
  
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  [self dismissModalViewControllerAnimated: YES];
}

- (void) saveChanges
{
  [ConfigManager setProfileList: _profileListCopy];
  [ConfigManager setCurrentProfile: _currentProfile];
}

- (void) dealloc
{
  [_profileListCopy release];
  [_originalProfile release];
#if !defined(IPAD_BUILD)
  [_customPage release];
#endif
  [super dealloc];
}

@end

