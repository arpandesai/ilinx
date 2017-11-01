//
//  EditTimerViewController.m
//  iLinX
//
//  Created by mcf on 22/05/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "EditTimerViewController.h"
#import "EditTimerViewCell.h"
#import "EditLabelViewController.h"
#import "ActionViewController.h"
#import "DayListViewController.h"
#import "DeprecationHelper.h"
#import "MainNavigationController.h"
#import "StandardPalette.h"
#import "TimersViewController.h"
#import "NLSource.h"
#import "NLTimer.h"

@interface EditTimerViewController ()

- (void) pressedCancel;
- (void) pressedSave;
- (void) enableTimerChanged: (UISwitch *) control;
- (void) dateChanged: (UIDatePicker *) picker;

@end

@implementation EditTimerViewController

- (id) initWithRoomList: (NLRoomList *) roomList timer: (NLTimer *) timer
{
  if ((self = [super initWithNibName: nil bundle: nil]) != nil)
  {
    UIFont *labelFont = [UIFont boldSystemFontOfSize: [UIFont labelFontSize]];
    CGSize bigSize = CGSizeMake( 480, 480 );
    CGSize actualTextArea;
    
    actualTextArea = [NSLocalizedString( @"Repeat", @"Title of repeat specification field for a timer" )
                      sizeWithFont: labelFont constrainedToSize: bigSize
                      lineBreakMode: UILineBreakModeWordWrap];
    _maxTitleWidth = actualTextArea.width + 10;
    actualTextArea = [NSLocalizedString( @"Action", @"Title of action specification field for a timer" )
                      sizeWithFont: labelFont constrainedToSize: bigSize
                      lineBreakMode: UILineBreakModeWordWrap];
    if (actualTextArea.width + 10 > _maxTitleWidth)
      _maxTitleWidth = actualTextArea.width + 10;
    actualTextArea = [NSLocalizedString( @"Enabled", @"Title of enabled flag field for a timer" )
                      sizeWithFont: labelFont constrainedToSize: bigSize
                      lineBreakMode: UILineBreakModeWordWrap];
    if (actualTextArea.width + 4 > _maxTitleWidth)
      _maxTitleWidth = actualTextArea.width + 4;
    actualTextArea = [NSLocalizedString( @"Label", @"Title of label field for a timer" )
                      sizeWithFont: labelFont constrainedToSize: bigSize
                      lineBreakMode: UILineBreakModeWordWrap];
    if (actualTextArea.width + 10 > _maxTitleWidth)
      _maxTitleWidth = actualTextArea.width + 10;

    _roomList = [roomList retain];
    //NSLog( @"NLRoomList %08X retained by EditTimerViewController %08X", _roomList, self );
    _timer = [timer mutableCopy]; 
    if (timer.permId == nil || [_timer.permId length] == 0)
      _oldTimer = nil;
    else
      _oldTimer = [timer retain];
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

  UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target: self action: @selector(pressedCancel)];
  UIBarButtonItem *saveButton = [[UIBarButtonItem alloc]
                                 initWithBarButtonSystemItem: UIBarButtonSystemItemSave target: self action: @selector(pressedSave)];
  UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                 initWithTitle: NSLocalizedString( @"Back", @"Title for going back to edit timer view" )
                                 style: UIBarButtonItemStyleBordered target: nil action: nil];

  self.navigationItem.leftBarButtonItem = cancelButton;
  self.navigationItem.rightBarButtonItem = saveButton;
  self.navigationItem.backBarButtonItem = backButton;
  [StandardPalette setTintForNavigationBar: self.navigationController.navigationBar];
  [cancelButton release];
  [saveButton release];
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

  _dateTimePicker = [UIDatePicker new];
  _dateTimePicker.frame = CGRectMake( contentView.bounds.origin.x + ((contentView.bounds.size.width - _dateTimePicker.frame.size.width) / 2), 
                                      contentView.bounds.origin.y + contentView.bounds.size.height - _dateTimePicker.frame.size.height,
                                     _dateTimePicker.frame.size.width, _dateTimePicker.frame.size.height );
  _dateTimePicker.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
  [_dateTimePicker addTarget: self action: @selector(dateChanged:) forControlEvents: UIControlEventValueChanged];
  
  [self.view addSubview: _dateTimePicker];
}

- (void) viewWillAppear: (BOOL) animated
{
  NSDateComponents *comps;
  
  [super viewWillAppear: animated];

  if (_oldTimer == nil)
    self.title = NSLocalizedString( @"Add Timer", @"Title for adding new iLinX timer" );
  else
    self.title = NSLocalizedString( @"Edit Timer", @"Title for editing an existing iLinX timer" );

  if (_timer.repeatedDayBitmask == 0)
  {
    _dateTimePicker.datePickerMode = UIDatePickerModeDateAndTime;
    comps = [[NSCalendar currentCalendar] components: NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                            fromDate: _timer.singleEventDate];
  }
  else
  {
    _dateTimePicker.datePickerMode = UIDatePickerModeTime;
    comps = [[NSCalendar currentCalendar] components: 0 fromDate: [NSDate date]];
  }
  
  comps.hour = _timer.eventTime / 60;
  comps.minute = _timer.eventTime % 60;
  
  _dateTimePicker.date = [[NSCalendar currentCalendar] dateFromComponents: comps];
  
  self.navigationItem.rightBarButtonItem.enabled =
  ((_timer.cmdFormat == NLTIMER_CMD_FORMAT_SIMPLE_ALARM || [_timer.macroName length] > 0) && [_timer.name length] > 0);
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];

  NSIndexPath *selected = [_optionsTable indexPathForSelectedRow];

  if (selected != nil)
    [_optionsTable deselectRowAtIndexPath: selected animated: animated];
  [_optionsTable reloadData];
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  return 4;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  CGRect area = CGRectInset( [tableView rectForRowAtIndexPath: indexPath], 10, 0 );
  BorderedTableViewCell *cell;

  if (indexPath.row == 2)
  {
    static NSString *CellIdentifier = @"Cell";
    UILabel *cellTitle = [[UILabel alloc] initWithFrame: CGRectMake( 10, 0, _maxTitleWidth, area.size.height )];
    UISwitch *enabledSwitch = [[UISwitch alloc] initWithFrame: CGRectMake( area.size.width - 104,
                                                                          (int) ((area.size.height - 27) / 2), 94, 27 )];

    cell = (BorderedTableViewCell *) [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    
    if (cell == nil)
      cell = [[[BorderedTableViewCell alloc] initDefaultWithFrame: CGRectZero 
                                                  reuseIdentifier: CellIdentifier
                                                            table: tableView] autorelease];
    else
    {
      while ([[cell.contentView subviews] count] > 0)
        [[[cell.contentView subviews] lastObject] removeFromSuperview];
    }
    
    cellTitle.font = [UIFont boldSystemFontOfSize: [UIFont buttonFontSize]];
    cellTitle.backgroundColor = [UIColor clearColor];
    cellTitle.text = NSLocalizedString( @"Enabled", @"Title of enabled flag field for a timer" );
    [cell.contentView addSubview: cellTitle];
    [cellTitle release];

    enabledSwitch.on = _timer.enabled;
    [enabledSwitch addTarget: self action: @selector(enableTimerChanged:) forControlEvents: UIControlEventValueChanged];
    [cell.contentView addSubview: enabledSwitch];
    [enabledSwitch release];

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  else
  {
    static NSString *TimerCellIdentifier = @"EditTimerCell";
    
    EditTimerViewCell *timerCell = (EditTimerViewCell *) [tableView dequeueReusableCellWithIdentifier: TimerCellIdentifier];
    
    if (timerCell == nil)
      timerCell = [[[EditTimerViewCell alloc] initWithArea: area maxWidth: _maxTitleWidth
                                           reuseIdentifier: TimerCellIdentifier
                                                     table: tableView] autorelease];
    
    switch (indexPath.row)
    {
      case 0:
        timerCell.title = NSLocalizedString( @"Repeat", @"Title of repeat specification field for a timer" );
        if (_timer.repeatedDayBitmask == 0)
          timerCell.content = NSLocalizedString( @"Never", @"String to indicate that a timer never repeats" );
        else if (_timer.repeatedDayBitmask == NLTIMER_WEEKLY_REPEAT_EVERY_DAY)
          timerCell.content = NSLocalizedString( @"Every day", @"String to indicate that a timer repeats every day" );
        else
          timerCell.content = [TimersViewController dayListForRepeatMask: _timer.repeatedDayBitmask];
        break;
      case 1:
        timerCell.title = NSLocalizedString( @"Action", @"Title of action specification field for a timer" );
        if (_timer.cmdFormat == NLTIMER_CMD_FORMAT_SIMPLE_ALARM)
        {
          if ([_timer.simpleAlarmSourceServiceName isEqualToString: [[NLSource noSourceObject] serviceName]])
            timerCell.content = [NSString stringWithFormat:
                                 NSLocalizedString( @"Sleep in %@", @"Indicates that timer is a sleep setting in the room named in the parameter" ), 
                                 _timer.simpleAlarmRoomDisplayName];
          else            
            timerCell.content = [NSString stringWithFormat:
                                 NSLocalizedString( @"Alarm in %@", @"Indicates that timer is an alarm in the room named in the parameter" ), 
                                 _timer.simpleAlarmRoomDisplayName];
        }
        else
        {
          if ([_timer.macroRoomDisplayName length] == 0)
            timerCell.content = _timer.macroName;
          else
            timerCell.content = [NSString stringWithFormat:
                                 NSLocalizedString( @"%@ in %@", @"Indicates that timer is a macro (param 1) in the room named in param 2" ), 
                                 _timer.macroName, _timer.macroRoomDisplayName];
        }
        break;
      case 3:
        timerCell.title = NSLocalizedString( @"Label", @"Title of label field for a timer" );
        timerCell.content = _timer.name;
        break;
      default:
        break;
    }

    cell = timerCell;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
  }

  [cell setBorderTypeForIndex: indexPath.row totalItems: 4];

  return cell;
}

- (NSIndexPath *) tableView: (UITableView *) tableView willSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  if (indexPath.row == 2)
    return nil;
  else
    return indexPath;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  UIViewController *nextPage;

  // Go to sub view
  switch (indexPath.row)
  {
    case 0:
      nextPage = [[DayListViewController alloc] initWithTimer: _timer];
      break;
    case 1:
      nextPage = [[ActionViewController alloc] initWithRoomList: _roomList timer: _timer];
      break;
    case 3:
      nextPage = [[EditLabelViewController alloc] initWithTimer: _timer];
      break;
    default:
      nextPage = nil;
      break;
  }
  
  if (nextPage == nil)
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
  else
  {
    [self.navigationController pushViewController: nextPage animated: YES];
    [nextPage release];
  }
}

- (void) pressedCancel
{
  [self dismissModalViewControllerAnimated: YES];
}

- (void) pressedSave
{
  [_timer commitChanges];
  if (_oldTimer != nil)
    [_oldTimer initFromOtherTimer: _timer];
  [self dismissModalViewControllerAnimated: YES];
}

- (void) enableTimerChanged: (UISwitch *) control
{
  _timer.enabled = control.on;
}

- (void) dateChanged: (UIDatePicker *) picker
{
  NSDateComponents *comps = [[NSCalendar currentCalendar] components: NSHourCalendarUnit|NSMinuteCalendarUnit fromDate: picker.date];
  NSUInteger time = comps.hour * 60 + comps.minute;
  
  if (_timer.repeatedDayBitmask == 0)
    [_timer setSingleEventOnDate: picker.date atTime: time];
  else
    [_timer setRepeatedEventOnDays: _timer.repeatedDayBitmask atTime: time];
}

- (void) dealloc
{
  //NSLog( @"NLRoomList %08X about to be released by EditTimerViewController %08X", _roomList, self );
  [_roomList release];
  [_timer release];
  [_oldTimer release];
  [_backdrop release];
  [_optionsTable release];
  [_dateTimePicker release];
  [super dealloc];
}

@end
