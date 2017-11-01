//
//  DayListViewController.h
//  iLinX
//
//  Created by mcf on 09/06/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TintedTableViewController.h"

@class NLTimer;

@interface DayListViewController : TintedTableViewController
{
@private
  NLTimer *_timer;
}

- (id) initWithTimer: (NLTimer *) timer;

@end
