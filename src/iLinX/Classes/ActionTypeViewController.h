//
//  ActionTypeViewController.h
//  iLinX
//
//  Created by mcf on 10/06/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TintedTableViewController.h"

@class NLRoomList;
@class NLTimer;

@interface ActionTypeViewController : TintedTableViewController 
{
@private
  NLTimer *_timer;
  NLRoomList *_roomList;
  NSUInteger _cmdFormat;
  NSUInteger _originalCmdFormat;
  NSUInteger _macroCount;
  NSInteger _selectedRow;
}

- (id) initWithRoomList: (NLRoomList *) roomList timer: (NLTimer *) timer macroCount: (NSUInteger) macroCount;

@end
