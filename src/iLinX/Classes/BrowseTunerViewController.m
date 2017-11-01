//
//  BrowseTunerViewController.m
//  iLinX
//
//  Created by mcf on 23/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "BrowseTunerViewController.h"
#import "NLSourceTuner.h"

@interface BrowseTunerViewController ()

- (void) clearAllPresets: (id) control;
- (void) refreshChannels: (id) control;

@end

@implementation BrowseTunerViewController

- (id) initWithRoomList: (NLRoomList *) roomList service: (NLService *) service
                 source: (NLSource *) source nowPlaying: (id<AVControlViewProtocol>) nowPlaying
{
  if (self = [super initWithRoomList: roomList service: service source: source nowPlaying: nowPlaying])
  {
    _tuner = (NLSourceTuner *) source;
  }
  
  return self;
}

- (void) loadView
{
  [super loadView];
  _basicButtonSet = [_toolBar.items retain];
}

- (void) viewDidDisappear: (BOOL) animated
{
  [_tuner removeDelegate: self];
  [super viewDidDisappear: animated];
  _wasVisible = YES;
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  
  if (_location != nil && _service != nil)
  {
    if (_wasVisible)
      [self source: _tuner stateChanged: 0xFFFFFFFF];
    [_tuner addDelegate: self];
  }
}

- (void) source: (NLSourceTuner *) source stateChanged: (NSUInteger) flags
{
  if ((flags & SOURCE_TUNER_BAND_CHANGED) != 0 ||
    (((flags & SOURCE_TUNER_CONTROL_STATE_CHANGED) != 0) && [source.controlState isEqualToString: @"REFRESH"]))
  {
#if defined(DEBUG)
    //**/NSLog( @"Refresh browse list due to state change" );
#endif
    [self refreshBrowseList];
  }
}

- (void) setBarButtonsForItem: (NSUInteger) itemIndex of: (NSUInteger) itemCount
{
  NSUInteger tag = ((UIBarItem *) [_tabBar.items objectAtIndex: itemIndex]).tag;
  
  if (tag < [_browseList countOfList])
  {
    NSString *type = [[_browseList itemAtIndex: tag] objectForKey: @"id"];
    UIBarButtonItem *addButton;
    
    if (type != nil && [type isEqualToString: @"presets"])
    {
      if ((_tuner.capabilities & SOURCE_TUNER_HAS_DYNAMIC_PRESETS) != 0)
        addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemTrash
                                                                  target: self action: @selector(clearAllPresets:)];
      else
        addButton = nil;
    }
    else if (itemIndex == 0 && ![_tuner.controlState isEqualToString: @"REFRESH"])
      addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemRefresh
                                                                target: self action: @selector(refreshChannels:)];
    else
      addButton = nil;
    
    NSMutableArray *newButtons = [_basicButtonSet mutableCopy];
    
    if (addButton == nil)
      _toolBar.items = newButtons;
    else
    {
      addButton.style = UIBarButtonItemStyleBordered;
      [newButtons addObject: addButton];
      [addButton release];
      _toolBar.items = newButtons;
    }
    [newButtons release];
  }
  
  [super setBarButtonsForItem: itemIndex of: itemCount];
}

- (void) actionSheet: (UIActionSheet *) actionSheet clickedButtonAtIndex: (NSInteger) buttonIndex
{
  if (buttonIndex != [actionSheet cancelButtonIndex])
  {
    if (_cancelPresetsAlert)
      [_tuner clearAllPresets];
    else
    {
      [_tuner rescanChannels];
      [self navigateToNowPlaying];
    }
  }
}

- (void) clearAllPresets: (id) control
{
  UIActionSheet *alert = [[UIActionSheet alloc] 
                          initWithTitle: NSLocalizedString( @"Delete All Presets", @"Title for clear all presets dialog" )
                          delegate: self
                          cancelButtonTitle: NSLocalizedString( @"Cancel", @"Title of button cancelling clearing all presets" )
                          destructiveButtonTitle: NSLocalizedString( @"Delete",
                                                                    @"Title of button proceeding with clearing all presets" )
                          otherButtonTitles: nil];
  
  _cancelPresetsAlert = YES;
  [alert showFromTabBar: _tabBar];
  [alert release];
}

- (void) refreshChannels: (id) control
{
  UIActionSheet *alert = [[UIActionSheet alloc] 
                          initWithTitle: NSLocalizedString( @"Refresh Channels", @"Title for refresh channels dialog" )
                          delegate: self
                          cancelButtonTitle: NSLocalizedString( @"Cancel", @"Title of button cancelling refreshing channels" )
                          destructiveButtonTitle: NSLocalizedString( @"Refresh", @"Title of button proceeding with refreshing channels" )
                          otherButtonTitles: nil];
  
  _cancelPresetsAlert = NO;
  [alert showFromTabBar: _tabBar];
  [alert release];
}

- (void) dealloc
{
  [_basicButtonSet release];
  [super dealloc];
}

@end
