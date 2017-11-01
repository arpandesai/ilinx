//
//  NSSourceList.m
//  iLinX
//
//  Created by mcf on 15/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLSourceList.h"
#import "NLRenderer.h"
#import "NLRoom.h"
#import "NLSource.h"
#import "JavaScriptSupport.h"

// Number of seconds between checks to see if our source list information is current
#define SOURCE_INFO_REFRESH_INTERVAL 5

// Number of seconds between checks on the current source
#define CURRENT_SOURCE_REFRESH_INTERVAL 30

// How many sources to fetch per list request
#define MENU_LIST_BLOCK_SIZE 8

static NSArray *g_MasterSources = nil;

static NSCharacterSet *HEX_CHARS = nil;

@interface NLSourceList ()

- (void) refreshListTimerFired: (NSTimer *) timer;

@end

@implementation NLSourceList

@synthesize
  sources = _sources,
  currentSource = _currentSource;

+ (NSArray *) masterSources
{
  return g_MasterSources;
}

+ (void) setMasterSources: (NSArray *) masterSources
{
  [g_MasterSources release];
  g_MasterSources = [masterSources retain];
}

- (id) initWithRoom: (NLRoom *) room comms: (NetStreamsComms *) comms
{
  if ((self = [super init]) != nil)
  {
    if (HEX_CHARS == nil)
      HEX_CHARS = [[NSCharacterSet characterSetWithCharactersInString: @"0123456789ABCDEF"] retain];

    self.sources = [NSMutableArray arrayWithCapacity: 10];
    _availableSources = [[NSSet setWithObject: [NLSource noSourceObject]] retain];
    _buildSources = [[NSMutableSet setWithObject: [NLSource noSourceObject]] retain];
    [_sources addObject: [NLSource noSourceObject]];
    _currentSource = [NLSource noSourceObject];
    _netStreamsComms = comms;
    _room = room;
  }
  
  return self;
}

- (void) addSource: (NLSource *) source
{
  [_sources addObject: source];
}

- (NSString *) listTitle
{
  return NSLocalizedString( @"Source", @"Title of list of services" );
}

- (NSUInteger) countOfList
{
  return [_sources count];
}

- (id) itemAtIndex: (NSUInteger) index
{
  if (index >= [_sources count])
    return nil;
  else
    return (NLSource *) [_sources objectAtIndex: index];
}

- (NSString *) titleForItemAtIndex: (NSUInteger) index
{
  NLSource *source = [self itemAtIndex: index];
  
  return source.displayName;
}

- (BOOL) itemIsSelectedAtIndex: (NSUInteger) index
{
  return ([_sources objectAtIndex: index] == _currentSource);
}

- (id<ListDataSource>) selectItemAtIndex: (NSUInteger) index executeAction: (BOOL) executeAction
{
  if ([self itemIsSelectableAtIndex: index])
  {
    NLSource *oldSource = _currentSource;
    NSString *serviceName;
    NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
    NSEnumerator *enumerator = [delegates objectEnumerator];
    id<ListDataDelegate> delegate;
    
    _currentSource = [_sources objectAtIndex: index];
    _currentIndex = index;
    serviceName = _currentSource.serviceName;
    
    if ([serviceName isEqualToString: [NLSource noSourceObject].serviceName])
    {
      [_netStreamsComms send: @"SRC_SEL \"\"" to: _room.renderer.serviceName];
      [_netStreamsComms send: @"ACTIVE OFF" to: _room.renderer.serviceName];
    }
    else
    {
      [_netStreamsComms send: [NSString stringWithFormat: @"SRC_SEL {{%@}}", serviceName] to: _room.renderer.serviceName];
      [_room.renderer ensureAmpOn];
    }
    
    if (oldSource != _currentSource)
    {
      oldSource.isCurrentSource = NO;
      _currentSource.isCurrentSource = YES;
      
      while ((delegate = [enumerator nextObject]))
      {
        if ([delegate respondsToSelector: @selector(currentItemForListData:changedFrom:to:at:)])
          [delegate currentItemForListData: self changedFrom: oldSource to: _currentSource at: index];
      }
    }
  }
  
  // No child list, so return nil
  return nil;
}

- (BOOL) itemIsSelectableAtIndex: (NSUInteger) index
{
#ifdef IGNORE_SOURCE_STATUS_REPORTS
  return (index < [_sources count]);
#else
  return (index < [_sources count] && [_availableSources containsObject: [_sources objectAtIndex: index]]);
#endif
}

// We're not acutally interested in the renderer details, just registering interest
// so that the REGISTER ON message gets sent and we get told of any changes to the 
// current source
- (void) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags
{
}

- (void) addDelegate: (id<ListDataDelegate>) delegate
{
  NSUInteger oldCount = [_listDataDelegates count];

  [self addSourceOnlyDelegate: delegate];
  
  if ([_listDataDelegates count] != oldCount && [delegate respondsToSelector: @selector(itemsInsertedInListData:range:)])
  {
    if (_listContentDelegateCount == 0)
    {
      _menuRspHandle = [_netStreamsComms registerDelegate: self forMessage: @"MENU_RESP" from: _room.renderer.serviceName];
      _menuMsgHandle = [_netStreamsComms send:
                        [NSString stringWithFormat: @"MENU_LIST 1,%u,SOURCES", MENU_LIST_BLOCK_SIZE]
                                           to: _room.renderer.serviceName
                                        every: SOURCE_INFO_REFRESH_INTERVAL];
#if defined(DEBUG)
      //**/NSLog( @"Register for sources 1: %@", _menuMsgHandle );
#endif
    }
    ++_listContentDelegateCount;
  }
}

- (void) removeDelegate: (id<ListDataDelegate>) delegate
{
  NSUInteger oldCount = [_listDataDelegates count];
  
  if (oldCount > 0)
  {
    [self removeSourceOnlyDelegate: delegate];
  
    if ([_listDataDelegates count] != oldCount && [delegate respondsToSelector: @selector(itemsInsertedInListData:range:)])
    {
      --_listContentDelegateCount;
      if (_listContentDelegateCount == 0)
      {
#if defined(DEBUG)
        //**/NSLog( @"Deregister for sources 1: %@", _menuMsgHandle );
#endif
        [_netStreamsComms cancelSendEvery: _menuMsgHandle];
        [_netStreamsComms deregisterDelegate: _menuRspHandle];
        _menuMsgHandle = nil;
        _menuRspHandle = nil;
        [_refreshListTimer invalidate];
        _refreshListTimer = nil;
        if (_addedSourceNotInStaticMenu)
        {
          if (_currentSource != [_sources lastObject])
          {
            [_sources removeLastObject];
            _addedSourceNotInStaticMenu = NO;
          }
        }
      }
    }
  }  
}

- (void) addSourceOnlyDelegate: (id<ListDataDelegate>) delegate
{
  NSUInteger oldCount = [_listDataDelegates count];
  
  if (oldCount == 0)
  {
    _queryRspHandle = [_netStreamsComms registerDelegate: self forMessage: @"REPORT" from: _room.renderer.serviceName];
    _queryMsgHandle = [_netStreamsComms send: @"QUERY CURRENT_SOURCE" to: _room.renderer.serviceName
                                       every: CURRENT_SOURCE_REFRESH_INTERVAL];
    [_room.renderer addDelegate: self];
  }
  
  [_listDataDelegates addObject: delegate];
}

- (void) removeSourceOnlyDelegate: (id<ListDataDelegate>) delegate
{
  NSUInteger oldCount = [_listDataDelegates count];
  
  if (oldCount > 0)
  {
    [_listDataDelegates removeObject: delegate];
    if ([_listDataDelegates count] == 0)
    {
      [_netStreamsComms cancelSendEvery: _queryMsgHandle];
      [_netStreamsComms deregisterDelegate: _queryRspHandle];
      _queryMsgHandle = nil;
      _queryRspHandle = nil;
      [_room.renderer removeDelegate: self];
    }
  }  
}

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects
{
  NSString *result;
  
  if ((statusMask & JSON_CURRENT_SOURCE) == 0)
    result = @"{}";
  else
  {
    NSInteger count = [_sources count];
    NSInteger currentSource = count;

    result = [NSString stringWithFormat: @"{ length: %d", count];
    
    for (int i = 0; i < count; ++i)
    {
      NLSource *source = [_sources objectAtIndex: i];

      if (source == _currentSource)
        currentSource = i;

      if (currentSource == i || (statusMask & JSON_ALL_SOURCES) != 0)
      {
        NSString *sourceString = [source jsonStringForStatus: statusMask withObjects: withObjects];
        
        if ([sourceString length] > 2)
          sourceString = [NSString stringWithFormat: @"{ available: %d,%@",
                          (NSUInteger) [self itemIsSelectableAtIndex: i],
                          [sourceString substringFromIndex: 1]];

        result = [result stringByAppendingFormat: @", %d: %@", i, sourceString];
      }
    }

    result = [result stringByAppendingFormat: @", currentIndex: %d }", currentSource];
  }
  
  return result;
}

- (id) listDataCurrentItem
{
  return _currentSource;
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  if ([messageType isEqualToString: @"REPORT"])
  {
    NSString *currentSourceName = [data objectForKey: @"currentSource"];
    NSRange underscorePos = [currentSourceName rangeOfString: @"_" options: NSBackwardsSearch];

    // Make sure it's the right sort of report.  Ignore source names that are reported
    // as permids; a new wrinkle that was introduced by NetStreams recently.
    if (currentSourceName != nil &&
        (underscorePos.length == 0 || underscorePos.location < 16 ||
         [[currentSourceName substringWithRange:
           NSMakeRange( underscorePos.location - 16, 16 )] rangeOfCharacterFromSet: HEX_CHARS].length == 16))
    {
      // We get a brief bogus "no source" occasionally, followed by a correct
      // source report, so only believe "no source" if we get two in a row.
      if ([currentSourceName length] == 0 && !_possibleNoSource)
        _possibleNoSource = YES;
      else
      {
        NSUInteger count = [_sources count];
        NSUInteger i;
        NLSource *source;
        
        //NSLog( @"Current source: %@", currentSourceName );
        _possibleNoSource = NO;
        
        for (i = 0; i < count; ++i)
        {
          source = [_sources objectAtIndex: i];
          
          if ([source.serviceName compare: currentSourceName options: NSCaseInsensitiveSearch] == NSOrderedSame)
            break;
        }
        
        if (i == count)
        {
          NSUInteger masterCount = [g_MasterSources count];
          
          for (i = 0; i < masterCount; ++i)
          {
            source = [g_MasterSources objectAtIndex: i];
            if ([source.serviceName compare: currentSourceName options: NSCaseInsensitiveSearch] == NSOrderedSame)
              break;
          }
          
          if (i == masterCount)
          {
            i = 0;
            source = [NLSource noSourceObject];
          }
          else
          {
            if (_addedSourceNotInStaticMenu)
              [_sources replaceObjectAtIndex: count - 1 withObject: source];
            else
            {
              _addedSourceNotInStaticMenu = YES;
              [_sources addObject: source];
            }
          }
        }
        
        if (source != _currentSource)
        {
          NSSet *delegates;
          NSEnumerator *enumerator;
          id<ListDataDelegate> delegate;
          NLSource *oldSource = _currentSource;
          
          _currentSource.isCurrentSource = NO;
          _currentSource = source;
          _currentIndex = i;
          _currentSource.isCurrentSource = YES;
          
          if (![_availableSources containsObject: source])
          {
            NSMutableSet *newAvailable = [NSMutableSet setWithSet: _availableSources];
            
            [newAvailable addObject: _currentSource];
            [_availableSources release];
            _availableSources = [[NSSet setWithSet: newAvailable] retain];
            
            delegates = [NSSet setWithSet: _listDataDelegates];
            enumerator = [delegates objectEnumerator];
            while ((delegate = [enumerator nextObject]))
            {
              if ([delegate respondsToSelector: @selector(itemsChangedInListData:range:)])
                [delegate itemsChangedInListData: self range: NSMakeRange( i, 1 )];
            }
          }
          
          delegates = [NSSet setWithSet: _listDataDelegates];
          enumerator = [delegates objectEnumerator];
          while ((delegate = [enumerator nextObject]))
          {
            if ([delegate respondsToSelector: @selector(currentItemForListData:changedFrom:to:at:)])
              [delegate currentItemForListData: self changedFrom: oldSource to: _currentSource at: i];
          }
        }
      }
    }
  }
  else if (_listContentDelegateCount > 0)
  {
    NSString *responseType = [data objectForKey: @"responseType"];
    
    if ([responseType isEqualToString: @"source"])
    {
      NSUInteger itemnum = [[data objectForKey: @"itemnum"] integerValue];

      if (itemnum == -1)
      {
        // End of list; transfer our built up list to the available list
        NSUInteger count = [_sources count];
        NSUInteger availableCount = [_availableSources count];
        NSUInteger buildCount = [_buildSources count];
        
        if (availableCount != count || buildCount != count)
        {
          // Old or new available not the same as the full list.
          // Needs further investigation.  First, are old and new the same?
          
          BOOL different = (availableCount != buildCount);
          
          if (!different)
          {
            NSEnumerator *enumerator = [_availableSources objectEnumerator];
            id source;
            
            while ((source = [enumerator nextObject]))
            {
              if (![_buildSources member: source])
              {
                different = YES;
                break;
              }
            }
          }
            
          if (different)
          {
            NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
            NSEnumerator *enumerator = [delegates objectEnumerator];
            id<ListDataDelegate> delegate;
            
            [_availableSources release];
            _availableSources = [[NSSet setWithSet: _buildSources] retain];

            while ((delegate = [enumerator nextObject]))
            {
              if ([delegate respondsToSelector: @selector(itemsChangedInListData:range:)])
                [delegate itemsChangedInListData: self range: NSMakeRange( 0, count )];
            }
          }
        }
        
        [_buildSources removeAllObjects];
        [_buildSources addObject: [NLSource noSourceObject]];
#if defined(DEBUG)
        //**/NSLog( @"Deregister for sources 2: %@", _menuMsgHandle );
#endif
        [_netStreamsComms cancelSendEvery: _menuMsgHandle];
        _menuMsgHandle = nil;
        _refreshListTimer = [NSTimer scheduledTimerWithTimeInterval: SOURCE_INFO_REFRESH_INTERVAL
                                                             target: self selector: @selector(refreshListTimerFired:)
                                                           userInfo: nil repeats: NO];
      }
      else
      {
        NSString *serviceName = [data objectForKey: @"id"];
        NSUInteger count = [_sources count];
        NSUInteger i;
        
        if (itemnum % MENU_LIST_BLOCK_SIZE == 0)
        {
#if defined(DEBUG)
          //**/NSLog( @"Deregister for sources 3: %@", _menuMsgHandle );
#endif
          [_netStreamsComms cancelSendEvery: _menuMsgHandle];
          _menuMsgHandle = [_netStreamsComms send:
                            [NSString stringWithFormat: @"MENU_LIST %u,%u,SOURCES", 
                             itemnum + 1, itemnum + MENU_LIST_BLOCK_SIZE]
                                               to: _room.renderer.serviceName
                                            every: SOURCE_INFO_REFRESH_INTERVAL];
#if defined(DEBUG)
          //**/NSLog( @"Register for sources 2: %@", _menuMsgHandle );
#endif
        }
        
        for (i = 1; i < count; ++i)
        {
          NLSource *source = [_sources objectAtIndex: i];
          
          if ([source.serviceName compare: serviceName options: NSCaseInsensitiveSearch] == NSOrderedSame)
          {
            [_buildSources addObject: source];
            break;
          }
        }
      }
    }
  }
}

- (void) refreshListTimerFired: (NSTimer *) timer
{
#if defined(DEBUG)
  //**/NSLog( @"Deregister for sources 4: %@", _menuMsgHandle );
#endif
  [_netStreamsComms cancelSendEvery: _menuMsgHandle];
  _menuMsgHandle = [_netStreamsComms send:
                    [NSString stringWithFormat: @"MENU_LIST 1,%u,SOURCES", MENU_LIST_BLOCK_SIZE]
                                       to: _room.renderer.serviceName
                                    every: SOURCE_INFO_REFRESH_INTERVAL];
#if defined(DEBUG)
  //**/NSLog( @"Register for sources 3: %@", _menuMsgHandle );
#endif
  _refreshListTimer = nil;
}

- (void) dealloc
{
  [_refreshListTimer invalidate];
#if defined(DEBUG)
  //**/NSLog( @"Deregister for sources 5: %@", _menuMsgHandle );
#endif
  [_netStreamsComms cancelSendEvery: _queryMsgHandle];
  [_netStreamsComms cancelSendEvery: _menuMsgHandle];
  [_netStreamsComms deregisterDelegate: _queryRspHandle];
  [_netStreamsComms deregisterDelegate: _menuRspHandle];
  [_room.renderer removeDelegate: self];
  
  // This ensures that we don't have a source languishing in memory waiting for a response
  // to a URL request.
  for (NLSource *source in _sources)
    [source deactivate];

  [_sources release];
  [_availableSources release];
  [_buildSources release];
  [super dealloc];
}

@end

