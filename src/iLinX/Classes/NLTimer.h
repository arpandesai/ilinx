//
//  NLTimer.h
//  iLinX
//
//  Created by mcf on 27/05/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NLTIMER_CMD_FORMAT_SIMPLE_ALARM   0
#define NLTIMER_CMD_FORMAT_MACRO          1
#define NLTIMER_CMD_FORMAT_MAX            1

#define NLTIMER_TIME_FORMAT_SINGLE_EVENT  0
#define NLTIMER_TIME_FORMAT_WEEKLY_REPEAT 1
#define NLTIMER_TIME_FORMAT_MAX           1

#define NLTIMER_WEEKLY_REPEAT_MON         0x0001
#define NLTIMER_WEEKLY_REPEAT_TUE         0x0002
#define NLTIMER_WEEKLY_REPEAT_WED         0x0004
#define NLTIMER_WEEKLY_REPEAT_THU         0x0008
#define NLTIMER_WEEKLY_REPEAT_FRI         0x0010
#define NLTIMER_WEEKLY_REPEAT_SAT         0x0020
#define NLTIMER_WEEKLY_REPEAT_SUN         0x0040
#define NLTIMER_WEEKLY_REPEAT_EVERY_DAY   0x007F

@class NLServiceTimers;

@interface NLTimer : NSObject <NSCopying, NSMutableCopying>
{
@private
  NLServiceTimers *_timersService;
  NSString *_permId;
  NSString *_name;
  NSUInteger _cmdFormat;
  NSMutableArray *_cmdParams;
  NSUInteger _timeFormat;
  NSMutableArray *_timeParams;
  BOOL _enabled;
}

@property (readonly) NLServiceTimers *timersService;
@property (readonly) NSString *permId;
@property (nonatomic, retain) NSString *name;
@property (readonly) NSUInteger cmdFormat;
@property (readonly) NSMutableArray *cmdParams;
@property (readonly) NSString *macroName;
@property (readonly) NSString *macroRoomServiceName;
@property (readonly) NSString *macroRoomDisplayName;
@property (readonly) NSString *simpleAlarmRoomServiceName;
@property (readonly) NSString *simpleAlarmRoomDisplayName;
@property (readonly) NSString *simpleAlarmSourceServiceName;
@property (readonly) NSString *simpleAlarmSourceDisplayName;
@property (assign) NSUInteger simpleAlarmVolume;
@property (readonly) NSUInteger timeFormat;
@property (readonly) NSMutableArray *timeParams;
@property (readonly) NSUInteger repeatedDayBitmask;
@property (readonly) NSDate *singleEventDate;
@property (readonly) NSUInteger eventTime; // In minutes from midnight.
@property (assign) BOOL enabled;
@property (readonly) NSString *menuUpdateString;

+ (NSString *) rfc3339stringFromDate: (NSDate *) date inZone: (NSTimeZone *) zone;
+ (NSDate *) dateFromRfc3339string: (NSString *) string;
+ (NSInteger) timeZoneOffsetFromRfc3339string: (NSString *) string;

- (id) initWithTimersService: (NLServiceTimers *) timersService;
- (id) initWithTimerData: (NSDictionary *) data timersService: (NLServiceTimers *) timersService;
- (id) initFromOtherTimer: (NLTimer *) timer;

- (void) setTimedMacro: (NSString *) macro room: (NSString *) room;
- (void) setSimpleAlarmForRoom: (NSString *) room source: (NSString *) source volume: (NSUInteger) volume;
- (void) setSingleEventOnDate: (NSDate *) date atTime: (NSUInteger) time;
- (void) setRepeatedEventOnDays: (NSUInteger) daysMask atTime: (NSUInteger) time;
- (void) commitChanges;

@end
