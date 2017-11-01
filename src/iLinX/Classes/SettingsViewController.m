//
//  SettingsViewController.m
//  iLinX
//
//  Created by mcf on 26/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "SettingsViewController.h"
#import "BorderedTableViewCell.h"
#import "ChangeSelectionHelper.h"
#import "CustomViewController.h"
#import "DeprecationHelper.h"
#import "NLRoom.h"
#import "NLZone.h"
#import "NLZoneList.h"
#import "SettingsControls.h"
#import "StandardPalette.h"
#import "XIBViewController.h"

#define VOLUME_CHANGE_REPEAT_INTERVAL 0.250

@interface SettingsViewController ()

- (void) addMultiroomControlsToView: (UIView *) contentView;
//- (UIView *) viewForHeaderInSection: (NSInteger) section;
- (void) multiVolumeDownPressed: (id) control;
- (void) multiVolumeDownReleased: (id) control;
- (void) multiVolumeUpPressed: (id) control;
- (void) multiVolumeUpReleased: (id) control;
- (void) multiVolumeSyncPressed: (id) control;
- (void) multiVolumeMutePressed: (id) control;
- (void) multiVolumeOffPressed: (id) control;
- (void) multiVolumeCreatePressed: (id) control;
- (void) multiVolumeLeavePressed: (id) control;
- (void) multiVolumeCancelPressed: (id) control;
- (NSUInteger) sectionForRow: (NSUInteger) row withTotalRows: (NSUInteger) totalRows;
- (void) reloadData;

@end

@implementation SettingsViewController

- (id) initWithTitle: (NSString *) title renderer: (NLRenderer *) renderer barStyle: (UIBarStyle) style
          doneTarget: (id) target doneSelector: (SEL) selector
{
  if (self = [super initWithStyle: UITableViewStyleGrouped])
  {
    _renderer = [renderer retain];
    _style = style;
    self.navigationItem.rightBarButtonItem =
    [[[UIBarButtonItem alloc] 
      initWithBarButtonSystemItem: UIBarButtonSystemItemDone
      target: target
      action: selector] autorelease];
  
    _customPage = [[CustomViewController alloc] initWithController: self customPage: @"avsettings.htm"];
    if (![_customPage isValid])
    {
      self.title = title;
      [_customPage release];
      _customPage = nil;
    }
    else
    {
      _customPage.closeMethod = selector;
      _customPage.closeTarget = target;

      if ([_customPage.title length] == 0)
        self.title = title;
      else
        self.title = _customPage.title;
    }
  }

  return self;
}

- (void) viewDidLoad
{
  [super viewDidLoad];

  if (_style != UIBarStyleDefault)
  {
    self.backdropTint = nil;
    self.headerTextColour = [UIColor whiteColor];
    self.headerShadowColour = [UIColor clearColor];
    self.view.backgroundColor = [UIColor blackColor];
  }
  
  if (_customPage != nil)
  {
    self.tableView.hidden = YES;
    [_customPage loadViewWithFrame: self.view.bounds];
    self.view = _customPage.view;
  }
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
  if ([_renderer.room.zones countOfList] == 0)
    return [_settings numberOfSections];
  else
    return [_settings numberOfSections] + 1;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  return 1;
}

- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section
{
  NSUInteger sectionCount = [_settings numberOfSections];
  NSString *title;
  
  if ([_renderer.room.zones countOfList] > 0)
    ++sectionCount;
  section = [self sectionForRow: section withTotalRows: sectionCount];
  
  if (section > 0)
    title = [_settings titleForSection: section - 1];
  else if (_inMultiRoom)
    title = _renderer.audioSessionDisplayName;
  else
    title = NSLocalizedString( @"MultiRoom", @"Title for header of MultiRoom section in settings view" );
  
  return title;
}

- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath
{
  NSUInteger section = [self sectionForRow: indexPath.section withTotalRows: [self numberOfSectionsInTableView: tableView]];
  CGFloat height;
  
  if (section > 0)
    height = [_settings heightForSection: section - 1];
  else if (_inMultiRoom)
    height = 104.0;
  else
    height = 58.0;
  
  return height;
}

- (NSIndexPath *) tableView: (UITableView *) tableView willSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  return nil;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  BorderedTableViewCell *cell = (BorderedTableViewCell *) [tableView dequeueReusableCellWithIdentifier: @"MyIdentifier"];
  NSUInteger section = [self sectionForRow: indexPath.section withTotalRows: [self numberOfSectionsInTableView: tableView]];
  
  if (cell == nil)
  {
    cell = [[[BorderedTableViewCell alloc] initDefaultWithFrame: CGRectZero reuseIdentifier: @"MyIdentifier"
                                                          table: tableView] autorelease];
    [cell setBorderTypeForIndex: 0 totalItems: 1];
  }
  else
  {
    while ([[cell.contentView subviews] count] > 0)
      [(UIView *) [[cell.contentView subviews] objectAtIndex: 0] removeFromSuperview];
  }

  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.contentView.backgroundColor = [UIColor clearColor];
  cell.contentView.frame = CGRectMake( 10, 0, 300, [self tableView: tableView heightForRowAtIndexPath: indexPath] );
  [cell adjustCellForResize];
  
  if (_style != UIBarStyleDefault)
  {
    cell.fillColour = [UIColor darkGrayColor];
    cell.borderColour = [UIColor lightGrayColor];
  }

  if (section == 0)
    [self addMultiroomControlsToView: cell.contentView];
  else
    [_settings addControlsForSection: section - 1 toView: cell.contentView];
  
  return cell;
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
 
  if (_settings == nil || ![_settings rightSettingsForRenderer])
  {
    [_settings release];
    _settings = [SettingsControls allocSettingsControlsForRenderer: _renderer style: _style];
  }
  
  [self renderer: _renderer stateChanged: 0xFFFFFFFF];
  [_renderer addDelegate: self];
  [_customPage viewWillAppear: animated];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_customPage viewWillDisappear: animated];
  [_renderer removeDelegate: self];
  [super viewWillDisappear: animated];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];

  CGRect frame = [UIApplication sharedApplication].keyWindow.bounds;
  
  self.navigationController.navigationBarHidden = [_customPage hidesNavigationBar];
  
  frame.size.height -= (2 * self.navigationController.navigationBar.frame.size.height);
  if (![UIApplication sharedApplication].statusBarHidden)
    frame.size.height -= [UIApplication sharedApplication].statusBarFrame.size.height;
  self.tableView.frame = frame;

  if (_choosingZone)
  {
    NLZone *newZone = _renderer.room.zones.listDataCurrentItem;
  
    if (newZone != nil &&
        !(_renderer.audioSessionActive && 
          [_renderer.audioSessionName compare: newZone.audioSessionName 
                                      options: NSCaseInsensitiveSearch] == NSOrderedSame))
      [_renderer multiRoomJoin: newZone];
    
    _choosingZone = NO;
  }
}

- (void) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags
{
  BOOL reloadRequired = [_settings renderer: renderer stateChanged: flags];

  if ((flags & NLRENDERER_AUDIO_SESSION_CHANGED) != 0)
  {
    _inMultiRoom = renderer.audioSessionActive;
    reloadRequired = YES;
  }
  if ((flags & NLRENDERER_PERMID_CHANGED) != 0)
  {
    if (![_settings rightSettingsForRenderer])
    {
      [_settings release];
      _settings = [SettingsControls allocSettingsControlsForRenderer: _renderer style: _style];
      reloadRequired = YES;
    }
  }
  
  if (reloadRequired)
    [self reloadData];
}

- (void) addMultiroomControlsToView: (UIView *) contentView
{
  if (_inMultiRoom)
  {
    UIButton *volDown = [SettingsControls standardButtonWithStyle: _style];
    UIButton *volUp = [SettingsControls standardButtonWithStyle: _style];
    UIButton *volSync = [SettingsControls standardButtonWithStyle: _style];
    UIButton *volMute = [SettingsControls standardButtonWithStyle: _style];
    UIButton *allOff = [SettingsControls standardButtonWithStyle: _style];
    UIButton *leave = [SettingsControls standardButtonWithStyle: _style];
    UIButton *cancel = [SettingsControls standardButtonWithStyle: _style];

    [volDown setTitle: NSLocalizedString( @"Vol -", @"Title of button to lower multiroom volume" ) forState: UIControlStateNormal];
    [volDown addTarget: self action: @selector(multiVolumeDownPressed:) forControlEvents: UIControlEventTouchDown];
    [volDown addTarget: self action: @selector(multiVolumeDownReleased:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
    [SettingsControls addButton: volDown to: contentView frame: CGRectMake( 9, 56, 50, 37 )];

    [volUp setTitle: NSLocalizedString( @"Vol +", @"Title of button to raise multiroom volume" ) forState: UIControlStateNormal]; 
    [volUp addTarget: self action: @selector(multiVolumeUpPressed:) forControlEvents: UIControlEventTouchDown];
    [volUp addTarget: self action: @selector(multiVolumeUpReleased:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
    [SettingsControls addButton: volUp to: contentView frame: CGRectMake( 67, 56, 50, 37 )];

    [volSync setTitle: NSLocalizedString( @"Sync", @"Title of button to synchronize multiroom volume" ) forState: UIControlStateNormal]; 
    [volSync addTarget: self action: @selector(multiVolumeSyncPressed:) forControlEvents: UIControlEventTouchDown];
    [SettingsControls addButton: volSync to: contentView frame: CGRectMake( 125, 56, 50, 37 )];

    [volMute setTitle: NSLocalizedString( @"Mute", @"Title of button to mute multiroom volume" ) forState: UIControlStateNormal]; 
    [volMute addTarget: self action: @selector(multiVolumeMutePressed:) forControlEvents: UIControlEventTouchDown];
    [SettingsControls addButton: volMute to: contentView frame: CGRectMake( 183, 56, 50, 37 )];

    [allOff setTitle: NSLocalizedString( @"Off", @"Title of button to switch off a multiroom session" ) forState: UIControlStateNormal]; 
    [allOff addTarget: self action: @selector(multiVolumeOffPressed:) forControlEvents: UIControlEventTouchDown];
    [SettingsControls addButton: allOff to: contentView frame: CGRectMake( 241, 56, 50, 37 )];

    [leave setTitle: NSLocalizedString( @"Leave", @"Title of button to leave a multiroom session" ) forState: UIControlStateNormal]; 
    [leave addTarget: self action: @selector(multiVolumeLeavePressed:) forControlEvents: UIControlEventTouchDown];
    [SettingsControls addButton: leave to: contentView frame: CGRectMake( 106, 10, 88, 37 )];

    [cancel setTitle: NSLocalizedString( @"Cancel", @"Title of button to cancel a multiroom session" ) forState: UIControlStateNormal];
    [cancel addTarget: self action: @selector(multiVolumeCancelPressed:) forControlEvents: UIControlEventTouchDown];
    [SettingsControls addButton: cancel to: contentView frame: CGRectMake( 202, 10, 89, 37 )];
  }
  
  UIButton *create = [SettingsControls standardButtonWithStyle: _style];
  
  [create setTitle: NSLocalizedString( @"New", @"Title of button to join a multiroom" ) forState: UIControlStateNormal]; 
  [create addTarget: self action: @selector(multiVolumeCreatePressed:) forControlEvents: UIControlEventTouchDown];
  [SettingsControls addButton: create to: contentView frame: CGRectMake( 9, 10, 89, 37 )];
}

- (void) multiVolumeDownPressed: (id) control
{
  [_volTimer invalidate];
  [_renderer multiRoomVolumeDown];
  _volTimer = [NSTimer scheduledTimerWithTimeInterval: VOLUME_CHANGE_REPEAT_INTERVAL target: self
                                             selector: @selector(multiVolumeDownPressed:) userInfo: nil repeats: NO];
}

- (void) multiVolumeDownReleased: (id) control
{
  [_volTimer invalidate];
  _volTimer = nil;
}

- (void) multiVolumeUpPressed: (id) control
{
  [_volTimer invalidate];
  [_renderer multiRoomVolumeUp];
  _volTimer = [NSTimer scheduledTimerWithTimeInterval: VOLUME_CHANGE_REPEAT_INTERVAL target: self
                                                 selector: @selector(multiVolumeUpPressed:) userInfo: nil repeats: NO];
}

- (void) multiVolumeUpReleased: (id) control
{
  [_volTimer invalidate];
  _volTimer = nil;
}

- (void) multiVolumeSyncPressed: (id) control
{
  [_renderer multiRoomVolumeSync];
}

- (void) multiVolumeMutePressed: (id) control
{
  [_renderer multiRoomVolumeMute];
}

- (void) multiVolumeOffPressed: (id) control
{
  [_renderer multiRoomAllOff];
}

- (void) multiVolumeCreatePressed: (id) control
{
  if (_renderer.audioSessionActive)
    [_renderer.room.zones setCurrentZoneToMatchAudioSession: _renderer.audioSessionName];
  else
    [_renderer.room.zones setCurrentZoneToMatchAudioSession: @""];
  
  _choosingZone = YES;
  [ChangeSelectionHelper showDialogOver: [self navigationController]
                           withListData: _renderer.room.zones];
}

- (void) multiVolumeLeavePressed: (id) control
{
  [_renderer multiRoomLeave];
}

- (void) multiVolumeCancelPressed: (id) control
{
  [_renderer multiRoomCancel];
}

- (NSUInteger) sectionForRow: (NSUInteger) row withTotalRows: (NSUInteger) totalRows
{
  NSUInteger section;

  // Map row to section, where first section = multi-room, unless multi-room is 
  // disabled, in which case it doesn't appear.  If there are two settings
  // sections, we want to reverse them to make video the top section.
  
  // Skip the MultiRoom section if it is disabled.  The MultiRoom section is the
  // last in the list, so we avoid this ever being returned by pretending that the
  // list is one longer than it really is.
  if ([_renderer.room.zones countOfList] == 0)
    ++totalRows;

  if (row >= totalRows - 1)
    section = 0;
  else if (totalRows < 3)
    section = row + 1;
  else if (row == 0)
    section = 2;
  else if (row == 1)
    section = 1;
  else
    section = row + 1;
  
  return section;
}

- (void) reloadData
{
  if (_customPage == nil)
    [self.tableView reloadData];
  else
    [_customPage reloadData];
}

- (void) dealloc 
{
  [_renderer release];
  [_settings release];
  [_volTimer invalidate];
  [_customPage release];
  [super dealloc];
}

@end
