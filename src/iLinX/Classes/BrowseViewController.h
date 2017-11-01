//
//  BrowseViewController.h
//  iLinX
//
//  Created by mcf on 16/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVViewController.h"
#import "NLSourceMediaServer.h"

@class BrowseSubViewController;
@class NLBrowseList;

@interface BrowseViewController : AVViewController <UITabBarDelegate, UINavigationBarDelegate,
                                                    UINavigationControllerDelegate, NLSourceMediaServerDelegate,
                                                    UITableViewDataSource, UITableViewDelegate>
{
@protected
  NLBrowseList *_browseList;
  NSMutableArray *_previousBrowseList;
  UITabBar *_tabBar;
  UITabBarItem *_currentTabBarItem;
  NSMutableArray *_allTabBarItems;
  NSMutableArray *_unusedTabBarItems;
  id<AVControlViewProtocol> _nowPlaying;
  UINavigationBar *_navBar;
  UINavigationController *_subNavController;
  NSMutableArray *_subViewControllers;
  UITableViewController *_moreViewController;
  NSUInteger _minNavItemCount;
  BOOL _animatePop;
  BOOL _programmaticPop;
  UIViewController *_disappearingController;
}

- (id) initWithRoomList: (NLRoomList *) roomList service: (NLService *) service
                 source: (NLSource *) source nowPlaying: (id<AVControlViewProtocol>) nowPlaying;
- (void) navigateToBrowseList: (NLBrowseList *) browseList;
- (void) navigateToNowPlaying;
- (void) refreshBrowseList;

// For derived classes
- (void) setBarButtonsForItem: (NSUInteger) itemIndex of: (NSUInteger) itemCount;

@end
