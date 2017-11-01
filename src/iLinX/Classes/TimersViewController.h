//
//  TimersViewController.h
//  iLinX
//
//  Created by mcf on 22/05/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServiceViewController.h"
#import "ListDataSource.h"
#import "NLServiceTimers.h"

@interface TimersViewController : ServiceViewController <UITableViewDataSource, UITableViewDelegate, ListDataDelegate, NLServiceTimersDelegate>
{
@private
  NLServiceTimers *_timersService;
  UITableView *_tableView;
  NSTimer *_initialActivityTimer;
}

@property (readonly) UITableView *tableView;

+ (NSString *) dayListForRepeatMask: (NSUInteger) repeatMask;
+ (NSUInteger) sundayIndexedWeekdayForLocalWeekday: (NSUInteger) weekday;

@end
