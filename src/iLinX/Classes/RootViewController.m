//
//  RootViewController.m
//  iLinX
//
//  Created by mcf on 30/12/2008.
//  Copyright 2008 Micropraxis Ltd. All rights reserved.
//

#import "RootViewController.h"
#import "AppStateNotification.h"
#import "AVControlViewProtocol.h"
#import "BorderedTableViewCell.h"
#import "CameraViewController.h"
#import "ChangeSelectionHelper.h"
#import "ConfigRootController.h"
#import "ConfigManager.h"
#import "ConfigProfile.h"
#import "ConfigViewController.h"
#import "CustomViewController.h"
#import "DeprecationHelper.h"
#import "Icons.h"
#import "FavouritesViewController.h"
#import "GenericViewController.h"
#import "HVACViewController.h"
#import "IROnlyViewController.h"
#import "LocalSourceViewController.h"
#import "MainNavigationController.h"
#import "MediaViewController.h"
#import "NLRenderer.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLSource.h"
#import "NLSourceList.h"
#import "NLService.h"
#import "NLServiceList.h"
#import "NoSourceViewController.h"
#import "PlaceholderViewController.h"
#import "ProfileListController.h"
#import "SecurityViewController.h"
#import "StandardPalette.h"
#import "TimersViewController.h"
#import "TunerViewController.h"
#import "DebugTracing.h"

static NSString * const kLocationKey = @"Location";
static NSString * const kDefaultHostKey = @"DefaultHost";
static NSString * const kDefaultPortKey = @"DefaultPort";
static NSString * const kCurrentServiceKey = @"CurrentService";

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

@interface RootViewController ()

- (void) restoreState: (NSMutableArray *) state fromLevel: (NSUInteger) level;
- (void) reinit;
- (void) reloadData;
- (void) changeLocation: (id) button;
- (void) viewSettings: (id) button;
- (void) determineFavouritesAsDefaultScreen;
- (void) handleFavouritesAsDefaultScreenAnimated: (BOOL) animated;
- (void) selectInitialService: (NLService *) service;
- (BOOL) selectHomeScreen: (BOOL) animated ignoreFavourites: (BOOL) ignoreFavourites;
- (void) setSettingsButton;

@property (nonatomic, retain) NSDictionary *serviceViewClasses;
@property (nonatomic, retain) NSDictionary *avViewClasses;
@property (nonatomic, retain) NSMutableDictionary *state;

@end

@implementation RootViewController

@synthesize
  serviceViewClasses = _serviceViewClasses,
  avViewClasses = _avViewClasses,
  state = _state;

#pragma mark UIViewController

- (void) _initialiseLocals
{
  _uiMessageHandler = [[GUIMessageHandler alloc] init];
  
  self.serviceViewClasses =
  [NSDictionary dictionaryWithObjectsAndKeys:
   [CameraViewController class], @"Cameras",
   [FavouritesViewController class], @"Favorites",
   [GenericViewController class], @"generic-serial",
   [GenericViewController class], @"generic-ir",
   [HVACViewController class], @"hvac",
   [HVACViewController class], @"hvac2",
   [GenericViewController class], @"lighting",
   [SecurityViewController class], @"security",
   [SecurityViewController class], @"security2",
   [TimersViewController class], @"Timers",
   nil];
  
  self.avViewClasses =
  [NSDictionary dictionaryWithObjectsAndKeys:
   [NoSourceViewController class], @"NOSOURCE",
   [LocalSourceViewController class], @"LOCALSOURCE",
   [LocalSourceViewController class], @"LOCALSOURCE-STREAM",
   [TunerViewController class], @"TUNER",
   [MediaViewController class], @"MEDIASERVER",
   [MediaViewController class], @"VTUNER",
   [TunerViewController class], @"XM TUNER",
   [TunerViewController class], @"ZTUNER",
   [IROnlyViewController class], @"TRNSPRT",
   [IROnlyViewController class], @"DVD",
   [IROnlyViewController class], @"PVR",
   nil];
  
#if defined(SPLASH_SCREEN_FADE)
  _streamNetLogo = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"SplashOverlay.png"]];
#else
  _streamNetLogo = nil;
#endif
  
  _configStartupType = [ConfigManager currentStartupType];
  if (_configStartupType == STARTUP_TYPE_USE_CURRENT_PROFILE)
    _configStartupType = STARTUP_TYPE_AUTO_DETECT;
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
  if ((self = [super initWithCoder: aDecoder]) != nil)
    [self _initialiseLocals];
  
  return self;
}

- (id) init
{
  if ((self = [super initWithStyle: UITableViewStylePlain]) != nil)
    [self _initialiseLocals];

  return self;
}

- (void) loadView
{
  [super loadView];
  
  UIBarButtonItem *roomItem = [[UIBarButtonItem alloc]
                               initWithTitle: NSLocalizedString( @"Location", @"Default title of the location selection button" )
                               style: UIBarButtonItemStyleBordered
                               target: self action: @selector(changeLocation:)];
  UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                 initWithTitle: NSLocalizedString( @"Home", @"Title of back button when returning to the home list for a location" )
                                 style: UIBarButtonItemStyleBordered target: nil action: nil];
  
  self.navigationItem.leftBarButtonItem = roomItem;
  [roomItem release];
  self.navigationItem.backBarButtonItem = backButton;
  [backButton release];
  [self setSettingsButton];

  UIView *footerView = [[UIView alloc] initWithFrame: CGRectMake( 0, 0, self.view.frame.size.width, 54.0 )];
  
  self.tableView.backgroundColor = [StandardPalette tableCellColour];
  footerView.backgroundColor = [StandardPalette tableCellColour];
  footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  self.tableView.tableFooterView = footerView;
  [footerView release];

  if (_streamNetLogo != nil)
  {
    [_streamNetLogo sizeToFit];
    _streamNetLogo.frame = CGRectOffset( _streamNetLogo.frame, 0, -self.navigationController.navigationBar.frame.size.height );
    _streamNetLogo.alpha = 0.6;
    [self.view addSubview: _streamNetLogo];
  }
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  _savedView = [self.view retain];
  
  [AppStateNotification addWillEnterForegroundObserver: self selector: @selector(setSettingsButton)];
}

- (void) viewDidUnload
{
  [AppStateNotification removeObserver: self];
  [_savedView release];
  _savedView = nil;
  [super viewDidUnload];
}

- (void) restoreState: (NSMutableArray *) state fromLevel: (NSUInteger) level
{
  MainNavigationController *mainController = (MainNavigationController *) self.navigationController;
  
  [_roomList removeDelegate: self];
  [_roomList removePopupMessageDelegate: _uiMessageHandler];
  if (_roomList.currentRoom != nil)
    [_roomList.currentRoom.sources removeSourceOnlyDelegate: self];
  [mainController setRenderer: nil];
  [_favouritesController release];
  _favouritesController = nil;
  _currentRoom = nil;
  //NSLog( @"NLRoomList %08X about to be released by RootViewController %08X", _roomList, self );
  [_roomList release];
  [CustomViewController setCurrentRoomList: nil];
#ifdef DEBUG
  NSLog( @"Retained objects: %@", [NSDebugObject liveObjects] );
#endif
  
  _roomList = [[NLRoomList alloc] init];
  [_roomList addPopupMessageDelegate: _uiMessageHandler];
  //NSLog( @"NLRoomList %08X allocated by RootViewController %08X", _roomList, self );
  [CustomViewController setCurrentRoomList: _roomList];

  [_customPage release];
  _customPage = [[CustomViewController alloc] initWithController: self customPage: @"home.htm"];
  if ([_customPage isValid])
  {
    self.tableView.hidden = YES;
    [_customPage loadViewWithFrame: self.view.bounds];
    self.view = _customPage.view;
    [_customPage setMacroHandler: mainController.executingMacroAlert];
  }
  else
  {
    self.view = _savedView;
    self.tableView.hidden = NO;
    [_customPage release];
    _customPage = nil;
  }
  
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

- (void) changeLocation: (id) button
{
  [_roomList addDelegate: self];
  [ChangeSelectionHelper showDialogOver: [self navigationController]
                           withListData: _roomList];
}

- (void) viewSettings: (id) button
{
  ConfigRootController *configRootController = [[ConfigRootController alloc]
                                                initWithRootClass: [ConfigManager settingsViewClass]
                                                startupTypeDelegate: self];
  
  [self presentModalViewController: configRootController animated: YES];
  [configRootController release];
}

- (void) setConfigStartupType: (NSInteger) startupType
{
  _configStartupType = startupType;
}

- (void) currentItemForListData: (id<ListDataSource>) listDataSource
                    changedFrom: (id) old to: (id) new at: (NSUInteger) index
{
  if (listDataSource == _roomList)
  {
    _currentRoom = _roomList.currentRoom;
    [self determineFavouritesAsDefaultScreen];
    if (_favouritesController != nil)
      [self handleFavouritesAsDefaultScreenAnimated: NO];
    else if (self.navigationController.topViewController != self)
      [self.navigationController popToRootViewControllerAnimated: NO];
  }
  else if (listDataSource == _roomList.currentRoom.services)
  {
    [self selectService: new animated: YES];
  }

  [_customPage reloadData];
}

- (void) viewWillAppear: (BOOL) animated
{
  self.navigationController.navigationBarHidden = [_customPage hidesNavigationBar];
  [super viewWillAppear: animated];

  [self setSettingsButton];

  if (_configStartupType == STARTUP_TYPE_AUTO_DETECT)
  {
    _configStartupType = STARTUP_TYPE_USE_CURRENT_PROFILE;
    [self reinit];
  }

    [_roomList removeDelegate: self];
    [_roomList resetCurrentItemToCurrentRoom];
    _currentRoom = [_roomList currentRoom];
    [self determineFavouritesAsDefaultScreen];

  MainNavigationController *mainController = (MainNavigationController *) self.navigationController;
  NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
  NSString *locationTitle;

  if (_currentRoom == nil)
    locationTitle = @"";
  else
    locationTitle = _currentRoom.displayName;

  [StandardPalette setTintForNavigationBar: mainController.navigationBar];
  [self refreshPalette];
  self.tableView.tableFooterView.backgroundColor = [StandardPalette tableCellColour];
  [mainController setAudioControlsStyle: UIBarStyleDefault];

  [self.tableView deselectRowAtIndexPath: tableSelection animated: NO];
  if ([locationTitle length] == 0 || [_roomList connectedHost] == nil)
    locationTitle = NSLocalizedString( @"iLinX", @"Master view navigation title" );
  else
  {
    [_state setObject: _roomList.currentRoom.serviceName forKey: kLocationKey];
    [_state setObject: [_roomList connectedHost] forKey: kDefaultHostKey];
    [_state setObject: [NSString stringWithFormat: @"%u", [_roomList connectedPort]] forKey: kDefaultPortKey];
  }
  [_state removeObjectForKey: kCurrentServiceKey];

  if (_customPage != nil)
  {
    [_customPage setMacroHandler: mainController.executingMacroAlert];
    if ([_customPage.title length] > 0)
      locationTitle = _customPage.title;
    [_customPage viewWillAppear: animated];
  }
  self.title = locationTitle;
  [self reloadData];
  
  // We don't do anything with this information, but registering for it ensures that
  // it is kept up to date, so that if and when A/V is selected we know which is the
  // current source.
  if (_currentRoom != nil)
  {
    [_currentRoom.sources addSourceOnlyDelegate: self];
    if (_customPage != nil)
      [_currentRoom.services addDelegate: self];
}
}

- (void) viewWillDisappear: (BOOL) animated
{
  if (_roomList.currentRoom != nil)
  {
    [_roomList.currentRoom.sources removeSourceOnlyDelegate: self];
    [_roomList.currentRoom.services removeDelegate: self];
  }
  if (_streamNetLogo != nil)
  {
    [_streamNetLogo removeFromSuperview];
    [_streamNetLogo release];
    _streamNetLogo = nil;
  }

  [_customPage setMacroHandler: nil];
  [_customPage viewWillDisappear: animated];
  [ConfigManager saveConfiguration];

  self.navigationController.navigationBarHidden = [_customPage hidesNavigationBar];
  [super viewWillDisappear: animated];
}

- (void) viewDidAppear: (BOOL) animated
{
  MainNavigationController *mainController = (MainNavigationController *) self.navigationController;
  BOOL showAudioControls = (_customPage == nil || !_customPage.hidesAudioControls);
  
  [super viewDidAppear: animated];

  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

  if ([_roomList currentRoom] != nil)
    [mainController setRenderer: _roomList.currentRoom.renderer];
  [mainController showAudioControls: showAudioControls];
  self.navigationController.navigationBarHidden = [_customPage hidesNavigationBar];
 
  if (_streamNetLogo != nil)
  {
    [UIView beginAnimations: @"HideStreamNetLogo" context: nil];
    [UIView setAnimationDuration: 3.0];
    
    _streamNetLogo.alpha = 0;
    
    [UIView commitAnimations];
  }

  if (_showLocationSelector)
  {
    _showLocationSelector = NO;
    [self performSelector: @selector(changeLocation:) withObject: nil afterDelay: 0];
  }
  else if (_initialService != nil)
  {
    [self performSelector: @selector(selectInitialService:) withObject: _initialService afterDelay: 0];
    _initialService = nil;
  }

  if (_configStartupType == STARTUP_TYPE_PRESENT_CHOICE)
  {
    UIViewController *profileList = [[ConfigRootController alloc] 
                                     initWithRootClass: [ProfileListController class] startupTypeDelegate: self];
    
    [self presentModalViewController: profileList animated: YES];
    [profileList release];
    _configStartupType = STARTUP_TYPE_AUTO_DETECT;
  }
}

// Standard table view data source and delegate methods

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
  return 1;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  // Only one section so return the number of items in the list
  
  return [_roomList.currentRoom.services countOfList];
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  BorderedTableViewCell *cell = (BorderedTableViewCell *) [tableView dequeueReusableCellWithIdentifier: @"MyIdentifier"];
  NLService *service = [_roomList.currentRoom.services itemAtIndex: indexPath.row];
  
  if (cell == nil)
    cell = [[[BorderedTableViewCell alloc] initDefaultWithFrame: CGRectZero 
                                                reuseIdentifier: @"MyIdentifier"
                                                          table: tableView] autorelease];
  else
    [cell refreshPaletteToVersion: _paletteVersion];
  [cell setLabelTextColor: [StandardPalette tableTextColour]];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  [cell setLabelImage: [Icons homeIconForServiceName: service.serviceType]];
  [cell setLabelSelectedImage: [Icons selectedHomeIconForServiceName: service.serviceType]];
  
  // Get the object to display and set the value in the cell
  [cell setLabelText: [_roomList.currentRoom.services titleForItemAtIndex: indexPath.row]];
  
  return cell;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  [self selectService: [_roomList.currentRoom.services serviceAtIndex: indexPath.row] animated: YES];
}

- (void) selectService: (NLService *) service animated: (BOOL) animated
{
  NSString *serviceType = service.serviceType;
  id serviceViewController;
  id browseViewController;
  BOOL ignoreFavourites = NO;
  
  if ([serviceType isEqualToString: @"Audio"])
  {
    // A/V service; create the appropriate view for the currently selected source type
    
    NLSource *currentSource = _roomList.currentRoom.sources.currentSource;
    Class viewClass = [_avViewClasses objectForKey: currentSource.sourceControlType];
    id<AVControlViewProtocol> avServiceViewController;
    
    //**/NSLog( @"Select service: %@ (%@)", serviceType, currentSource );

    if (viewClass == nil)
      viewClass = [PlaceholderViewController class];
    
    avServiceViewController = [[viewClass alloc] initWithRoomList: _roomList service: service source: currentSource];
    if (avServiceViewController.isBrowseable)
    {
      serviceViewController = [avServiceViewController allocBrowseViewController];
      if (_roomList.currentRoom.renderer.ampOn &&
          currentSource.controlState != nil && ![currentSource.controlState isEqualToString: @"STOP"])
      {
        // We can jump straight to the now playing screen, so just stack the browse screen
        browseViewController = serviceViewController;
        serviceViewController = avServiceViewController;
      }
      else
      {
        // We need to go to the browse screen to select something to play, so discard the now
        // playing screen for the moment
        browseViewController = nil;
        [avServiceViewController release];
      }
    }
    else
    {
      serviceViewController = avServiceViewController;
      browseViewController = nil;
    }
  }
  else if ([serviceType isEqualToString: @"CHANGE_SCREEN"])
  {
    //**/NSLog( @"Select service: %@", serviceType );

    // Dummy service type created when handling a "change screen" macro.  For now,
    // just go back to the home screen for "home" and ignore everything else.
    // We should also really deal with "Location", "sourceList" and "multi-room"
    // as well, but they are more problematic, so we're leaving that for another day...
    serviceViewController = nil;
    browseViewController = nil;
    ignoreFavourites = ([service.displayName compare: @"home" options: NSCaseInsensitiveSearch] == NSOrderedSame);
  }
  else
  {
    //**/NSLog( @"Select service: %@", serviceType );

    // Other type of service.  Create a view to manage that type of service
    
    Class serviceViewClass = [_serviceViewClasses objectForKey: serviceType];
    
    if (serviceViewClass == nil)
      serviceViewClass = [PlaceholderViewController class];

    serviceViewController = [[serviceViewClass alloc] initWithRoomList: _roomList service: service];
    browseViewController = nil;
  }

  // If there's a stack of other controllers to be removed, remove them quietly and
  // then transition to the new view without animation, unless we're just popping
  // back to the home screen and staying there, in which case animate it.
  
  if ([self selectHomeScreen: (serviceViewController == nil) ignoreFavourites: ignoreFavourites])
    animated = NO;

  if (browseViewController != nil)
  {
    [self.navigationController pushViewController: browseViewController animated: NO];
    [browseViewController release];
  }
  
  if (serviceViewController != nil)
  {
    [_state setObject: [service serviceName] forKey: kCurrentServiceKey];
    if (![serviceViewController isKindOfClass: [FavouritesViewController class]] || _favouritesController == nil)
      [self.navigationController pushViewController: serviceViewController animated: animated];
    else
    {
      if (self.navigationController.topViewController != _favouritesController)
        [self.navigationController pushViewController: _favouritesController animated: animated];
    }
    [serviceViewController release];
  }
}

- (BOOL) selectHomeScreen: (BOOL) animated
{
  return [self selectHomeScreen: animated ignoreFavourites: NO];
}

- (BOOL) selectHomeScreen: (BOOL) animated ignoreFavourites: (BOOL) ignoreFavourites
{
  NSArray *popped;

  [_roomList resetCurrentItemToCurrentRoom];
  if (_roomList.currentRoom == _currentRoom)
  {
    if (ignoreFavourites || _favouritesController == nil)
      popped = [self.navigationController popToRootViewControllerAnimated: animated];
    else
    {
      NSArray *viewControllers = self.navigationController.viewControllers;
      NSUInteger count = [viewControllers count];
      NSUInteger i;
      
      for (i = 0; i < count; ++i)
      {
        if ([viewControllers objectAtIndex: i] == _favouritesController)
        {
          popped = [self.navigationController popToViewController: _favouritesController animated: animated];
          break;
        }
      }
      
      if (i == count)
        popped = [self.navigationController popToRootViewControllerAnimated: animated];
    }
  }
  else
  {
    _currentRoom = _roomList.currentRoom;
    [self determineFavouritesAsDefaultScreen];
    popped = [self.navigationController popToRootViewControllerAnimated:
              animated && (ignoreFavourites || _favouritesController == nil)];
    if (!ignoreFavourites)
      [self handleFavouritesAsDefaultScreenAnimated: animated];
  }

  return ([popped count] > 0);
}

- (void) didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (void) reinit
{
  ConfigProfile *profile = [ConfigManager currentProfileData];

  // Attempt to restore the previous state (note that this may not be possible if
  // the configuration has changed or we have moved to a different location).
  [self restoreState: profile.state fromLevel: 0];
  
  NSString *room = [_state objectForKey: kLocationKey];
  NSString *host = [_state objectForKey: kDefaultHostKey];
  NSUInteger port = [[_state objectForKey: kDefaultPortKey] integerValue];
  
  if ([room length] == 0 && [_roomList refreshIsComplete] && [_roomList countOfList] > 0)
    room = [[_roomList itemAtIndex: 0] serviceName];

  if ([room length] > 0 && [host length] > 0 && [_roomList refreshIsComplete])
    [_roomList connectToRoom: room defaultHost: host port: port];
  if ([_roomList.currentRoom.serviceName length] == 0)
  {
    if (_customPage == nil)
      _showLocationSelector = YES;
  }
  else
  {
    NSString *initialServiceName = [_state objectForKey: kCurrentServiceKey];

    [_state setObject: [_roomList connectedHost] forKey: kDefaultHostKey];
    [_state setObject: [NSString stringWithFormat: @"%u", [_roomList connectedPort]] forKey: kDefaultPortKey];
    _currentRoom = _roomList.currentRoom;
    [self determineFavouritesAsDefaultScreen];
    
    if (initialServiceName != nil)
    {
      _initialService = nil;
      for (NSUInteger i = 0; i < [_currentRoom.services countOfList]; ++i)
      {
        NLService *service = [_currentRoom.services itemAtIndex: i];

        if ([initialServiceName isEqualToString: [service serviceName]])
        {
          _initialService = service;
          break;
  }
}
    }

    if (_initialService == nil)
      [self handleFavouritesAsDefaultScreenAnimated: NO];
  }
}

- (void) reloadData
{
  if (_customPage == nil)
    [self.tableView reloadData];
  else
    [_customPage reloadData];
}

- (void) determineFavouritesAsDefaultScreen
{
  NSArray *services = _roomList.currentRoom.services.services;
  NSUInteger count = [services count];
  NSUInteger i;
  
  for (i = 0; i < count; ++i)
  {
    NLService *service = [services objectAtIndex: i];
    
    if ([service.serviceType isEqualToString: @"Favorites"])
    {
      if (service.isDefaultScreen)
      {
        if ([_favouritesController service] != service)
        {
          [_favouritesController release];
          _favouritesController = [[FavouritesViewController alloc]
                                   initWithRoomList: _roomList service: service];
        }
      }
      else
      {
        [_favouritesController release];
        _favouritesController = nil;
      }
      break;
    }
  }
  
  if (i == count)
  {
    [_favouritesController release];
    _favouritesController = nil;
  }
}

- (void) handleFavouritesAsDefaultScreenAnimated: (BOOL) animated
{
  if (_favouritesController != nil && self.navigationController.topViewController == self)
  {
    if (_roomList.currentRoom != nil)
      [(MainNavigationController *) self.navigationController setRenderer: _roomList.currentRoom.renderer];
    [self.navigationController pushViewController: _favouritesController animated: animated];
  }
}

- (void) selectInitialService: (NLService *) service
{
  [self selectService: service animated: NO];
}

- (void) setSettingsButton
{
  Class settingsClass = [ConfigManager settingsViewClass];
  UIBarButtonItem *settingsItem;
  
  if (settingsClass == [ConfigViewController class])
    settingsItem = [[UIBarButtonItem alloc]
                    initWithTitle: NSLocalizedString( @"Settings", @"Title of the iLinX settings button" )
                    style: UIBarButtonItemStyleBordered
                    target: self action: @selector(viewSettings:)];
  else if (settingsClass == [ProfileListController class])
    settingsItem = [[UIBarButtonItem alloc]
                    initWithTitle: NSLocalizedString( @"Profiles", @"Title of the iLinX profiles button" )
                    style: UIBarButtonItemStyleBordered
                    target: self action: @selector(viewSettings:)];
  else
    settingsItem = nil;

  
  self.navigationItem.rightBarButtonItem = settingsItem;
  [settingsItem release];
}

- (void) dealloc 
{
  //NSLog( @"NLRoomList %08X about to be released by RootViewController %08X", _roomList, self );
  [AppStateNotification removeObserver: self];

  [_roomList removePopupMessageDelegate: _uiMessageHandler];
  [_uiMessageHandler release];
  [_roomList release];
  [_serviceViewClasses release];
  [_favouritesController release];
  [_customPage release];
  [_savedView release];
  [_avViewClasses release];
  [_streamNetLogo release];
  [_state release];
  [super dealloc];
}

@end
