//
//  TimersViewControllerIPad.m
//  iLinX
//
//  Created by Tony Short on 27/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "TimersViewControllerIPad.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLSource.h"
#import "NLTimer.h"
#import "NLTimerList.h"
#import "TimersViewCellIPad.h"
#import "DeprecationHelper.h"
#import "UncodableObjectArchiver.h"

// Possible states of the interface
enum 
{
  UncheckedState = 0,
  InvalidState,
  NoItemsState,
  AddState,
  EditState,
  ViewState
};

@interface TimersViewControllerIPad ()

- (void) updateToolbars;
- (void) addTimer;
- (void) enableTimerChanged: (UISwitch *) enableSwitch;
- (void) initialActivityTimeout: (NSTimer *) timer;
- (void) deleteTimerAtRow: (NSIndexPath *) indexPath;
- (void) selectNewRowAfterDeletingRow: (NSInteger) row;
- (void) refreshStateAfterChanges;
- (void) reloadTable;
- (void) ensureTimerSelected;

@end

@implementation TimersViewControllerIPad

+ (NSString *) dayListForRepeatMask: (NSUInteger) repeatMask
{
  NSDateFormatter *dateFormatter = [NSDateFormatter new];
  NSUInteger firstWeekday = [[NSCalendar currentCalendar] firstWeekday] - 1;
  NSUInteger limit = 7;
  NSArray *weekdays = [dateFormatter shortWeekdaySymbols];
  NSString *days = @"";
  NSUInteger i;
  
  if ([weekdays count] < 7)
    limit = [weekdays count];
  if (firstWeekday >= limit)
    firstWeekday = 0;
  
  // Adjustments are needed here as the weekdays are returned with Sunday first,
  // whereas we have Sunday last, and the days should be presented in locale
  // specific order, which could be different again.
  for (i = 0; i < limit; ++i)
  {
    if ((repeatMask & (1<<((i + limit - 1 + firstWeekday) % limit))) != 0)
      days = [days stringByAppendingFormat: @"%@ ", [weekdays objectAtIndex: (i + firstWeekday) % limit]];
  }
  
  if ([days length] > 0)
    days = [days substringToIndex: [days length] - 1];
  
  [dateFormatter release];
  
  return days;
}

+ (NSUInteger) sundayIndexedWeekdayForLocalWeekday: (NSUInteger) weekday
{
  NSUInteger firstWeekday = [[NSCalendar currentCalendar] firstWeekday] - 1;
  
  return (firstWeekday + weekday) % 7;
}

- (id) initWithOwner: (RootViewControllerIPad *) owner service: (NLService *) service
{
  self = [super initWithOwner: owner service: service
                      nibName: @"TimersViewIPad" bundle: nil];
  if (self != nil)
  {
    NSUInteger count = [self.roomList countOfListInSection: 1];
    NSMutableArray *roomNames = [NSMutableArray arrayWithCapacity: count];
    NSUInteger roomStringLength = 0;
    NSUInteger i;
    
    for (i = 0; i < count; ++i)
    {
      NSString *name = [self.roomList titleForItemAtOffset: i inSection: 1];
      
      [roomNames addObject: name];
      roomStringLength += [name length];
    }
    
    _timersService = [(NLServiceTimers *) service retain];
    
    // DigiLinX messages must be less than 1000 characters.  If we have a
    // huge list of names that might exceed this length, don't bother to
    // filter - it probably means that we're authorised to see all rooms anyway...
    if (roomStringLength > 0 && roomStringLength < 500)
      [_timersService.timers filterByListOfRooms: roomNames];		
  }
  
  return self;
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  
  [self updateToolbars];
  [self service: _timersService changed: 0xFFFFFFFF];
  [_timersService addDelegate: self];
  [_timersService.timers addDelegate: self];
  [self itemsChangedInListData: _timersService.timers range: NSMakeRange( 0, [_timersService.timers countOfList] )];
  [_editTimerView setRoomList: self.roomList timersService: _timersService];
  [self reloadTable];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_editTimerView commitTimer];
  [_newTimer release];
  _newTimer = nil;
  [_timersService.timers removeDelegate: self];
  [_timersService removeDelegate: self];
  [self initialActivityTimeout: nil];
  [super viewWillDisappear: animated];  
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];	
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  _initialActivityTimer = [NSTimer scheduledTimerWithTimeInterval: 5.0 target: self 
                                                         selector: @selector(initialActivityTimeout:)
                                                         userInfo: nil repeats: NO];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
  // Overriden to allow any orientation.
  return YES;
}

- (void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation) fromInterfaceOrientation
{
  [self reloadTable];
}

#pragma mark Table view methods

// Customize the number of rows in the table view.
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  NSInteger count = (NSInteger) [_timersService.timers countOfList];
  
  if ([_timersService isLicensed])
  {
    if (_newTimer == nil)
    {
      if (_status < AddState && count > 0)
        _status = ViewState;
    }
    else 
    {
      ++count;
      if (_status < AddState)
        _status = AddState;
    }
  }
  else
  {
    count = 0;
  }
  
  return count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: _templateCell.reuseIdentifier];
    
  if (cell == nil)
  {
    cell = [UncodableObjectUnarchiver unarchiveObjectWithDictionary: 
            [UncodableObjectArchiver dictionaryEncodingWithRootObject: _templateCell]];
    for (int i = 0; i < 32; ++i)
    {
      for (NSString *selector in [_templateCell.enabledSwitch actionsForTarget: _templateCell forControlEvent: 1<<i])
      {
        [((TimersViewCellIPad *) cell).enabledSwitch
         addTarget: cell action: NSSelectorFromString( selector ) forControlEvents: 1<<i];
      }
    }
  }
    
  if (indexPath.row < [_timersService.timers countOfList])
    ((TimersViewCellIPad *) cell).timer = [_timersService.timers itemAtIndex: indexPath.row];
  else
    ((TimersViewCellIPad *) cell).timer = _newTimer;
  ((TimersViewCellIPad *) cell).timerTag = indexPath.row;

  if ((_status != AddState && _status != EditState) || 
      [((TimersViewCellIPad *) cell).timer.permId isEqualToString: _editTimerView.timer.permId])
    cell.contentView.alpha = 1.0;
  else
    cell.contentView.alpha = 0.2;

  return cell;
}

- (NSString *) tableView: (UITableView *) tableView titleForDeleteConfirmationButtonForRowAtIndexPath: (NSIndexPath *) indexPath
{
  return  NSLocalizedString( @"Delete", @"Timer action type: macro" );
}

- (NSIndexPath *) tableView: (UITableView *) tableView willSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  if (_status == ViewState)
    return indexPath;
  else
    return nil;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];
  NLTimer *timer;

  if (indexPath.row == [_timersService.timers countOfList])
    timer = _newTimer;
  else
  {
    timer = [_timersService.timers itemAtIndex: indexPath.row];
  
    if (_status == InvalidState || _status == NoItemsState)
    {
      _status = ViewState;
      [self updateToolbars];
    }
  }
  
  if (![timer.permId isEqualToString: _editTimerView.timer.permId])
  {
    _editTimerView.timer = timer;
    if (timer != _newTimer)
      [_timersService.timers selectItemAtIndex: indexPath.row];
  }

  if (cell != nil)
    cell.contentView.alpha = 1.0;
}

- (void) tableView: (UITableView *) tableView commitEditingStyle: (UITableViewCellEditingStyle) editingStyle 
 forRowAtIndexPath: (NSIndexPath *) indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete)
    [self deleteTimerAtRow: indexPath];
}

- (void) tableView: (UITableView *) tableView didEndEditingRowAtIndexPath: (NSIndexPath *) indexPath
{
  [self ensureTimerSelected];
}

- (void) service: (NLServiceTimers *) service changed: (NSUInteger) changed
{
  if ((changed & (SERVICE_TIMERS_TIMERS_LIST_CHANGED|SERVICE_TIMERS_IS_LICENSED_CHANGED)) != 0)
  {
    [self updateToolbars];
    [self reloadTable];
    
    if (_initialActivityTimer != nil)
      [self initialActivityTimeout: nil];
  }
}

- (void) itemsChangedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [self reloadTable];
}

- (void) listDataRefreshDidStart: (id<ListDataSource>) listDataSource
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void) listDataRefreshDidEnd: (id<ListDataSource>) listDataSource
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void) updateToolbars
{
  if (![_timersService licenceChecked])
    _status = UncheckedState;
  else if (_status != InvalidState && ![_timersService isLicensed])
    _status = InvalidState;
  else if (_status == UncheckedState || _status == InvalidState)
  {
    if ([_timersService.timers countOfList] == 0)
      _status = NoItemsState;
    else
      _status = ViewState;
  }

  switch (_status)
  {
    case UncheckedState:
      _addBar.hidden = YES;
      _editBar.hidden = YES;
      _saveCancelBar.hidden = YES;
      _deleteButton.hidden = YES;
      _editTimerView.hidden = NO;
      _noServiceView.hidden = YES;
      _noTimersMessage.hidden = NO;
      break;
    case NoItemsState:
      _addBar.hidden = NO;
      _editBar.hidden = YES;
      _saveCancelBar.hidden = YES;
      _deleteButton.hidden = YES;
      _editTimerView.hidden = NO;
      _noServiceView.hidden = YES;
      _noTimersMessage.hidden = NO;
      break;
    case AddState:
      _addBar.hidden = YES;
      _editBar.hidden = YES;
      _saveCancelBar.hidden = NO;
      _deleteButton.hidden = YES;
      _editTimerView.hidden = NO;
      _noServiceView.hidden = YES;
      _noTimersMessage.hidden = YES;
      break;
    case EditState:
      _addBar.hidden = YES;
      _editBar.hidden = YES;
      _saveCancelBar.hidden = NO;
      _deleteButton.hidden = NO;
      _editTimerView.hidden = NO;
      _noServiceView.hidden = YES;
      _noTimersMessage.hidden = YES;
      break;
    case ViewState:
      _addBar.hidden = NO;
      _editBar.hidden = NO;
      _saveCancelBar.hidden = YES;
      _deleteButton.hidden = YES;
      _editTimerView.hidden = NO;
      _noServiceView.hidden = YES;
      _noTimersMessage.hidden = YES;
      break;
    case InvalidState:
    default:
      _addBar.hidden = YES;
      _editBar.hidden = YES;
      _saveCancelBar.hidden = YES;
      _deleteButton.hidden = YES;
      _editTimerView.hidden = YES;
      _noServiceView.hidden = NO;
      _noTimersMessage.hidden = YES;
      break;
  }
  _coverButton.hidden = !_saveCancelBar.hidden;
  _timersTableView.userInteractionEnabled = _saveCancelBar.hidden;
  _barDivider.hidden = !_noServiceView.hidden;
  _editControls.hidden = !_noTimersMessage.hidden;
}

- (IBAction) addTimer
{
  _newTimer = [[NLTimer alloc] initWithTimersService: _timersService];
  [_newTimer setSimpleAlarmForRoom: self.roomList.currentRoom.serviceName 
                            source: [[NLSource noSourceObject] serviceName] volume: 0];
  _status = AddState;
  [self updateToolbars];

  _newTimer.enabled = YES;
  _editTimerView.timer = _newTimer;
  [self reloadTable];
}

- (void) enableTimerChanged: (UISwitch *) enableSwitch
{
  NLTimer *timer = [_timersService.timers itemAtIndex: enableSwitch.tag];
  
  if (timer != nil)
  {
    timer.enabled = enableSwitch.on;
    [timer commitChanges];
  }
}

- (void) initialActivityTimeout: (NSTimer *) timer
{
  if (timer == nil)
    [_initialActivityTimer invalidate];
  _initialActivityTimer = nil;
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  [self updateToolbars];
  [self reloadTable];
}

- (void) reloadTable 
{
  [_timersTableView reloadData];
  [self performSelector: @selector(ensureTimerSelected) withObject: nil afterDelay: 0];
}

- (void) ensureTimerSelected
{
  NSInteger count = (NSInteger) [_timersService.timers countOfList];
  NLTimer *timer;
  NSInteger row;
  
  [self updateToolbars];
  if (_newTimer != nil)
  {
    row = count;
    timer = _newTimer;
  }
  else if (count == 0)
  {
    row = NSNotFound;
    timer = nil;
  }
  else
  {
    row = [_timersService.timers listDataCurrentItemIndex];
    
    if (row >= count)
      row = 0;
    timer = (NLTimer *) [_timersService.timers itemAtIndex: row];
  }

  if (row != NSNotFound && [_timersTableView indexPathForSelectedRow] == nil)
  {
    NSIndexPath *newIndex = [NSIndexPath indexPathForRow: row inSection: 0];
      
    [_timersTableView selectRowAtIndexPath: newIndex animated: NO 
                            scrollPosition: UITableViewScrollPositionNone];
    [self tableView: _timersTableView didSelectRowAtIndexPath: newIndex];
  }

  if (_status != EditState && _status != AddState)
    _editTimerView.timer = timer;
}

- (void) deleteTimerAtRow: (NSIndexPath *) indexPath
{
  NLTimer *timerToDelete = [_timersService.timers itemAtIndex: indexPath.row];
  BOOL deletingCurrentTimer = (timerToDelete == _editTimerView.timer);
  
  NSUInteger oldCount = [_timersService.timers countOfList];
  
  [_timersService.timers deleteTimerAtIndex: indexPath.row];
  
  // There is a possible race condition between the server deleting the timer and forcing a list update and us
  // manually deleting it from the list.   We need to try to manually delete it to avoid the possibility of the
  // user requesting a delete but the row not disappearing, however if the row has already disappeared we get
  // an exception.  Hence this.
  @try
  {
    NSUInteger newCount = [_timersService.timers countOfList];
    
    if (oldCount == newCount && indexPath.row < newCount)
      [_timersTableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
                              withRowAnimation: UITableViewRowAnimationFade];
  }
  @catch (id exception)
  {
    // Ignore
  }
  
  // If we've deleted the last timer, end the editing session.
  if (oldCount == 1)
    _timersTableView.editing = NO;
  
  if (deletingCurrentTimer)
    [self selectNewRowAfterDeletingRow: indexPath.row];
}

- (void) selectNewRowAfterDeletingRow: (NSInteger) row
{
  NSInteger count = [_timersService.timers countOfList];
  
  if (row >= count)
    row = count - 1;
  
  if (row < 0)
  {
    _editTimerView.timer = nil;
    _editTimerView.hidden = YES;
  }
  else
  {
    NSIndexPath *newIndex = [NSIndexPath indexPathForRow: row inSection: 0];
    
    [_timersTableView selectRowAtIndexPath: newIndex animated: YES scrollPosition: UITableViewScrollPositionNone];
    [self tableView: _timersTableView didSelectRowAtIndexPath: newIndex];
  }
}

- (IBAction) buttonSave
{
  [_editTimerView commitTimer];
  [_newTimer release];
  _newTimer = nil;
  [self refreshStateAfterChanges];
}

- (IBAction) buttonEdit
{
  _status = EditState;
  [self updateToolbars];
  [self reloadTable];
}

- (IBAction) buttonDelete 
{
  UIAlertView *alert = [[UIAlertView alloc] 
                        initWithTitle: nil message: NSLocalizedString( @"Delete Timer?", @"Prompt to confirm deleting a timer" )
                        delegate: self
                    cancelButtonTitle: NSLocalizedString( @"No", @"Cancel deleting a timer" )
                    otherButtonTitles: NSLocalizedString( @"Yes", @"Confirm deleting a timer" ), nil];
  
  [alert show];
  [alert release];
}

- (void) alertView: (UIAlertView *) alertView clickedButtonAtIndex: (NSInteger) buttonIndex
{
  if (buttonIndex == 1)
  {
    [self deleteTimerAtRow: [_timersTableView indexPathForSelectedRow]];
    [self refreshStateAfterChanges];
  }
}

- (IBAction) buttonCancel 
{
  [_newTimer release];
  _newTimer = nil;
  [self refreshStateAfterChanges];
}

- (void) refreshStateAfterChanges
{
  _editTimerView.timer = nil;
  if ([_timersService.timers countOfList] == 0)
    _status = NoItemsState;
  else 
    _status = ViewState;
  
  [self updateToolbars];
  [self reloadTable];
}

- (void) dealloc 
{
  [_timersService release];
  [_timersTableView release];
  [_templateCell release];
  [_noServiceView release];
  [_noTimersMessage release];
  [_addBar release];
  [_barDivider release];
  [_editTimerView release];
  [_editControls release];
  [_editBar release];
  [_saveCancelBar release];
  [_deleteButton release];
  [_coverButton release];
  [_newTimer release];
  [super dealloc];
}

@end
