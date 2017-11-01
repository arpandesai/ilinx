//
//  ActionTypeViewController.m
//  iLinX
//
//  Created by mcf on 10/06/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "ActionTypeViewController.h"
#import "DeprecationHelper.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLSource.h"
#import "NLTimer.h"
#import "SelectableListViewCell.h"

@implementation ActionTypeViewController

- (id) initWithRoomList: (NLRoomList *) roomList timer: (NLTimer *) timer macroCount: (NSUInteger) macroCount
{
  if (self = [super initWithStyle: UITableViewStyleGrouped])
  {
    self.title = NSLocalizedString( @"Type", @"Title of the view that sets the type of a timer" );
    _timer = [timer retain];
    _roomList = [roomList retain];
    //NSLog( @"NLRoomList %08X retained by ActionTypeViewController %08X", roomList, self );
    if (_timer.cmdFormat != NLTIMER_CMD_FORMAT_SIMPLE_ALARM)
      _cmdFormat = _timer.cmdFormat;
    else if ([_timer.simpleAlarmSourceServiceName isEqualToString: [[NLSource noSourceObject] serviceName]])
      _cmdFormat = NLTIMER_CMD_FORMAT_MAX + 1;
    else
      _cmdFormat = _timer.cmdFormat;
    _originalCmdFormat = _cmdFormat;
    _macroCount = macroCount;
  }
  
  return self;
}

- (void) viewWillDisappear: (BOOL) animated
{
  if (_cmdFormat != _originalCmdFormat)
  {
    if (_cmdFormat == NLTIMER_CMD_FORMAT_MACRO)
      [_timer setTimedMacro: @"" room: nil];
    else if (_cmdFormat == NLTIMER_CMD_FORMAT_SIMPLE_ALARM)
      [_timer setSimpleAlarmForRoom: _roomList.currentRoom.serviceName source: @"" volume: 0];
    else
      [_timer setSimpleAlarmForRoom: _roomList.currentRoom.serviceName source: [[NLSource noSourceObject] serviceName] volume: 0];
  }
  
  [super viewWillDisappear: animated];
}

#pragma mark Table view methods

// Customize the number of rows in the table view.
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  if (_macroCount == 0)
    return 2;
  else
    return 3;
}


// Customize the appearance of table view cells.
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  static NSString *CellIdentifier = @"SelectableListViewCell";
  
  SelectableListViewCell *cell = (SelectableListViewCell *) [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  
  if (cell == nil)
    cell = [[[SelectableListViewCell alloc] initDefaultWithFrame: CGRectMake( 0, 0, tableView.frame.size.width, tableView.rowHeight )
                                          reuseIdentifier: CellIdentifier
                                                           table: tableView] autorelease];
  
  [cell setBorderTypeForIndex: indexPath.row totalItems: [self tableView: tableView numberOfRowsInSection: 0]];

  if (indexPath.row == 0)
  {
    cell.title = NSLocalizedString( @"Alarm", @"Timer action type: alarm" );
    cell.tag = NLTIMER_CMD_FORMAT_SIMPLE_ALARM;
  }
  else if (_macroCount == 0 || indexPath.row != 1)
  {
    cell.title = NSLocalizedString( @"Sleep", @"Timer action type: sleep" );
    cell.tag = NLTIMER_CMD_FORMAT_MAX + 1;
  }
  else
  {
    cell.title = NSLocalizedString( @"Macro", @"Timer action type: macro" );
    cell.tag = NLTIMER_CMD_FORMAT_MACRO;
  }

  if (cell.tag == _cmdFormat)
  {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    _selectedRow = indexPath.row;
  }
  else
    cell.accessoryType = UITableViewCellAccessoryNone;
  
  return cell;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  if (indexPath.row != _selectedRow)
  {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];

    _cmdFormat = cell.tag;
    [tableView cellForRowAtIndexPath: 
     [NSIndexPath indexPathForRow: _selectedRow inSection: 0]].accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    _selectedRow = indexPath.row;
  }

  [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

- (void) dealloc
{
  [_timer release];
  //NSLog( @"NLRoomList %08X to be released by ActionTypeViewController %08X", _roomList, self );
  [_roomList release];
  [super dealloc];
}

@end

