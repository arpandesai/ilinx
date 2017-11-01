//
//  NoSourceViewController.h
//  iLinX
//
//  Created by mcf on 13/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVViewController.h"

@class CustomViewController;
@class NLSourceList;
@class TintedTableViewDelegate;

@interface NoSourceViewController : AVViewController <UITableViewDataSource, UITableViewDelegate>
{
@private
  NSTimer *_forceSourceSelectTimer;
  NLSourceList *_sources;
  UITableView *_tableView;
  TintedTableViewDelegate *_tintHandler;
  NSIndexPath *_selectedIndex;
  CustomViewController *_customPage;
}

@end
