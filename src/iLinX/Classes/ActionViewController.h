//
//  ActionViewController.h
//  iLinX
//
//  Created by mcf on 10/06/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CustomSlider;
@class NLRoomList;
@class NLTimer;

@interface ActionViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate,
                                                    UITableViewDataSource, UITableViewDelegate>
{
@private
  NLRoomList *_roomList;
  NLTimer *_timer;
  NSUInteger _timerType;
  UIView *_backdrop;
  UITableView *_optionsTable;
  UIPickerView *_parameterPicker;
  CustomSlider *_volumeSlider;
  CGFloat _maxTitleWidth;
  NSMutableArray *_rooms;
  NSMutableArray *_sources;
  NSMutableArray *_macros;
  NSMutableArray *_roomSpecificMacros;
  BOOL _showMacroRoomPicker;
}

- (id) initWithRoomList: (NLRoomList *) roomList timer: (NLTimer *) timer;

@end
