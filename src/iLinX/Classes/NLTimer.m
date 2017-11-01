//
//  NLTimer.m
//  iLinX
//
//  Created by mcf on 27/05/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "NLTimer.h"
#import "NLServiceTimers.h"
#import "GuiXmlParser.h"

static NSString *DAYS_STRING = @"MTWTFSS";

@interface NLTimer ()

- (NSString *) unbracketAndUnescapeString: (NSString *) string;
- (NSString *) bracketAndEscapeString: (NSString *) string;
- (NSMutableArray *) unbracketAndUnescapeArray: (NSString *) string;
- (NSString *) bracketAndEscapeArray: (NSArray *) array;

@end

@implementation NLTimer

@synthesize
  timersService = _timersService,
  permId = _permId,
  name = _name,
  cmdFormat = _cmdFormat,
  cmdParams = _cmdParams,
  timeFormat = _timeFormat,
  timeParams = _timeParams,
  enabled = _enabled;

+ (NSString *) rfc3339stringFromDate: (NSDate *) date inZone: (NSTimeZone *) zone
{
  NSCalendar *calendar = [NSCalendar currentCalendar];
  
  [calendar setTimeZone: zone];
  
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  NSDateComponents *comps = [calendar components: NSHourCalendarUnit fromDate: date];
  NSInteger timeZoneOffset = zone.secondsFromGMT / 60;
  NSString *dateString;
  
  [dateFormatter setDateFormat: [NSString stringWithFormat: @"yyyy-MM-dd'T%02u':mm:ss", [comps hour]]];
  [dateFormatter setTimeZone: zone];
  dateString = [dateFormatter stringFromDate: date];
  
  // Work round NSDateFormatter bug where the overall system 12/24 hour settings messes up
  // the formating and parsing of HH in time strings.  In 12 hour mode, it formats the times
  // in 12 hour format even if the format string is 24 hour format (and vice-versa).
  if (timeZoneOffset == 0)
    dateString = [dateString stringByAppendingString: @"Z"];
  else
  {
    if (timeZoneOffset > 0)
      dateString = [dateString stringByAppendingString: @"+"];
    else
    {
      timeZoneOffset = -timeZoneOffset;
      dateString = [dateString stringByAppendingString: @"-"];
    }
    dateString = [dateString stringByAppendingString:
                  [NSString stringWithFormat: @"%02d:%02d", timeZoneOffset / 60, timeZoneOffset % 60]];
  }
  
  [dateFormatter release];
  
  return dateString;
}

+ (NSDate *) dateFromRfc3339string: (NSString *) string
{
  NSDate *date;
  
  if ([string length] < 19)
    date = nil;
  else
  {
    NSInteger timeZoneOffset = [self timeZoneOffsetFromRfc3339string: string];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSRange dateRange = NSMakeRange( 0, 10 );
    NSError *problem;
    
    // Would like to parse this as yyyy-MM-dd'T'HH:mm:ss but bug in NSDateFormatter means that
    // it is unable to parse 24 hour time specifications when the system is set in 12 hour
    // mode (and vice versa).  So, parse the date, hours, minutes and seconds all separately
    // and then add them together.
    [dateFormatter setDateFormat: @"yyyy-MM-dd"];
    [dateFormatter setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: timeZoneOffset * 60]];
    if (![dateFormatter getObjectValue: &date forString: string range: &dateRange error: &problem])
      date = nil;
    else
    {
      NSInteger hours = [[string substringWithRange: NSMakeRange( 11, 2 )] integerValue];
      NSInteger minutes = [[string substringWithRange: NSMakeRange( 14, 2 )] integerValue]; 
      NSInteger seconds = [[string substringWithRange: NSMakeRange( 17, 2 )] integerValue];
      
      date = [date dateByAddingTimeInterval: seconds + (60 * (minutes + (60 * hours)))];
    }
    
    [dateFormatter release];
  }
  
  return date;
}

+ (NSInteger) timeZoneOffsetFromRfc3339string: (NSString *) string
{
  NSInteger timeZoneOffset;
  
  if ([string length] < 25)
    timeZoneOffset = 0;
  else
  {
    unichar offsetChar = [string characterAtIndex: 19];
    
    if (offsetChar != '+' && offsetChar != '-')
      timeZoneOffset = 0;
    else
    {
      NSInteger hours = [[string substringWithRange: NSMakeRange( 20, 2 )] integerValue];
      NSInteger minutes = [[string substringWithRange: NSMakeRange( 23, 2 )] integerValue];
      
      timeZoneOffset = (hours * 60) + minutes;
      if (offsetChar == '-')
        timeZoneOffset = -timeZoneOffset;
     }
  }
  
  return timeZoneOffset;
}

// Create a new uninitialised timer
- (id) initWithTimersService: (NLServiceTimers *) timersService
{
  if ((self = [super init]) != nil)
  {
    NSString *now = [NLTimer rfc3339stringFromDate: [NSDate date] inZone: [NSTimeZone localTimeZone]];
    
    _timersService = timersService;// retain
    _permId = [@"" retain];
    _name = [NSLocalizedString( @"Timer", @"Default timer name" ) retain];
    _cmdFormat = NLTIMER_CMD_FORMAT_MACRO;
    _cmdParams = [[NSMutableArray arrayWithObject: @""] retain];
    _timeFormat = NLTIMER_TIME_FORMAT_SINGLE_EVENT;
    _timeParams = [[NSMutableArray arrayWithObjects: [now substringToIndex: 10],
                    [now substringWithRange: NSMakeRange( 11, 5 )], nil] retain];
    _enabled = NO;
  }
  
  return self;
}

// Create a timer based on information returned from the timer service
- (id) initWithTimerData: (NSDictionary *) data timersService: (NLServiceTimers *) timersService
{
  if ((self = [super init]) != nil)
  {
    _timersService = timersService;// retain
    _permId = [[data objectForKey: @"id"] retain];
    _name = [[self unbracketAndUnescapeString: [data objectForKey: @"display"]] retain];
    _cmdFormat = [[data objectForKey: @"cmdformat"] integerValue];
    _cmdParams = [[self unbracketAndUnescapeArray: [data objectForKey: @"cmdparams"]] retain];
    _timeFormat = [[data objectForKey: @"timeformat"] integerValue];
    _timeParams = [[self unbracketAndUnescapeArray: [data objectForKey: @"timeparams"]] retain];
    _enabled = [[data objectForKey: @"enabled"] isEqualToString: @"1"];
  }
  
  return self;
}

- (id) initFromOtherTimer: (NLTimer *) timer
{
  if ((self = [super init]) != nil)
  {
    //[_timersService release];
    _timersService = timer->_timersService;// retain
    [_permId release];
    _permId = [timer->_permId retain];
    [_name release];
    _name = [timer->_name retain];
    _cmdFormat = timer->_cmdFormat;
    [_cmdParams release];
    _cmdParams = [timer->_cmdParams mutableCopy];
    _timeFormat = timer->_timeFormat;
    [_timeParams release];
    _timeParams = [timer->_timeParams mutableCopy];
    _enabled = timer->_enabled;
  }
  
  return self;
}

- (NSString *) macroName
{
  if (_cmdFormat != NLTIMER_CMD_FORMAT_MACRO || [_cmdParams count] < 1)
    return nil;
  else
    return [_cmdParams objectAtIndex: 0];
}

- (NSString *) macroRoomServiceName
{
  if (_cmdFormat != NLTIMER_CMD_FORMAT_MACRO || [_cmdParams count] < 2)
    return nil;
  else
    return [_cmdParams objectAtIndex: 1];
}

- (NSString *) macroRoomDisplayName
{
  if (_cmdFormat != NLTIMER_CMD_FORMAT_MACRO || [_cmdParams count] < 2)
    return nil;
  else
    return [GuiXmlParser stripSpecialAffixesFromString: [_cmdParams objectAtIndex: 1]];
}

- (NSString *) simpleAlarmRoomServiceName
{
  if (_cmdFormat != NLTIMER_CMD_FORMAT_SIMPLE_ALARM || [_cmdParams count] < 1)
    return nil;
  else
    return [_cmdParams objectAtIndex: 0];
}

- (NSString *) simpleAlarmRoomDisplayName
{
  if (_cmdFormat != NLTIMER_CMD_FORMAT_SIMPLE_ALARM || [_cmdParams count] < 1)
    return nil;
  else
    return [GuiXmlParser stripSpecialAffixesFromString: [_cmdParams objectAtIndex: 0]];
}

- (NSString *) simpleAlarmSourceServiceName
{
  if (_cmdFormat != NLTIMER_CMD_FORMAT_SIMPLE_ALARM || [_cmdParams count] < 2)
    return nil;
  else
    return [_cmdParams objectAtIndex: 1];
}

- (NSString *) simpleAlarmSourceDisplayName
{
  if (_cmdFormat != NLTIMER_CMD_FORMAT_SIMPLE_ALARM || [_cmdParams count] < 2)
    return nil;
  else
    return [GuiXmlParser stripSpecialAffixesFromString: [_cmdParams objectAtIndex: 1]];
}

- (NSUInteger) simpleAlarmVolume
{
  if (_cmdFormat != NLTIMER_CMD_FORMAT_SIMPLE_ALARM || [_cmdParams count] < 3)
    return 0;
  else
    return [[_cmdParams objectAtIndex: 2] integerValue];
}

- (void) setSimpleAlarmVolume: (NSUInteger) volume
{
  if (_cmdFormat == NLTIMER_CMD_FORMAT_SIMPLE_ALARM && [_cmdParams count] >= 3 && volume <= 100)
    [_cmdParams replaceObjectAtIndex: 2 withObject: [NSString stringWithFormat: @"%u", volume]];
}

- (NSUInteger) repeatedDayBitmask
{
  NSUInteger bitmask = 0;

  if (_timeFormat == NLTIMER_TIME_FORMAT_WEEKLY_REPEAT && [_timeParams count] > 0)
  {
    NSString *param = [_timeParams objectAtIndex: 0];
    NSUInteger limit = [param length];
    NSUInteger i;

    if (limit > 7)
      limit = 7;
    for (i = 0; i < limit; ++i)
    {
      if ([param characterAtIndex: i] != '_')
        bitmask |= (1<<i);
    }
  }
  
  return bitmask;
}

- (NSDate *) singleEventDate
{
  NSDate *date;

  if (_timeFormat != NLTIMER_TIME_FORMAT_SINGLE_EVENT || [_timeParams count] < 1)
    date = nil;
  else
  {
#if TIME_ZONES_REQUIRED
    NSInteger minutesFromGMT = ([NSTimeZone localTimeZone].secondsFromGMT / 60);

    date = [NLTimer dateFromRfc3339string: [NSString stringWithFormat: @"%@T%@:00%c%02d:%02d",
                                            [_timeParams objectAtIndex: 0], [_timeParams objectAtIndex: 1],
                                            ((minutesFromGMT >= 0) ? '+' : '-'),
                                            minutesFromGMT / 60, minutesFromGMT % 60]];
#else
    date = [NLTimer dateFromRfc3339string: [NSString stringWithFormat: @"%@T12:00:00Z", [_timeParams objectAtIndex: 0]]];
#endif
  }

  return date;
}

- (NSUInteger) eventTime
{
  NSUInteger time;

  if ([_timeParams count] < 2)
    time = 0;
  else
  {
    switch (_timeFormat)
    {
      case NLTIMER_TIME_FORMAT_SINGLE_EVENT:
      case NLTIMER_TIME_FORMAT_WEEKLY_REPEAT:
      {
        NSString *timeString = [_timeParams objectAtIndex: 1];
        
        if ([timeString length] < 5)
          time = 0;
        else
        {
          time = ([[timeString substringToIndex: 2] integerValue] * 60) +
            [[timeString substringFromIndex: 3] integerValue];
        }
        break;
      }
      default:
      {
        time = 0;
        break;
      }
    }
  }
   
  return time;
}

- (NSString *) menuUpdateString
{
  NSString *permId = _permId;
  
  if (permId == nil || [permId length] == 0)
    permId = @" ";

  return [NSString stringWithFormat: @"{{%@}},%@,%u,%@,%u,%@,%u",
          permId, [self bracketAndEscapeString: _name],
          _cmdFormat, [self bracketAndEscapeArray: _cmdParams],
          _timeFormat, [self bracketAndEscapeArray: _timeParams],
          _enabled ? 1 : 0];
}

- (void) setTimedMacro: (NSString *) macro room: (NSString *) room
{
  _cmdFormat = NLTIMER_CMD_FORMAT_MACRO;
  [_cmdParams release];
  if (room == nil)
    room = @"";
  _cmdParams = [[NSMutableArray arrayWithObjects: macro, room, nil] retain];
}

- (void) setSimpleAlarmForRoom: (NSString *) room source: (NSString *) source volume: (NSUInteger) volume
{
  _cmdFormat = NLTIMER_CMD_FORMAT_SIMPLE_ALARM;
  [_cmdParams release];
  _cmdParams = [[NSMutableArray arrayWithObjects: room, source, [NSString stringWithFormat: @"%u", volume], nil] retain];
}

- (void) setSingleEventOnDate: (NSDate *) date atTime: (NSUInteger) time
{
#if TIME_ZONES_REQUIRED
  NSString *dateString = [NLTimer rfc3339stringFromDate: date inZone: [NSTimeZone localTimeZone]];
#else
  //NSString *dateString = [NLTimer rfc3339stringFromDate: date inZone: [NSTimeZone timeZoneForSecondsFromGMT: 0]];
  NSString *dateString = [NLTimer rfc3339stringFromDate: date inZone: [NSTimeZone localTimeZone]];
#endif
  
  dateString = [dateString substringToIndex: 10];
  _timeFormat = NLTIMER_TIME_FORMAT_SINGLE_EVENT;
  [_timeParams release];
  _timeParams = [[NSMutableArray arrayWithObjects: dateString, [NSString stringWithFormat: @"%02u:%02u",
                                                                (time / 60) % 60, time % 60], nil] retain];
}

- (void) setRepeatedEventOnDays: (NSUInteger) daysMask atTime: (NSUInteger) time
{
  NSString *daysString = DAYS_STRING;
  NSUInteger i;
  
  for (i = 0; i < 7; ++i)
  {
    if ((daysMask & (1<<i)) == 0)
      daysString = [daysString stringByReplacingCharactersInRange: NSMakeRange( i, 1 ) withString: @"_"];
  }
  
  _timeFormat = NLTIMER_TIME_FORMAT_WEEKLY_REPEAT;
  [_timeParams release];
  _timeParams = [[NSMutableArray arrayWithObjects: daysString, [NSString stringWithFormat: @"%02u:%02u",
                                                                (time / 60) % 60, time % 60], nil] retain];
}

- (void) commitChanges
{
  [_timersService setTimer: self];
}

- (id) copyWithZone: (NSZone *) zone
{
  return [self mutableCopyWithZone: zone];
}

- (id) mutableCopyWithZone: (NSZone *) zone
{
  return [[NLTimer allocWithZone: zone] initFromOtherTimer: self];
}

- (NSString *) unbracketAndUnescapeString: (NSString *) string
{
  NSString *returnString;

  if ([string hasPrefix: @"{{"] && [string hasSuffix: @"}}"])
    string = [string substringWithRange: NSMakeRange( 2, [string length] - 4 )];
  
  returnString = [string stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
  if (returnString == nil)
    returnString = string;
  
  return returnString;
}

- (NSString *) bracketAndEscapeString: (NSString *) string
{
  string = [NSString stringWithFormat: @"{{%@}}", [string stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
  
  return [string stringByReplacingOccurrencesOfString: @"," withString: @"%2C"];
}

- (NSMutableArray *) unbracketAndUnescapeArray: (NSString *) string
{
  NSMutableArray *array = [[[string componentsSeparatedByString: @","] mutableCopy] autorelease];
  NSUInteger count = [array count];
  NSUInteger i;
  
  for (i = 0; i < count; ++i)
  {
    NSString *replacement = [[array objectAtIndex: i] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
  
    if (replacement == nil)
      replacement = [array objectAtIndex: i];
    replacement = [replacement stringByReplacingOccurrencesOfString: @"," withString: @"%2C"];
    
    if (replacement != nil)
      [array replaceObjectAtIndex: i withObject: replacement];
  }
  
  return array;
}

- (NSString *) bracketAndEscapeArray: (NSArray *) array
{
  NSString *returnString = @"";
  
  for (NSString *item in array)
  {
    returnString = [returnString stringByAppendingFormat: @"%@,", 
                    [item stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
  }
  
  if ([returnString length] > 0)
    returnString = [returnString substringToIndex: [returnString length] - 1];
  
  return [NSString stringWithFormat: @"{{%@}}", returnString];
}

- (void) dealloc
{
  //[_timersService release];
  [_permId release];
  [_name release];
  [_cmdParams release];
  [_timeParams release];
  [super dealloc];
}

@end
