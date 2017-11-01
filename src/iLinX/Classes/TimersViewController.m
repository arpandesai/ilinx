//
//  TimersViewController.m
//  iLinX
//
//  Created by mcf on 22/05/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "TimersViewController.h"
#import "TimersViewCell.h"
#import "DeprecationHelper.h"
#import "EditTimerViewController.h"
#import "MainNavigationController.h"
#import "NLServiceTimers.h"
#import "NLTimer.h"
#import "NLTimerList.h"
#import "StandardPalette.h"

@interface TimersViewController ()

- (void) enableAddTimerButton;
- (void) addTimer;
- (void) beginEditing;
- (void) endEditing;
- (void) enableTimerChanged: (UISwitch *) enableSwitch;
- (void) initialActivityTimeout: (NSTimer *) timer;

@end

@implementation TimersViewController

@synthesize tableView = _tableView;

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

- (id) initWithRoomList: (NLRoomList *) roomList service: (NLService *) service
{
  if (self = [super initWithRoomList: roomList service: service])
  {
    NSUInteger count = [roomList countOfListInSection: 1];
    NSMutableArray *roomNames = [NSMutableArray arrayWithCapacity: count];
    NSUInteger roomStringLength = 0;
    NSUInteger i;
    
    for (i = 0; i < count; ++i)
    {
      NSString *name = [roomList titleForItemAtOffset: i inSection: 1];
      
      [roomNames addObject: name];
      roomStringLength += [name length];
    }

    _timersService = (NLServiceTimers *) service;
    
    // DigiLinX messages must be less than 1000 characters.  If we have a
    // huge list of names that might exceed this length, don't bother to
    // filter - it probably means that we're authorised to see all rooms anyway...
    if (roomStringLength > 0 && roomStringLength < 500)
      [_timersService.timers filterByListOfRooms: roomNames];
  }
  
  return self;
}

- (void) loadView
{
  [super loadView];

  [StandardPalette setTintForToolbar: _toolBar];
  
  if ([_timersService isLicensed])
    [self enableAddTimerButton];

  // Create a new table
  _tableView = [[UITableView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame] 
                                            style: UITableViewStylePlain];
  
  _tableView.frame = CGRectMake( _tableView.frame.origin.x, _toolBar.frame.origin.y + _toolBar.frame.size.height,
                                _tableView.frame.size.width, _tableView.frame.size.height - (2 * _toolBar.frame.size.height) + 1 );

  // Set the autoresizing mask so that the table will always fill the view
  _tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
  
  // Set the cell separator to a single straight line.
  _tableView.sectionIndexMinimumDisplayRowCount = NSIntegerMax;
  _tableView.delegate = self;
  _tableView.dataSource = self;
  _tableView.rowHeight = 92;
  _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  _tableView.allowsSelectionDuringEditing = YES;
  _tableView.backgroundColor = [UIColor clearColor];
  
  [self.view insertSubview: _tableView atIndex: 0];

  UIImageView *backdrop = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"BackdropLight.png"]];

  backdrop.backgroundColor = [StandardPalette backdropTint];
  [self.view insertSubview: backdrop atIndex: 0];
  [backdrop release];
}

- (void) viewWillAppear: (BOOL) animated
{
  MainNavigationController *mainController = (MainNavigationController *) self.navigationController;
  
  [super viewWillAppear: animated];

  [StandardPalette setTintForNavigationBar: mainController.navigationBar];
  [mainController setAudioControlsStyle: UIBarStyleDefault];

  [_timersService addDelegate: self];
  [self itemsChangedInListData: _timersService.timers range: NSMakeRange( 0, [_timersService.timers countOfList] )];
  [_timersService.timers addDelegate: self];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_timersService.timers removeDelegate: self];
  [_timersService removeDelegate: self];
  [self initialActivityTimeout: nil];
  [super viewWillDisappear: animated];  
}

- (void) viewDidAppear: (BOOL) animated
{
  MainNavigationController *mainController = (MainNavigationController *) self.navigationController;
  
  [super viewDidAppear: animated];

  [_tableView deselectRowAtIndexPath: [_tableView indexPathForSelectedRow] animated: animated];
  [mainController showAudioControls: YES];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  _initialActivityTimer = [NSTimer scheduledTimerWithTimeInterval: 5.0 target: self 
                                                         selector: @selector(initialActivityTimeout:)
                                                         userInfo: nil repeats: NO];
}

#pragma mark Table view methods

// Customize the number of rows in the table view.
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  NSInteger count = (NSInteger) [_timersService.timers countOfList];
  
  if (count > 0 && [_timersService isLicensed])
    _tableView.scrollEnabled = YES;
  else
  {
    count = 1;
    _tableView.scrollEnabled = NO;
  }

  return count;
}

- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath
{
  if ([_timersService.timers countOfList] > 0 && [_timersService isLicensed])
    return _tableView.rowHeight;
  else
    return _tableView.bounds.size.height;
}

// Customize the appearance of table view cells.
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  UITableViewCell *cell;

  if ([_timersService.timers countOfList] > 0 && [_timersService isLicensed])
  {
    static NSString *CellIdentifier = @"TimerCell";
    
    cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    
    if (cell == nil)
      cell = [[[TimersViewCell alloc] initDefaultWithFrame: CGRectZero reuseIdentifier: CellIdentifier
                                       switchTarget: self switchSelector: @selector(enableTimerChanged:)] autorelease];
    
    ((TimersViewCell *) cell).timer = [_timersService.timers itemAtIndex: indexPath.row];
    ((TimersViewCell *) cell).timerTag = indexPath.row;
  }
  else
  {
    static NSString *CellIdentifier = @"Cell";
    CGRect area = CGRectMake( 0, 0, _tableView.bounds.size.width, _tableView.bounds.size.height );
    UILabel *noTimersLabel = [[UILabel alloc] initWithFrame: area];
    
    cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    
    if (cell == nil)
      cell = [[[UITableViewCell alloc] initDefaultWithFrame: CGRectZero 
                                            reuseIdentifier: CellIdentifier] autorelease];
    else
    {
      for (UIView *subview in cell.contentView.subviews)
        [subview removeFromSuperview];
    }
    
    noTimersLabel.font = [UIFont boldSystemFontOfSize: [UIFont labelFontSize]];
    if (![_timersService licenceChecked] || [_timersService isLicensed])
      noTimersLabel.text = NSLocalizedString( @"No Timers", @"Message indicating no timers have been configured" );
    else
      noTimersLabel.text = NSLocalizedString( @"Timers service is not licensed.\nPlease contact your dealer.",
                                             @"Message indicating the timer service has not been licensed." );
    noTimersLabel.textAlignment = UITextAlignmentCenter;
    noTimersLabel.textColor = [UIColor whiteColor];
    noTimersLabel.shadowColor = [UIColor darkGrayColor];
    noTimersLabel.shadowOffset = CGSizeMake( 0, -1 );
    noTimersLabel.backgroundColor = [UIColor clearColor];
    noTimersLabel.lineBreakMode = UILineBreakModeWordWrap;
    noTimersLabel.numberOfLines = 4;
    
    [cell.contentView addSubview: noTimersLabel];
    [noTimersLabel release];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  
  return cell;
}

- (NSIndexPath *) tableView: (UITableView *) tableView willSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  if (tableView.editing)
    return indexPath;
  else
    return nil;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  NLTimer *timer = [_timersService.timers itemAtIndex: indexPath.row];
  
  if (timer == nil)
    [_tableView deselectRowAtIndexPath: indexPath animated: YES];
  else
  {
    EditTimerViewController *editTimerViewController = [[EditTimerViewController alloc] initWithRoomList: _roomList timer: timer];
    UINavigationController *modalNavControl = [[UINavigationController alloc] initWithRootViewController: editTimerViewController];
    
    modalNavControl.view.backgroundColor = [StandardPalette standardTintColour];
    [self.navigationController presentModalViewController: modalNavControl animated: YES];
    [editTimerViewController release];
    [modalNavControl release];
  }
}

- (BOOL) tableView: (UITableView *) tableView canEditRowAtIndexPath: (NSIndexPath *) indexPath
{
  return tableView.editing;
}

- (void) tableView: (UITableView *) tableView commitEditingStyle: (UITableViewCellEditingStyle) editingStyle 
 forRowAtIndexPath: (NSIndexPath *) indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete) 
  {
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
        [tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath] withRowAnimation: UITableViewRowAnimationFade];
    }
    @catch (id exception)
    {
      // Ignore
    }
    
    // If we've deleted the last timer, end the editing session.
    if (oldCount == 1)
    {
      [self endEditing];
      self.navigationItem.rightBarButtonItem = nil;
    }
  }
}

- (void) service: (NLServiceTimers *) service changed: (NSUInteger) changed
{
  if ((changed & (SERVICE_TIMERS_TIMERS_LIST_CHANGED|SERVICE_TIMERS_IS_LICENSED_CHANGED)) != 0)
  {
    if ((changed & SERVICE_TIMERS_IS_LICENSED_CHANGED) != 0 && [service isLicensed])
      [self enableAddTimerButton];
    [_tableView reloadData];
    
    if (_initialActivityTimer != nil)
      [self initialActivityTimeout: nil];
  }
}

- (void) itemsChangedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  if (!_tableView.editing)
  {
    if ([_timersService.timers countOfList] == 0)
      self.navigationItem.rightBarButtonItem = nil;
    else
      [self endEditing];
  }

  [_tableView reloadData];
}

- (void) listDataRefreshDidStart: (id<ListDataSource>) listDataSource
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void) listDataRefreshDidEnd: (id<ListDataSource>) listDataSource
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void) enableAddTimerButton
{
  if ([[_toolBar items] count] < 3)
  {
    NSMutableArray *newItems = [[_toolBar items] mutableCopy];
    UIBarButtonItem *spacing = [[UIBarButtonItem alloc]
                                initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                target: nil action: nil];
    UIBarButtonItem *addTimer = [[UIBarButtonItem alloc]
                                 initWithBarButtonSystemItem: UIBarButtonSystemItemAdd
                                 target: self action: @selector(addTimer)];
  
    addTimer.style = UIBarButtonItemStyleBordered;
    [newItems addObject: spacing];
    [newItems addObject: addTimer];
    _toolBar.items = newItems;
    [newItems release];
    [spacing release];
    [addTimer release];
  }
}

- (void) addTimer
{
  NLTimer *timer = [[NLTimer alloc] initWithTimersService: _timersService];
  
  timer.enabled = YES;

  EditTimerViewController *editTimerViewController = [[EditTimerViewController alloc] initWithRoomList:_roomList timer: timer];
  UINavigationController *modalNavControl = [[UINavigationController alloc] initWithRootViewController: editTimerViewController];
  
  [self.navigationController presentModalViewController: modalNavControl animated: YES];
  [timer release];
  [editTimerViewController release];
  [modalNavControl release];
}

- (void) beginEditing
{
  UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
                                 initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                 target: self action: @selector(endEditing)];
  
  
  doneButton.style = UIBarButtonItemStyleBordered;
  self.navigationItem.rightBarButtonItem = doneButton;
  [doneButton release];
  [_tableView setEditing: YES animated: YES];
  [_tableView reloadData];
}

- (void) endEditing
{
  UIBarButtonItem *editButton = [[UIBarButtonItem alloc]
                                 initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                 target: self action: @selector(beginEditing)];
  
  
  editButton.style = UIBarButtonItemStyleBordered;
  self.navigationItem.rightBarButtonItem = editButton;
  [editButton release];
  [_tableView setEditing: NO animated: YES];
  [_tableView reloadData];
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
}

- (void) dealloc 
{
  [_tableView release];
  [super dealloc];
}


@end

