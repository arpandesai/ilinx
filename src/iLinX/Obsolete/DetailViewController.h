//
//  DetailViewController.h
//  NetStreams
//
//  Created by mcf on 31/12/2008.
//  Copyright 2008 Micropraxis Ltd. All rights reserved.
//


#import <UIKit/UIkit.h>
#import "ServiceViewController.h"

@class ChangeSelectionHelper;

@interface DetailViewController : ServiceViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
  NSArray *_keys;
  NSArray *_values;
  UITableView *_tableView;
}

@end
