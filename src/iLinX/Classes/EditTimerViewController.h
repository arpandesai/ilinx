//
//  EditTimerViewController.h
//  iLinX
//
//  Created by mcf on 22/05/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NLRoomList;
@class NLServiceTimers;
@class NLTimer;

@interface EditTimerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
  NLRoomList *_roomList;
  NLTimer *_timer;
  NLTimer *_oldTimer;
  UIView *_backdrop;
  UITableView *_optionsTable;
  UIDatePicker *_dateTimePicker;
  CGFloat _maxTitleWidth;
}

- (id) initWithRoomList: (NLRoomList *) roomList timer: (NLTimer *) timer;

@end
