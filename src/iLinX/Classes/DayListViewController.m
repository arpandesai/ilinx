//
//  DayListViewController.m
//  iLinX
//
//  Created by mcf on 09/06/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "DayListViewController.h"
#import "DeprecationHelper.h"
#import "NLTimer.h"
#import "SelectableListViewCell.h"
#import "TimersViewController.h"

@implementation DayListViewController

- (id) initWithTimer: (NLTimer *) timer
{
  if (self = [super initWithStyle: UITableViewStyleGrouped])
  {
    self.title = NSLocalizedString( @"Repeat", @"Title of the view that sets the repeat on a timer" );
    _timer = [timer retain];
  }
  
  return self;
}

#pragma mark Table view methods

// Customize the number of rows in the table view.
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  return 7;
}


// Customize the appearance of table view cells.
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  static NSString *CellIdentifier = @"SelectableListViewCell";
    
  SelectableListViewCell *cell = (SelectableListViewCell *) [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  NSDateFormatter *formatter = [NSDateFormatter new];
  NSUInteger weekday = [TimersViewController sundayIndexedWeekdayForLocalWeekday: indexPath.row];

  if (cell == nil)
    cell = [[[SelectableListViewCell alloc] initDefaultWithFrame: CGRectMake( 0, 0, tableView.bounds.size.width, tableView.rowHeight )
                                                 reuseIdentifier: CellIdentifier
                                                           table: tableView] autorelease];

  cell.title = [NSString stringWithFormat: NSLocalizedString( @"Every %@", 
                @"String that takes a weekday name as a parameter to indicate every occurrence of that day" ),
                [[formatter weekdaySymbols] objectAtIndex: weekday]];
  [cell setBorderTypeForIndex: indexPath.row totalItems: 7];

  if ((_timer.repeatedDayBitmask & (1<<((weekday + 6) % 7))) == 0)
    cell.accessoryType = UITableViewCellAccessoryNone;
  else
    cell.accessoryType = UITableViewCellAccessoryCheckmark;

  [formatter release];

  return cell;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  NSUInteger mask = _timer.repeatedDayBitmask;
  NSUInteger weekday = ([TimersViewController sundayIndexedWeekdayForLocalWeekday: indexPath.row] + 6) % 7;
  
  if ((mask & (1<<weekday)) == 0)
  {
    mask |= (1<<weekday);
    [tableView cellForRowAtIndexPath: indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
  }
  else
  {
    mask &= ~(1<<weekday);
    [tableView cellForRowAtIndexPath: indexPath].accessoryType = UITableViewCellAccessoryNone;
  }
  
  if (mask == 0)
    [_timer setSingleEventOnDate: [NSDate date] atTime: _timer.eventTime];
  else
    [_timer setRepeatedEventOnDays: mask atTime: _timer.eventTime];
  
  [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

- (void) dealloc
{
  [_timer release];
  [super dealloc];
}

@end

