//
//  IROnlyListViewController.h
//  iLinX
//
//  Created by mcf on 01/04/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLBrowseList.h"

@interface IROnlyListViewController : UIViewController <ListDataDelegate, UITableViewDelegate, UITableViewDataSource>
{
@private
  NLBrowseList *_presets;
  UITableView *_tableView;
}

@property (readonly) UITableView *tableView;

- initWithPresets: (NLBrowseList *) presets;

@end