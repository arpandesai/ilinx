//
//  BrowseSubViewController.h
//  iLinX
//
//  Created by mcf on 19/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ListDataSource.h"
#import "NLSourceMediaServer.h"

@class BrowseViewController;
@class NLBrowseList;
@class TintedTableViewDelegate;

@interface BrowseSubViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,
                                                       ListDataDelegate, NLSourceMediaServerDelegate>
{
@private
  NLSourceMediaServer *_source;
  NLBrowseList *_browseList;
  BrowseViewController *_owner;

  UITableView *_tableView;
  
  TintedTableViewDelegate *_tintHandler;
  NSMutableDictionary *_pendingConnections;
  NSTimer *_thumbnailRefreshTimer;
  BOOL _hasSections;
  BOOL _active;
}

@property (readonly) UITableView *tableView;

- (id) initWithSource: (NLSource *) source browseList: (NLBrowseList *) browseList
                owner: (BrowseViewController *) owner;

@end
