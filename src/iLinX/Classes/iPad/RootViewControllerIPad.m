//
//  RootViewControllerIPad.m
//  iLinX
//
//  Created by mcf on 04/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "RootViewControllerIPad.h"
#import "AppStateNotification.h"
#import "AudioSettingsViewControllerIPad.h"
#import "DisplaySettingsViewControllerIPad.h"
#import "MultiRoomViewControllerIPad.h"
#import "AudioViewControllerIPad.h"
#import "CameraViewControllerIPad.h"
#import "ConfigRootController.h"
#import "ConfigProfile.h"
#import "ConfigViewController.h"
#import "CustomSliderIPad.h"
#import "DeprecationHelper.h"
#import "DiscoveryFailureAlert.h"
#import "FavouritesViewControllerIPad.h"
#import "GenericViewControllerIPad.h"
#import "HVACViewControllerIPad.h"
#import "NLRenderer.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLSource.h"
#import "NLSourceList.h"
#import "NLService.h"
#import "NLServiceList.h"
#import "PlaceholderViewControllerIPad.h"
#import "ProfileListController.h"
#import "PseudoBarButton.h"
#import "SecurityViewControllerIPad.h"
#import "ServiceListViewController.h"
#import "TimersViewControllerIPad.h"

static NSString * const kLocationKey = @"Location";
static NSString * const kDefaultHostKey = @"DefaultHost";
static NSString * const kDefaultPortKey = @"DefaultPort";
static NSString * const kServiceKey = @"Service";

@interface GUIMessageHandler : NSObject <NLPopupMessageDelegate>
{
}

@end

@implementation  GUIMessageHandler

- (void) _dismissTimeout: (NSTimer *) timer
{
  UIAlertView *alert = (UIAlertView *) [timer userInfo];
  
  if (!alert.hidden)
    [alert dismissWithClickedButtonIndex: alert.cancelButtonIndex animated: YES];
}

- (void) receivedPopupMessage: (NSString *) message timeout: (NSTimeInterval) timeout
{
  UIAlertView *alert = [[[UIAlertView alloc] initWithTitle: @"" message: message delegate: nil 
                                         cancelButtonTitle: NSLocalizedString( @"OK", @"Title of button to dismiss DigiLinX message" )
                                         otherButtonTitles: nil] autorelease];
  
  if (timeout > 0)
    [NSTimer scheduledTimerWithTimeInterval: timeout target: self selector: @selector(_dismissTimeout:) userInfo: alert repeats: NO];
  [alert show];
}

@end

@interface RootViewControllerIPad ()

- (void) adjustForOrientation: (UIInterfaceOrientation) orientation;
- (void) handleRoomChange;
- (void) restoreState: (NSMutableArray *) state fromLevel: (NSUInteger) level;
- (void) showViewForService: (NLService *) service;
- (void) reinit;
- (NSArray *) visibleSubControllers;
- (void) setSettingsButton;
- (void) setMuteIcon;
- (void) setAudioControlsForRenderer: (NLRenderer *) renderer;

@property (nonatomic, retain) NSDictionary *serviceViewClasses;
@property (nonatomic, retain) NSMutableDictionary *state;

@end


@implementation RootViewControllerIPad

@synthesize
  roomList = _roomList,
  currentRoom = _currentRoom,
  serviceViewClasses = _serviceViewClasses,
  state = _state;

- (NSString *) dumpView: (UIView *) view toDepth: (NSUInteger) depth atLevel: (NSUInteger) level
{
  NSString *dump = [NSString stringWithFormat: @"%*.*s%@", level - 1, level - 1, "", view];
  if (level < depth)
  {
    for (UIView *subView in [view subviews])
      dump = [dump stringByAppendingFormat: @"\n%@", [self dumpView: subView toDepth: depth atLevel: level + 1]];
  }
  
  return dump;
}

- (NSString *) dumpView: (UIView *) view toDepth: (NSUInteger) depth
{
  return [self dumpView: view toDepth: depth atLevel: 1];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void) viewDidLoad 
{
  [super viewDidLoad];
  
  _configStartupType = [ConfigManager currentStartupType];
  if (_serviceViewClasses == nil)
  {
    self.serviceViewClasses =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [AudioViewControllerIPad class], @"Audio",
     [AudioSettingsViewControllerIPad class], @"AudioSettings",
     [DisplaySettingsViewControllerIPad class], @"DisplaySettings",
     [MultiRoomViewControllerIPad class], @"MultiRoomSettings",
     [CameraViewControllerIPad class], @"Cameras",
     [FavouritesViewControllerIPad class], @"Favorites",
     [GenericViewControllerIPad class], @"generic-serial",
     [GenericViewControllerIPad class], @"generic-ir",
     [HVACViewControllerIPad class], @"hvac",
     [HVACViewControllerIPad class], @"hvac2",
     [GenericViewControllerIPad class], @"lighting",

     [SecurityViewControllerIPad class], @"security",
     [SecurityViewControllerIPad class], @"security2",
     [TimersViewControllerIPad class], @"Timers",

     nil];

    [_serviceListViewController resetDataSource];
    if (_configStartupType == STARTUP_TYPE_USE_CURRENT_PROFILE)
      _configStartupType = STARTUP_TYPE_AUTO_DETECT;
  }

  if (_uiMessageHandler == nil)
    _uiMessageHandler = [[GUIMessageHandler alloc] init];

  _sideBarTitleBar.backgroundColor = [UIColor grayColor];
  self.view.backgroundColor = [UIColor blackColor];
  [_toolbarSettingsButton retain];
  _multiroomMessage = [_multiroomMessageLabel.text retain];

  [self setSettingsButton];
  [_serviceListViewController resetDataSource];
  
  [AppStateNotification addWillEnterForegroundObserver: self selector: @selector(setSettingsButton)];

  //NSLog( @"On load main view: %@", self.view );
  //NSLog( @"On load main content view: %@", [self dumpView: _contentView toDepth: 6] );
}

- (void) viewDidUnload
{
  [super viewDidUnload];
  [AppStateNotification removeObserver: self];
  [_toolbarSettingsButton release];
  _toolbarSettingsButton = nil;
  [_multiroomMessage release];
  _multiroomMessage = nil;
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  //[self adjustForOrientation: [[UIApplication sharedApplication] statusBarOrientation]];
  [self setSettingsButton];

  if (_configStartupType == STARTUP_TYPE_AUTO_DETECT)
  {
    _configStartupType = STARTUP_TYPE_USE_CURRENT_PROFILE;
    [self reinit];
  }
  
  [self handleRoomChange];
  for (UIViewController *controller in [self visibleSubControllers])
    [controller viewWillAppear: animated];
}

- (void) viewWillDisappear: (BOOL) animated
{
  for (UIViewController *controller in [self visibleSubControllers])
    [controller viewWillDisappear: animated]; 

  if (_roomList.currentRoom != nil)
  {
    [_roomList.currentRoom.sources removeSourceOnlyDelegate: self];
    [_roomList.currentRoom.renderer removeDelegate: self];
  }

  [ConfigManager saveConfiguration];
  
  [super viewWillDisappear: animated];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  
  [self adjustForOrientation: [[UIApplication sharedApplication] statusBarOrientation]];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

  if (_configStartupType == STARTUP_TYPE_PRESENT_CHOICE)
  {
    UIViewController *profileList = [[ConfigRootController alloc] 
                                     initWithRootClass: [ProfileListController class]
                                     startupTypeDelegate: self];
    
    _configStartupType = STARTUP_TYPE_AUTO_DETECT;
    [self presentModalViewController: profileList animated: YES];
    [profileList release];
  }
  
  for (UIViewController *controller in [self visibleSubControllers])
    [controller viewDidAppear: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
  for (UIViewController *controller in [self visibleSubControllers])
    [controller viewDidDisappear: animated];

  if (_currentSelectionPopover != nil)
  {
    [_currentSelectionPopover dismissPopoverAnimated: NO];
    [_currentSelectionPopover release];
    _currentSelectionPopover = nil;
    _displayPopover = NO;
  }

  [super viewDidDisappear: animated];
}

- (BOOL) shouldAutorotate
{
  return YES;
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
  // Overriden to allow any orientation.
  return YES;
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskAll;
}

- (UIView *) rotatingHeaderView
{
  return _toolbar;
}

- (void) willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation 
                                          duration: (NSTimeInterval) duration
{
  [self adjustForOrientation: interfaceOrientation];

  for (UIViewController *controller in [self visibleSubControllers])
    [controller willAnimateRotationToInterfaceOrientation: interfaceOrientation duration: duration];
}

- (void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation) fromInterfaceOrientation
{
  UIInterfaceOrientation newOrientation = [[UIApplication sharedApplication] statusBarOrientation];

  //NSLog( @"After rotate main view: %@", self.view );
  //NSLog( @"After rotate main content view: %@", [self dumpView: _contentView toDepth: 6] );
  if (UIInterfaceOrientationIsPortrait( newOrientation ))
  {
    _sideBar.hidden = YES;    
    [_locationListViewController viewDidDisappear: YES];
    [_serviceListViewController viewDidDisappear: YES];
    if (_displayPopover)
      [self showSelectionPopover: _toolbarPopoverButton];
  }
  else
  {
    [_locationListViewController viewDidAppear: YES];
    [_serviceListViewController viewDidAppear: YES];
  }

  for (UIViewController *controller in [self visibleSubControllers])
    [controller didRotateFromInterfaceOrientation: fromInterfaceOrientation];
}

- (IBAction) showSelectionPopover: (id) popoverButton
{
  if (_currentSelectionPopover != nil)
  {
    [_currentSelectionPopover dismissPopoverAnimated: YES];
    [self popoverControllerDidDismissPopover: _currentSelectionPopover];
  }
  else
  {
    UIViewController *popoverViewController = [[UIViewController alloc] initWithNibName: nil bundle: nil];

    [_currentSelectionView removeFromSuperview];
    popoverViewController.view = _currentSelectionView;
    _currentSelectionPopover = [[UIPopoverController alloc] 
                                initWithContentViewController: popoverViewController];
    [popoverViewController release];
    _currentSelectionPopover.delegate = self;
    _currentSelectionView.frame = CGRectMake( 0, 0, 256, _contentView.frame.size.height - 44 );
    _currentSelectionPopover.popoverContentSize = _currentSelectionView.frame.size;
    [_locationListViewController viewWillAppear: YES];
    [_serviceListViewController viewWillAppear: YES];
    if ([popoverButton isKindOfClass: [UIBarButtonItem class]]) 
      [_currentSelectionPopover presentPopoverFromBarButtonItem: popoverButton 
                                       permittedArrowDirections: UIPopoverArrowDirectionAny
                                                       animated: YES];
    else
      [_currentSelectionPopover presentPopoverFromRect: [popoverButton frame] inView: [popoverButton superview]
                              permittedArrowDirections: UIPopoverArrowDirectionAny animated: YES];
    [_locationListViewController viewDidAppear: YES];
    [_serviceListViewController viewDidAppear: YES];
  }
}


- (void) selectService: (NLService *) service animated: (BOOL) animated
{
  NLServiceList *serviceList = _currentRoom.services;
  BOOL found = NO;

  if (service != serviceList.listDataCurrentItem)
  {
    NSUInteger count = [serviceList countOfList];
    NSUInteger i;
    
    for (i = 0; i < count; ++i)
    {
      if ([serviceList itemAtIndex: i] == service)
      {
	NSIndexPath *index = [serviceList indexPathFromIndex: i];
	
	[_serviceTableView selectRowAtIndexPath: index animated: animated 
				 scrollPosition: UITableViewScrollPositionNone];
	[_serviceListViewController tableView: _serviceTableView didSelectRowAtIndexPath: index];
	found = YES;
	break;
      }
    }
  }
  
  if (!found)
    [self showViewForService: service];
}

- (void) popoverControllerDidDismissPopover: (UIPopoverController *) popoverController
{
  [_locationListViewController viewWillDisappear: YES];
  [_serviceListViewController viewWillDisappear: YES];
  [_currentSelectionView removeFromSuperview];
  [_locationListViewController viewDidDisappear: YES];
  [_serviceListViewController viewDidDisappear: YES];
  _currentSelectionView.frame = _currentSelectionViewHolder.bounds;
  [_currentSelectionViewHolder addSubview: _currentSelectionView];
  [_currentSelectionPopover release];
  _currentSelectionPopover = nil;
  _displayPopover = NO;
}

- (void) setConfigStartupType: (NSInteger) startupType
{
  _configStartupType = startupType;
}

- (void) dataSource: (DataSourceViewController *) dataSource selectedItemChanged: (id) item
{
  if (dataSource == (DataSourceViewController *) _locationListViewController)
  {
    [self handleRoomChange];
  }
  else
  {
    [self showViewForService: (NLService *) item];
  }
  
  NSString *title = [_currentRoom displayName];
  NSString *serviceName = [[_currentRoom.services listDataCurrentItem] displayName];
  
  if ([serviceName length] > 0)
    title = [NSString stringWithFormat: @"%@ - %@", title, serviceName];
  else if ([title length] == 0)
  {
    if ([_roomList refreshIsComplete])
      title = NSLocalizedString( @"No Rooms Found", @"Room button title if no rooms are discovered" );
    else
      title = NSLocalizedString( @"Discovering...", @"Room button title if discovery in progress" );
  }

  _toolbarPopoverButton.title = title;
}

- (void) dataSourceRefreshed: (DataSourceViewController *) dataSource
{
  if (dataSource == (DataSourceViewController *) _locationListViewController)
  {
    if ([_roomList countOfListInSection: 1] == 0)
      [DiscoveryFailureAlert showAlertWithError: _roomList.lastError];
    else
      [self handleRoomChange];
  }
}

- (void) handleRoomChange
{
  NLRoom *oldRoom = _currentRoom;

  [_roomList resetCurrentItemToCurrentRoom];
  _currentRoom = [_roomList currentRoom];
  if (oldRoom != _currentRoom)
  {
    if (oldRoom != nil)
    {
      [oldRoom.sources removeSourceOnlyDelegate: self];
      [oldRoom.renderer removeDelegate: self];
    }

    if (_currentRoom == nil)
      [self setAudioControlsForRenderer: nil];
    else
    {
      NLRenderer *renderer = _currentRoom.renderer;

      // We don't do anything with this information, but registering for it ensures that
      // it is kept up to date, so that if and when A/V is selected we know which is the
      // current source.
      [_currentRoom.sources addSourceOnlyDelegate: self];
      [self setAudioControlsForRenderer: renderer];
      if (renderer != nil)
        [renderer addDelegate: self];
    }
  }

  [_serviceListViewController resetDataSource];
  
  if (_currentRoom == nil || [_roomList connectedHost] == nil)
  {
    [self dataSource: _serviceListViewController selectedItemChanged: nil];
  }
  else
  {
    NSString *serviceName = [[_roomList.currentRoom.services listDataCurrentItem] serviceName];

    [_state setObject: _roomList.currentRoom.serviceName forKey: kLocationKey];
    [_state setObject: [_roomList connectedHost] forKey: kDefaultHostKey];
    [_state setObject: [NSString stringWithFormat: @"%u", [_roomList connectedPort]] forKey: kDefaultPortKey];
    if (serviceName == nil)
      [_state setObject: [NSNull null] forKey: kServiceKey];
    else
      [_state setObject: serviceName forKey: kServiceKey];
  }
}

- (void) adjustForOrientation: (UIInterfaceOrientation) orientation
{
  if (UIInterfaceOrientationIsPortrait( orientation ))
  {
    [_locationListViewController viewWillDisappear: YES];
    [_serviceListViewController viewWillDisappear: YES];
    _toolbar.hidden = NO;
    _toolbarTitle.hidden = NO;
    _contentView.frame = CGRectMake( 0, _toolbar.frame.size.height, self.view.bounds.size.width,
                                    self.view.bounds.size.height - _toolbar.frame.size.height );
  }
  else
  {
    [_locationListViewController viewWillAppear: YES];
    [_serviceListViewController viewWillAppear: YES];
    _toolbar.hidden = YES;
    _toolbarTitle.hidden = YES;
    _sideBar.hidden = NO;
    _contentView.frame = CGRectMake( _sideBar.frame.size.width + 1, 0, 
                                    self.view.bounds.size.width - (_sideBar.frame.size.width + 1),
                                    self.view.bounds.size.height );
    if (_currentSelectionPopover != nil)
    {
      [_currentSelectionView removeFromSuperview];
      [_currentSelectionPopover dismissPopoverAnimated: YES];
      _currentSelectionView.frame = _currentSelectionViewHolder.bounds;
      [_currentSelectionViewHolder addSubview: _currentSelectionView];
      [_currentSelectionPopover release];
      _currentSelectionPopover = nil;
      _displayPopover = YES;
    }
  }
}

- (void) restoreState: (NSMutableArray *) state fromLevel: (NSUInteger) level
{
  if (_currentRoom != nil)
  {
    [_currentRoom.sources removeSourceOnlyDelegate: self];
    [_currentRoom.renderer removeDelegate: self];
    _currentRoom = nil;
  }
    
  //NSLog( @"NLRoomList %08X about to be released by RootViewController %08X", _roomList, self );
  NLRoomList *tempRoomList = _roomList;

  [_roomList removePopupMessageDelegate: _uiMessageHandler];
  [_topBarAudioControls setRenderer: nil];
  [_sideBarAudioControls setRenderer: nil];
  [self showViewForService: nil];
  _roomList = nil;
  [_locationListViewController resetDataSource];
  [_serviceListViewController resetDataSource];
  [tempRoomList release];

#ifdef DEBUG
  NSLog( @"Retained objects: %@", [NSDebugObject liveObjects] );
#endif
  _roomList = [[NLRoomList alloc] init];
  [_roomList addPopupMessageDelegate: _uiMessageHandler];
  //NSLog( @"NLRoomList %08X allocated by RootViewController %08X", _roomList, self );
    
  if (state != nil)
  {
    if (level < [state count])
    {
      // Restore our state from the object at position "level" in "state"
      self.state = [state objectAtIndex: level];
    }
    else
    {
      NSMutableDictionary *myState = [NSMutableDictionary new];
      
      self.state = myState;
      [state insertObject: myState atIndex: level];
      [myState release];
    }
  }
}

- (void) handleRefresh
{
  [_roomList refresh];
  [self reinit];
}

- (IBAction) viewSettings: (id) button
{
  Class settingsViewClass = [ConfigManager settingsViewClass];
  
  if (settingsViewClass == nil)
  {
    [self performSelector: @selector(handleRefresh) withObject: nil afterDelay: 0];
  }
  else 
  {
    ConfigRootController *configRootController = [[ConfigRootController alloc]
                                                  initWithRootClass: settingsViewClass
                                                  startupTypeDelegate: self];
  
    [self presentModalViewController: configRootController animated: YES];
    [configRootController release];
  }
}

- (void) showViewForService: (NLService *) service
{
  if (service == nil)
  {
    ServiceViewControllerIPad *serviceViewController = 
      [[PlaceholderViewControllerIPad alloc] initWithOwner: self service: nil];
    UIView *newView = serviceViewController.view;
    
    newView.frame = _contentView.bounds;
    [_contentViewController viewWillDisappear: YES];
    [serviceViewController viewWillAppear: YES];
    [_contentViewController.view removeFromSuperview];
    [_contentView addSubview: newView];
    [_contentViewController viewDidDisappear: YES];
    [serviceViewController viewDidAppear: YES];
    [_contentViewController release];
    _contentViewController = serviceViewController;
  }
  else if (service != [_contentViewController service])
  {
    NSString *serviceType = service.serviceType;
    ServiceViewControllerIPad *serviceViewController;
    
    if ([serviceType isEqualToString: @"CHANGE_SCREEN"])
    {
      //**/NSLog( @"Select service: %@", serviceType );
      
      // Dummy service type created when handling a "change screen" macro.  For now,
      // just go back to the home screen for "home" and ignore everything else.
      // We should also really deal with "Location", "sourceList" and "multi-room"
      // as well, but they are more problematic, so we're leaving that for another day...
      serviceViewController = nil;
    }
    else
    {
      //**/NSLog( @"Select service: %@", serviceType );
      
      // Other type of service.  Create a view to manage that type of service
      
      Class serviceViewClass = [_serviceViewClasses objectForKey: serviceType];
      
      if (serviceViewClass == nil)
        serviceViewClass = [PlaceholderViewControllerIPad class];
      
      serviceViewController = 
       [(ServiceViewControllerIPad *) [serviceViewClass alloc] initWithOwner: self service: service];
      
    }
    
    if (serviceViewController != nil)
    {
      UIView *newView = serviceViewController.view;

      //NSLog( @"Main view: %@", self.view );
      //NSLog( @"Main content view: %@", [self dumpView: _contentView toDepth: 6] );
      newView.frame = _contentView.bounds;
      [_contentViewController viewWillDisappear: YES];
      [serviceViewController viewWillAppear: YES];
      [_contentViewController.view removeFromSuperview];
      [_contentView addSubview: newView];
      [_contentViewController viewDidDisappear: YES];
      [serviceViewController viewDidAppear: YES];
      [_contentViewController release];
      _contentViewController = serviceViewController;
      
      [_state setObject: service.serviceName forKey: kServiceKey];
    }
  }
}

- (void) reinit
{
  ConfigProfile *profile = [ConfigManager currentProfileData];
  
  // Ensure we're not showing anything in the service pane, so that we don't have 
  // the problem of old views with stale data hanging around and having problems
  // trying to access room data from the previous profile that has now gone away.
  [self showViewForService: nil];

  // Attempt to restore the previous state (note that this may not be possible if
  // the configuration has changed or we have moved to a different location).
  [self restoreState: profile.state fromLevel: 0];
  
  NSString *room = [_state objectForKey: kLocationKey];
  NSString *host = [_state objectForKey: kDefaultHostKey];
  NSUInteger port = [[_state objectForKey: kDefaultPortKey] integerValue];
  id serviceName = [[_state objectForKey: kServiceKey] retain];

  if ([room length] > 0 && [host length] > 0 && [_roomList refreshIsComplete])
    [_roomList connectToRoom: room defaultHost: host port: port];
  if ([_roomList.currentRoom.serviceName length] == 0 && [_roomList countOfList] > 0)
    [_roomList selectItemAtIndex: 0];

  [_locationListViewController resetDataSource];
  [self handleRoomChange];

  if ([_roomList.currentRoom.serviceName length] > 0)
  {
    [_state setObject: _roomList.currentRoom.serviceName forKey: kLocationKey];
    [_state setObject: [_roomList connectedHost] forKey: kDefaultHostKey];
    [_state setObject: [NSString stringWithFormat: @"%u", [_roomList connectedPort]] forKey: kDefaultPortKey];
    
    if ([serviceName isKindOfClass: [NSString class]])
    {
      NSUInteger count = [_currentRoom.services countOfList];
    
      for (NSUInteger i = 0; i < count; ++i)
      {
        if ([[[_currentRoom.services itemAtIndex: i] serviceName] isEqualToString: serviceName])
        {
          [_currentRoom.services selectItemAtIndex: i];
          break;
        }
      }
    }

    [serviceName release];
    serviceName = [[[_roomList.currentRoom.services listDataCurrentItem] serviceName] retain];
    if (serviceName == nil)
      [_state setObject: [NSNull null] forKey: kServiceKey];
    else
      [_state setObject: serviceName forKey: kServiceKey];
  }

  [serviceName release];
}

- (void) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags
{
  if ((flags & NLRENDERER_VOLUME_CHANGED) != 0 && !_ignoreVolumeUpdates)
  {
    _toolbarVolume.value = renderer.volume;
    _sideBarVolume.value = renderer.volume;
  }

  if ((flags & NLRENDERER_MUTE_CHANGED) != 0)
    [self setMuteIcon];

  if ((flags & (NLRENDERER_NO_FEEDBACK_CHANGED|NLRENDERER_AUDIO_SESSION_CHANGED)) != 0)
    [self setAudioControlsForRenderer: renderer];
}

- (void) disableVolumeUpdates
{
  _ignoreVolumeUpdates = YES;
  [_ignoreVolumeUpdatesDebounceTimer invalidate];
  _ignoreVolumeUpdatesDebounceTimer = nil;
}

- (void) enableVolumeUpdatesAfterDelay
{
  _ignoreVolumeUpdatesDebounceTimer =
  [NSTimer scheduledTimerWithTimeInterval: 2.0 target: self selector: @selector(enableVolumeUpdates) 
                                 userInfo: nil repeats: NO];
}

- (void) enableVolumeUpdates
{
  _ignoreVolumeUpdatesDebounceTimer = nil;
  _ignoreVolumeUpdates = NO;
  [self renderer: _roomList.currentRoom.renderer stateChanged: NLRENDERER_VOLUME_CHANGED];
}

- (IBAction) setVolume: (UISlider *) slider
{
  if (_muteStartedTime == nil || [_muteStartedTime timeIntervalSinceNow] < -0.5)
    _roomList.currentRoom.renderer.volume = slider.value;
}

- (IBAction) toggleMuteStart: (UISlider *) slider
{
  [self disableVolumeUpdates];
  [_muteStartedTime release];
  _muteStartedTime = [[NSDate date] retain];
  _originalVolume = slider.value;
}

- (IBAction) toggleMuteEnd: (UISlider *) slider
{
  [self enableVolumeUpdatesAfterDelay];
  if (_muteStartedTime != nil)
  {
    if ([_muteStartedTime timeIntervalSinceNow] >= -0.5)
    {
      [_roomList.currentRoom.renderer toggleMute];
      slider.value = _originalVolume;
      [self setMuteIcon];
    }
    [_muteStartedTime release];
    _muteStartedTime = nil;
  }
}

- (IBAction) cancelToggleMute: (UISlider *) slider
{
  [self enableVolumeUpdatesAfterDelay];
  [_muteStartedTime release];
  _muteStartedTime = nil;
}

- (NSArray *) visibleSubControllers
{
  UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
  NSArray *subControllers;

  if (_contentViewController == nil)
  {
    if (UIInterfaceOrientationIsPortrait( orientation ) && _contentViewController == nil)
      subControllers = nil;
    else
      subControllers = [NSArray arrayWithObjects: _locationListViewController, _serviceListViewController, nil];
  }
  else
  {
    if (UIInterfaceOrientationIsPortrait( orientation ) && _contentViewController == nil)
      subControllers = [NSArray arrayWithObject: _contentViewController];
    else
      subControllers = [NSArray arrayWithObjects: _contentViewController, _locationListViewController,
                        _serviceListViewController, nil];
  }

  return subControllers;
}

- (void) setSettingsButton
{
  Class settingsClass = [ConfigManager settingsViewClass];
  CGFloat initialWidth = _sideBarSettingsButton.frame.size.width;
  UIImage *toolbarImage;
  UIImage *image;
  NSString *title;

  if (settingsClass == [ConfigViewController class])
    title = NSLocalizedString( @"Settings", @"Title of the iLinX settings button" );
  else if (settingsClass == [ProfileListController class])
    title = NSLocalizedString( @"Profiles", @"Title of the iLinX profiles button" );
  else
    title = nil;
  
  if (title == nil)
  {
    toolbarImage = [UIImage imageNamed: @"RefreshIconToolbar"];
    image = [UIImage imageNamed: @"RefreshIcon"];
  }
  else
  {
    toolbarImage = nil;
    image = nil;
  }
  
  _sideBarSettingsButton.title = title;
  _sideBarSettingsButton.image = image;
  _sideBarSettingsButton.frame = CGRectOffset( _sideBarSettingsButton.frame, initialWidth - 
                                                _sideBarSettingsButton.frame.size.width, 0 );
  _toolbarSettingsButton.title = title;
  _toolbarSettingsButton.image = toolbarImage;
}

- (void) setMuteIcon
{
  BOOL muted = (_currentRoom.renderer == nil || _currentRoom.renderer.noFeedback || _currentRoom.renderer.mute);
  
  _sideBarVolume.showAlternateThumb = muted;
  _toolbarVolume.showAlternateThumb = muted;
}

- (void) setAudioControlsForRenderer: (NLRenderer *) renderer
{
  if (renderer == nil)
  {
    _toolbarVolume.value = 0;
    _sideBarVolume.value = 0;
    _toolbarVolume.enabled = NO;
    _sideBarVolume.enabled = NO;
    [_topBarAudioControls disable];
    [_sideBarAudioControls disable];
    _toolbarPopoverButton.tintColor = nil;
    if (!_multiroomMessageView.hidden)
    {
      _multiroomMessageView.hidden = YES;
      _locationTableView.frame = CGRectMake( _locationTableView.frame.origin.x,
                                            _locationTableView.frame.origin.y - _multiroomMessageView.frame.size.height,
                                            _locationTableView.frame.size.width,
                                            _locationTableView.frame.size.height + _multiroomMessageView.frame.size.height );
    }
  }
  else
  {
    _toolbarVolume.value = renderer.volume;
    _sideBarVolume.value = _toolbarVolume.value;
    _toolbarVolume.enabled = YES;
    _sideBarVolume.enabled = YES;
    [_topBarAudioControls enable];
    [_sideBarAudioControls enable];
    [_topBarAudioControls setRenderer: renderer];
    [_sideBarAudioControls setRenderer: renderer];
    if (renderer.audioSessionActive)
    {
      _toolbarPopoverButton.tintColor = [_multiroomTintView backgroundColor];
      if (_multiroomMessageView.hidden)
      {
        _multiroomMessageView.hidden = NO;
        _locationTableView.frame = CGRectMake( _locationTableView.frame.origin.x,
                                              _locationTableView.frame.origin.y + _multiroomMessageView.frame.size.height,
                                              _locationTableView.frame.size.width,
                                              _locationTableView.frame.size.height - _multiroomMessageView.frame.size.height );
      }
      _multiroomMessageLabel.text = [NSString stringWithFormat: _multiroomMessage, renderer.audioSessionName]; 
    }
    else
    {
      _toolbarPopoverButton.tintColor = nil;
      if (!_multiroomMessageView.hidden)
      {
        _multiroomMessageView.hidden = YES;
        _locationTableView.frame = CGRectMake( _locationTableView.frame.origin.x,
                                              _locationTableView.frame.origin.y - _multiroomMessageView.frame.size.height,
                                              _locationTableView.frame.size.width,
                                              _locationTableView.frame.size.height + _multiroomMessageView.frame.size.height );
      }
    }
  }
}

- (void) showExecutingMacroBanner: (BOOL) show
{
  _executingMacro.hidden = !show;
  if (show)
    [_executingMacroActivity startAnimating];
  else
    [_executingMacroActivity stopAnimating];
}

- (void) dealloc 
{
  //NSLog( @"NLRoomList %08X about to be released by RootViewController %08X", _roomList, self );
  [AppStateNotification removeObserver: self];

  [_toolbar release];
  [_toolbarTitle release];
  [_toolbarPopoverButton release];
  [_toolbarTitleButton release];
  [_toolbarVolume release];
  [_toolbarSettingsButton release];
  [_sideBar release];
  [_sideBarTitleBar release];
  [_sideBarTitle release];
  [_sideBarTitleButton release];
  [_sideBarSettingsButton release];
  [_sideBarToolbar release];
  [_sideBarVolume release];
  [_currentSelectionViewHolder release];
  [_currentSelectionView release];
  [_locationTableView release];
  [_divider release];
  [_serviceTableView release];
  [_contentView release];
  [_locationListViewController release];
  [_serviceListViewController release];
  [_executingMacro release];
  [_executingMacroActivity release];
  [_topBarAudioControls release];
  [_sideBarAudioControls release];
  [_multiroomTintView release];
  [_multiroomMessageView release];
  [_multiroomMessageLabel release];
  [_roomList release];
  [_serviceViewClasses release];
  [_state release];
  [_contentViewController release];
  [_currentSelectionPopover dismissPopoverAnimated: NO];
  [_currentSelectionPopover release];
  [_ignoreVolumeUpdatesDebounceTimer invalidate];
  [_muteStartedTime release];
  [_executingMacro release];
  [_executingMacroActivity release];
  [_toolbarSettingsButton release];
  [_multiroomMessage release];
  [_uiMessageHandler release];
  [super dealloc];
}

@end

