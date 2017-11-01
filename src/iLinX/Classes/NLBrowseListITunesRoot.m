//
//  NLBrowseListITunesRoot.m
//  iLinX
//
//  Created by mcf on 05/11/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "NLBrowseListITunesRoot.h"
#import "ITRequest.h"
#import "ITResponse.h"
#import "ITSession.h"
#import "ITURLConnection.h"
#import "NLBrowseListITunesType.h"
#import "NLBrowseListITunesWaiting.h"

#define SPECIAL_LIST_PODCASTS      1
#define SPECIAL_LIST_ITUNES_DJ     2
#define SPECIAL_LIST_MOVIES        4
#define SPECIAL_LIST_TV_SHOWS      5
#define SPECIAL_LIST_MUSIC         6
#define SPECIAL_LIST_AUDIOBOOKS    7
#define SPECIAL_LIST_PURCHASED     8
#define SPECIAL_LIST_RENTALS      10
#define SPECIAL_LIST_GENIUS       12
#define SPECIAL_LIST_ITUNES_UNI   13
#define SPECIAL_LIST_GENIUS_MIXES 15
#define SPECIAL_LIST_GENIUS_MIX   16

static NSInteger SortListContents( id item1, id item2, void *context );

// Oddball list that needs to be in root and not playlists, but
// which does not have a special list tag.  We have to search by
// name - yuck.
static NSString *MUSIC_VIDEOS = @"Music Videos";

static NSSet *MANDATORY_ITEMS = nil;
static NSDictionary *MANDATORY_ITEM_TITLES = nil;

@interface NLBrowseListITunesRoot ()

- (void) handleFindMusicIdResponse: (ITResponse *) response;
- (NSDictionary *) menuEntryFor: (NSString *) title;
- (NSDictionary *) menuEntryFor: (NSString *) title withItem: (ITResponse *) item;

@end

@implementation NLBrowseListITunesRoot

- (id) initWithSource: (NLSource *) source title: (NSString *) title
              session: (ITSession *) session
{
  if ((self = [super initWithSource: source title: title session: session]) != nil)
  {
    if (MANDATORY_ITEMS == nil)
    {
      MANDATORY_ITEMS = [[NSSet setWithObjects: 
                          [NSNumber numberWithUnsignedInteger: SPECIAL_LIST_PODCASTS],
                          [NSNumber numberWithUnsignedInteger: SPECIAL_LIST_MOVIES],
                          [NSNumber numberWithUnsignedInteger: SPECIAL_LIST_TV_SHOWS],
                          [NSNumber numberWithUnsignedInteger: SPECIAL_LIST_AUDIOBOOKS],
                          [NSNumber numberWithUnsignedInteger: SPECIAL_LIST_ITUNES_UNI],
                          nil] retain];
      MANDATORY_ITEM_TITLES = [[NSDictionary dictionaryWithObjectsAndKeys:
                                @"Podcasts", [NSNumber numberWithUnsignedInteger: SPECIAL_LIST_PODCASTS],
                                @"Movies", [NSNumber numberWithUnsignedInteger: SPECIAL_LIST_MOVIES],
                                @"TV Shows", [NSNumber numberWithUnsignedInteger: SPECIAL_LIST_TV_SHOWS],
                                @"Audiobooks", [NSNumber numberWithUnsignedInteger: SPECIAL_LIST_AUDIOBOOKS],
                                @"iTunes U", [NSNumber numberWithUnsignedInteger: SPECIAL_LIST_ITUNES_UNI],
                                nil] retain];
    }
    
    if (_items == nil)
    {
      NLBrowseListITunesWaiting *connecting = [[NLBrowseListITunesWaiting alloc] initWithSource: source session: session];
      
      _items = [[NSArray arrayWithObject: [NSDictionary dictionaryWithObjectsAndKeys: @"Connecting", @"display", @"Connecting", @"listType", 
                                           @"0", @"children", connecting, @"list", nil]] retain];
      [connecting release];
    }
  }
  
  return self;
}

- (void) loadList
{
  // fetch playlists to fill out content of root menu with special items
  ITRequest *request = [ITRequest allocRequest:
                        [NSString stringWithFormat: @"%@/databases/%@/containers?session-id=%@&meta=dmap.itemname,dmap.itemcount,dmap.itemid,dmap.persistentid,daap.baseplaylist,com.apple.itunes.special-playlist,com.apple.itunes.smart-playlist,com.apple.itunes.saved-genius,dmap.parentcontainerid,dmap.editcommandssupported,com.apple.itunes.jukebox-current,daap.songcontentdescription",
                         [_session getRequestBase], _session.databaseId, _session.sessionId]
                                     connection: _conn delegate: self];

  [_pendingCalls setObject: NSStringFromSelector( @selector(handleFindMusicIdResponse:) ) forKey: request];
  [request release];
}

- (void) handleFindMusicIdResponse: (ITResponse *) response
{
  NSMutableArray *playlists = [NSMutableArray arrayWithCapacity: 10];
  NSMutableDictionary *containers = [NSMutableDictionary dictionaryWithCapacity: 8];
  NSMutableArray *items = [NSMutableArray arrayWithObjects: 
                           [self menuEntryFor: @"Albums"],
                           [self menuEntryFor: @"Artists"], 
                           [self menuEntryFor: @"Composers"],
                           [self menuEntryFor: @"Genres"],
                           [self menuEntryFor: @"Songs"], nil];

  for (ITResponse *resp in [[[response responseForKey: @"aply"] responseForKey: @"mlcl"] allItemsWithPrefix: @"mlit"])
  {
    id isBaseList = [resp itemForKey: @"abpl"];
    id specialPlaylistObj = [resp itemForKey: @"aePS"];
    NSUInteger specialPlaylistType = (specialPlaylistObj == nil) ? 0 : [resp unsignedIntegerForKey: @"aePS"];
    NSString *name = [resp stringForKey: @"minm"];
    NSString *parentContainerId = [resp numberStringForKey: @"mpco"];

    if (specialPlaylistType != SPECIAL_LIST_MUSIC && isBaseList == nil)
    {
      id parent = [containers objectForKey: parentContainerId];

      [containers setObject: resp forKey: [resp numberStringForKey: @"miid"]];

      if (parent != nil)
      {
        if ([parent isKindOfClass: [ITResponse class]])
        {
          parent = [NSMutableArray arrayWithCapacity: 8];
          [containers setObject: parent forKey: parentContainerId];
        }
        [parent addObject: [NSDictionary dictionaryWithObjectsAndKeys: name, @"display",
                            [resp numberStringForKey: @"mimc"], @"children", 
                            @"Playlist", @"listType",
                            @"Song", @"itemType",
                            [resp numberStringForKey: @"miid"], @"id",
                            [resp numberStringForKey: @"mper"], @"persistId", nil]];
      }
      else if ((specialPlaylistType == 0 && ![name isEqualToString: MUSIC_VIDEOS]) ||
          specialPlaylistType == SPECIAL_LIST_GENIUS || specialPlaylistType == SPECIAL_LIST_ITUNES_DJ ||
          specialPlaylistType == SPECIAL_LIST_PURCHASED || specialPlaylistType == SPECIAL_LIST_RENTALS)
      {
        [playlists addObject: [NSDictionary dictionaryWithObjectsAndKeys: name, @"display",
                               [resp numberStringForKey: @"mimc"], @"children", 
                               @"Playlist", @"listType",
                               @"Song", @"itemType",
                               [resp numberStringForKey: @"miid"], @"id",
                               [resp numberStringForKey: @"mper"], @"persistId", nil]];
      }
      else
      {
        [items addObject: [self menuEntryFor: name withItem: resp]];
      }
    }
  }
  
  NLBrowseListITunesType *playlistsType = 
  [NLBrowseListITunesType allocTypeDataForType: @"Playlists" session: _session
                                   parentFilter: nil item: [NSDictionary dictionary]];
  NLBrowseList *playlistsList = [[NLBrowseListITunes alloc] initWithSource: _source title: @"Playlists" session: _session
                                                                     items: playlists type: playlistsType];
  NSMutableSet *mandatoryItems = [MANDATORY_ITEMS mutableCopy];

  [items addObject: [NSDictionary dictionaryWithObjectsAndKeys: @"Playlists", @"display",
                     [NSString stringWithFormat: @"%u", [playlists count]], @"children",
                     @"Playlists", @"listType", @"Playlist", @"itemType", playlistsList, @"list", nil]];  
  [playlistsList release];

  for (NSUInteger i = 0; i < [items count]; ++i)
  {
    NSDictionary *item = [items objectAtIndex: i];
    NSString *itemId = [item objectForKey: @"id"];
    NSNumber *specialType = [item objectForKey: @"specialType"];
    
    if ([mandatoryItems containsObject: specialType])
      [mandatoryItems removeObject: specialType];

    if (itemId != nil)
    {
      id container = [containers objectForKey: itemId];
      
      if ([container isKindOfClass: [NSArray class]])
      {
        NSMutableDictionary *replacementItem = [item mutableCopy];
        
        playlistsList = [[NLBrowseListITunes alloc] initWithSource: _source 
                                                             title: [item objectForKey: @"display"] session: _session
                                                             items: container type: playlistsType];
        [replacementItem setObject: playlistsList forKey: @"list"];
        [replacementItem setObject: @"Playlists" forKey: @"listType"];
        [replacementItem setObject: [NSString stringWithFormat: @"%u", [container count]] forKey: @"children"];
        [items replaceObjectAtIndex: i withObject: replacementItem];
        [replacementItem release];
        [playlistsList release];
      }
    }
  }

  // Fill in any mandatory items that the server itself fails to send us
  for (NSNumber *mandItem in [mandatoryItems allObjects])
    [items addObject: [self menuEntryFor: [MANDATORY_ITEM_TITLES objectForKey: mandItem]]];

  [mandatoryItems release];
  [playlistsType release];
  [_items release];
  _items = [[items sortedArrayUsingFunction: SortListContents context: NULL] retain];

  NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<ListDataDelegate> delegate;
  
  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(itemsChangedInListData:range:)])
      [delegate itemsChangedInListData: self range: NSMakeRange( 0, [_items count] )];
  }
}

- (id<ListDataSource>) selectItemAtIndex: (NSUInteger) index executeAction: (BOOL) executeAction
{
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

  return [self browseListForItemAtIndex: index];
}

- (NLBrowseList *) browseListForItemAtIndex: (NSUInteger) index
{
  NSDictionary *item = [_items objectAtIndex: index];
  NSString *listType = [item objectForKey: @"listType"];
  NLBrowseList *list = [item objectForKey: @"list"];

  if (list == nil)
  {
    NLBrowseListITunesType *type = [NLBrowseListITunesType allocTypeDataForType: listType session: _session
                                                                    parentFilter: nil item: item];
    
    list = [[[NLBrowseListITunes alloc] initWithSource: _source title: [item objectForKey: @"display"]
                                               session: _session type: type] autorelease];
    [type release];
  }

  return list;
}

- (NSDictionary *) menuEntryFor: (NSString *) title
{
  return [NSDictionary dictionaryWithObjectsAndKeys: title, @"display", title, @"listType", 
          @"32767", @"children", nil];
}

- (NSDictionary *) menuEntryFor: (NSString *) title withItem: (ITResponse *) item
{
  id specialPlaylistObj = [item itemForKey: @"aePS"];
  NSDictionary *menuEntry;
  
  if (specialPlaylistObj == nil)
    menuEntry = [NSDictionary dictionaryWithObjectsAndKeys: title, @"display", title, @"listType", 
                 [item numberStringForKey: @"mimc"], @"children", 
                 [item numberStringForKey: @"miid"], @"id",
                 [item numberStringForKey: @"mper"], @"persistId", nil];
  else
  {
    NSNumber *specialType = [NSNumber numberWithUnsignedInt: [item unsignedIntegerForKey: @"aePS"]];
    NSString *listType = [MANDATORY_ITEM_TITLES objectForKey: specialType];
    
    if (listType == nil)
      listType = title;
    menuEntry = [NSDictionary dictionaryWithObjectsAndKeys: title, @"display", listType, @"listType", 
                 [item numberStringForKey: @"mimc"], @"children", 
                 [item numberStringForKey: @"miid"], @"id",
                 [item numberStringForKey: @"mper"], @"persistId",
                 specialType, @"specialType",
                 nil];
  }
  
  return menuEntry;
}

@end

static NSInteger SortListContents( id item1, id item2, void *context )
{
  return [[item1 objectForKey: @"display"] localizedCaseInsensitiveCompare: [item2 objectForKey: @"display"]];
}

