//
//  ActionViewController.m
//  iLinX
//
//  Created by mcf on 10/06/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "ActionViewController.h"
#import "ActionTypeViewController.h"
#import "BorderedTableViewCell.h"
#import "DeprecationHelper.h"
#import "EditTimerViewCell.h"
#import "CustomSlider.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLServiceTimers.h"
#import "NLSource.h"
#import "NLSourceList.h"
#import "NLTimer.h"
#import "StandardPalette.h"

#define ACTIONVIEW_TIMER_TYPE_SLEEP (NLTIMER_CMD_FORMAT_MAX + 1)

static NSString *NO_SOURCES_STRING = nil;

@interface ActionViewController ()

- (void) initialiseSourcesWithRoom: (NLRoom *) room;
- (void) setRoomPickerForMacroIndex: (NSInteger) row;
- (void) setTimerType;

@end

@implementation ActionViewController

- (id) initWithRoomList: (NLRoomList *) roomList timer: (NLTimer *) timer
{
  if ((self = [super initWithNibName: nil bundle: nil]) != nil)
  {
    UIFont *labelFont = [UIFont boldSystemFontOfSize: [UIFont labelFontSize]];
    CGSize bigSize = CGSizeMake( 480, 480 );
    CGSize actualTextArea;
    
    if (NO_SOURCES_STRING == nil)
      NO_SOURCES_STRING = NSLocalizedString( @"No Sources",
                                            @"String shown if there are no sources available in a room" );

    actualTextArea = [NSLocalizedString( @"Type", @"Title of type of timer action" )
                      sizeWithFont: labelFont constrainedToSize: bigSize
                      lineBreakMode: UILineBreakModeWordWrap];
    _maxTitleWidth = actualTextArea.width + 10;
    actualTextArea = [NSLocalizedString( @"Volume", @"Title of volume field for alarm timer action" )
                      sizeWithFont: labelFont constrainedToSize: bigSize
                      lineBreakMode: UILineBreakModeWordWrap];
    if (actualTextArea.width + 10 > _maxTitleWidth)
      _maxTitleWidth = actualTextArea.width + 10;

   _roomList = [roomList retain];
    //NSLog( @"NLRoomList %08X retained by ActionViewController %08X", _roomList, self );
    _timer = [timer retain];
    self.title = NSLocalizedString( @"Action", @"Title of the timer action view" );
    
    _macros = [[NSMutableArray arrayWithCapacity: [_roomList.currentRoom.macros count]] retain];
    _roomSpecificMacros = [[NSMutableArray arrayWithCapacity: [_roomList.currentRoom.macros count]] retain];
    
    NSString *matchPattern = [NSString stringWithFormat: @"#@%@", _timer.timersService.serviceName];
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
    
    NSUInteger count = [_roomList countOfListInSection: 1];
    NSUInteger i;
    
    _rooms = [[NSMutableArray arrayWithCapacity: count] retain];
    for (i = 0; i < count; ++i)
      [_rooms addObject: [[_roomList itemAtOffset: i inSection: 1] serviceName]];

    [self setTimerType];

    if (_timerType == ACTIONVIEW_TIMER_TYPE_SLEEP ||
      (_timerType == NLTIMER_CMD_FORMAT_MACRO && [_macros count] > 0))
      _sources = nil;
    else
    {
      NSString *room;

      if (_timerType == NLTIMER_CMD_FORMAT_MACRO)
        room = [[_roomList itemAtOffset: 0 inSection: 1] serviceName];
      else
        room = _timer.simpleAlarmRoomServiceName;

      for (i = 0; i < count; ++i)
      {
        if ([[[_roomList itemAtOffset: i inSection: 1] serviceName] compare: room
                                                                    options: NSCaseInsensitiveSearch] == NSOrderedSame)
          break;
      }
      
      if (i == count)
        i = 0;

      [self initialiseSourcesWithRoom: [_roomList itemAtOffset: i inSection: 1]];        
      
      if (_timerType == NLTIMER_CMD_FORMAT_MACRO)
      {
        [_timer setSimpleAlarmForRoom: [[_roomList itemAtOffset: 0 inSection: 1] serviceName] 
                               source: [[NLSource noSourceObject] serviceName] volume: 0];
        _timerType = ACTIONVIEW_TIMER_TYPE_SLEEP;
      }
    }
  }
  
  return self;
}

- (void) loadView 
{
  UIView *contentView = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
  UIColor *tint = [StandardPalette standardTintColour];

  contentView.autoresizesSubviews = YES;
  contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  self.view = contentView;
  [contentView release];
  
  UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                 initWithTitle: NSLocalizedString( @"Back", @"Title for going back to timer action view" )
                                 style: UIBarButtonItemStyleBordered target: nil action: nil];
  
  self.navigationItem.backBarButtonItem = backButton;
  [backButton release];
  
  _optionsTable = [[UITableView alloc] initWithFrame: contentView.bounds style: UITableViewStyleGrouped];
  _optionsTable.delegate = self;
  _optionsTable.dataSource = self;
  _optionsTable.scrollEnabled = NO;
  
  if (tint == nil)
    _optionsTable.backgroundColor = [UIColor groupTableViewBackgroundColor];
  else
  {
    _optionsTable.backgroundColor = [UIColor clearColor];
    _backdrop = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"GroupTableBackground.png"]];
    _backdrop.frame = _optionsTable.frame;
    _backdrop.backgroundColor = [StandardPalette standardTintColour];
    [contentView addSubview: _backdrop];
  }
  
  [contentView addSubview: _optionsTable];
  
  _parameterPicker = [UIPickerView new];
  _parameterPicker.frame = CGRectMake( contentView.bounds.origin.x + ((contentView.bounds.size.width - _parameterPicker.frame.size.width) / 2), 
                                      contentView.bounds.origin.y + contentView.bounds.size.height - _parameterPicker.frame.size.height,
                                      _parameterPicker.frame.size.width, _parameterPicker.frame.size.height );
  _parameterPicker.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
  _parameterPicker.showsSelectionIndicator = YES;
  _parameterPicker.dataSource = self;
  _parameterPicker.delegate = self;
  [self.view addSubview: _parameterPicker];
  
  _volumeSlider = [[CustomSlider alloc] initWithFrame: CGRectZero tint: nil progressOnly: NO];
  _volumeSlider.minimumValue = 0;
  _volumeSlider.maximumValue = 100;
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];

  [self setTimerType];
  [_parameterPicker reloadAllComponents];
  if (_timerType == NLTIMER_CMD_FORMAT_MACRO || _timerType == ACTIONVIEW_TIMER_TYPE_SLEEP)
  {
    _volumeSlider.enabled = NO;
    _volumeSlider.hidden = YES;
  }
  else
  {
    NSString *room = _timer.simpleAlarmRoomServiceName;
    NSUInteger count = [_roomList countOfListInSection: 1];
    NSUInteger i;

    _volumeSlider.enabled = YES;
    _volumeSlider.hidden = NO;
    _volumeSlider.value = _timer.simpleAlarmVolume;
 
    for (i = 0; i < count; ++i)
    {
      if ([[[_roomList itemAtOffset: i inSection: 1] serviceName] compare: room
                                                                  options: NSCaseInsensitiveSearch] == NSOrderedSame)
        break;
    }
    
    if (i == count)
      i = 0;
    
    [self initialiseSourcesWithRoom: [_roomList itemAtOffset: i inSection: 1]];
  }
}

- (void) viewDidAppear: (BOOL) animated
{
  NSIndexPath *selected = [_optionsTable indexPathForSelectedRow];
  
  [super viewDidAppear: animated];

  if (selected != nil)
    [_optionsTable deselectRowAtIndexPath: selected animated: animated];
  [_optionsTable reloadData];

  if (_timerType == NLTIMER_CMD_FORMAT_MACRO)
  {
    NSInteger row = [_macros indexOfObject: _timer.macroName];
    
    if (row == NSNotFound)
      row = 0;
        
    [_parameterPicker selectRow: row inComponent: 0 animated: NO];
    [self setRoomPickerForMacroIndex: row];
  }
  else if (_timerType == NLTIMER_CMD_FORMAT_SIMPLE_ALARM)
  {
    NSInteger row1 = [_rooms indexOfObject: _timer.simpleAlarmRoomServiceName];
    NSInteger row2 = [_sources indexOfObject: _timer.simpleAlarmSourceServiceName];
    
    if (row1 != NSNotFound)
      [_parameterPicker selectRow: row1 inComponent: 0 animated: NO];
    if (row2 != NSNotFound)
      [_parameterPicker selectRow: row2 inComponent: 1 animated: NO];
  }
  else
  {
    NSInteger row1 = [_rooms indexOfObject: _timer.simpleAlarmRoomServiceName];
    
    if (row1 != NSNotFound)
      [_parameterPicker selectRow: row1 inComponent: 0 animated: NO];
  }
}

- (void) viewWillDisappear: (BOOL) animated
{
  if (_timerType == NLTIMER_CMD_FORMAT_MACRO)
  {
    NSString *room;

    if (_parameterPicker.numberOfComponents == 1)
      room = nil;
    else
      room = [_rooms objectAtIndex: [_parameterPicker selectedRowInComponent: 1]];
    [_timer setTimedMacro: [_macros objectAtIndex: [_parameterPicker selectedRowInComponent: 0]] room: room];
  }
  else
  {
    NSString *source;

    if (_timerType == NLTIMER_CMD_FORMAT_SIMPLE_ALARM)
      source = [_sources objectAtIndex: [_parameterPicker selectedRowInComponent: 1]];
    else
      source = [[NLSource noSourceObject] serviceName];
    if ([source isEqualToString: NO_SOURCES_STRING])
      source = [[NLSource noSourceObject] serviceName];

    [_timer setSimpleAlarmForRoom: [_rooms objectAtIndex: [_parameterPicker selectedRowInComponent: 0]]
                           source: source volume: (NSUInteger) _volumeSlider.value];
  }
  
  [super viewWillDisappear: animated];
}

- (NSInteger) numberOfComponentsInPickerView: (UIPickerView *) pickerView
{
  if (_timerType == ACTIONVIEW_TIMER_TYPE_SLEEP ||
      (_timerType == NLTIMER_CMD_FORMAT_MACRO && !_showMacroRoomPicker))
    return 1;
  else
    return 2;
}

- (NSInteger) pickerView: (UIPickerView *) pickerView numberOfRowsInComponent: (NSInteger) component
{
  NSInteger count;

  if (_timerType == NLTIMER_CMD_FORMAT_MACRO)
  {
    if (component == 0)
      count = [_macros count];
    else
      count = [_rooms count];
  }
  else
  {
    if (component == 0)
      count = [_rooms count];
    else
      count = [_sources count];
  }
  
  return count;
}

- (NSString *) pickerView: (UIPickerView *) pickerView titleForRow: (NSInteger) row forComponent: (NSInteger) component
{
  NSString *title;

  if (_timerType == NLTIMER_CMD_FORMAT_MACRO)
  {
    if (component == 0)
      title = [_macros objectAtIndex: row];
    else
      title = [GuiXmlParser stripSpecialAffixesFromString: [_rooms objectAtIndex: row]];
  }
  else
  {
    if (component == 0)
      title = [GuiXmlParser stripSpecialAffixesFromString: [_rooms objectAtIndex: row]];
    else
      title = [GuiXmlParser stripSpecialAffixesFromString: [_sources objectAtIndex: row]];
  }
  
  return title;
}

- (void) pickerView: (UIPickerView *) pickerView didSelectRow: (NSInteger) row inComponent: (NSInteger) component
{
  if (component == 0)
  {
    if (_timerType == NLTIMER_CMD_FORMAT_MACRO)
      [self setRoomPickerForMacroIndex: row];
    else if (_timerType == NLTIMER_CMD_FORMAT_SIMPLE_ALARM)
    {
      [self initialiseSourcesWithRoom: [_roomList itemAtOffset: row inSection: 1]];
      row = [_sources indexOfObject: _timer.simpleAlarmSourceServiceName];
    
      if (row != NSNotFound)
        [_parameterPicker selectRow: row inComponent: 1 animated: YES];
    }
  }
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  if (_timerType == NLTIMER_CMD_FORMAT_SIMPLE_ALARM)
    return 2;
  else
    return 1;
}

- (CGFloat) tableView: (UITableView *) tableView heightForHeaderInSection: (NSInteger) section
{
  if (_timerType == NLTIMER_CMD_FORMAT_SIMPLE_ALARM)
    return 50;
  else
    return 72;
}

- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section
{
  return @" ";
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  CGRect area = CGRectInset( [tableView rectForRowAtIndexPath: indexPath], 10, 0 );
  BorderedTableViewCell *cell;
  
  if (indexPath.row == 0)
  {
    static NSString *TimerCellIdentifier = @"EditTimerCell";
    EditTimerViewCell *timerCell = (EditTimerViewCell *) [tableView dequeueReusableCellWithIdentifier: TimerCellIdentifier];
    
    if (timerCell == nil)
      timerCell = [[[EditTimerViewCell alloc] initWithArea: area maxWidth: _maxTitleWidth
                                           reuseIdentifier: TimerCellIdentifier
                                                     table: tableView] autorelease];
    
    timerCell.title = NSLocalizedString( @"Type", @"Title of type of timer action" );
    if ([_macros count] == 0)
    {
      timerCell.accessoryType = UITableViewCellAccessoryNone;
      timerCell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else
    {
      timerCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      timerCell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    switch (_timerType)
    {
      case NLTIMER_CMD_FORMAT_MACRO:
        timerCell.content = NSLocalizedString( @"Macro", @"Timer action type: macro" );
        break;
      case NLTIMER_CMD_FORMAT_SIMPLE_ALARM:
        timerCell.content = NSLocalizedString( @"Alarm", @"Timer action type: simple alarm" );
        break;
      case ACTIONVIEW_TIMER_TYPE_SLEEP:
        timerCell.content = NSLocalizedString( @"Sleep", @"Timer action type: sleep" );
        break;
      default:
        timerCell.content = @"";
        break;
    }
    
    cell = timerCell;
  }
  else
  {
    static NSString *CellIdentifier = @"Cell";
    UILabel *cellTitle = [[UILabel alloc] initWithFrame: CGRectMake( 10, 0, _maxTitleWidth, area.size.height )];
    
    cell = (BorderedTableViewCell *) [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    
    if (cell == nil)
      cell = [[[BorderedTableViewCell alloc] initDefaultWithFrame: CGRectZero reuseIdentifier: CellIdentifier
                                                            table: tableView] autorelease];
    else
    {
      while ([[cell.contentView subviews] count] > 0)
        [[[cell.contentView subviews] lastObject] removeFromSuperview];
    }
    
    cellTitle.font = [UIFont boldSystemFontOfSize: [UIFont buttonFontSize]];
    cellTitle.backgroundColor = [UIColor clearColor];
    cellTitle.text = NSLocalizedString( @"Volume", @"Title of volume field for alarm timer action" );
    [cell.contentView addSubview: cellTitle];
    [cellTitle release];
    
    [_volumeSlider sizeToFit];
    _volumeSlider.frame = CGRectMake( _maxTitleWidth + 10, (int) ((area.size.height - _volumeSlider.frame.size.height) / 2),
                                     area.size.width - (_maxTitleWidth + 20), _volumeSlider.frame.size.height );
    [cell.contentView addSubview: _volumeSlider];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  
  [cell setBorderTypeForIndex: indexPath.row totalItems: [self tableView: tableView numberOfRowsInSection: 0]];

  return cell;
}

- (NSIndexPath *) tableView: (UITableView *) tableView willSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  if (indexPath.row > 0)
    return nil;
  else
    return indexPath;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  ActionTypeViewController *nextPage =
  [[ActionTypeViewController alloc] initWithRoomList: _roomList timer: _timer macroCount: [_macros count]];

  [self.navigationController pushViewController: nextPage animated: YES];
  [nextPage release];
}

- (void) initialiseSourcesWithRoom: (NLRoom *) room
{
  NSString *noSourceTitle = [[NLSource noSourceObject] serviceName];
  NLSourceList *sources = room.sources;
  NSUInteger count = [sources countOfList];
  NSUInteger i;
  
  [_sources release];
  _sources = [[NSMutableArray arrayWithCapacity: count] retain];
  for (i = 0; i < count; ++i)
  {
    NSString *title = [[sources itemAtIndex: i] serviceName];
    
    if (![title isEqualToString: noSourceTitle])
      [_sources addObject: title];
  }
  
  if ([_sources count] == 0)
    [_sources addObject: NO_SOURCES_STRING];

  [_parameterPicker reloadComponent: 1];
}

- (void) setRoomPickerForMacroIndex: (NSInteger) row
{
  BOOL oldShow = _showMacroRoomPicker;
  _showMacroRoomPicker = ([_roomSpecificMacros objectAtIndex: row] != [NSNull null]);
  
  if (oldShow != _showMacroRoomPicker)
    [_parameterPicker reloadAllComponents];

  if (_showMacroRoomPicker)
  {
    NSString *macroRoom = _timer.macroRoomServiceName;
    
    if (macroRoom != nil && [macroRoom length] > 0)
    {
      row = [_rooms indexOfObject: macroRoom];
      if (row != NSNotFound)
        [_parameterPicker selectRow: row inComponent: 1 animated: NO];
    }
  }
}

- (void) setTimerType
{
  _timerType = _timer.cmdFormat;
  if (_timerType == NLTIMER_CMD_FORMAT_SIMPLE_ALARM && 
      [_timer.simpleAlarmSourceServiceName isEqualToString: [[NLSource noSourceObject] serviceName]])
    _timerType = ACTIONVIEW_TIMER_TYPE_SLEEP;
}

- (void) dealloc
{
  //NSLog( @"NLRoomList %08X about to be released by ActionViewController %08X", _roomList, self );
  [_roomList release];
  [_timer release];
  [_backdrop release];
  [_optionsTable release];
  [_parameterPicker release];
  [_volumeSlider release];
  [_rooms release];
  [_sources release];
  [_macros release];
  [_roomSpecificMacros release];
  [super dealloc];
}

@end
