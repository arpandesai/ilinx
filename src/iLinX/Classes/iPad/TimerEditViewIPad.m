//
//  TimerEditViewIPad.m
//  iLinX
//
//  Created by Tony Short on 06/10/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <QuartzCore/CALayer.h>
#import "CustomSliderIPad.h"
#import "TimerEditViewIPad.h"
#import "TimersViewControllerIPad.h"
#import "NLSource.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLServiceTimers.h"
#import "NLTimer.h"
#import "UncodableObjectArchiver.h"

#define ACTIONVIEW_TIMER_TYPE_SLEEP  NLTIMER_CMD_FORMAT_MAX + 1

enum 
{
  RepeatButton = 1,
  TimeButton,
  ActionButton,
  MacroButton,
  RoomButton,
  SourceButton
};

@interface TimerEditViewIPad ()

- (void) initButtons;
- (void) setButtonImages: (UIButton *) button;
- (NSInteger) convertTimerType;
- (void) updateActionFieldsForTimer;
- (void) setTimeTitle;
- (NSInteger) numRowsForPopupTableView;

@end


@implementation TimerEditViewIPad

@synthesize
  timer = _timer;

- (id) initWithCoder: (NSCoder *) aDecoder
{
  if ((self = [super initWithCoder: aDecoder]) != nil)
    [self initButtons];

  return self;
}

- (id) initWithFrame: (CGRect) frame
{
  if ((self = [super initWithFrame: frame]) != nil)
    [self initButtons];
  
  return self;
}

- (void) setRoomList: (NLRoomList *) roomList timersService: (NLServiceTimers *) timersService
{
  [_roomList release];
  _roomList = [roomList retain];
  
  [_macros release];
  _macros = [[NSMutableArray arrayWithCapacity: _roomList.currentRoom.macros.count] retain];
  [_roomSpecificMacros release];
  _roomSpecificMacros = [[NSMutableArray arrayWithCapacity: _roomList.currentRoom.macros.count] retain];
  
  NSString *matchPattern = [NSString stringWithFormat: @"#@%@", timersService.serviceName];
  for (NSString *macroName in [_roomList.currentRoom.macros allKeys])
  {
    NSString *macro = [_roomList.currentRoom.macros objectForKey: macroName];
    NSRange pattern = [macro rangeOfString: matchPattern];
    
    if (pattern.length > 0)
    {
      [_macros addObject: macroName];
      
      pattern = [macro rangeOfString: @"#@NS_CUR_ROOM"];
      if (pattern.length == 0)
        [_roomSpecificMacros addObject: [NSNull null]];
      else
        [_roomSpecificMacros addObject: macroName];
    }
  }
}

- (void) setTimer: (NLTimer *) timer
{
  if (_originalTimer != timer)
  {
    if (_currentPopover != nil)
    {
      if (_currentPopover.popoverVisible)
        [_currentPopover dismissPopoverAnimated: YES];
      [_currentPopover release];
      _currentPopover = nil;
      _currentPopoverId = 0;
    }
    
    [_originalTimer release];
    _originalTimer = [timer retain];
    [_timer release];
    _timer = [timer mutableCopy];
    
    [self setTimeTitle];
    
    if (timer.singleEventDate == nil)
      [_dateOrRepeatButton setTitle: [TimersViewControllerIPad dayListForRepeatMask: timer.repeatedDayBitmask]
                           forState: UIControlStateNormal];
    else
      [_dateOrRepeatButton setTitle: NSLocalizedString( @"Never", @"String shown when a timer event does not repeat" )
                           forState: UIControlStateNormal];
    
    [self updateActionFieldsForTimer];
    
    _nameTextField.text = timer.name;
    _enabledSwitch.on = timer.enabled;
  }
}

- (void) textFieldDidEndEditing: (UITextField *) textField
{
  if (![_timer.name isEqualToString: textField.text])
    _timer.name = textField.text;
}

- (BOOL) textFieldShouldReturn: (UITextField *) textField
{
  [textField resignFirstResponder];
  return YES;
}

- (IBAction) enabledSwitchChanged: (UIControl *) control
{
  _timer.enabled = !_timer.enabled;
}

- (IBAction) buttonPressed: (UIControl *) control
{
  if (_currentPopoverId != control.tag)
  {
    _currentPopoverId = 0;
    if (_currentPopover.popoverVisible)
      [_currentPopover dismissPopoverAnimated: YES];
    [_currentPopover release];
    _currentPopover = nil;
  }
  
  if (_currentPopover == nil)
  {
    _currentPopoverId = control.tag;
    if (_currentPopoverId == TimeButton)
    {
      NSDateComponents *comps;
      
      _timeDatePicker.locale = [NSLocale currentLocale];
      _timeDatePickerController.contentSizeForViewInPopover = _timeDatePicker.frame.size;
      _currentPopover = [[UIPopoverController alloc] initWithContentViewController: _timeDatePickerController];
      _currentPopover.popoverContentSize = _timeDatePickerController.contentSizeForViewInPopover; 

      if (_timer.repeatedDayBitmask == 0)
      {
        _timeDatePicker.datePickerMode = UIDatePickerModeDateAndTime;
        comps = [[NSCalendar currentCalendar] components: NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                                fromDate: _timer.singleEventDate];
      }
      else
      {
        _timeDatePicker.datePickerMode = UIDatePickerModeTime;
        comps = [[NSCalendar currentCalendar] components: 0 fromDate: [NSDate date]];
      }
      
      comps.hour = _timer.eventTime / 60;
      comps.minute = _timer.eventTime % 60;
      
      _timeDatePicker.date = [[NSCalendar currentCalendar] dateFromComponents: comps];
      
    }
    else
    {
      _tableViewController.tableView.frame = CGRectMake( 0, 0, _templateCell.frame.size.width,
                                                        [self numRowsForPopupTableView] * _tableViewController.tableView.rowHeight );
      _tableViewController.contentSizeForViewInPopover = _tableViewController.tableView.frame.size;
      _tableViewController.view.tag = _currentPopoverId;
      _currentPopover = [[UIPopoverController alloc] initWithContentViewController: _tableViewController];
      _currentPopover.popoverContentSize = _tableViewController.contentSizeForViewInPopover;
      [_tableViewController.tableView reloadData];
    }
  }
  
  if (!_currentPopover.popoverVisible)
    [_currentPopover presentPopoverFromRect: control.frame inView: control.superview 
              permittedArrowDirections: UIPopoverArrowDirectionAny animated: YES];
}

- (IBAction) timeDatePickerValueChanged
{
  NSDateComponents *comps = [[NSCalendar currentCalendar] components: NSHourCalendarUnit|NSMinuteCalendarUnit 
                                                            fromDate: _timeDatePicker.date];
  NSUInteger time = comps.hour * 60 + comps.minute;
  
  if (_timer.repeatedDayBitmask == 0)
    [_timer setSingleEventOnDate: _timeDatePicker.date atTime: time];
  else
    [_timer setRepeatedEventOnDays: _timer.repeatedDayBitmask atTime: time];
  
  [self setTimeTitle];
}

- (IBAction) volumeValueChanged
{
  _timer.simpleAlarmVolume = (NSUInteger) _alarmVolumeSlider.value;
}

- (void) commitTimer
{
  [_timer commitChanges];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section 
{
  return [self numRowsForPopupTableView];
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  NSString *reuseStr = [NSString stringWithFormat: @"Cell"];
  UITableViewCell *cell = (UITableViewCell*) [tableView dequeueReusableCellWithIdentifier: reuseStr];
  
  if (cell == nil)
    cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: reuseStr] autorelease];
  
  switch (_currentPopoverId) 
  {
    case RepeatButton:
    {
      NSUInteger weekday = [TimersViewControllerIPad sundayIndexedWeekdayForLocalWeekday: indexPath.row];
      NSDateFormatter *formatter = [NSDateFormatter new];
      
      cell.textLabel.text = [NSString stringWithFormat: NSLocalizedString( @"Every %@", 
                                                                          @"String that takes a weekday name as a parameter to indicate every occurrence of that day" ),
                             [[formatter weekdaySymbols] objectAtIndex: weekday]];
      
      if ((_timer.repeatedDayBitmask & (1<<((weekday + 6) % 7))) == 0)
        cell.accessoryType = UITableViewCellAccessoryNone;
      else
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
      
      [formatter release];
      break;
    }
    case ActionButton:
    {
      NSInteger timerType = indexPath.row;
      
      // Account for Macros row not being available if there are no macros!
      if (timerType > 0 && [_macros count] == 0)
        ++timerType;
      switch (timerType) 
      {
        case NLTIMER_CMD_FORMAT_SIMPLE_ALARM:
          cell.textLabel.text = NSLocalizedString( @"Alarm", @"Title of button on timers view when timer is an alarm" );
          break;
        case NLTIMER_CMD_FORMAT_MACRO:
          cell.textLabel.text = NSLocalizedString( @"Macro", @"Title of button on timers view when timer is a macro" );
          break;
        case ACTIONVIEW_TIMER_TYPE_SLEEP:
          cell.textLabel.text = NSLocalizedString( @"Sleep", @"Title of button on timers view when timer is a sleep timer" );
          break;
        default:
          break;
      }

      if (timerType == [self convertTimerType])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
      else
        cell.accessoryType = UITableViewCellAccessoryNone;
      break;
    }
    case MacroButton:
      cell.textLabel.text = [_macros objectAtIndex: indexPath.row];
      if ([cell.textLabel.text isEqualToString: _timer.macroName])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
      else
        cell.accessoryType = UITableViewCellAccessoryNone;
      break;
    case RoomButton:
    {
      NLRoom *room = [_roomList itemAtIndex: indexPath.row];
      
      cell.textLabel.text = [room displayName];
      if (_timer.cmdFormat == NLTIMER_CMD_FORMAT_MACRO)
      {
        if ([[room serviceName] isEqualToString: _timer.macroRoomServiceName])
          cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
          cell.accessoryType = UITableViewCellAccessoryNone;
      }
      else
      {
        if ([[room serviceName] isEqualToString: _timer.simpleAlarmRoomServiceName])
          cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
          cell.accessoryType = UITableViewCellAccessoryNone;
      }
      break;
    }
    case SourceButton:
    {
      NLSource *source = [[_timerRoom sources] itemAtIndex: indexPath.row + 1];

      cell.textLabel.text = [source displayName];
      if ([[source serviceName] isEqualToString: _timer.simpleAlarmSourceServiceName])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
      else
        cell.accessoryType = UITableViewCellAccessoryNone;
      break;
    }
    default:
      cell.textLabel.text = @"";
      cell.accessoryType = UITableViewCellAccessoryNone;
      break;
  }

  return cell;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  switch (tableView.tag) 
  {
    case RepeatButton:
    {			
      NSUInteger mask = _timer.repeatedDayBitmask;
      NSUInteger weekday = ([TimersViewControllerIPad sundayIndexedWeekdayForLocalWeekday: indexPath.row] + 6) % 7;
      
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
      {
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
#if TIME_ZONES_REQUIRED
        [dateFormatter setTimeZone: [NSTimeZone localTimeZone]];
#else
        [dateFormatter setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: 0]];
#endif
        [dateFormatter setDateStyle: NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle: NSDateFormatterNoStyle];
        
        [_timer setSingleEventOnDate: [NSDate date] atTime: _timer.eventTime];
        [_dateOrRepeatButton setTitle: NSLocalizedString( @"Never", @"Title of date button when an event does not repeat" )
                             forState: UIControlStateNormal];
        [dateFormatter release];
      }
      else
      {
        [_timer setRepeatedEventOnDays: mask atTime: _timer.eventTime];
        [_dateOrRepeatButton setTitle: [TimersViewControllerIPad dayListForRepeatMask: _timer.repeatedDayBitmask]
                             forState: UIControlStateNormal];
      }
      
      [self setTimeTitle];
      break;
    }
    case ActionButton:
    {
      NSInteger newTimerType = indexPath.row;
      NSInteger oldTimerType = [self convertTimerType];
      
      // Account for Macros row not being available if there are no macros!
      if ([_macros count] == 0)
      {
        if (newTimerType == NLTIMER_CMD_FORMAT_MACRO)
          newTimerType = ACTIONVIEW_TIMER_TYPE_SLEEP;
      }

      if (newTimerType != oldTimerType)
      {
        if (newTimerType == NLTIMER_CMD_FORMAT_MACRO)
           [_timer setTimedMacro: [_macros objectAtIndex: 0] room: _roomList.currentRoom.serviceName];
        else if (newTimerType == NLTIMER_CMD_FORMAT_SIMPLE_ALARM &&
                 [_roomList.currentRoom.sources countOfList] > 1)
          [_timer setSimpleAlarmForRoom: _roomList.currentRoom.serviceName 
                                 source: [[_roomList.currentRoom.sources itemAtIndex: 1] serviceName] volume: 0];
        else
          [_timer setSimpleAlarmForRoom: _roomList.currentRoom.serviceName 
                                 source: [[NLSource noSourceObject] serviceName] volume: 0];
      }
      break;
    }
    case MacroButton:
    {
      NSString *room = _timer.macroRoomServiceName;
      
      if ([room length] == 0)
        room = [_roomList.currentRoom serviceName];
                
      [_timer setTimedMacro: [_macros objectAtIndex: indexPath.row] room: room];
      break;
    }
    case RoomButton:
      _timerRoom = [_roomList itemAtIndex: indexPath.row];

      if (_timer.cmdFormat == NLTIMER_CMD_FORMAT_MACRO)
        [_timer setTimedMacro: _timer.macroName room: [_timerRoom serviceName]];
      else if ([_timer.simpleAlarmSourceServiceName isEqualToString: [[NLSource noSourceObject] serviceName]])
        [_timer setSimpleAlarmForRoom: [_timerRoom serviceName] source: [[NLSource noSourceObject] serviceName] volume: 0];
      else
      {
        NSString *sourceName = [[_timerRoom.sources itemAtIndex: 1] serviceName];
        NSUInteger count = [_timerRoom.sources countOfList];
        
        for (NSUInteger i = 2; i < count; ++i)
        {
          NSString *match = [[_timerRoom.sources itemAtIndex: i] serviceName];

          if ([_timer.simpleAlarmSourceServiceName isEqualToString: match])
          {
            sourceName = match;
            break;
          }
        }
        [_timer setSimpleAlarmForRoom: [_timerRoom serviceName] source: sourceName volume: _timer.simpleAlarmVolume];
      } 
      break;
    case SourceButton:
      [_timer setSimpleAlarmForRoom: _timer.simpleAlarmRoomServiceName 
                             source: [[_timerRoom.sources itemAtIndex: indexPath.row + 1] serviceName]
                             volume: _timer.simpleAlarmVolume];
      break;
    default:
      break;
  }

  [tableView deselectRowAtIndexPath: indexPath animated: YES];
  if (_currentPopoverId != RepeatButton)
  {
    [_currentPopover dismissPopoverAnimated: YES];
    [self updateActionFieldsForTimer];
  }
}

- (void) initButtons
{
  [self setButtonImages: _dateOrRepeatButton];
  [self setButtonImages: _timeButton];
  [self setButtonImages: _actionButton];
  [self setButtonImages: _macroButton];
  [self setButtonImages: _macroRoomButton];
  [self setButtonImages: _alarmSourceButton];
  [self setButtonImages: _alarmRoomButton];
  [self setButtonImages: _sleepRoomButton];
}

- (void) setButtonImages: (UIButton *) button
{
  UIImage *image = [button backgroundImageForState: UIControlStateNormal];
  
  [button setBackgroundImage: [image stretchableImageWithLeftCapWidth: (int) ((image.size.width - 1) / 2)
                                                         topCapHeight: (int) ((image.size.height - 1) / 2)]
                    forState: UIControlStateNormal];
  
  image = [button backgroundImageForState: UIControlStateHighlighted];
  [button setBackgroundImage: [image stretchableImageWithLeftCapWidth: (int) ((image.size.width - 1) / 2)
                                                         topCapHeight: (int) ((image.size.height - 1) / 2)]
                    forState: UIControlStateHighlighted];
}

- (NSInteger) convertTimerType
{
  NSInteger timerType;
  
  if (_timer == nil)
    timerType = -1;
  else 
  {
    timerType = _timer.cmdFormat;
  
    if (timerType == NLTIMER_CMD_FORMAT_SIMPLE_ALARM && 
      [_timer.simpleAlarmSourceServiceName isEqualToString: [[NLSource noSourceObject] serviceName]])
      timerType = ACTIONVIEW_TIMER_TYPE_SLEEP;
  }

  return timerType;
}

- (void) updateActionFieldsForTimer
{
  NSString *actionString;
  
  _macroSettings.hidden = YES;
  _alarmSettings.hidden = YES;
  _sleepSettings.hidden = YES;
  
  switch ([self convertTimerType])
  {
    case NLTIMER_CMD_FORMAT_MACRO:
    {
      NSInteger index = [_macros indexOfObject: _timer.macroName];

      actionString = NSLocalizedString( @"Macro", @"Timer action type: macro" );
      _macroSettings.hidden = NO;
      [_macroButton setTitle: _timer.macroName forState: UIControlStateNormal];
      [_macroRoomButton setTitle: _timer.macroRoomDisplayName forState: UIControlStateNormal];
      _macroRoomLabel.hidden = (index == NSNotFound || [_roomSpecificMacros objectAtIndex: index] == [NSNull null]);
      _macroRoomButton.hidden = _macroRoomLabel.hidden;
      _timerRoom = nil;
      break;
    }
    case NLTIMER_CMD_FORMAT_SIMPLE_ALARM:
    {
      NSUInteger count = [_roomList countOfList];

      actionString = NSLocalizedString( @"Alarm", @"Timer action type: alarm" );
      _alarmSettings.hidden = NO;
      [_alarmRoomButton setTitle: _timer.simpleAlarmRoomDisplayName forState: UIControlStateNormal];
      [_alarmSourceButton setTitle: _timer.simpleAlarmSourceDisplayName forState: UIControlStateNormal];
      _alarmVolumeSlider.value = _timer.simpleAlarmVolume;
      _timerRoom = nil;
      for (NSUInteger i = 0; i < count; ++i)
      {
        NLRoom *room = [_roomList itemAtIndex: i];
        
        if ([[room serviceName] isEqualToString: _timer.simpleAlarmRoomServiceName])
        {
          _timerRoom = room;
          break;
        }
      }
      break;
    }
    case ACTIONVIEW_TIMER_TYPE_SLEEP:
      actionString = NSLocalizedString( @"Sleep", @"Timer action type: sleep" );
      _sleepSettings.hidden = NO;
      [_sleepRoomButton setTitle: _timer.simpleAlarmRoomDisplayName forState: UIControlStateNormal];
      _timerRoom = nil;
      break;
    default:
      actionString = NSLocalizedString( @"Unknown", @"Timer action type: unknown" );
      _timerRoom = nil;
      break;
  }

  [_actionButton setTitle: actionString forState: UIControlStateNormal];
  [_tableViewController.tableView reloadData];
}


- (void) setTimeTitle
{
  NSDateFormatter *dateFormatter = [NSDateFormatter new];
  NSDate *time = _timer.singleEventDate;
  
#if TIME_ZONES_REQUIRED
  [dateFormatter setTimeZone: [NSTimeZone localTimeZone]];
#else
  [dateFormatter setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: 0]];
#endif
  
  [dateFormatter setTimeStyle: NSDateFormatterShortStyle];
  if (time != nil)
  {
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps;
    
   [gregorian setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: 0]];
   comps = [gregorian components: NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                        fromDate: time];
  
    comps.hour = _timer.eventTime / 60;
    comps.minute = _timer.eventTime % 60;
    time = [gregorian dateFromComponents: comps];
    [dateFormatter setDateStyle: NSDateFormatterMediumStyle];
    [gregorian release];
  }
  else
  {
    time = [NSDate dateWithTimeIntervalSince1970: _timer.eventTime * 60];
    [dateFormatter setDateStyle: NSDateFormatterNoStyle];
  }
  
  [_timeButton setTitle: [dateFormatter stringFromDate: time] forState: UIControlStateNormal];
  [dateFormatter release];
}


- (NSInteger) numRowsForPopupTableView
{
  switch (_currentPopoverId) 
  {
    case RepeatButton:
      return 7;
    case ActionButton:
      if ([_macros count] == 0)
        return 2;
      else
        return 3;
    case MacroButton:
      return _macros.count;
    case RoomButton:
      return [_roomList countOfList];
    case SourceButton:
      return [[_timerRoom sources] countOfList] - 1;
    default:
      return 0;
  }
}

- (void) dealloc
{
  [_nameTextField release];
  [_enabledSwitch release];
  [_timeButton release];
  [_dateOrRepeatButton release];
  [_actionButton release];
  [_actionSettingsView release];
  [_macroSettings release];
  [_macroButton release];
  [_macroRoomLabel release];
  [_macroRoomButton release];
  [_alarmSettings release];
  [_alarmRoomButton release];
  [_alarmSourceButton release];
  [_alarmVolumeSlider release];
  [_sleepSettings release];
  [_sleepRoomButton release];
  [_timeDatePickerController release];
  [_timeDatePicker release];
  [_tableViewController release];
  [_tableView release];
  [_templateCell release];
  [_originalTimer release];
  [_timer release];
  [_roomList release];
  [_macros release];
  [_roomSpecificMacros release];
  [_currentPopover release];
  [super dealloc];
}

@end
