//
//  NLBrowseListNetStreamsRoot.m
//  iLinX
//
//  Created by mcf on 19/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//
// Special version of the NLBrowseList class for the root menu of the
// browse hierarchy.  This does two extra things:
// 1. Adds presets to the root menu list
// 2. Spots when the root menu is a flat list of items and converts
// this to be a submenu (with Presets being the other submenu)

#import "NLBrowseListNetStreamsRoot.h"
#import "NLSource.h"

#define ROOT_TYPE_UNDECIDED 0
#define ROOT_TYPE_NORMAL    1
#define ROOT_TYPE_FLAT      2

static NSSet *IPORT_MENU_STRUCTURE = nil;

@interface NLBrowseListNetStreamsRoot ()

- (void) initWithRefreshing;
- (void) initWithPresetsOnly;

@end

@implementation NLBrowseListNetStreamsRoot

@synthesize 
  presetsList = _presetsList;

- (id) initWithSource: (NLSource *) source title: (NSString *) title
                 path: (NSString *) rootPath listCount: (NSUInteger) count
          addAllSongs: (NSUInteger) addAllSongs comms: (NetStreamsComms *) comms
{
  if ((self = [super initWithSource: source title: title path: rootPath
                          listCount: count addAllSongs: addAllSongs comms: comms]) != nil)
  {
    if (IPORT_MENU_STRUCTURE == nil)
      IPORT_MENU_STRUCTURE = [[NSSet setWithObjects: @"Playlist", @"Album", @"Artist", @"Genre", @"Song", @"Composer", nil] retain]; 

    _presetsList = [[NLBrowseListNetStreams alloc]
                    initWithSource: _source title: NSLocalizedString( @"Presets", @"Name of presets list" )
                    path: @"presets" listCount: NSUIntegerMax addAllSongs: ADD_ALL_SONGS_NO comms: _netStreamsComms];
    _presetsItem = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                     @"presets", @"id",
                     NSLocalizedString( @"Presets", @"Name of presets list" ), @"display",
                     @"32767", @"children",
                     nil] retain];
    if (_source.controlState != nil && [_source.controlState isEqualToString: @"REFRESH"])
      [self initWithRefreshing];
    else if (_rootPath == nil)
      [self initWithPresetsOnly];
  }

  return self;
}

- (void) doRefresh
{
  NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<ListDataDelegate> delegate;
  
  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(listDataRefreshDidStart:)])
      [delegate listDataRefreshDidStart: self];
  }
  
  _rootPath = [_source browseRootPath];
  [self reinit];
  
  if (_source.controlState != nil && [_source.controlState isEqualToString: @"REFRESH"])
    [self initWithRefreshing];
  else if (_rootPath == nil)
   [self initWithPresetsOnly];
  else 
    _rootType = ROOT_TYPE_UNDECIDED;
  
  if ([_listDataDelegates count] > 0)
  {
    [self registerForData];
  
    delegates = [NSSet setWithSet: _listDataDelegates];
    enumerator = [delegates objectEnumerator];
  
    while ((delegate = [enumerator nextObject]))
    {
      if ([delegate respondsToSelector: @selector(listDataRefreshDidEnd:)])
        [delegate listDataRefreshDidEnd: self];
    }
  }
}

- (NSUInteger) countOfList
{
  if (_count == NSUIntegerMax)
    return _count;
  else
    return _count + 1;
}

- (NSUInteger) countOfListInSection: (NSUInteger) section
{
  if (section == 0)
    return [self countOfList];
  else
    return 0;
}

- (id) itemAtIndex: (NSUInteger) index
{
  if (index == _count)
    return _presetsItem;
  else
    return [super itemAtIndex: index];
}

- (id) listDataCurrentItem
{
  if (_currentIndex > _count)
    return nil;
  else
    return [self itemAtIndex: _currentIndex];
}

- (id<ListDataSource>) selectItemAtIndex: (NSUInteger) index executeAction: (BOOL) executeAction
{
  NSDictionary *item = [self itemAtIndex: index];
  NSString *idpath = [item objectForKey: @"idpath"];
  id<ListDataSource> retValue = nil;
  
  if (idpath == nil)
  {
    NSString *path = [item objectForKey: @"id"];
    
    if (path != nil && [path isEqualToString: @"presets"])
      retValue = _presetsList;
  }
  
  if (retValue == nil)
    retValue = [super selectItemAtIndex: index executeAction: executeAction];
  else
  {
    NSDictionary *oldItem = [self listDataCurrentItem];
    NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
    NSEnumerator *enumerator = [delegates objectEnumerator];
    id<ListDataDelegate> delegate;
    
    _currentIndex = index;
    
    while ((delegate = [enumerator nextObject]))
    {
      if ([delegate respondsToSelector: @selector(currentItemForListData:changedFrom:to:at:)])
        [delegate currentItemForListData: self changedFrom: oldItem to: item at: index];
    }
  }

  return retValue;
}

- (void) handleListResponse: (NSDictionary *) data forRequest: (DataRequest *) currentRequest
{
  if (_rootType != ROOT_TYPE_FLAT)
  {
    NSUInteger oldCount = _count;

    [super handleListResponse: data forRequest: currentRequest];

    if (_rootType == ROOT_TYPE_UNDECIDED && currentRequest.remaining == 0)
    {
      NSMutableArray *block = [self blockForIndex: currentRequest.range.location prioritised: NO];
      NSUInteger count = [block count];
      NSUInteger i;
      
      // Identify an iPort source by its root menu structure: it is unique in having a list of
      // six items, all of which are singular rather than plural.  A bit naff to rely on this,
      // but it's the best we can do at the moment...

      if (count == [IPORT_MENU_STRUCTURE count])
      {
        for (i = 0; i < count; ++i)
        {
          if (![IPORT_MENU_STRUCTURE containsObject: [[block objectAtIndex: i] objectForKey: @"id"]])
            break;
        }
        
        if (i == count)
          _source.isSlowSource = YES; 
      }
      
      for (i = 0; i < count; ++i)
      {
        NSString *children = [[block objectAtIndex: i] objectForKey: @"children"];
        NSString *idName = [[block objectAtIndex: i] objectForKey: @"id"];
        
        if (children != nil && ![children isEqualToString: @"0"] && ![idName isEqualToString: @"presets"])
          break;
      }
      
      if (i != count)
      {
        if (![_source.sourceControlType isEqualToString: @"XM TUNER"])
        {
          _rootType = ROOT_TYPE_NORMAL;
          // Nasty hack to support Favorites only on VTuners at the moment.
          if ([_source.sourceType isEqualToString: @"VTUNER"])
          {
            _count = 1;
            if ([_pendingRequests count] > 1)
              [_pendingRequests removeObjectsInRange: NSMakeRange( 1, [_pendingRequests count] - 1 )];
          }
        }
        else
        {
          // Special case for XM and Sirius tuners.  Their root list is a complete list of 
          // categories, with "all channels" being the first entry.  This is too long for the
          // root list (it mucks up the iPhone's icon rearrangement page), so we make a fake
          // root list of All Channels, Categories, Presets and then shuffle the real root
          // list off to live under Categories.

          NSMutableDictionary *item0 = [[block objectAtIndex: 0] mutableCopy];
          NSMutableDictionary *item1 = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        _rootPath, @"id", 
                                        NSLocalizedString( @"1001Categories",
                                                          @"Title of the categories root menu item for satellite tuners" ),
                                        @"display", @"32767", @"children", nil];
          
          [item0 setObject: NSLocalizedString( @"1001All Channels",
                                              @"Title of the all channels root menu item for satellite tuners" )
                    forKey: @"display"];
          [block replaceObjectAtIndex: 0 withObject: item0];
          [block replaceObjectAtIndex: 1 withObject: item1];
          [item0 release];
          oldCount = 0;
          _count = 2;
          _rootType = ROOT_TYPE_FLAT;
          
          if ([_pendingRequests count] > 1)
            [_pendingRequests removeObjectsInRange: NSMakeRange( 1, [_pendingRequests count] - 1 )];
        }
      }
      else
      {
        // If there are no items in the root menu that have children, then this is a flat
        // list, e.g. a list of stations from a tuner.  Fiddle it so that instead this
        // list becomes the first child of a new root menu.

        NSMutableDictionary *item = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     _rootPath, @"id", _title, @"display", @"32767", @"children", nil];
        
        [block replaceObjectAtIndex: 0 withObject: item];
        oldCount = 0;
        _count = 1;
        _rootType = ROOT_TYPE_FLAT;

        if ([_pendingRequests count] > 1)
          [_pendingRequests removeObjectsInRange: NSMakeRange( 1, [_pendingRequests count] - 1 )];
      }
    }
   
    if (_count != oldCount)
      currentRequest.changed = YES;
  }
}

- (void) initWithRefreshing
{
  // Refreshing message only root browse menu
  NSMutableArray *block = [[NLBrowseListNetStreams emptyBlock] mutableCopy];
  NSMutableDictionary *item = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                               NSLocalizedString( @"Refreshing", @"Title to show in browse screen when details are being refreshed" ), @"display",
                               @"0", @"children",
                               nil];
  
  self.lastKey = @"0";
  [block replaceObjectAtIndex: 0 withObject: item];
  [_content setObject: block forKey: _lastKey];
  [block release];
  _count = 1;
  _rootType = ROOT_TYPE_FLAT;
}

- (void) initWithPresetsOnly
{
  // Presets only root browse menu
  NSMutableArray *block = [[NLBrowseListNetStreams emptyBlock] mutableCopy];
  
  _count = 0;
  self.lastKey = @"0";
  [_content setObject: block forKey: _lastKey];
  [block release];
  _rootType = ROOT_TYPE_FLAT;
}

- (void) dealloc
{
  [_presetsList release];
  [_presetsItem release];
  [super dealloc];
}

@end
