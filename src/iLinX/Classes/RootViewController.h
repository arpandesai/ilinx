//
//  RooViewController.h
//  iLinX
//
//  Created by mcf on 30/12/2008.
//  Copyright 2008 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConfigManager.h"
#import "ListDataSource.h"
#import "TintedTableViewController.h"

@class ConfigProfile;
@class CustomViewController;
@class NLRoom;
@class NLRoomList;
@class NLService;
@class FavouritesViewController;
@class GUIMessageHandler;

@interface RootViewController : TintedTableViewController <ConfigStartupDelegate,ListDataDelegate>
{
@private
  NLRoomList *_roomList;
  NLRoom *_currentRoom;
  NSDictionary *_serviceViewClasses;
  NSDictionary *_avViewClasses;
  NSMutableDictionary *_state;
  FavouritesViewController *_favouritesController;
  CustomViewController *_customPage;
  UIView *_savedView;
  UIImageView *_streamNetLogo;
  NSInteger _configStartupType;
  BOOL _showLocationSelector;
  NLService *_initialService;
  GUIMessageHandler *_uiMessageHandler;
}

- (void) selectService: (NLService *) service animated: (BOOL) animated;
- (BOOL) selectHomeScreen: (BOOL) animated;

@end
