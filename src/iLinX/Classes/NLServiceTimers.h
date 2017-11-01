//
//  NLServiceTimers.h
//  iLinX
//
//  Created by mcf on 22/05/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ListDataSource.h"
#import "NetStreamsComms.h"
#import "NLService.h"

#define SERVICE_TIMERS_TIMERS_LIST_CHANGED      0x0001
#define SERVICE_TIMERS_DATE_CHANGED             0x0002
#define SERVICE_TIMERS_TIME_ZONE_OFFSET_CHANGED 0x0004
#define SERVICE_TIMERS_DST_TIME_ZONE_CHANGED    0x0008
#define SERVICE_TIMERS_NEXT_DST_CHANGE_CHANGED  0x0010
#define SERVICE_TIMERS_IN_DST_CHANGED           0x0020
#define SERVICE_TIMERS_LICENCE_CHANGED          0x0040
#define SERVICE_TIMERS_IS_LICENSED_CHANGED      0x0080

@class NLServiceTimers;
@class NLServiceTimersCheckService;
@class NLTimer;
@class NLTimerList;

@protocol NLServiceTimersDelegate <NSObject>
- (void) service: (NLServiceTimers *) service changed: (NSUInteger) changed;
@end


@interface NLServiceTimers : NLService <NetStreamsMsgDelegate, ListDataDelegate>
{
@private
  NLTimerList *_timers;
  NSMutableSet *_delegates;
  id _statusRspHandle;
  id _registerMsgHandle;
  NSDate *_date;
  NSInteger _timeZoneOffset;
  NSTimeZone *_dstTimeZone;
  NSDate *_nextDstChange;
  BOOL _inDst;
  NSString *_timersListDataStamp;
  NSString *_licence;
  NLServiceTimersCheckService *_licenceChecker;
  BOOL _isLicensed;
  BOOL _licenceChecked;
}

@property (readonly) NLTimerList *timers;
@property (readonly) NSDate *date;
@property (readonly) NSInteger timeZoneOffset;
@property (readonly) NSTimeZone *dstTimeZone;
@property (readonly) NSDate *nextDstChange;
@property (readonly) BOOL inDst;
@property (readonly) NSString *timersListDataStamp;
@property (readonly) NSString *licence;
@property (readonly) BOOL isLicensed;
@property (readonly) BOOL licenceChecked;

- (void) setDate: (NSDate *) date inTimeZone: (NSTimeZone *) zone;
- (void) setDaylightSavingZone: (NSTimeZone *) zone;
- (void) setTimer: (NLTimer *) timer;
- (void) deleteTimer: (NLTimer *) timer;
- (void) deleteAllTimers;

- (void) addDelegate: (id<NLServiceTimersDelegate>) delegate;
- (void) removeDelegate: (id<NLServiceTimersDelegate>) delegate;

@end
