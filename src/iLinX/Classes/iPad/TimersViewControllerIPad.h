//
//  TimersViewControllerIPad.h
//  iLinX
//
//  Created by Tony Short on 27/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServiceViewControllerIPad.h"
#import "NLServiceTimers.h"
#import "TimerEditViewIPad.h"

@class TimersViewCellIPad;

@interface TimersViewControllerIPad : ServiceViewControllerIPad 
	<UITableViewDelegate, UITableViewDataSource, NLServiceTimersDelegate, ListDataDelegate>
{
@private
  NLServiceTimers *_timersService;
  IBOutlet UITableView *_timersTableView;
  IBOutlet TimersViewCellIPad *_templateCell;
  IBOutlet UIView *_noServiceView;
  IBOutlet UIView *_noTimersMessage;
  IBOutlet UIView *_addBar;
  IBOutlet UIView *_barDivider;
  IBOutlet TimerEditViewIPad *_editTimerView;
  IBOutlet UIView *_editControls;
  IBOutlet UIView *_editBar;
  IBOutlet UIView *_saveCancelBar;  
  IBOutlet UIView *_deleteButton;
  IBOutlet UIView *_coverButton;
  
  NSTimer *_initialActivityTimer;
  NLTimer *_newTimer;
  NSInteger _status;
}

+ (NSString *) dayListForRepeatMask: (NSUInteger) repeatMask;
+ (NSString *) dayListForRepeatMask: (NSUInteger) repeatMask;
+ (NSUInteger) sundayIndexedWeekdayForLocalWeekday: (NSUInteger) weekday;

- (IBAction) addTimer;
- (IBAction) buttonDelete;
- (IBAction) buttonSave;
- (IBAction) buttonEdit;
- (IBAction) buttonCancel;

@end
