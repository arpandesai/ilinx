//
//  NLTimerList.h
//  iLinX
//
//  Created by mcf on 27/05/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLListDataSource.h"
#import "NetStreamsComms.h"

@class NLServiceTimers;

@interface NLTimerList : NLListDataSource <NetStreamsMsgDelegate>
{
@private
  NetStreamsComms *_comms;
  NLServiceTimers *_timersService;
  NSMutableArray *_timers;
  BOOL _doRefreshWhenReady;
  id _menuMsgHandle;
  id _menuRspHandle;
  NSUInteger _count;
  NSString *_filter;
}

- (id) initWithTimersService: (NLServiceTimers *) timersService comms: (NetStreamsComms *) comms;
- (void) filterByListOfRooms: (NSArray *) listOfRooms;
- (void) deleteTimerAtIndex: (NSUInteger) index;

@end
