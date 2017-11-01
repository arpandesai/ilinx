//
//  ConfigOptionViewController.m
//  iLinX
//
//  Created by mcf on 28/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "ConfigOptionViewController.h"
#import "ConfigProfile.h"
#import "DeprecationHelper.h"
#import "SelectableListViewCell.h"
#import "StandardPalette.h"

@implementation ConfigOptionViewController

@synthesize
  delegate = _delegate;

- (id) initWithTitle: (NSString *) title options: (NSArray *) options chosenOption: (NSInteger) chosenOption
{
  if (self = [super initWithStyle: UITableViewStyleGrouped])
  {
    self.title = title;
    _options = [options retain];
    _chosenOption = chosenOption;
  }
  
  return self;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  return [_options count];
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  static NSString *CellIdentifier = @"Cell";
  SelectableListViewCell *cell = (SelectableListViewCell *) [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  
  if (cell == nil)
    cell = [[[SelectableListViewCell alloc] initDefaultWithFrame: CGRectMake( 0, 0, tableView.bounds.size.width, tableView.rowHeight )
                                                 reuseIdentifier: CellIdentifier
                                                           table: tableView] autorelease];
  
  cell.title = [_options objectAtIndex: indexPath.row];
  [cell setBorderTypeForIndex: indexPath.row totalItems: [_options count]];

  if (indexPath.row == _chosenOption)
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  else
    cell.accessoryType = UITableViewCellAccessoryNone;
  
  return cell;
}

- (NSIndexPath *) tableView: (UITableView *) tableView willSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  return indexPath;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  if (_chosenOption != indexPath.row)
  {
    if (_chosenOption < [_options count])
      [tableView cellForRowAtIndexPath: 
       [NSIndexPath indexPathForRow: _chosenOption inSection: 0]].accessoryType = UITableViewCellAccessoryNone;
    _chosenOption = indexPath.row;
    [tableView cellForRowAtIndexPath: indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    [_delegate chosenConfigOption: indexPath.row];
  }
  [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

- (void) dealloc
{
  [_options release];
  [super dealloc];
}

@end

