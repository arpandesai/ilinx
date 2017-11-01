//
//  NLBrowseListITunesType.m
//  iLinX
//
//  Created by mcf on 12/11/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "NLBrowseListITunesType.h"
#import "ITSession.h"

static NSDictionary *TYPE_DATA = nil;

@interface NLBrowseListITunesType ()

- (id) initWithName: (NSString *) name data: (NSArray *) data session: (ITSession *) session
       parentFilter: (NSSet *) parentFilter item: (NSDictionary *) item;
- (NSString *) replaceParametersInString: (NSString *) string parameters: (NSDictionary *) parameters;
- (NSString *) replaceParametersInSessionString: (NSString *) string parameters: (NSDictionary *) parameters;

@end

@implementation NLBrowseListITunesType

@synthesize name = _name;

- (NSString *) childType
{
  return [_typeData objectAtIndex: 0];
}

+ (NLBrowseListITunesType *) allocTypeDataForType: (NSString *) type session: (ITSession *) session
                                      parentFilter: (NSSet *) parentFilter item: (NSDictionary *) item
{
  NLBrowseListITunesType *newTypeData;

  if (TYPE_DATA == nil)
  {
    TYPE_DATA = [[NSDictionary dictionaryWithObjectsAndKeys:
                  // Albums
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Album",
                   // Child play
                   @"",
                   // List command
                   @"${requestBase}/databases/${dbId}/groups?session-id=${sessionId}&meta=dmap.itemname,dmap.itemid,dmap.persistentid,daap.songartist&type=music&group-type=albums&sort=album&include-sort-headers=1&query=${filter}+'daap.songalbum!:'",
                   // Filter
                   @"('com.apple.itunes.mediakind:1','com.apple.itunes.mediakind:32')",
                   // Special menu entries
                   [NSArray arrayWithObjects:
                    // Albums>All Songs
                    [NSDictionary dictionaryWithObjectsAndKeys: 
                     NSLocalizedString( @"All Songs", @"" ), @"display",
                     @"Songs", @"listType",
                     @"Song", @"itemType",
                     @"32767", @"children", nil],
                     nil], nil], @"Albums",
                  // Album
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Song",
                   // Child play
                   @"${requestBase}/ctrl-int/1/cue?command=play&query=${filter}&dacp.shufflestate=0&index=${index}&sort=album&session-id=${sessionId}",
                   // List command
                   @"${requestBase}/databases/${dbId}/containers/${musicId}/items?session-id=${sessionId}&meta=dmap.itemname,dmap.itemid,daap.songartist,daap.songalbum,dmap.containeritemid,com.apple.itunes.has-video&type=music&sort=album&query=${filter}",
                   // Filter
                   @"'daap.songalbumid:${persistId}'",
                   // Special menu entries
                   [NSArray arrayWithObjects:
                    // Shuffle
                    [NSDictionary dictionaryWithObjectsAndKeys: 
                     NSLocalizedString( @"Shuffle", @"" ), @"display",
                     @"Song", @"itemType",
                     @"${requestBase}/ctrl-int/1/cue?command=play&query=${filter}&dacp.shufflestate=1&sort=album&session-id=${sessionId}", @"itemPlay",
                     @"0", @"children", nil],
                     nil], nil], @"Album",
                  // Artists
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Artist",
                   // Child play
                   @"",
                   // List command
                   @"${requestBase}/databases/${dbId}/browse/artists?session-id=${sessionId}&include-sort-headers=1&filter=${filter}+'daap.songartist!:'",
                   // Filter
                   @"('com.apple.itunes.mediakind:1','com.apple.itunes.mediakind:32')",
                   // Special menu entries
                   [NSArray arrayWithObjects:
                    // Artists>All Albums
                    [NSDictionary dictionaryWithObjectsAndKeys: 
                     NSLocalizedString( @"All Albums", @"" ), @"display",
                     @"Albums", @"listType",
                     @"Album", @"itemType",
                     @"32767", @"children", nil],
                     nil], nil], @"Artists",
                  // Artist
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Album",
                   // Child play
                   @"",
                   // List command
                   @"${requestBase}/databases/${dbId}/groups?session-id=${sessionId}&meta=dmap.itemname,dmap.itemid,dmap.persistentid,daap.songartist&type=music&group-type=albums&sort=album&include-sort-headers=1&query=${filter}+'daap.songalbum!:'",
                   // Filter
                   @"'daap.songartist:${id}'",
                   // Special menu entries
                   [NSArray arrayWithObjects:
                    // Artist>All Songs
                    [NSDictionary dictionaryWithObjectsAndKeys: 
                     NSLocalizedString( @"All Songs", @"" ), @"display",
                     @"Songs", @"listType",
                     @"Song", @"itemType",
                     @"32767", @"children", nil],
                     nil], nil], @"Artist",
                  // Composers
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Composer",
                   // Child play
                   @"",
                   // List command
                   @"${requestBase}/databases/${dbId}/browse/composers?session-id=${sessionId}&include-sort-headers=1&filter=${filter}+'daap.songcomposer!:'",
                   // Filter
                   @"('com.apple.itunes.mediakind:1','com.apple.itunes.mediakind:32')",
                   // Special menu entries
                   [NSArray arrayWithObjects:
                    // Composers>All Albums
                    [NSDictionary dictionaryWithObjectsAndKeys: 
                     NSLocalizedString( @"All Albums", @"" ), @"display",
                     @"Albums", @"listType",
                     @"Album", @"itemType",
                     @"32767", @"children", nil],
                     nil], nil], @"Composers",
                  // Composer
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Album",
                   // Child play
                   @"",
                   // List command
                   @"${requestBase}/databases/${dbId}/groups?session-id=${sessionId}&meta=dmap.itemname,dmap.itemid,dmap.persistentid,daap.songartist&type=music&group-type=albums&sort=album&include-sort-headers=1&query=${filter}+'daap.songalbum!:'",
                   // Filter
                   @"'daap.songcomposer:${id}'",
                   // Special menu entries
                   [NSArray arrayWithObjects:
                    // Composer>All Songs
                    [NSDictionary dictionaryWithObjectsAndKeys: 
                     NSLocalizedString( @"All Songs", @"" ), @"display",
                     @"Songs", @"listType",
                     @"Song", @"itemType",
                     @"32767", @"children", nil],
                     nil], nil], @"Composer",
                  // Genres
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Genre",
                   // Child play
                   @"",
                   // List command
                   @"${requestBase}/databases/${dbId}/browse/genres?session-id=${sessionId}&include-sort-headers=1&filter=${filter}+'daap.songgenre!:'",
                   // Filter
                   @"('com.apple.itunes.mediakind:1','com.apple.itunes.mediakind:32')",
                   // Special menu entries
                   [NSArray array], nil], @"Genres",
                  // Genre
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Artist",
                   // Child play
                   @"",
                   // List command
                   @"${requestBase}/databases/${dbId}/browse/artists?session-id=${sessionId}&include-sort-headers=1&filter=${filter}+'daap.songartist!:'",
                   // Filter
                   @"'daap.songgenre:${id}'",
                   // Special menu entries
                   [NSArray arrayWithObjects:
                    // Genre>All Albums
                    [NSDictionary dictionaryWithObjectsAndKeys: 
                     NSLocalizedString( @"All Albums", @"" ), @"display",
                     @"Albums", @"listType",
                     @"Album", @"itemType",
                     @"32767", @"children", nil],
                     nil], nil], @"Genre",
                  // Songs
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Song",
                   // Child play
                   @"${requestBase}/ctrl-int/1/cue?command=play&query=${filter}&dacp.shufflestate=0&index=${index}&sort=name&session-id=${sessionId}",
                   // List command
                   @"${requestBase}/databases/${dbId}/containers/${musicId}/items?session-id=${sessionId}&meta=dmap.itemname,dmap.itemid,daap.songartist,daap.songalbum,dmap.containeritemid,com.apple.itunes.has-video&type=music&sort=name&include-sort-headers=1&query=${filter}",
                   // Filter
                   @"('com.apple.itunes.mediakind:1','com.apple.itunes.mediakind:32')",
                   // Special menu entries
                   [NSArray arrayWithObjects:
                    // Shuffle
                    [NSDictionary dictionaryWithObjectsAndKeys: 
                     NSLocalizedString( @"Shuffle", @"" ), @"display",
                     @"Song", @"itemType",
                     @"${requestBase}/ctrl-int/1/cue?command=play&query=${filter}&dacp.shufflestate=1&sort=name&session-id=${sessionId}", @"itemPlay",
                     @"0", @"children", nil],
                     nil], nil], @"Songs",
                  // Playlists
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Playlist",
                   // Child play
                   @"",
                   // List command
                   @"", // None - it is preinitialised
                   // Filter
                   @"",
                   // Special menu entries
                   [NSArray array], nil], @"Playlists",
                  // Playlist
                  [NSArray arrayWithObjects:
                   // Child type
                   @"Song",
                   // Child play
                   @"${requestBase}/ctrl-int/1/playspec?database-spec='dmap.persistentid:${dbPersistId}'&container-spec='dmap.persistentid:${persistId}'&container-item-spec='dmap.containeritemid:${containerItemId}'&session-id=${sessionId}",
                   // List command
                   @"${requestBase}/databases/${dbId}/containers/${id}/items?session-id=${sessionId}&meta=dmap.itemname,dmap.itemid,daap.songartist,daap.songalbum,dmap.containeritemid",
                   // Filter
                   @"",
                   // Special menu entries
                   [NSArray arrayWithObjects:
                    // Shuffle
                    [NSDictionary dictionaryWithObjectsAndKeys: 
                     NSLocalizedString( @"Shuffle", @"" ), @"display",
                     @"Song", @"itemType",
                     @"${requestBase}/ctrl-int/1/playspec?database-spec='dmap.persistentid:${dbPersistId}'&container-spec='dmap.persistentid:${persistId}'&dacp.shufflestate=1&session-id=${sessionId}", @"itemPlay",
                     @"0", @"children", nil],
                    nil], nil], @"Playlist",
                  // Audiobooks
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Audiobook",
                   // Child play
                   @"",
                   // List command
                   @"${requestBase}/databases/${dbId}/groups?session-id=${sessionId}&meta=dmap.itemname,dmap.itemid,dmap.persistentid,daap.songartist&type=music&group-type=albums&sort=album&include-sort-headers=1&query=${filter}+'daap.songalbum!:'",
                   // Filter
                   @"'com.apple.itunes.mediakind:8'",
                   // Special menu entries
                   [NSArray array], nil], @"Audiobooks",
                  // Audiobook
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Chapter",
                   // Child play
                   @"${requestBase}/ctrl-int/1/cue?command=play&query=${filter}&dacp.shufflestate=0&index=${index}&sort=album&session-id=${sessionId}",
                   // List command
                   @"${requestBase}/databases/${dbId}/containers/${musicId}/items?session-id=${sessionId}&meta=dmap.itemname,dmap.itemid,daap.songartist,daap.songalbum,dmap.containeritemid,com.apple.itunes.has-video&type=music&sort=album&query=${filter}",
                   // Filter
                   @"'daap.songalbumid:${persistId}'",
                   // Special menu entries
                   [NSArray array], nil], @"Audiobook",
                  // iTunes U
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"iTunes U Course",
                   // Child play
                   @"",
                   // List command
                   @"${requestBase}/databases/${dbId}/groups?session-id=${sessionId}&meta=dmap.itemname,dmap.itemid,dmap.persistentid,daap.songartist&type=music&group-type=albums&sort=album&include-sort-headers=1&query=${filter}+'daap.songalbum!:'",
                   // Filter
                   @"('com.apple.itunes.mediakind:2097152','com.apple.itunes.mediakind:2097154','com.apple.itunes.mediakind:2097156','com.apple.itunes.mediakind:2097158')",
                   // Special menu entries
                   [NSArray array], nil], @"iTunes U",
                  // iTunes U Course
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Chapter",
                   // Child play
                   @"${requestBase}/ctrl-int/1/cue?command=play&query=${filter}&dacp.shufflestate=0&index=${index}&sort=album&session-id=${sessionId}",
                   // List command
                   @"${requestBase}/databases/${dbId}/containers/${musicId}/items?session-id=${sessionId}&meta=dmap.itemname,dmap.itemid,daap.songartist,daap.songalbum,dmap.containeritemid,com.apple.itunes.has-video&type=music&sort=album&query=${filter}",
                   // Filter
                   @"'daap.songalbumid:${persistId}'",
                   // Special menu entries
                   [NSArray array], nil], @"iTunes U Course",
                  // Podcasts
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Podcast",
                   // Child play
                   @"",
                   // List command
                   @"${requestBase}/databases/${dbId}/groups?session-id=${sessionId}&meta=dmap.itemname,dmap.itemid,dmap.persistentid,daap.songartist&type=music&group-type=albums&sort=album&include-sort-headers=1&query=${filter}+'daap.songalbum!:'",
                   // Filter
                   @"('com.apple.itunes.mediakind:4','com.apple.itunes.mediakind:36','com.apple.itunes.mediakind:6')",
                   // Special menu entries
                   [NSArray array], nil], @"Podcasts",
                  // Podcast
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Podcast episode",
                   // Child play
                   @"${requestBase}/ctrl-int/1/cue?command=play&query=${filter}&dacp.shufflestate=0&index=${index}&sort=album&session-id=${sessionId}",
                   // List command
                   @"${requestBase}/databases/${dbId}/containers/${musicId}/items?session-id=${sessionId}&meta=dmap.itemname,dmap.itemid,daap.songartist,daap.songalbum,dmap.containeritemid,com.apple.itunes.has-video&type=music&sort=album&query=${filter}",
                   // Filter
                   @"'daap.songalbumid:${persistId}'",
                   // Special menu entries
                   [NSArray array], nil], @"Podcast",
                  // Movies
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Movie",
                   // Chid play
                   //@"${requestBase}/ctrl-int/1/playspec?database-spec='dmap.persistentid:${dbPersistId}'&container-spec='dmap.persistentid:${persistId}'&item-spec='dmap.itemid:${containerItemId}'&session-id=${sessionId}",
                   @"${requestBase}/ctrl-int/1/cue?command=play&query=${filter}&index=${index}&sort=name&session-id=${sessionId}",
                   // List command
                   @"${requestBase}/databases/${dbId}/containers/${musicId}/items?session-id=${sessionId}&meta=dmap.itemname,dmap.itemid,daap.songartist,daap.songalbum,dmap.containeritemid,com.apple.itunes.has-video,daap.songtime,com.apple.itunes.content-rating&type=music&sort=name&include-sort-headers=1&query=${filter}",
                   // Filter
                   @"'com.apple.itunes.mediakind:2'",
                   // Special menu entries
                   [NSArray array], nil], @"Movies",
                  // Music Videos
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Music Video",
                   // Child play
                   //@"${requestBase}/ctrl-int/1/playspec?database-spec='dmap.persistentid:${dbPersistId}'&container-spec='dmap.persistentid:${persistId}'&item-spec='dmap.itemid:${containerItemId}'&session-id=${sessionId}",
                   @"${requestBase}/ctrl-int/1/cue?command=play&query=${filter}&index=${index}&sort=name&session-id=${sessionId}",
                   // List command
                   @"${requestBase}/databases/${dbId}/containers/${musicId}/items?session-id=${sessionId}&meta=dmap.itemname,dmap.itemid,daap.songartist,daap.songalbum,dmap.containeritemid,com.apple.itunes.has-video,daap.songtime&type=music&sort=name&include-sort-headers=1&query=${filter}",
                   // Filter
                   @"'com.apple.itunes.mediakind:32'",
                   // Special menu entries
                   [NSArray array], nil], @"Music Videos",
                   // TV Shows
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"TV Show",
                   // Child play
                   //@"${requestBase}/ctrl-int/1/playspec?database-spec='dmap.persistentid:${dbPersistId}'&container-spec='dmap.persistentid:${persistId}'&item-spec='dmap.itemid:${containerItemId}'&session-id=${sessionId}",
                   @"${requestBase}/ctrl-int/1/cue?command=play&query=${filter}&index=${index}&sort=album&invert-sort-order=1&session-id=${sessionId}",
                   // List command
                   @"${requestBase}/databases/${dbId}/containers/${musicId}/items?session-id=${sessionId}&meta=dmap.itemname,dmap.itemid,daap.songartist,daap.songalbum,dmap.containeritemid,com.apple.itunes.has-video,daap.songtime,daap.songhasbeenplayed,daap.songdatereleased,com.apple.itunes.series-name,daap.sortartist,daap.songalbum,com.apple.itunes.season-num,com.apple.itunes.episode-sort,com.apple.itunes.is-hd-video&type=music&sort=album&invert-sort-order=1&query=${filter}",
                   // Filter
                   @"'com.apple.itunes.mediakind:64'",
                   // Special menu entries
                   [NSArray array], nil], @"TV Shows",
                  // Connecting
                  [NSArray arrayWithObjects: 
                   // Child type
                   @"Connecting",
                   // Child play
                   @"",
                   // List command
                   @"",
                   // Filter
                   @"",
                   // Special menu entries
                   [NSArray array], nil], @"Connecting",
                  nil] retain];
  }
  NSArray *data = [TYPE_DATA objectForKey: type];
  
  if (data == nil)
    newTypeData = nil;
  else
    newTypeData = [[NLBrowseListITunesType alloc] initWithName: type data: data session: session parentFilter: parentFilter item: item];
  
  return newTypeData;
}

- (id) initWithName: (NSString *) name data: (NSArray *) data session: (ITSession *) session 
       parentFilter: (NSSet *) parentFilter item: (NSDictionary *) item
{
  if ((self = [super init]) != nil)
  {    
    NSString *filter = [data objectAtIndex: 3];

    _session = [session retain];
    _parameters = [[NSMutableDictionary dictionaryWithDictionary: item] retain];
    _typeData = [data retain];
    
    if ([filter length] == 0)
      _filter = parentFilter;
    else
    {
      filter = [self replaceParametersInString: filter parameters: nil];
      if (parentFilter == nil)
        _filter = [NSSet setWithObject: filter];
      else
      {
        NSMutableSet *filters = [NSMutableSet setWithSet: parentFilter];
      
        [filters addObject: filter];
        _filter = filters;
      }
    }
    [_filter retain];
    if ([_filter count] == 0)
      filter = @"";
    else
      filter = [[_filter allObjects] componentsJoinedByString: @"+"];
    [_parameters setObject: filter forKey: @"filter"];

    if ([self isLeafType])
      _name = [name retain];
    else
      _name = [[data objectAtIndex: 0] retain];
  }

  return self;
}

- (NSArray *) specialItems
{
  return [_typeData objectAtIndex: 4];
}

- (NSString *) listItemsCommand
{
  return [self replaceParametersInSessionString: [_typeData objectAtIndex: 2] parameters: nil];
}

- (NSString *) selectCommandForChildIndex: (NSUInteger) index inItems: (NSArray *) items
{
  NSString *cmd;

  if (![self isLeafType])
    cmd = nil;
  else
  {
    NSArray *specialItems = [_typeData objectAtIndex: 4];
    NSUInteger specialCount = [specialItems count];
    
    if ([items count] < 2)
      specialCount = 0;

    if (index < specialCount)
      cmd = [self replaceParametersInSessionString: [[specialItems objectAtIndex: index] objectForKey: @"itemPlay"]
                                        parameters: nil];
    else
    {
      NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary: [items objectAtIndex: index]];
      
      [parameters setObject: [NSString stringWithFormat: @"%u", index - specialCount] forKey: @"index"];
      cmd = [self replaceParametersInSessionString: [_typeData objectAtIndex: 1] parameters: parameters];
    }
  }

  return cmd;
}

- (BOOL) isLeafType
{
  return ([TYPE_DATA objectForKey: [_typeData objectAtIndex: 0]] == nil);
}

- (NLBrowseListITunesType *) allocTypeForChildIndex: (NSUInteger) index inItems: (NSArray *) items
{
  NLBrowseListITunesType *childList;
  
  if ([self isLeafType])
    childList = nil;
  else
  {
    NSArray *specialItems = [_typeData objectAtIndex: 4];
    NSUInteger specialCount = [specialItems count];
    NSString *type;
    
    if ([items count] < 2)
      specialCount = 0;
    
    if (index < specialCount)
      type = [[specialItems objectAtIndex: index] objectForKey: @"listType"];
    else
      type = [_typeData objectAtIndex: 0];
    
    childList = [NLBrowseListITunesType allocTypeDataForType: type session: _session
                                                 parentFilter: _filter item: [items objectAtIndex: index]];
  }

  return childList;
}

- (NSString *) replaceParametersInString: (NSString *) string parameters: (NSDictionary *) parameters
{
  NSMutableDictionary *allParams;

  if (parameters == nil)
    allParams = _parameters;
  else
  {
    allParams = [NSMutableDictionary dictionaryWithDictionary: _parameters];
    [allParams addEntriesFromDictionary: parameters];
  }

  for (NSString *parameter in [allParams allKeys])
  {
    string = [string stringByReplacingOccurrencesOfString: 
              [NSString stringWithFormat: @"${%@}", parameter] withString: [allParams objectForKey: parameter]];
  }

  return string;
}

- (NSString *) replaceParametersInSessionString: (NSString *) string parameters: (NSDictionary *) parameters
{
  if (![_session isConnected])
    string = @"";
  else
  {
    NSMutableDictionary *allParams = [NSMutableDictionary dictionaryWithCapacity: [parameters count] + 5];
    
    if (parameters != nil)
      [allParams addEntriesFromDictionary: parameters];
  
    [allParams setObject: [_session getRequestBase] forKey: @"requestBase"];
    [allParams setObject: _session.databaseId forKey: @"dbId"];
    [allParams setObject: _session.databasePersistentId forKey: @"dbPersistId"];
    [allParams setObject: _session.musicId forKey: @"musicId"];
    [allParams setObject: _session.sessionId forKey: @"sessionId"];
    string = [self replaceParametersInString: string parameters: allParams];
  }

  return string;
}


- (void) dealloc
{
  [_session release];
  [_name release];
  [_filter release];
  [_typeData release];
  [_parameters release];
  [super dealloc];
}

@end
