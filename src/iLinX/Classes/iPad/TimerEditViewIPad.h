//
//  TimerEditViewIPad.h
//  iLinX
//
//  Created by Tony Short on 06/10/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CustomSliderIPad;
@class NLRoom;
@class NLRoomList;
@class NLServiceTimers;
@class NLTimer;

@interface TimerEditViewIPad : UIView <UITextFieldDelegate, UITableViewDelegate, 
                                       UITableViewDataSource, UIAlertViewDelegate>
{
  NLRoomList *_roomList;
  NLRoom *_timerRoom;
  NLTimer *_originalTimer;
  NLTimer *_timer;
  NSMutableArray *_macros;
  NSMutableArray *_roomSpecificMacros;

  IBOutlet UITextField *_nameTextField;
  IBOutlet UISwitch *_enabledSwitch;
  IBOutlet UIButton *_timeButton;
  IBOutlet UIButton *_dateOrRepeatButton;
  IBOutlet UIButton *_actionButton;
  IBOutlet UIView   *_actionSettingsView;
  IBOutlet UIView   *_macroSettings;
  IBOutlet UIButton *_macroButton;
  IBOutlet UIView   *_macroRoomLabel;
  IBOutlet UIButton *_macroRoomButton;
  IBOutlet UIView   *_alarmSettings;
  IBOutlet UIButton *_alarmRoomButton;
  IBOutlet UIButton *_alarmSourceButton;
  IBOutlet CustomSliderIPad *_alarmVolumeSlider;
  IBOutlet UIView   *_sleepSettings;
  IBOutlet UIButton *_sleepRoomButton;
  IBOutlet UIViewController *_timeDatePickerController;
  IBOutlet UIDatePicker *_timeDatePicker;
  IBOutlet UITableViewController *_tableViewController;
  IBOutlet UITableView *_tableView;
  IBOutlet UITableViewCell *_templateCell;

  UIPopoverController *_currentPopover;
  NSInteger _currentPopoverId;
}

@property (nonatomic, assign) NLTimer *timer;

- (IBAction) enabledSwitchChanged: (UIControl *) control;
- (IBAction) buttonPressed: (UIControl *) control;
- (IBAction) timeDatePickerValueChanged;
- (IBAction) volumeValueChanged;

- (void) setRoomList: (NLRoomList *) roomList timersService: (NLServiceTimers *) timersService;
- (void) commitTimer;

@end
