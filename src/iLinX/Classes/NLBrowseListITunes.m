//
//  NLBrowseListITunes.m
//  iLinX
//
//  Created by mcf on 04/11/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "NLBrowseListITunes.h"
#import "DebugTracing.h"
#import "ITRequest.h"
#import "ITResponse.h"
#import "ITSession.h"
#import "NLBrowseListITunesType.h"
#import "WeakReference.h"

#define SESSION_START_RETRY_TIME 5

static const NSString *SEL_KEY = @"selector";

@interface NLBrowseListITunes ()

- (void) waitAndLoadList;
- (void) loadListTimerFired: (NSTimer *) timer;
- (void) handleItemFetchResponse: (ITResponse *) response;

@end

@interface NLBrowseListITunesLoader : NSDebugObject
{
@private
  WeakReference *_list;
}

- (id) initWithList: (NLBrowseListITunes *) list;
- (void) loadListTimerFired: (NSTimer *) timer;

@end

@implementation NLBrowseListITunesLoader

- (id) initWithList: (NLBrowseListITunes *) list
{
  if ((self = [super init]) != nil)
    _list = [[WeakReference weakReferenceForObject: list] retain];
  
  return self;
}

- (void) loadListTimerFired: (NSTimer *) timer
{
  [(NLBrowseListITunes *) [_list referencedObject] loadListTimerFired: timer];
}

- (void) dealloc
{
  [_list release];
  [super dealloc];
}

@end

@implementation NLBrowseListITunes

- (id) initWithSource: (NLSource *) source title: (NSString *) title
              session: (ITSession *) session
{
  if ((self = [super initWithSource: source title: title]) != nil)
  {
    _session = [session retain];
    _pendingCalls = [NSMutableDictionary new];
    [_session.status addDelegate: self];
    
    if (![_session isConnected])
      [self waitAndLoadList];
    else
      [self loadListTimerFired: nil];
  }
  
  return self;
}

- (id) initWithSource: (NLSource *) source title: (NSString *) title
              session: (ITSession *) session items: (NSMutableArray *) items
                 type: (NLBrowseListITunesType *) type
{
  if ((self = [super initWithSource: source title: title]) != nil)
  {
    _session = [session retain];
    _pendingCalls = [NSMutableDictionary new];
    _items = [items retain];
    _type = [type retain];
    _itemType = [[type childType] retain];
    [_session.status addDelegate: self];
  }
  
  return self;
}

- (id) initWithSource: (NLSource *) source title: (NSString *) title
              session: (ITSession *) session type: (NLBrowseListITunesType *) type
{
  if ((self = [self initWithSource: source title: title session: session items: nil type: type]) != nil)
  {
    if (![_session isConnected])
      [self waitAndLoadList];
    else
      [self loadListTimerFired: nil];
  }
  
  return self;
}

- (void) waitAndLoadList
{
  [_conn close];
  [_conn release];
  _conn = nil;
  _loadListTimer = [NSTimer scheduledTimerWithTimeInterval: SESSION_START_RETRY_TIME
                                                    target: [[[NLBrowseListITunesLoader alloc] initWithList: self] autorelease]
                                                  selector: @selector(loadListTimerFired:)
                                                  userInfo: nil repeats: NO];
}

- (void) loadListTimerFired: (NSTimer *) timer
{
  _loadListTimer = nil;
  if (![_session isConnected])
    [self waitAndLoadList];
  else
  {
    _conn = [[ITURLConnection alloc] init];
  
    [self loadList];
  }
}

- (void) loadList
{
  if (_type != nil)
  {
    NSString *listItemsCommand = [_type listItemsCommand];
    
    if ([listItemsCommand length] > 0)
    {
      // A zero length items command indicates that this list was pre-initialised and so does not need to
      // be refetched.
      
      ITRequest *request = [ITRequest allocRequest: listItemsCommand
                                        connection: _conn delegate: self];
      
      [_pendingCalls setObject: NSStringFromSelector( @selector(handleItemFetchResponse:) ) forKey: request];
      [request release];
    }
  }
}

- (void) request: (ITRequest *) request succeededWithResponse: (ITResponse *) response
{
  id item = [[_pendingCalls objectForKey: request] retain];
  
  [request retain];
  [_pendingCalls removeObjectForKey: request];
  
  if ([item isKindOfClass: [NSString class]])
    [self performSelector: NSSelectorFromString( item ) withObject: response];
  else if ([item isKindOfClass: [NSDictionary class]])
    [self performSelector: NSSelectorFromString( [item objectForKey: SEL_KEY] ) withObject: response withObject: item];

  [request release];
  [item release];
}

- (void) request: (ITRequest *) request failedWithError: (NSError *) error
{
  [_pendingCalls removeObjectForKey: request];
  if (![_session isConnected] || ([[error domain] isEqualToString: [ITRequest requestErrorDomain]] && 
       ([error code] == 403 /* HTTP Forbidden */ || [error code] == 406 /* Server error */)))
    [self waitAndLoadList];
  else
  {
    NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
    NSEnumerator *enumerator = [delegates objectEnumerator];
    id<ListDataDelegate> delegate;

    [_items release];
    _items = nil;
    while ((delegate = [enumerator nextObject]))
    {
      if ([delegate respondsToSelector: @selector(itemsChangedInListData:range:)])
        [delegate itemsChangedInListData: self range: NSMakeRange( 0, 0 )];
    }
  }
}

- (void) handleItemFetchResponse: (ITResponse *) response
{
  NSUInteger oldCount = [_items count];
  ITResponse *topLevel = [response responseForKey: @"abro"];
  ITResponse *itemList = nil;
  NSArray *secondItem = nil;
  NSString *coverArt = nil;

  [_items release];
  
  if (topLevel == nil)
  {
    topLevel = [response responseForKey: @"agal"];
    
    if (topLevel != nil)
    {
      secondItem = [NSArray arrayWithObject: @"asaa"];
      coverArt = @"%@/databases/%@/groups/%@/extra_data/artwork?session-id=%@&mw=130&mh=130&group-type=albums";
    }
    else
    {
      topLevel = [response responseForKey: @"apso"];
      if (topLevel != nil)
      {
        if ([[_type childType] isEqualToString: @"Song"])
          secondItem = [NSArray arrayWithObjects: @"asal", @"asar", nil];
        else
        {
          coverArt = @"%@/databases/%@/items/%@/extra_data/artwork?session-id=%@&mw=130&mh=130";
          // Track date and track time...
        }
      }
    }

    if (topLevel != nil)
      itemList = [topLevel responseForKey: @"mlcl"];
  }
  else
  {
    itemList = [topLevel responseForKey: @"abar"];
    if (itemList == nil)
      itemList = [topLevel responseForKey: @"abgn"];
    if (itemList == nil)
      itemList = [topLevel responseForKey: @"abcp"];
  }
  
  if (topLevel == nil || itemList == nil)
    _items = nil;
  else
  {
    ITResponse *sectionList = [topLevel responseForKey: @"mshl"];
    NSUInteger itemCount = [topLevel unsignedIntegerForKey: @"mtco"];
    NSArray *specialItems = [_type specialItems];
    NSUInteger specialCount = [specialItems count];
    NSArray *listItems = [itemList allItemsWithPrefix: @"mlit"];

    if (itemCount < 2)
    {
      specialCount = 0;
      secondItem = nil;
    }

    NSMutableArray *items = [NSMutableArray arrayWithCapacity: itemCount + specialCount];
    if (specialCount > 0)
      [items addObjectsFromArray: specialItems];

    if (secondItem != nil)
    {
      NSMutableArray *editedSecondItem = [NSMutableArray array];
      
      for (NSString *field in secondItem)
      {
        NSString *firstValue = [[listItems objectAtIndex: 0] stringForKey: field];
        BOOL addField = NO;

        for (ITResponse *item in listItems)
        {
          if (![[item stringForKey: field] isEqualToString: firstValue])
          {
            addField = YES;
            break;
          }
        }

        if (addField)
          [editedSecondItem addObject: field];
      }

      if ([editedSecondItem count] == 0)
        secondItem = nil;
      else
        secondItem = editedSecondItem;
    }

    for (id item in listItems)
    {
      NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithCapacity: 5];

      if ([item isKindOfClass: [NSString class]])
      {
        CFStringRef itemId = CFURLCreateStringByAddingPercentEscapes( NULL, (CFStringRef) item, NULL, 
                                                                     (CFStringRef) @"$&+,/:;=?@'\"<>#%{}|\\^~[]`",
                                                                     kCFStringEncodingUTF8 );

        [temp setObject: item forKey: @"display"];
        [temp setObject: (NSString *) itemId forKey: @"id"];
        CFRelease( itemId );
      }
      else
      {
        ITResponse *itemAsResponse = (ITResponse *) item;

        [temp setObject: [itemAsResponse stringForKey: @"minm"] forKey: @"display"];
        [temp setObject: [itemAsResponse numberStringForKey: @"miid"] forKey: @"id"];
        if ([itemAsResponse itemForKey: @"mper"] != nil)
          [temp setObject: [itemAsResponse numberStringForKey: @"mper"] forKey: @"persistId"];
        if ([itemAsResponse itemForKey: @"mcti"] != nil)
          [temp setObject: [itemAsResponse numberStringForKey: @"mcti"] forKey: @"containerItemId"];
        if (secondItem != nil)
        {
          NSString *display2 = [itemAsResponse stringForKey: [secondItem objectAtIndex: 0]];
          
          for (NSUInteger i = 1; i < [secondItem count]; ++i)
          {
            NSString *nextData = [itemAsResponse stringForKey: [secondItem objectAtIndex: i]];
            
            if ([nextData length] > 0)
              display2 = [display2 stringByAppendingFormat: @" - %@", nextData];
          }

          [temp setObject: display2 forKey: @"display2"];
        }
      }
      
      if (coverArt != nil)
        [temp setObject: [NSString stringWithFormat:
                          coverArt,
                          [_session getRequestBase], _session.databaseId, [(ITResponse *) item numberStringForKey: @"miid"], _session.sessionId] forKey: @"thumbnail"];

      if ([_type isLeafType])
        [temp setObject: @"0" forKey: @"children"];
      else
        [temp setObject: @"32767" forKey: @"children"];

      [items addObject: [NSDictionary dictionaryWithDictionary: temp]];
    }
    
    _items = [items retain];

    if (sectionList == nil || itemCount < SECTIONS_ITEM_COUNT_THRESHOLD)
    {
      _sectionTitles = [[NSMutableArray arrayWithObjects: @"", @"", nil] retain];
      _sectionLengths = [[NSMutableArray arrayWithObjects:
                          [NSNumber numberWithUnsignedInteger: specialCount],
                          [NSNumber numberWithUnsignedInteger: itemCount], nil] retain];
      _sectionOffsets = [[NSMutableArray arrayWithObjects:
                          [NSNumber numberWithUnsignedInteger: 0],
                          [NSNumber numberWithUnsignedInteger: specialCount], nil] retain];
    }
    else
    {
      NSArray *sections = [sectionList allItemsWithPrefix: @"mlit"];
      NSUInteger offset = specialCount;
      
      _sectionTitles = [[NSMutableArray arrayWithCapacity: [sections count] + 1] retain];
      _sectionLengths = [[NSMutableArray arrayWithCapacity: [sections count] + 1] retain];
      _sectionOffsets = [[NSMutableArray arrayWithCapacity: [sections count] + 1] retain];
      
      [_sectionTitles addObject: @""];
      [_sectionLengths addObject: [NSNumber numberWithUnsignedInteger: specialCount]];
      [_sectionOffsets addObject: [NSNumber numberWithUnsignedInteger: 0]];

      for (ITResponse *section in sections)
      {
        NSUInteger length = [section unsignedIntegerForKey: @"mshn"];

        [_sectionTitles addObject: [NSString stringWithFormat: @"%C", (unichar) [section unsignedIntegerForKey: @"mshc"]]];
        [_sectionLengths addObject: [NSNumber numberWithUnsignedInteger: length]];
        [_sectionOffsets addObject: [NSNumber numberWithUnsignedInteger: offset]];
        offset += length;
      }
    }
  }

  NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<ListDataDelegate> delegate;
  NSUInteger count = [_items count];
  NSRange itemRange = NSMakeRange( 0, count );
  
  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(itemsChangedInListData:range:)])
      [delegate itemsChangedInListData: self range: itemRange];
  }

  if (oldCount > count)
  {
    itemRange = NSMakeRange( count, oldCount - count );
    
    enumerator = [delegates objectEnumerator];
    while ((delegate = [enumerator nextObject]))
    {
      if ([delegate respondsToSelector: @selector(itemsRemovedInListData:range:)])
        [delegate itemsRemovedInListData: self range: itemRange];
    }
  }
}

- (NSUInteger) countOfList
{
  return [_items count];
}

- (BOOL) itemIsSelectableAtIndex: (NSUInteger) index
{
  return [_session isConnected] && index < [_items count];
}

- (id<ListDataSource>) selectItemAtIndex: (NSUInteger) index executeAction: (BOOL) executeAction
{
  id<ListDataSource> newList;

  if (_type == nil || index >= [_items count])
    newList = nil;
  else if ([_type isLeafType])
  {
    if (executeAction)
      [_session clearAndDoAction: [_type selectCommandForChildIndex: index inItems: _items]];  
    newList = nil;
  }
  else
  {
    NLBrowseListITunesType *newType = [_type allocTypeForChildIndex: index inItems: _items];
    
    newList = [[[NLBrowseListITunes alloc] initWithSource: _source title: [self titleForItemAtIndex: index] 
                                                  session: _session type: newType] autorelease];
    [newType release];
  }

  NSDictionary *oldItem = [self listDataCurrentItem];
  NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<ListDataDelegate> delegate;
  
  _currentIndex = index;
  
  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(currentItemForListData:changedFrom:to:at:)])
      [delegate currentItemForListData: self changedFrom: oldItem to: [self itemAtIndex: index] at: index];
  }

  return newList;
}

- (id) itemAtIndex: (NSUInteger) index
{
  if (index < [_items count])
    return [_items objectAtIndex: index];
  else
    return nil;
}

- (BOOL) dataPending
{
  return _loadListTimer != nil || [_pendingCalls count] > 0 || ![_session isConnected];
}

- (NSUInteger) countOfSections
{
  if (_sectionTitles == nil)
    return 1;
  else
    return [_sectionTitles count];
}

- (NSString *) titleForSection: (NSUInteger) section
{
  if (section < [_sectionTitles count])
    return [_sectionTitles objectAtIndex: section];
  else
    return @"";
}

- (NSUInteger) sectionForPrefix: (NSString *) prefix
{
  NSUInteger section = [_sectionTitles indexOfObject: prefix];

  if (section == NSNotFound)
    section = 0;

  return section;
}

- (NSUInteger) countOfListInSection: (NSUInteger) section
{
  if (section < [_sectionLengths count])
    return [(NSNumber *) [_sectionLengths objectAtIndex: section] unsignedIntegerValue];
  else if (_sectionLengths != nil)
    return 0;
  else if (section == 0)
    return [_items count];
  else
    return 0;
}

- (NSUInteger) convertFromOffset: (NSUInteger) index inSection: (NSUInteger) section
{
  NSUInteger newIndex;

  if (section >= [_sectionOffsets count])
    newIndex = index;
  else
    newIndex = [(NSNumber *) [_sectionOffsets objectAtIndex: section] unsignedIntegerValue] + index;

  return newIndex;
}

- (NSIndexPath *) indexPathFromIndex: (NSUInteger) index
{
  NSUInteger lastOffset = 0;
  NSUInteger offsetCount = [_sectionOffsets count];
  NSUInteger section;
  
  for (section = 1; section < offsetCount; ++section)
  {
    NSUInteger offset = [[_sectionOffsets objectAtIndex: section] unsignedIntegerValue];
    
    if (index < offset)
      break;
    else
      lastOffset = offset;
  }

  return [NSIndexPath indexPathForRow: index - lastOffset inSection: section - 1];
}

- (BOOL) initAlphaSections
{
  return [_sectionTitles count] > 2;
}

- (NSArray *) sectionIndices
{
  return _sectionTitles;
}

- (void) iTunesStatus: (ITStatus *) status changed: (NSUInteger) changeType
{
  if ((changeType & ITSTATUS_CONNECTED) != 0)
  {
    if (!status.connected && _loadListTimer == nil)
    {
      for (ITRequest *request in _pendingCalls)
        [request cancel];
      [_pendingCalls removeAllObjects];
      [self waitAndLoadList];
    }
  }
}

- (void) dealloc
{
  for (ITRequest *request in _pendingCalls)
    [request cancel];

  [_loadListTimer invalidate];
  [_session.status removeDelegate: self];
  [_session release];
  [_conn close];
  [_conn release];
  [_pendingCalls release];
  [_type release];
  [_items release];
  [_sectionTitles release];
  [_sectionLengths release];
  [_sectionOffsets release];
  [super dealloc];
}

@end
