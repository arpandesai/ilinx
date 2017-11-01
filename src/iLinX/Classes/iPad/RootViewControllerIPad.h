//
//  RootViewControllerIPad.h
//  iLinX
//
//  Created by mcf on 04/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConfigManager.h"
#import "DataSourceViewController.h"
#import "ListDataSource.h"
#import "NLRenderer.h"
#import "AudioControlsViewIPad.h"

@class CustomSliderIPad;
@class LocationListViewController;
@class ServiceListViewController;
@class ServiceViewControllerIPad;
@class DataSourceViewController;
@class ConfigProfile;
@class NLRoom;
@class NLRoomList;
@class NLService;
@class PseudoBarButton;
@class GUIMessageHandler;

@interface RootViewControllerIPad : UIViewController <ListDataDelegate, ConfigStartupDelegate,
                                                      DataSourceViewControllerDelegate,
                                                      UIPopoverControllerDelegate, NLRendererDelegate>

{
@private
  IBOutlet UIToolbar *_toolbar;
  IBOutlet UILabel *_toolbarTitle;
  IBOutlet PseudoBarButton *_toolbarPopoverButton;
  IBOutlet UIBarButtonItem *_toolbarTitleButton;
  IBOutlet CustomSliderIPad *_toolbarVolume;
  IBOutlet UIBarButtonItem *_toolbarSettingsButton;
  IBOutlet UIView *_sideBar;
  IBOutlet UIImageView *_sideBarTitleBar;
  IBOutlet UILabel *_sideBarTitle;
  IBOutlet UIButton *_sideBarTitleButton;
  IBOutlet PseudoBarButton *_sideBarSettingsButton;
  IBOutlet UIToolbar *_sideBarToolbar;
  IBOutlet CustomSliderIPad *_sideBarVolume;
  IBOutlet UIView *_currentSelectionViewHolder;
  IBOutlet UIView *_currentSelectionView;
  IBOutlet UITableView *_locationTableView;
  IBOutlet UIImageView *_divider;
  IBOutlet UITableView *_serviceTableView;
  IBOutlet UIView *_contentView;
  IBOutlet LocationListViewController *_locationListViewController;
  IBOutlet ServiceListViewController *_serviceListViewController;
  IBOutlet UIView *_executingMacro;
  IBOutlet UIActivityIndicatorView *_executingMacroActivity;
  IBOutlet AudioControlsViewIPad *_topBarAudioControls;
  IBOutlet AudioControlsViewIPad *_sideBarAudioControls;
  IBOutlet UIView *_multiroomTintView;
  IBOutlet UIView *_multiroomMessageView;
  IBOutlet UILabel *_multiroomMessageLabel;
  
  NLRoomList *_roomList;
  NLRoom *_currentRoom;
  NSDictionary *_serviceViewClasses;
  NSMutableDictionary *_state;
  NSInteger _configStartupType;
  ServiceViewControllerIPad *_contentViewController;
  UIPopoverController *_currentSelectionPopover;
  BOOL _displayPopover;
  BOOL _ignoreVolumeUpdates;
  NSTimer *_ignoreVolumeUpdatesDebounceTimer;
  NSDate *_muteStartedTime;
  CGFloat _originalVolume;
  NSString *_multiroomMessage;
  GUIMessageHandler *_uiMessageHandler;
}

@property (readonly) NLRoomList *roomList;
@property (readonly) NLRoom *currentRoom;

- (IBAction) showSelectionPopover: (id) popoverButton;
- (IBAction) viewSettings: (id) settingsButton;
- (void) selectService: (NLService *) service animated: (BOOL) animated;
- (void) showExecutingMacroBanner: (BOOL) show;

//FIX THIS! should be put in a separate renderer object
- (IBAction) setVolume: (UISlider *) slider;
- (IBAction) toggleMuteStart: (UISlider *) slider;
- (IBAction) toggleMuteEnd: (UISlider *) slider;
- (IBAction) cancelToggleMute: (UISlider *) slider;

@end
