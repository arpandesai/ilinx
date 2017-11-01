//
//  MediaSubMenuViewController.h
//  iLinX
//
//  Created by mcf on 10/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ListDataSource.h"

@class MediaSubMenuViewController;
@class TableViewData;
@class NLBrowseList;

@protocol MediaSubMenuDelegate <NSObject>

- (void) subMenu: (MediaSubMenuViewController *) subMenu hasDisplayOptions: (NSArray *) displayOptions;
- (void) subMenu: (MediaSubMenuViewController *) subMenu didChangeToDisplayOption: (NSUInteger) displayOption;

@end

@interface MediaSubMenuViewController : UITableViewController <ListDataDelegate>
{
@private
  IBOutlet UIView *_viewTemplates;
  
  id<MediaSubMenuDelegate> _displayOptionsDelegate;
  NSArray *_viewData;
  //NSUInteger _currentDisplayOption;
  TableViewData *_currentViewData;
  NSUInteger _itemsPerRow;
  NSUInteger _minimumRows;
  CGFloat _originalRowHeight;
  NLBrowseList *_browseList;
  NSUInteger _lastTopItemIndex;
  NSUInteger _listProperties;
  BOOL _hasAllItemsEntries;
  NSMutableDictionary *_pendingConnections;
  NSTimer *_thumbnailRefreshTimer;
  BOOL _hasSections;
  BOOL _active;
}

@property (nonatomic, retain) NLBrowseList *browseList;
@property (nonatomic, assign) id<MediaSubMenuDelegate> displayOptionsDelegate;

- (IBAction) selectedRowItem: (UIControl *) control;
- (void) setDisplayOption: (NSUInteger) displayOption;

@end
