//
//  NLTimerList.m
//  iLinX
//
//  Created by mcf on 27/05/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "NLTimerList.h"
#import "NLTimer.h"
#import "NLServiceTimers.h"

// How many timers to fetch per list request
#define MENU_LIST_BLOCK_SIZE 8

// How often to retry fetching if a message response is not received (in seconds)
#define NO_COMMS_RETRY_INTERVAL 5

@interface NLTimerList ()

- (void) registerForNetStreams;
- (void) deregisterFromNetStreams;
- (void) notifyDelegatesOfChangedRange: (NSRange) range;
- (void) notifyDelegatesOfIsRefreshing: (BOOL) isRefreshing;

@end

@implementation NLTimerList

- (id) initWithTimersService: (NLServiceTimers *) timersService comms: (NetStreamsComms *) comms
{
  if (self = [super init])
  {
    _timersService = timersService;
    _timers = [NSMutableArray new];
    _comms = [comms retain];
    _filter = [@"" retain];
  }
  
  return self;
}

- (void) filterByListOfRooms: (NSArray *) listOfRooms
{
  NSUInteger i;
  
  if (_menuRspHandle == nil)
  {
    for (i = 0; i < _count; ) 
    {
      NLTimer *timer = [_timers objectAtIndex: i];
      
      if (timer.cmdFormat != NLTIMER_CMD_FORMAT_SIMPLE_ALARM ||
          [listOfRooms indexOfObject: timer.simpleAlarmRoomServiceName] == NSNotFound)
        ++i;
      else
      {
        [_timers removeObjectAtIndex: i];
        --_count;
      }
    }
  }
  
  [_filter release];
  if (listOfRooms == nil || [listOfRooms count] == 0)
    _filter = [@"" retain];
  else
  {
    _filter = [NSString stringWithFormat: @",{{%@",
               [[listOfRooms objectAtIndex: 0] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    for (i = 1; i < [listOfRooms count]; ++i)
      _filter = [_filter stringByAppendingFormat: @"|%@",
                 [[listOfRooms objectAtIndex: i] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    _filter = [_filter stringByAppendingString: @"}}"];
    [_filter retain];
  }
  
  [self refresh];
}

- (void) deleteTimerAtIndex: (NSUInteger) index
{
  if (index < [_timers count])
  {
    NLTimer *timer = [_timers objectAtIndex: index];
    
    [_timersService deleteTimer: timer];
    
    if (_menuRspHandle == nil)
    {
      [_timers removeObjectAtIndex: index];
      --_count;
      [self notifyDelegatesOfChangedRange: NSMakeRange( index, _count + 1 - index )];
    }

    [self refresh];
  }
}

- (NSString *) listTitle
{
  return NSLocalizedString( @"Timers", @"Title of list of timers" );
}

- (NSUInteger) countOfList
{
  return _count;
}


- (BOOL) canBeRefreshed
{
  return YES;
}

- (void) refresh
{
  if (_menuRspHandle == nil)
    [self registerForNetStreams];
  else
    _doRefreshWhenReady = YES;
}

- (id) itemAtIndex: (NSUInteger) index
{
  id item;

  if (index >= [_timers count])
    item = nil;
  else
  {
    item = [_timers objectAtIndex: index];
    if (item == [NSNull null])
      item = nil;
  }
  
  return item;
}

- (NSString *) titleForItemAtIndex: (NSUInteger) index
{
  NLTimer *timer = [self itemAtIndex: index];
  
  if (timer == nil)
    return @"";
  else
    return timer.name;
}

- (BOOL) itemIsSelectableAtIndex: (NSUInteger) index
{
  NLTimer *timer = [self itemAtIndex: index];

  return (timer != nil);
}

- (id<ListDataSource>) selectItemAtIndex: (NSUInteger) index executeAction: (BOOL) executeAction
{
  _currentIndex = index;

  // No child list, so return nil
  return nil;
}

- (void) addDelegate: (id<ListDataDelegate>) delegate
{
  NSUInteger oldCount = [_listDataDelegates count];
  
  [_listDataDelegates addObject: delegate];
  
  if ([_listDataDelegates count] != oldCount)
    [self registerForNetStreams];
}

- (void) removeDelegate: (id<ListDataDelegate>) delegate
{
  NSUInteger oldCount = [_listDataDelegates count];
  
  if (oldCount > 0)
  {
    [_listDataDelegates removeObject: delegate];
    
    if ([_listDataDelegates count] == 0)
      [self deregisterFromNetStreams];
  }  
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  NSInteger itemnum = [[data objectForKey: @"itemnum"] integerValue];
  
  if (itemnum < 0)
  {
    NSUInteger blockStart = (_count / MENU_LIST_BLOCK_SIZE) * MENU_LIST_BLOCK_SIZE;
    
    [self deregisterFromNetStreams];
    [self notifyDelegatesOfChangedRange: NSMakeRange( blockStart, _count - blockStart )];
    if (_doRefreshWhenReady)
    {
      _doRefreshWhenReady = NO;
      [self registerForNetStreams];
    }
    else
    {
      [self notifyDelegatesOfIsRefreshing: NO];
    }
  }
  else
  {
    NLTimer *newTimer = [[NLTimer alloc] initWithTimerData: data timersService: _timersService];
    NSInteger itemIndex = itemnum - 1;

    _count = [[data objectForKey: @"itemtotal"] integerValue];
    _currentIndex = _count;
    
    if (itemIndex < [_timers count])
      [_timers replaceObjectAtIndex: itemIndex withObject: newTimer];
    else
    {
      while (itemIndex > [_timers count])
        [_timers addObject: [NSNull null]];
      [_timers addObject: newTimer];
    }
    
    [newTimer release];

    if (itemnum % MENU_LIST_BLOCK_SIZE == 0)
    {
      [_comms cancelSendEvery: _menuMsgHandle];
      _menuMsgHandle = [_comms send:
                        [NSString stringWithFormat: @"MENU_LIST %u,%u,{{timers}}%@", 
                         itemnum + 1, itemnum + MENU_LIST_BLOCK_SIZE, _filter]
                                 to: _timersService.serviceName
                              every: NO_COMMS_RETRY_INTERVAL];
      [self notifyDelegatesOfChangedRange: NSMakeRange( itemnum - MENU_LIST_BLOCK_SIZE, MENU_LIST_BLOCK_SIZE )];
    }
  }
}

- (void) registerForNetStreams
{
  if (_menuMsgHandle == nil)
  {
    _menuRspHandle = [_comms registerDelegate: self forMessage: @"MENU_RESP" from: _timersService.serviceName];
    _menuMsgHandle = [_comms send:
                      [NSString stringWithFormat: @"MENU_LIST 1,%u,{{timers}}%@", MENU_LIST_BLOCK_SIZE, _filter]
                               to: _timersService.serviceName
                            every: NO_COMMS_RETRY_INTERVAL];
    [self notifyDelegatesOfIsRefreshing: YES];
  }
}

- (void) deregisterFromNetStreams
{
  if (_menuMsgHandle != nil)
  {
    [_comms cancelSendEvery: _menuMsgHandle];
    [_comms deregisterDelegate: _menuRspHandle];
    _menuMsgHandle = nil;
    _menuRspHandle = nil;
  }
}

- (void) notifyDelegatesOfChangedRange: (NSRange) range
{
  NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<ListDataDelegate> delegate;
  
  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(itemsChangedInListData:range:)])
      [delegate itemsChangedInListData: self range: range];
  }
}

- (void) notifyDelegatesOfIsRefreshing: (BOOL) isRefreshing
{
  NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<ListDataDelegate> delegate;
  
  while ((delegate = [enumerator nextObject]))
  {
    if (isRefreshing)
    {
      if ([delegate respondsToSelector: @selector(listDataRefreshDidStart:)])
        [delegate listDataRefreshDidStart: self];
    }
    else
    {
      if ([delegate respondsToSelector: @selector(listDataRefreshDidEnd:)])
        [delegate listDataRefreshDidEnd: self];
    }
  }
}

- (void) dealloc
{
  [self deregisterFromNetStreams];
  [_timers release];
  [_comms release];
  [_filter release];
  [super dealloc];
}

@end
