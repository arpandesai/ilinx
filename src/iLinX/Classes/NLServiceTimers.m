//
//  NLServiceTimers.m
//  iLinX
//
//  Created by mcf on 22/05/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "NLServiceTimers.h"
#import "NLTimer.h"
#import "NLTimerList.h"
#import "LicenceString.h"
#import "WeakReference.h"

#define _pcomms NETSTREAMSCOMMS_PRODUCTION_ONLY(_comms)

// How often, in seconds, to send the report registration request to ensure
// that it does not expire
#define REGISTRATION_RENEWAL_INTERVAL 30

// How long we are prepared to wait for a valid licence response
#define LICENCE_SERVICE_TIMEOUT 60

// How often we check within that period
#define LICENCE_CHECK_REPEAT_INTERVAL 5

// Record of the timer services that we have checked to see that their time data is
// correct and that they are licensed.
static NSMutableDictionary *g_checkedServices = nil;

@class NLServiceTimersCheckServiceProxy;

@interface NLServiceTimers ()

- (void) registerForNetStreams;
- (void) deregisterFromNetStreams;
- (void) setIsLicensed: (BOOL) isLicensed;
- (void) notifyDelegates: (NSUInteger) changed;

@end

// Small local class to perform a one-off check on the timer service to ensure that its settings are correct
@interface NLServiceTimersCheckService : NSDebugObject <NLServiceTimersDelegate, NetStreamsMsgDelegate>
{
@private
  NLServiceTimers *_primaryService;
  NLServiceTimersCheckServiceProxy *_proxy;
  NSMutableSet *_timers;
  NetStreamsComms *_comms;
  id _licenceCheckHandle;
  id _responseHandle;
  NSTimer *_licenceCheckTimeout;
  NSString *_controllerRoot;
  BOOL _isLicensed;
}

@property (readonly) BOOL initCompleted;
@property (readonly) BOOL isLicensed;

- (id) initWithTimersService: (NLServiceTimers *) timersService comms: (NetStreamsComms *) comms;
- (void) addTimersService: (NLServiceTimers *) timersService;
- (void) checkLicence: (NSString *) licence;
- (void) licenceTimeoutExpired: (NSTimer *) timer;
- (void) reportLicenceResult: (BOOL) isLicensed;
- (void) cleanup;

@end

// Minimal class to allow NLServiceTimersCheckService object to register as a delegate of
// an NLServiceTimers object without that object then retaining a reference to it (thus
// setting up a circular dependency)
@interface NLServiceTimersCheckServiceProxy : NSDebugObject <NLServiceTimersDelegate>
{
@private
  WeakReference *_checkService;
}

- (id) initWithChecker: (NLServiceTimersCheckService *) checker;

@end

@implementation NLServiceTimersCheckServiceProxy

- (id) initWithChecker: (NLServiceTimersCheckService *) checker
{
  if ((self = [super init]) != nil)
    _checkService = [[WeakReference weakReferenceForObject: checker] retain];
  
  return self;
}

- (void) service: (NLServiceTimers *) service changed: (NSUInteger) changed
{
  [(NLServiceTimersCheckService *) [_checkService referencedObject] service: service changed: changed];
}

- (void) timerFired: (NSTimer *) timer
{
  [(NLServiceTimersCheckService *) [_checkService referencedObject] licenceTimeoutExpired: timer];
}

- (void) dealloc
{
  [_checkService release];
  [super dealloc];
}

@end

@implementation NLServiceTimersCheckService

@synthesize isLicensed = _isLicensed;

- (BOOL) initCompleted
{
  return (_timers == nil);
}

- (id) initWithTimersService: (NLServiceTimers *) timersService comms: (NetStreamsComms *) comms
{
  if ((self = [super init]) != nil)
  {
    _comms = [comms retain];
    _primaryService = timersService;
    _proxy = [[NLServiceTimersCheckServiceProxy alloc] initWithChecker: self];
    _timers = [[NSMutableSet setWithObject: [WeakReference weakReferenceForObject: timersService]] retain];
    [timersService addDelegate: _proxy];
  }

  return self;
}

- (void) addTimersService: (NLServiceTimers *) timersService
{
  [_timers addObject: [WeakReference weakReferenceForObject: timersService]];
}

- (void) removeTimersService: (NLServiceTimers *) timersService
{
  [_timers removeObject: [WeakReference weakReferenceForObject: timersService]];
  if (timersService == _primaryService)
  {
    [_primaryService removeDelegate: _proxy];
    [_proxy release];
    _proxy = nil;
    _primaryService = nil;
  }
}

- (void) checkLicence: (NSString *) licence
{
  _controllerRoot = [[licence decodeAsiLinXLicenceString] retain];
  
  if (_controllerRoot == nil)
    [self reportLicenceResult: NO];
}

- (void) licenceTimeoutExpired: (NSTimer *) timer
{
  [_licenceCheckTimeout release];
  _licenceCheckTimeout = nil;
  [self reportLicenceResult: NO];
}

- (void) cleanup
{
  if (_comms != nil)
  {
    if (_licenceCheckHandle != nil)
    {
      [_comms cancelSendEvery: _licenceCheckHandle];
      _licenceCheckHandle = nil;
    }
    if (_responseHandle != nil)
    {
      [_comms deregisterDelegate: _responseHandle];
      _responseHandle = nil;
    }
    [_comms release];
    _comms = nil;
  }

  if (_controllerRoot != nil)
  {
    [_controllerRoot release];
    _controllerRoot = nil;
  }

  if (_primaryService != nil)
  {
    [_primaryService removeDelegate: _proxy];
    [_proxy release];
    _proxy = nil;
    _primaryService = nil;
  }

  [_timers release];
  _timers = nil;
  [_licenceCheckTimeout invalidate];
  [_licenceCheckTimeout release];
  _licenceCheckTimeout = nil;
}

- (void) reportLicenceResult: (BOOL) isLicensed
{
  _isLicensed = isLicensed;
  if ([_timers count] > 0)
  {
    // Take a copy of _timers because it can be set to nil if isLicensed is NO.
    // That then mucks up the iterator and crashes.
    NSSet *timersCopy = [NSSet setWithSet: _timers];
    
    for (WeakReference *service in timersCopy)
      [(NLServiceTimers *) [service referencedObject] setIsLicensed: isLicensed];
  }
  [self cleanup];
}

- (void) service: (NLServiceTimers *) service changed: (NSUInteger) changed
{
  if (_licenceCheckTimeout == nil)
    _licenceCheckTimeout =
    [[NSTimer scheduledTimerWithTimeInterval: LICENCE_SERVICE_TIMEOUT
                                     target: _proxy selector: @selector(timerFired:)
                                   userInfo: nil repeats: NO] retain];
  
  if (_responseHandle == nil)
    [self checkLicence: service.licence];
  
  if (_controllerRoot != nil && _responseHandle == nil)
  {
    NSTimeZone *here = [NSTimeZone localTimeZone];
    
    [service setDate: [NSDate date] inTimeZone: here];
    [service setDaylightSavingZone: here];
    _responseHandle = [_comms registerDelegate: self forMessage: @"REPORT" from: _controllerRoot];
    _licenceCheckHandle = [_comms send: @"QUERY SERVICE" to: _controllerRoot every: LICENCE_CHECK_REPEAT_INTERVAL];
  }
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  BOOL foundTimers = NO;
  BOOL foundRoot = NO;
  NSString *timersServiceName = _primaryService.serviceName;
  NSString *serviceName;
  
  for (serviceName in [data allValues])
  {
    if ([serviceName compare: timersServiceName options: NSCaseInsensitiveSearch] == NSOrderedSame)
      foundTimers = YES;
    else if ([serviceName isEqualToString: _controllerRoot])
      foundRoot = YES;
    if (foundTimers && foundRoot)
    {
      [self reportLicenceResult: YES];
      break;
    }
  }
}

- (void) dealloc
{
  [self cleanup];
  for (NSString *key in [g_checkedServices allKeysForObject: [WeakReference weakReferenceForObject: self]])
    [g_checkedServices removeObjectForKey: key];
  [super dealloc];
}

@end

@implementation NLServiceTimers

@synthesize 
  timers = _timers,
  date = _date,
  timeZoneOffset = _timeZoneOffset,
  dstTimeZone = _dstTimeZone,
  nextDstChange = _nextDstChange,
  inDst = _inDst,
  timersListDataStamp = _timersListDataStamp,
  licence = _licence,
  isLicensed = _isLicensed,
  licenceChecked = _licenceChecked;

- (id) initWithServiceData: (NSDictionary *) serviceData room: (NLRoom *) room comms: (NetStreamsComms *) comms
{
  if ((self = [super initWithServiceData: serviceData room: room comms: comms]) != nil)
  {
    _delegates = [NSMutableSet new];
    _timers = [[NLTimerList alloc] initWithTimersService: self comms: _comms];
    if (g_checkedServices == nil)
      g_checkedServices = [NSMutableDictionary new];
    
    _licenceChecker = [[[g_checkedServices objectForKey: self.serviceName] referencedObject] retain];
    if (_licenceChecker == nil)
    {
      _licenceChecker = [[NLServiceTimersCheckService alloc] initWithTimersService: self comms: _comms];      
      [g_checkedServices setObject: [WeakReference weakReferenceForObject: _licenceChecker] forKey: self.serviceName];
    }
    else if ([_licenceChecker initCompleted])
    {
      _isLicensed = _licenceChecker.isLicensed;
      _licenceChecked = YES;
    }
    else
      [_licenceChecker addTimersService: self];
  }
  
  return self;
}

- (void) setDate: (NSDate *) date inTimeZone: (NSTimeZone *) zone
{
  NSString *dateString = @"SET DATETIME ";
  
  dateString = [dateString stringByAppendingString: [NLTimer rfc3339stringFromDate: date inZone: zone]];
  [_comms send: dateString to: self.serviceName];
}

- (void) setDaylightSavingZone: (NSTimeZone *) zone
{
  NSInteger dstOffset = (NSInteger) (zone.daylightSavingTimeOffset / 60);
  NSDate *nextDstChange = zone.nextDaylightSavingTimeTransition;
  NSInteger nextDstOffset = (NSInteger) ([zone daylightSavingTimeOffsetForDate: [nextDstChange dateByAddingTimeInterval: 3600]] / 60);
  BOOL dstOffsetNegative = (dstOffset < 0);
  BOOL nextDstOffsetNegative = (nextDstOffset < 0);

  if (dstOffsetNegative)
    dstOffset = -dstOffset;
  if (nextDstOffsetNegative)
    nextDstOffset = -nextDstOffset;

  [_comms send: [NSString stringWithFormat: @"SET DST {{%@}},%c%02d:%02d,%@,%c%02d:%02d",
                 zone.name,
                 (dstOffsetNegative ? '-' : '+'), dstOffset / 60, dstOffset % 60,
                 [NLTimer rfc3339stringFromDate: nextDstChange inZone: zone],
                 (nextDstOffsetNegative ? '-' : '+'), nextDstOffset / 60, nextDstOffset % 60]
            to: self.serviceName];
}

- (void) setTimer: (NLTimer *) timer
{
  [_pcomms send: [NSString stringWithFormat: @"MENU_UPDATE {{timers}},%@", [timer menuUpdateString]] to: self.serviceName];
}

- (void) deleteTimer: (NLTimer *) timer
{
  [_pcomms send: [NSString stringWithFormat: @"MENU_DELETE {{timers}},%@", timer.permId] to: self.serviceName];
}

- (void) deleteAllTimers
{
  [_pcomms send: @"MENU_DELETE {{timers}},ALL" to: self.serviceName];
}

- (void) addDelegate: (id<NLServiceTimersDelegate>) delegate
{
  if ([_delegates count] == 0)
    [self registerForNetStreams];
  
  [_delegates addObject: delegate];
}

- (void) removeDelegate: (id<NLServiceTimersDelegate>) delegate
{
  NSUInteger oldCount = [_delegates count];
  
  if (oldCount > 0)
  {
    [_delegates removeObject: delegate];
    if ([_delegates count] == 0)
      [self deregisterFromNetStreams];
  }  
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  NSString *type = [data objectForKey: @"type"];
  
  if ([type isEqualToString: @"state"])
  {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSString *dateString = [data objectForKey: @"date"];
    NSString *timeString = [data objectForKey: @"time"];
    NSString *timeZoneString = [data objectForKey: @"timezone"];
    NSString *dstString = [data objectForKey: @"dst"];
    NSString *dstZoneString = [data objectForKey: @"dstzone"];
    NSString *dstChangeString = [data objectForKey: @"dstchange"];
    NSString *dataStamp = [data objectForKey: @"datastamp"];
    NSString *licence = [data objectForKey: @"license"];
    NSString *dateFormat = @"";
    NSString *dateTimeString = @"";
    NSUInteger changed = 0;

    if (_date != nil)
      [dateFormatter setDefaultDate: _date];
    
    if (dateString != nil && [dateString length] > 0)
    {
      dateFormat = @"yyyy-MM-dd";
      dateTimeString = dateString;
    }
    
    if (timeString != nil && [timeString length] > 0)
    {
      dateFormat = [dateFormat stringByAppendingString: @"HH:mm:ss"];
      dateTimeString = [dateTimeString stringByAppendingString: timeString];
    }
    
    if (timeZoneString != nil && [timeZoneString length] > 0)
    {
      NSInteger newTimeZoneOffset;

      dateFormat = [dateFormat stringByAppendingString: @"ZZZZ"];
      if ([timeZoneString isEqualToString: @"Z"])
      {
        dateTimeString = [dateTimeString stringByAppendingString: @"GMT+00:00"];
        newTimeZoneOffset = 0;
      }
      else
      {
        dateTimeString = [NSString stringWithFormat: @"%@GMT%@", dateTimeString, timeZoneString];
        newTimeZoneOffset = [NLTimer timeZoneOffsetFromRfc3339string: [NSString stringWithFormat: @"0001-01-01T00:00:00%@", timeZoneString]];
      }
      
      if (newTimeZoneOffset != _timeZoneOffset)
      {
        _timeZoneOffset = newTimeZoneOffset;
        changed |= SERVICE_TIMERS_TIME_ZONE_OFFSET_CHANGED;
      }
    }
    
    if ([dateFormat length] > 0)
    {
      NSDate *newDate;
      NSRange dateRange = NSMakeRange( 0, [dateTimeString length] );
      NSError *problem;

      [dateFormatter setDateFormat: dateFormat];
      if ([dateFormatter getObjectValue: &newDate forString: dateTimeString range: &dateRange error: &problem] &&
         (_date == nil || ![_date isEqualToDate: newDate]))
      {
        [_date release];
        _date = [newDate retain];
        changed |= SERVICE_TIMERS_DATE_CHANGED;
      }
    }
    
    if (dstString != nil && [dstString length] > 0)
    {
      BOOL newDST = [dstString isEqualToString: @"1"];
      
      if (newDST != _inDst)
      {
        _inDst = newDST;
        changed |= SERVICE_TIMERS_IN_DST_CHANGED;
      }
    }
    
    if (dstZoneString != nil && [dstZoneString length] > 0)
    {
      if (_dstTimeZone == nil || ![_dstTimeZone.name isEqualToString: dstZoneString])
      {
        NSTimeZone *newDstTimeZone = [NSTimeZone timeZoneWithName: dstZoneString];
        
        if (newDstTimeZone != nil)
        {
          [_dstTimeZone release];
          _dstTimeZone = [newDstTimeZone retain];
          changed |= SERVICE_TIMERS_DST_TIME_ZONE_CHANGED;
        }
      }
    }
    
    if (dstChangeString != nil && [dstChangeString length] > 0)
    {
      NSDate *newDstChangeDate = [NLTimer dateFromRfc3339string: dstChangeString];
      
      if (newDstChangeDate != nil && (_nextDstChange == nil || ![_nextDstChange isEqualToDate: newDstChangeDate]))
      {
        [_nextDstChange release];
        _nextDstChange = [newDstChangeDate retain];
        changed |= SERVICE_TIMERS_NEXT_DST_CHANGE_CHANGED;
      }
    }
    
    if (dataStamp != nil && [dataStamp length] > 0 && 
      (_timersListDataStamp == nil || ![_timersListDataStamp isEqualToString: dataStamp]))
    {
      [_timersListDataStamp release];
      _timersListDataStamp = [dataStamp retain];
      [_timers refresh];
      changed |= SERVICE_TIMERS_TIMERS_LIST_CHANGED;
    }
    
    if (licence != nil && [licence length] > 0 && 
        (_licence == nil || ![_licence isEqualToString: licence]))
    {
      [_licence release];
      _licence = [licence retain];
      changed |= SERVICE_TIMERS_LICENCE_CHANGED;
    }
    
    if (changed != 0)
      [self notifyDelegates: changed];
    
    [dateFormatter release];
  }
}

- (void) registerForNetStreams
{  
  //NSLog( @"Register" );
  _statusRspHandle = [_comms registerDelegate: self forMessage: @"REPORT" from: self.serviceName];
  _registerMsgHandle = [_comms send: [NSString stringWithFormat: @"REGISTER ON,{{%@}}", self.serviceName] to: nil
                              every: REGISTRATION_RENEWAL_INTERVAL];
}

- (void) deregisterFromNetStreams
{
  //NSLog( @"Deregister" );
  if (_statusRspHandle != nil)
  {
    [_comms deregisterDelegate: _statusRspHandle];
    _statusRspHandle = nil;
  }
  //NSLog( @"Cancel send every" );
  if (_registerMsgHandle != nil)
  {
    [_comms cancelSendEvery: _registerMsgHandle];
    [_comms send: [NSString stringWithFormat: @"REGISTER OFF,{{%@}}", self.serviceName] to: nil];
    _registerMsgHandle = nil;
  }
}

- (void) setIsLicensed: (BOOL) isLicensed
{
  if (!_licenceChecked || _isLicensed != isLicensed)
  {
    _licenceChecked = YES;
    _isLicensed = isLicensed;
    [self notifyDelegates: SERVICE_TIMERS_IS_LICENSED_CHANGED];
  }
}

- (void) notifyDelegates: (NSUInteger) changed
{
  NSSet *fixedDelegates = [NSSet setWithSet: _delegates];
  NSEnumerator *enumerator = [fixedDelegates objectEnumerator];
  id<NLServiceTimersDelegate> delegate;
  
  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(service:changed:)])
      [delegate service: self changed: changed];
  }
}

- (void) dealloc
{
  [self deregisterFromNetStreams];
  [_licenceChecker removeTimersService: self];
  [_licenceChecker release];
  [_delegates release];
  [_timers release];
  [_date release];
  [_dstTimeZone release];
  [_nextDstChange release];
  [_timersListDataStamp release];
  [_licence release];
  [super dealloc];
}

@end
