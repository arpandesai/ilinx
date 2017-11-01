//
//  NLBrowseListNetStreams.m
//  iLinX
//
//  Created by mcf on 19/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLBrowseListNetStreams.h"
#import "NLSource.h"
#import "NLSourceMediaServer.h"
#import "NLSourceTuner.h"
#import "DebugTracing.h"

#define _pcomms NETSTREAMSCOMMS_PRODUCTION_ONLY(_netStreamsComms)

#if defined(DEBUG)
// Set to 1 to log queries from table view into here for list details
#  define LOG_LIST_QUERIES 0
#endif

// Time to wait for choice of A-Z index to settle before fetching the relevant page
#define A_Z_SETTLE_TIME 0.4

#define LIST_TYPE_SORTED                             0x000
#define LIST_TYPE_SORTED_WITH_SECTIONS               0x001
#define LIST_TYPE_UNSORTED                           0x002

#define LIST_TYPE_FLAG_ALL_SONGS                     0x080
#define LIST_TYPE_SORTED_AND_ALL_SONGS               0x080
#define LIST_TYPE_SORTED_WITH_SECTIONS_AND_ALL_SONGS 0x081
#define LIST_TYPE_UNSORTED_AND_ALL_SONGS             0x082

// Number of items to store in each block of items fetched
#define REQUEST_BLOCK_POWER_OF_2 4
#define REQUEST_BLOCK_SIZE (1<<(REQUEST_BLOCK_POWER_OF_2))
// Maximum number of items to fetch in a single MENU_LIST request
#define REQUEST_MAX_ITEMS_VTUNER 4
#define REQUEST_MAX_ITEMS 8

#define UNDETERMINED_OFFSET (NSUIntegerMax - 1)
#define PENDING_OFFSET      (NSUIntegerMax - 2)
#define TEMP_SCROLL_OFFSET  (NSUIntegerMax - 3)
#define NO_CONTENT_OFFSET   (NSUIntegerMax - 4)

static unichar LetterForString( NSString *string );

static NSArray *EMPTY_ARRAY = nil;
static NSString **FIRST_LETTERS = nil;
static NSString *ITEM_TYPE_SONG = @"Song";
static NSSet *CANNOT_SELECT_WITH_NO_CHILDREN = nil;

NS_INLINE NSString *ItemTitle( NSDictionary *item )
{
  NSString *initialised = [item objectForKey: @"initialized"];
  
  if (initialised != nil && [initialised isEqualToString: @"0"])
    return [NSString stringWithFormat: @"%@%@",
            [item objectForKey: @"display"],
            NSLocalizedString( @" (Uninitialized)", @"Suffix for list item that has not been initialised" )];
  else
    return [item objectForKey: @"display"];
}

NSString *SortCompareTitle( NSDictionary *item, BOOL *pThePrefix )
{
  NSString *title = ItemTitle( item );
  NSUInteger len = [title length];
  
  if (len == 0)
    *pThePrefix = NO;
  else if (len < 4 || [[title substringToIndex: 4]
                       compare: @"the " 
                       options: NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch|NSWidthInsensitiveSearch] != NSOrderedSame)
  {
    *pThePrefix = NO;
    title = [title substringToIndex: 1];
  }
  else
  {
    *pThePrefix = YES;
    title = [title substringWithRange: NSMakeRange( 4, 1 )];
  }
  
  return title;
}

NS_INLINE NSString *StringForLetter( unichar c )
{
  if (c == 0)
    return nil;
  else if (c == 65535)
    return @"";
  else if (c >= 'A' && c <= 'Z')
    return FIRST_LETTERS[c - 'A'];
  else
    return @"#";
}

@interface NLBrowseListNetStreams ()

- (void) doRefresh;
- (BOOL) updateSectionDataForPrefix: (unichar) prefix offset: (NSUInteger) offset;
- (void) handleAlphaPositionMessage: (NSDictionary *) data forRequest: (DataRequest *) currentRequest;
- (void) clearPendingRequestsBeyond: (NSUInteger) listLength;
- (void) clearAllPendingMessages;
- (void) indexRequestDelayTimerFired: (NSTimer *) timer;
- (void) sendAlphaRequestForLetter: (unichar) c;
- (void) checkBlockForAlphaSorting: (NSUInteger) index;
- (void) processNewMetadata: (NSDictionary *) metadata;

@end

@implementation DataRequest

@synthesize
isAlphaRequest = _isAlphaRequest,
range = _range,
subBlockSize = _subBlockSize,
remaining = _remaining,
pending = _pending,
changed = _changed;

+ (DataRequest *) dataRequestWithRange: (NSRange) range subBlockSize: (NSUInteger) subBlockSize
{
  DataRequest *request = [[DataRequest new] autorelease];
  
  request.isAlphaRequest = NO;
  request.range = range;
  request.subBlockSize = subBlockSize;
  request.remaining = range.length;
  request.pending = 0;
  request.changed = NO;
  
  return request;
}

+ (DataRequest *) dataRequestForLetter: (unichar) letter
{
  DataRequest *request = [[DataRequest new] autorelease];
  
  request.isAlphaRequest = YES;
  request.range = NSMakeRange( letter, 0 );
  request.subBlockSize = 1;
  request.remaining = request.range.length;
  request.pending = 0;
  request.changed = NO;
  
  return request;
}

@end

@interface NSArray (NLBrowseListing) 

- (NSString *) listRequests;

@end

@implementation NSArray (NLBrowseListing)

- (NSString *) listRequests
{
  NSString *result = nil;

  for (DataRequest *request in self)
  {
    if (result == nil)
      result = [NSString stringWithFormat: @"%u", request.range.location];
    else
      result = [result stringByAppendingFormat: @", %u", request.range.location];
  }

  return (result == nil)?@"":result;
}

@end

@interface SectionData : NSObject
{
  unichar _prefix;
  NSUInteger _offset;
  NSString *_prefixString;
}

@property (assign) unichar prefix;
@property (assign) NSUInteger offset;
@property (readonly) NSString *prefixString;

+ (id) sectionDataWithPrefix: (unichar) prefix offset: (NSUInteger) offset;

@end

@implementation SectionData

@synthesize
prefix = _prefix,
offset = _offset;

+ (id) sectionDataWithPrefix: (unichar) prefix offset: (NSUInteger) offset
{
  SectionData *data = [[SectionData new] autorelease];
  
  data.prefix = prefix;
  data.offset = offset;
  
  return data;
}

- (NSString *) prefixString
{
  if (_prefixString == nil && _prefix != 0)
    _prefixString = [StringForLetter( _prefix ) retain];
  
  return _prefixString;
}

- (NSComparisonResult) compare: (SectionData *) other
{
  if (_prefix < other.prefix)
    return NSOrderedAscending;
  else if (_prefix > other.prefix)
    return NSOrderedDescending;
  else
    return NSOrderedSame;
}

- (NSString *) description
{
  return [[super description] stringByAppendingFormat: @" %@: %d", _prefixString, _offset];
}

- (void) dealloc
{
  [_prefixString release];
  [super dealloc];
}

@end

@interface NaimVersionHandler : NSObject <NSStreamDelegate>
{
  NLBrowseListNetStreams *_delegate;
  NSDictionary *_metadata;
  CFReadStreamRef _rStream;
  CFWriteStreamRef _wStream;
  NSInputStream *_iStream;
  NSOutputStream *_oStream;
  NSMutableData *_data;
  BOOL _requested;
}

- (id) initWithMetadata: (NSDictionary *) metadata delegate: (NLBrowseListNetStreams *) delegate;
- (void) getVersion;
- (void) disconnect;

@end

@implementation NaimVersionHandler

- (id) initWithMetadata: (NSDictionary *) metadata delegate: (NLBrowseListNetStreams *) delegate
{
  if ((self = [super init]) != nil)
  {
    _delegate = delegate;
    _metadata = [metadata retain];
    _data = [[NSMutableData alloc] init];
  }
  
  return self;
}

- (void) getVersion
{
  NSString *prefix = [_metadata objectForKey: @"A1"];
  NSRange addrStart = [prefix rangeOfString: @"://"];
  
  if (addrStart.length > 0)
  {
    prefix = [prefix substringFromIndex: NSMaxRange( addrStart )];
    
    NSRange addrEnd = [prefix rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString: @":/"]];
    
    if (addrEnd.length > 0)
    {
      prefix = [prefix substringToIndex: addrEnd.location];
      CFStreamCreatePairWithSocketToHost( kCFAllocatorDefault, (CFStringRef) prefix, 2921, &_rStream, &_wStream );
      
      if (_rStream != NULL && _wStream != NULL)
      {
        CFReadStreamSetProperty( _rStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue );
        CFWriteStreamSetProperty( _wStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue );
        _iStream = [(NSInputStream *) _rStream retain];
        _oStream = [(NSOutputStream *) _wStream retain];
        [_iStream setDelegate: self];
        [_oStream setDelegate: self];
        [_iStream scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
        [_iStream open];
        [_oStream scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
        [_oStream open];
      }
    }
  }
}

- (void) stream: (NSStream *) stream handleEvent: (NSStreamEvent) eventCode
{
  switch (eventCode)
  {
    case NSStreamEventHasSpaceAvailable:
      if (stream == _oStream && !_requested)
      {
        _requested = YES;
        [_oStream write: (const uint8_t *) "[Version]\r\n" maxLength: 11];
      }
      break;
    case NSStreamEventHasBytesAvailable:
    {
      uint8_t buf[1024];
      unsigned int len = [_iStream read: buf maxLength: sizeof(buf)];
      
      if (len > 0)
      {
        // Looking for [ACK Version "servicever" "protocolver" "commandsver" "systemver"]
        // from which we need to extract systemver.
        [_data appendBytes: buf length: len];
        NSString *response = [[[NSString alloc] initWithData: _data encoding: NSASCIIStringEncoding] autorelease];
        NSRange r = [response rangeOfString: @"[ACK Version"];
        
        if (r.length > 0)
        {
          response = [response substringFromIndex: NSMaxRange( r )];
          r = [response rangeOfString: @"]"];
          if (r.length > 0)
          {
            response = [response substringToIndex: r.location];
            r = [response rangeOfString: @"\"" options: NSBackwardsSearch];
            if (r.length > 0)
            {
              response = [response substringToIndex: r.location];
              r = [response rangeOfString: @"\"" options: NSBackwardsSearch];
              if (r.length > 0)
              {
                response = [response substringFromIndex: r.location + 1];
                NSArray *parts = [response componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"._ "]];
                
                if ([parts count] >= 2)
                {
                  int major = [[parts objectAtIndex: 0] intValue];
                  int minor = [[parts objectAtIndex: 1] intValue];
                  NSMutableDictionary *newMetadata;
                  
                  if ([_metadata isKindOfClass: [NSMutableDictionary class]])
                    newMetadata = (NSMutableDictionary *) _metadata;
                  else
                  {
                    newMetadata = [[NSMutableDictionary alloc] initWithDictionary: _metadata];
                    [_metadata release];
                    _metadata = newMetadata;
                  }

                  if (major <= 1 && (major != 1 || minor <= 6))
                  {
                    // Pre-v1.7 server onwards with old Naimnet.lua driver.  We need to create an A4 metadata
                    // item that is identical to A2 to correspond to a hack elsewhere in this file where A2s
                    // for album thumbnails are changed to A4s.
                    [newMetadata setObject: [_metadata objectForKey: @"A2"] forKey: @"A4"];
                  }
                  else
                  {
                    // v1.7 server onwards but with old Naimnet.lua driver.  We need to hack A2 metadata to
                    // add keytype=track and add A4 keytype=album
                    [newMetadata setObject: [[_metadata objectForKey: @"A2"] 
                                             stringByAppendingString: @"&keytype=album"] forKey: @"A4"];
                    [newMetadata setObject: [[_metadata objectForKey: @"A2"] 
                                             stringByAppendingString: @"&keytype=track"] forKey: @"A2"];
                  }
                  [_data setLength: 0];
                }
              }
            }
            
            // Got here means we've had the full reply, so disconnect now
            [self disconnect];
          }
        }
      }
      break;
    }
    case NSStreamEventErrorOccurred:
    case NSStreamEventEndEncountered:
      [self disconnect];
      break;
    default:
      break;
  }
}

- (void) disconnect
{
  if (_iStream != nil)
  {
    [_iStream removeFromRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
    [_oStream removeFromRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
    [_iStream close];
    [_oStream close];
    [_iStream release];
    [_oStream release];
    _iStream = nil;
    _oStream = nil;
  }
  
  [_delegate processNewMetadata: _metadata];
}

- (void) dealloc
{
  [self disconnect];
  
  [_metadata release];
  [_data release];
  if (_rStream != NULL)
    CFRelease( _rStream );
  if (_wStream != NULL)
    CFRelease( _wStream );
  [super dealloc];
}

@end

@implementation NLBrowseListNetStreams

@synthesize
  lastKey = _lastKey;

+ (NSArray *) emptyBlock
{
  return EMPTY_ARRAY;
}

- (void) reinit
{
  unichar c;
  
#if defined(DEBUG)
  //**/NSLog( @"%@ (%@): Reinit", self, _rootPath );
#endif
  
  _indexedSections = 0;
  [_content release];
  _content = [NSMutableDictionary new];
  //**/NSLog( @"%@ (%@): All blocks discarded", self, _rootPath );
  [_sectionData release];
  _sectionData = [[NSMutableArray arrayWithCapacity: 29] retain];
  [_sectionData addObject: [SectionData sectionDataWithPrefix: 0 offset: 0]];
  [_sectionData addObject: [SectionData sectionDataWithPrefix: '#' offset: 0]];
  for (c = 'A'; c <= 'Z'; ++c)
    [_sectionData addObject: [SectionData sectionDataWithPrefix: c offset: UNDETERMINED_OFFSET]];
  
  _listType = LIST_TYPE_SORTED;
  
  if (_addAllSongs == ADD_ALL_SONGS_YES)
  {
    _listType |= LIST_TYPE_FLAG_ALL_SONGS;
    _listOffset = -1;
    if (_originalCount == NSUIntegerMax)
      _count = NSUIntegerMax;
    else
      _count = _originalCount + 2;
    ((SectionData *) [_sectionData objectAtIndex: 1]).offset = 2;
  }
  else
  {
    _listOffset = 1;
    _count = _originalCount;
  }
  
  [_sectionData addObject: [SectionData sectionDataWithPrefix: 65535 offset: _count]];
  [self clearAllPendingMessages];
  [_pendingRequests release];
  _pendingRequests = [[NSMutableArray arrayWithCapacity: 28] retain];
#if RESET_CURRENT_INDEX
  _currentIndex = 0;
#endif
  self.lastKey = nil;
}

- (id) initWithSource: (NLSource *) source title: (NSString *) title
                 path: (NSString *) rootPath listCount: (NSUInteger) count
          addAllSongs: (NSUInteger) addAllSongs comms: (NetStreamsComms *) comms
{
  if ((self = [super initWithSource: source title: title]) != nil)
  {
    NSArray *pathComponents = [rootPath componentsSeparatedByString: @">"];
    BOOL isPlayQueue = [title isEqualToString: @"Current Play Queue"];
    unichar c;
    
    if (EMPTY_ARRAY == nil)
    {
      EMPTY_ARRAY = [[NSArray arrayWithObjects:
                      [NSDictionary dictionary], [NSDictionary dictionary], [NSDictionary dictionary], [NSDictionary dictionary], 
                      [NSDictionary dictionary], [NSDictionary dictionary], [NSDictionary dictionary], [NSDictionary dictionary], 
                      [NSDictionary dictionary], [NSDictionary dictionary], [NSDictionary dictionary], [NSDictionary dictionary], 
                      [NSDictionary dictionary], [NSDictionary dictionary], [NSDictionary dictionary], [NSDictionary dictionary], 
                      nil] retain];
      FIRST_LETTERS = (NSString **) malloc( sizeof(NSString *) * 26 );
      for (c = 'A'; c <= 'Z'; ++c)
        FIRST_LETTERS[c - 'A'] = [[NSString stringWithCharacters: &c length: 1] retain];
      CANNOT_SELECT_WITH_NO_CHILDREN = [[NSSet setWithObjects: @"Album", @"Albums", @"Artist", @"Artists", @"Composer", @"Composers",
                                         @"Conductor", @"Conductors", @"Device", @"Devices", @"Genre", @"Genres", 
                                         @"Playlist", @"Playlists", @"Server", @"Servers", @"Share", @"Shares", nil] retain];
    }
    _rootPath = [rootPath retain];
    _netStreamsComms = [comms retain];
    _menuRspHandle = nil;
    _currentMessageHandle = nil;
    _originalCount = count;
    _menuLevel = [pathComponents count] - 1;
    if ([rootPath isEqualToString: @"presets"])
      ++_menuLevel;
    else if ([source isKindOfClass: [NLSourceMediaServer class]])
    {
      if (!([rootPath hasPrefix: @"media>Shares"] || [rootPath hasPrefix: @"media>Network Music"] ||
            [rootPath hasPrefix: @"media>Devices"] || [rootPath hasPrefix: @"media>USB Music"]))
      {
        if ([rootPath hasPrefix: @"media>Server"] || [rootPath hasPrefix: @"media>CD Collection"])
          ++_menuLevel;
        else
          _menuLevel += 2;
      }
    }
    
    if (_menuLevel == 0 || _menuLevel == 2)
      _itemType = nil;
    else if (_menuLevel == 1 || _menuLevel == 3)
    {
      if ([title isEqualToString: @"Song"])
        _itemType = [@"Songs" retain];
      else
        _itemType = [title retain];
    }
    else
      _itemType = [@"Albums" retain];
    
    _addAllSongs = addAllSongs;
    _isVTuner = [source.sourceType isEqualToString: @"VTUNER"];
    if (_addAllSongs == ADD_ALL_SONGS_YES && 
        (count == 0 || ((_menuLevel == 1 || _menuLevel == 3) && 
                        (isPlayQueue || [title isEqualToString: @"Quick Play"]))))
      _addAllSongs = ADD_ALL_SONGS_CHILDREN_ONLY;
    
    [self reinit];
    if (isPlayQueue)
      _listType = LIST_TYPE_UNSORTED;
  }
  
  return self;
}

- (NSUInteger) countOfSections
{
  NSUInteger count = [_sectionData count];
  
  // This routine is called on table refresh.  That in turn happens when our data has changed.
  // So, take this opportunity to check whether we are still sorted
  
  if ((_listType & LIST_TYPE_SORTED_WITH_SECTIONS) == 0)
  {
    if ((_listType & LIST_TYPE_FLAG_ALL_SONGS) != 0)
      count = 2;
    else
      count = 1;
  }
  
#if LOG_LIST_QUERIES
  NSLog( [NSString stringWithFormat: @"%@ (%@): countOfSections -> %u", self, _rootPath, count] );
#endif
  
  return count;
}

- (NSString *) titleForSection: (NSUInteger) section
{
  NSString *retValue;
  NSUInteger sectionCount = [_sectionData count];
  
  if ((_listType & LIST_TYPE_SORTED_WITH_SECTIONS) == 0 || section >= sectionCount - 1)
    retValue = @"";
  else
  {
    SectionData *thisSection = [_sectionData objectAtIndex: section];
    
    if (thisSection.offset != NO_CONTENT_OFFSET && thisSection.offset != UNDETERMINED_OFFSET)
      retValue = thisSection.prefixString;
    else
      retValue = @"";
  }
  
#if LOG_LIST_QUERIES
  NSLog( [NSString stringWithFormat: @"%@ (%@): titleForSection: %u -> %@", self, _rootPath, section, retValue] );
#endif
  
  return retValue;
}

- (NSUInteger) sectionForPrefix: (NSString *) prefix
{
  NSUInteger section;
  
  if (prefix == nil)
    section = 0;
  else if ((_listType & LIST_TYPE_SORTED_WITH_SECTIONS) == 0)
    section = 1;
  else
  {
    unichar c = LetterForString( prefix );
    
    if (c == '#')
      section = 1;
    else
    {
      section = (c - 'A') + 2;
      
      // If we've not yet located this section, ensure that its location request is moved
      // to the head of the queue
      if ((_indexedSections & (1 << (c - 'A'))) == 0)
      {
        NSUInteger count = [_pendingRequests count];
        NSUInteger i;
        
        for (i = 0; i < count; ++i)
        {
          DataRequest *request = [_pendingRequests objectAtIndex: i];
          
          if (request.isAlphaRequest && request.range.location == c)
          {
            if (i > 1)
            {
              [request retain];
              [_pendingRequests removeObjectAtIndex: i];
              [_pendingRequests insertObject: request atIndex: 1];
              [request release];
              //**/NSLog( @"%@ (%@): pendingRequests modified by titleForSection: %@", self, _rootPath, [_pendingRequests listRequests] );
            }
            break;
          }
        }
        
        if (i == count)
        {
          SectionData *sectionData = [_sectionData objectAtIndex: section];
          
          [_indexRequestDelayTimer invalidate];
          _indexRequestDelayTimer = [NSTimer scheduledTimerWithTimeInterval: A_Z_SETTLE_TIME
                                                                     target: self
                                                                   selector: @selector(indexRequestDelayTimerFired:) 
                                                                   userInfo: [NSNumber numberWithInteger: c] repeats: NO];
          
          if (sectionData.offset == UNDETERMINED_OFFSET)
          {
            sectionData.offset = TEMP_SCROLL_OFFSET;
            NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
            NSEnumerator *enumerator = [delegates objectEnumerator];
            id<ListDataDelegate> delegate;
            NSRange allItems = NSMakeRange( 0, _count );
            
            while ((delegate = [enumerator nextObject]))
            {
              if ([delegate respondsToSelector: @selector(itemsChangedInListData:range:)])
                [delegate itemsChangedInListData: self range: allItems];
            }
          }
        }
      }
    }
  }
  
  
#if LOG_LIST_QUERIES
  NSLog( [NSString stringWithFormat: @"%@ (%@): sectionForPrefix: %@ -> %u", self, _rootPath, prefix, section] );
#endif
  
  return section;
}

- (NSUInteger) countOfListInSection: (NSUInteger) section
{
  NSUInteger sectionCount = [_sectionData count];
  NSUInteger count;
  
  if ((_listType & LIST_TYPE_SORTED_WITH_SECTIONS) == 0)
  {
    if (section == 0)
    {
      if ((_listType & LIST_TYPE_FLAG_ALL_SONGS) != 0)
        count = 2;
      else if (_count == NSUIntegerMax)
        count = ((_highestIndexSoFar / REQUEST_BLOCK_SIZE) * REQUEST_BLOCK_SIZE) + REQUEST_BLOCK_SIZE; 
      else
        count = _count;
    }
    else if (section == 1)
    {
      if ((_listType & LIST_TYPE_FLAG_ALL_SONGS) == 0)
        count = 0;
      else if (_count == NSUIntegerMax)
        count = ((_highestIndexSoFar / REQUEST_BLOCK_SIZE) * REQUEST_BLOCK_SIZE) + REQUEST_BLOCK_SIZE;
      else
        count = _count - 2;
    }
    else
      count = 0;
  }
  else
  {
    if (section >= sectionCount - 1)
      count = 0;
    else
    {
      NSUInteger thisSectionOffset = ((SectionData *) [_sectionData objectAtIndex: section]).offset;
      
      if (thisSectionOffset == UNDETERMINED_OFFSET || thisSectionOffset == NO_CONTENT_OFFSET)
        count = 0;
      else if (thisSectionOffset == PENDING_OFFSET || thisSectionOffset == TEMP_SCROLL_OFFSET)
        count = 10;
      else
      {
        NSUInteger nextSectionIndex = section;
        NSUInteger nextSectionOffset;
        
        do
        {
          ++nextSectionIndex;
          nextSectionOffset = ((SectionData *) [_sectionData objectAtIndex: nextSectionIndex]).offset;
        }
        while (nextSectionOffset >= NO_CONTENT_OFFSET && nextSectionOffset != NSUIntegerMax);
        
        if (_count == NSUIntegerMax)
        {
          if (nextSectionOffset >= NO_CONTENT_OFFSET)
            nextSectionOffset = ((_highestIndexSoFar / REQUEST_BLOCK_SIZE) * REQUEST_BLOCK_SIZE) + REQUEST_BLOCK_SIZE;
        }
        else
        {
          if (nextSectionOffset > _count)
            nextSectionOffset = _count;
        }
        count = nextSectionOffset - thisSectionOffset;
      }
    }
  }
  
#if LOG_LIST_QUERIES
  NSLog( [NSString stringWithFormat: @"%@ (%@): countOfListInSection: %u -> %u (%d)", self,
          _rootPath, section, count, ((SectionData *) [_sectionData objectAtIndex: section]).offset] );
#endif
  
  return count;
}

- (BOOL) dataPending
{
  NSUInteger count = [_pendingRequests count];
  
#if LOG_LIST_QUERIES
  NSLog( [NSString stringWithFormat: @"%@ (%@): dataPending( %u, %s ) -> %s", self, _rootPath, count,
          (_indexRequestDelayTimer != nil)?"YES":"NO",
          (_indexRequestDelayTimer != nil || !(count == 0 ||
                                               (count == 1 && ((DataRequest *) [_pendingRequests objectAtIndex: 0]).remaining == 0)))?"YES":"NO"] );
#endif
  
  return (_indexRequestDelayTimer != nil || !(count == 0 ||
                                              (count == 1 && ((DataRequest *) [_pendingRequests objectAtIndex: 0]).remaining == 0)));
}

- (NSUInteger) convertFromOffset: (NSUInteger) index inSection: (NSUInteger) section
{
  NSUInteger newIndex;
  
  if ((_listType & LIST_TYPE_SORTED_WITH_SECTIONS) == 0)
  {
    if (section == 0)
      newIndex = index;
    else if (section == 1 && ((_listType & LIST_TYPE_FLAG_ALL_SONGS) != 0))
      newIndex = index + 2;
    else if (_count == NSUIntegerMax)
      newIndex = NSUIntegerMax - 32 + (index % 32);
    else
      newIndex = _count + index;
  }
  else
  {
    if (section >= [_sectionData count])
      newIndex = _count;
    else
    {
      newIndex = ((SectionData *) [_sectionData objectAtIndex: section]).offset;
      while (newIndex >= NO_CONTENT_OFFSET && ++section < [_sectionData count])
        newIndex = ((SectionData *) [_sectionData objectAtIndex: section]).offset;
      
      if (newIndex < NO_CONTENT_OFFSET && newIndex <= _count)
        newIndex += index;
      else if (_count == NSUIntegerMax)
        newIndex = NSUIntegerMax - 32 + (newIndex % 32);
      else
        newIndex = _count + index;
    }
  }
  
  return newIndex;
}

- (NSIndexPath *) indexPathFromIndex: (NSUInteger) index
{
  NSIndexPath *result;

  if ((_listType & LIST_TYPE_SORTED_WITH_SECTIONS) == 0)
  {
    if ((_listType & LIST_TYPE_FLAG_ALL_SONGS) == 0 || index < 2)
      result = [NSIndexPath indexPathForRow: index inSection: 0];
    else
      result = [NSIndexPath indexPathForRow: index - 2 inSection: 1];
  }
  else
  {
    NSUInteger lastSection = 0;
    NSUInteger lastOffset = 0;
    NSUInteger offsetCount = [_sectionData count];
    NSUInteger section;
    
    for (section = 1; section < offsetCount; ++section)
    {
      NSUInteger offset = ((SectionData *) [_sectionData objectAtIndex: section]).offset;
      
      if (offset < NO_CONTENT_OFFSET)
      {
        if (index < offset)
          break;
        else
        {
          lastSection = section;
          lastOffset = offset;
        }
      }
    }
    
    result = [NSIndexPath indexPathForRow: index - lastOffset inSection: lastSection];
  }
  
  return result;
}

- (NSString *) pendingMessage
{
  return _noItemsCaption;
}

- (void) source: (NLSourceMediaServer *) source stateChanged: (NSUInteger) flags
{
  if ((flags & SOURCE_MEDIA_SERVER_LIBRARY_CHANGED) != 0 ||
      ((flags & SOURCE_MEDIA_SERVER_PLAY_QUEUE_CHANGED) != 0 && 
       [_title isEqualToString: @"Current Play Queue"]))
    [self refresh];
  else if ((flags & SOURCE_MEDIA_SERVER_METADATA_CHANGED) != 0)
    [self processNewMetadata: [source metadata]];
}

- (void) setServerToThisContext
{
  //if ([[_source controlType] isEqualToString: @"NS_ANTHOLOGY"])
  //  [self sendAlphaRequestForLetter: 'T'];
}

- (void) dealloc
{
  if (_currentMessageHandle != nil)
  {
    //**/NSLog( @"%@ (%@): Cancel send every 3", self, _rootPath );
    [_netStreamsComms cancelSendEvery: _currentMessageHandle];
  }
  if (_menuRspHandle != nil)
  {
    //**/NSLog( @"%@ (%@): Deregister 1", self, _rootPath );
    [_netStreamsComms deregisterDelegate: _menuRspHandle];
  }
  [_indexRequestDelayTimer invalidate];
  [_rootPath release];
  [_netStreamsComms release];
  [_content release];
  [_sectionData release];
  [_pendingRequests release];
  [_bogusResponse release];
  [_lastKey release];
  [_noItemsCaption release];
  [_naimVersionHandler release];
  if (_metadataTimer != nil)
  {
    [_metadataTimer invalidate];
    [_metadataTimer release];
    
    // Reset to unknown as we haven't received the response needed to initialise it correctly
    [_source setMetadata: nil];
  }
  [super dealloc];
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
  if ([_pendingRequests count] == 0)
    [self doRefresh];
  else
    _doRefreshWhenRequestComplete = YES;
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
  
  [self reinit];
  if ([_listDataDelegates count] > 0)
    [self registerForData];
  
  delegates = [NSSet setWithSet: _listDataDelegates];
  enumerator = [delegates objectEnumerator];
  
  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(listDataRefreshDidEnd:)])
      [delegate listDataRefreshDidEnd: self];
  }
}

- (BOOL) refreshIsComplete
{
  return YES;
}

- (id) itemAtIndex: (NSUInteger) index
{
  if (index >= _count)
    return nil;
  else
  {
    NSArray *block = [self blockForIndex: index];
    
    return [block objectAtIndex: index % REQUEST_BLOCK_SIZE];
  }
}

- (NSString *) titleForItemAtIndex: (NSUInteger) index
{
  return ItemTitle( [self itemAtIndex: index] );
}

- (id<ListDataSource>) selectItemAtIndex: (NSUInteger) index executeAction: (BOOL) executeAction
{
  NSDictionary *item = [self itemAtIndex: index];
  NSDictionary *oldItem = [self listDataCurrentItem];
  NSString *childCount = [item objectForKey: @"children"];
  id<ListDataSource> retValue;
  
  _currentIndex = index;

  if (childCount == nil)
    retValue = nil;
  else if (!([childCount isEqualToString: @"0"] || [[item objectForKey: @"responseType"] isEqualToString: @"song"]))
    retValue = [self browseListForItemAtIndex: index];
  else
  {
    NSArray *actions = [item objectForKey: @"mp-ns-actions"];
    
    if (actions != nil)
    {
      if (executeAction)
      {
        NSUInteger i;
      
        for (i = 0; i < [actions count]; ++i)
          [_pcomms send: [actions objectAtIndex: i] to: _source.serviceName];
      }
      retValue = nil;
    }
    else
    {
      NSString *path = [item objectForKey: @"idpath"];
      NSString *itemType = _itemType;
      
      if (itemType == nil)
        itemType = ItemTitle( item );
      
      if (path == nil)
        path = [item objectForKey: @"id"];
      else
        path = [NSString stringWithFormat: @"%@>%@", path, [item objectForKey: @"id"]];
      
      if (path == nil || [CANNOT_SELECT_WITH_NO_CHILDREN containsObject: itemType])
        retValue = self;
      else
      {
        if (executeAction)
          [_pcomms send: [NSString stringWithFormat: @"MENU_SEL {{%@}}", path] to: _source.serviceName];
        retValue = nil;
      }
    }
    
    // Nasty hack time!
    if ([_rootPath isEqualToString: @"presets"] && [_source respondsToSelector: @selector(ifNoFeedbackSetCaption:)])
      [(id) _source ifNoFeedbackSetCaption: [self titleForItemAtIndex: index]];
  }
  
  NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<ListDataDelegate> delegate;
  
  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(currentItemForListData:changedFrom:to:at:)])
      [delegate currentItemForListData: self changedFrom: oldItem to: item at: index];
  }

  return retValue;
}

- (NLBrowseList *) browseListForItemAtIndex: (NSUInteger) index
{
  NLBrowseList *retValue;
  NSDictionary *item = [self itemAtIndex: index];
  NSString *path;
  NSInteger iChildren = [[item objectForKey: @"children"] integerValue];
  NSUInteger children;
  NSUInteger addAllSongs;
  
  // XiVA and vTuner "feature" - returns child count of >= 32767 when it's too lazy to figure out
  // how many children there really are
  if (iChildren >= 32767)
    children = NSUIntegerMax;
  else if (iChildren < 0)
    children = 0;
  else
    children = iChildren;
  
  if (_addAllSongs == ADD_ALL_SONGS_NO || _isVTuner)
    addAllSongs = ADD_ALL_SONGS_NO;
  else if ([[item objectForKey: @"itemselectable"] isEqualToString: @"0"])
    addAllSongs = ADD_ALL_SONGS_CHILDREN_ONLY;
  else
    addAllSongs = ADD_ALL_SONGS_YES;
  _currentIndex = index;
  
  path = [item objectForKey: @"idpath"];
  if (path == nil)
  {
    path = [item objectForKey: @"id"];
    if (addAllSongs == ADD_ALL_SONGS_YES)
      addAllSongs = ADD_ALL_SONGS_CHILDREN_ONLY;
  }
  else
    path = [NSString stringWithFormat: @"%@>%@", path, [item objectForKey: @"id"]];
  
  retValue = [[[NLBrowseListNetStreams alloc]
               initWithSource: _source title: [item objectForKey: @"display"] path: path
               listCount: children addAllSongs: addAllSongs comms: _netStreamsComms] autorelease];
  
  return retValue;
}

- (BOOL) itemIsSelectableAtIndex: (NSUInteger) index
{
  NSDictionary *item = [self itemAtIndex: index];
  NSString *initialised = [item objectForKey: @"initialized"];
  
  return ([self titleForItemAtIndex: index] != nil && !(initialised != nil && [initialised isEqualToString: @"0"]));
}

- (void) addDelegate: (id<ListDataDelegate>) delegate
{
#if defined(DEBUG)
  //**/NSLog( @"%@ (%@): %@", self, _rootPath, [self stackTraceToDepth: 10] );
#endif
  if ([_listDataDelegates count] == 0)
  {
    [self registerForData];
    if ([_source isKindOfClass: [NLSourceMediaServer class]])
      [(NLSourceMediaServer *) _source addDelegate: self];
  }
  
  [_listDataDelegates addObject: delegate];
}

- (void) removeDelegate: (id<ListDataDelegate>) delegate
{
  NSUInteger oldCount = [_listDataDelegates count];
  
#if defined(DEBUG)
  //**/NSLog( @"%@ (%@): %@", self, _rootPath, [self stackTraceToDepth: 10] );
#endif
  
  if (oldCount > 0)
  {
    [_listDataDelegates removeObject: delegate];
    if ([_listDataDelegates count] == 0)
    {
      [self clearAllPendingMessages];
      if ([_source isKindOfClass: [NLSourceMediaServer class]])
        [(NLSourceMediaServer *) _source removeDelegate: self];
    }
  }  
}

- (id) listDataCurrentItem
{
  if (_currentIndex >= _count)
    return nil;
  else
    return [self itemAtIndex: _currentIndex];
}

- (BOOL) updateSectionDataForPrefix: (unichar) prefix offset: (NSUInteger) offset
{
  NSUInteger section;
  
  if (prefix == 0)
    section = 0;
  else if (prefix == '#' || (_listType & LIST_TYPE_UNSORTED) != 0)
    section = 1;
  else
    section = (prefix - 'A') + 2;
  
  SectionData *sectionData = [_sectionData objectAtIndex: section];
  BOOL changed;
  
  if (offset < sectionData.offset || offset == NO_CONTENT_OFFSET)
  {
    if (sectionData.offset > NO_CONTENT_OFFSET || offset != NO_CONTENT_OFFSET)
      sectionData.offset = offset;
    changed = YES;
  }
  else
    changed = NO;
  
  sectionData = [_sectionData objectAtIndex: 1];
  
  if (sectionData.offset != NO_CONTENT_OFFSET &&
      (((_listType & LIST_TYPE_SORTED_AND_ALL_SONGS) == 0 && offset == 0) ||
       ((_listType & LIST_TYPE_SORTED_AND_ALL_SONGS) != 0 && offset == 2)))
  {
    sectionData.offset = NO_CONTENT_OFFSET;
    changed = YES;
  }
  
  return changed;
}

- (void) handleAlphaPositionMessage: (NSDictionary *) data forRequest: (DataRequest *) currentRequest
{
  if ((_listType & LIST_TYPE_UNSORTED) != 0)
    return;
  
  NSInteger itemNum = [(NSString *) [data objectForKey: @"itemnum"] integerValue];
  unichar prefix = (unichar) currentRequest.range.location;
  NSString *prefixString = StringForLetter( prefix );
  NSString *displayName = [data objectForKey: @"display"];
  NSRange firstAlpha = [displayName rangeOfCharacterFromSet: [NSCharacterSet capitalizedLetterCharacterSet]];
  
  if (firstAlpha.length > 0 && firstAlpha.location != 0)
    displayName = [displayName substringFromIndex: firstAlpha.location];
  
  BOOL hasThe = ([displayName hasPrefix: @"The "] || [displayName hasPrefix: @"the "]);
  
  if (prefix != 'T' && hasThe)
    displayName = [displayName substringFromIndex: 4];
  
  // Record that we have checked for this letter
  _indexedSections |= (1 << ((prefix - 'A') & 0x1F));
  
  // Only make use of the returned message if it is actually a correct response for the given prefix.
  // This is because the responses for non-existent prefixes are wrong - they give the index of the
  // first record with the previous letter, not the first record with the following letter.
  
  if (itemNum > 0 && prefixString != nil &&
    [displayName compare: prefixString
                  options: (NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch|NSWidthInsensitiveSearch)
                     range: NSMakeRange( 0, 1 )] == NSOrderedSame)
  {
    //**/NSLog( @"%@ (%@): Found prefix %@ (%@), item: %d", self, _rootPath, prefixString, displayName, itemNum );
    currentRequest.changed = [self updateSectionDataForPrefix: prefix offset: itemNum - _listOffset];
  }
  else
  {
    //**/NSLog( @"%@ (%@): Prefix %@ not found (%@), item: %d", self, _rootPath, prefixString, displayName, itemNum );
    currentRequest.changed = [self updateSectionDataForPrefix: prefix offset: NO_CONTENT_OFFSET];
    
    if (itemNum > 0 && !hasThe)
    {
      unichar alternativePrefix = [displayName characterAtIndex: 0];
      unichar end;
      unichar c;
      
      if (alternativePrefix >= 'A' && alternativePrefix <= 'Z')
      {
        //**/NSLog( @"%@ (%@): Recording prefix %C (%@), item: %d", self, _rootPath, alternativePrefix, displayName, itemNum );
        currentRequest.changed |= [self updateSectionDataForPrefix: alternativePrefix offset: itemNum - _listOffset];
        if (alternativePrefix < prefix)
        {
          c = alternativePrefix + 1;
          end = prefix;
        }
        else
        {
          c = prefix + 1;
          end = alternativePrefix;
        }
        
        for ( ; c < end; ++c)
        {
          //**/NSLog( @"%@ (%@): Recording prefix %C not found (%@), item: %d", self, _rootPath, alternativePrefix, displayName, itemNum );
          currentRequest.changed |= [self updateSectionDataForPrefix: alternativePrefix offset: NO_CONTENT_OFFSET];
        }
      }
    }
    
    // Nasty hack to get round ReQuest bug where it sends two response messages to a request
    // for a non-existent section.  First an invalid end-of-list response and then a -1 response.
    // Keep a copy of our current request to handle the second response.
    if (itemNum > 0 && [_source.controlType isEqualToString: @"NS_ARQ"])
    {
      _bogusResponse = [[DataRequest dataRequestWithRange: 
                         NSMakeRange( currentRequest.range.location, NSUIntegerMax ) subBlockSize: 1] retain];
    }
  }
}

- (void) handleListResponse: (NSDictionary *) data forRequest: (DataRequest *) currentRequest
{
  NSInteger itemNum = [(NSString *) [data objectForKey: @"itemnum"] integerValue];
  NSString *itemCount = [data objectForKey: @"itemtotal"];
  NSUInteger oldCount = _count; 
  
  if (itemNum < 0)
  {
    // Check that this isn't the tail end of a previous request - the negative number
    // should be the negation of a number within the range of the current request
    // -1 is a generic "end of list" marker where exact position isn't known (or the end
    // of a single item list, in which case there can't be a following request so the
    // confusion we're trying to avoid can't arise).
    if (itemNum != -1)
      itemNum = -(itemNum + _listOffset);
    
    if (itemNum == -1 || (itemNum >= currentRequest.range.location &&
                          itemNum < currentRequest.range.location + currentRequest.range.length))
    {
      // Too many items requested.  This is the end of the list
      currentRequest.range = NSMakeRange( currentRequest.range.location,
                                         currentRequest.range.length - currentRequest.remaining );
      currentRequest.remaining = 0;
      currentRequest.pending = 0;
      currentRequest.changed = YES;
      
      if (itemCount != nil || itemNum == -1)
      {
        if (itemCount != nil)
          _count = [itemCount integerValue] - (_listOffset - 1);
        else if (currentRequest.range.location + currentRequest.range.length < oldCount)
          _count = currentRequest.range.location + currentRequest.range.length;
      }
    }
    
    [_noItemsCaption release];
    if (_count == 0 && [[data objectForKey: @"responseType"] isEqualToString: @"error"])
      _noItemsCaption = [[data objectForKey: @"display"] retain];
    else
      _noItemsCaption = nil;
  }
  else if (itemNum > 0)
  {
    if (itemCount != nil)
      _count = [itemCount integerValue] - (_listOffset - 1);
    else if (itemNum - (_listOffset - 1) > _highestIndexSoFar)
      _highestIndexSoFar = itemNum - (_listOffset - 1);
    
    itemNum -= _listOffset;
    
    // Only process this message further if it actually relates to our current request.
    // Otherwise we get ourselves confused.
    if (itemNum >= currentRequest.range.location && itemNum < NSMaxRange(currentRequest.range))
    {
      NSString *display = [data objectForKey: @"display"];
      NSString *itemId = [data objectForKey: @"id"];
      unichar prefix = LetterForString( display );
      NSMutableArray *block = [self blockForIndex: itemNum prioritised: NO];
      NSDictionary *item = [block objectAtIndex: itemNum % REQUEST_BLOCK_SIZE];
      
      if ([item count] == 0)
      {
        --currentRequest.remaining;
        --currentRequest.pending;
      }
      
      if (itemNum >= SECTIONS_ITEM_COUNT_THRESHOLD &&
          ((_listType & (LIST_TYPE_UNSORTED|LIST_TYPE_SORTED_WITH_SECTIONS)) == 0))
        [self initAlphaSections];
      
      if (prefix >= 'A' && !([display hasPrefix: @"The "] || [display hasPrefix: @"the "]))
        currentRequest.changed = [self updateSectionDataForPrefix: prefix offset: itemNum];
      
      // Replace item itemNum
      
      if (![[item objectForKey: @"id"] isEqualToString: itemId] ||
          ![[item objectForKey: @"display"] isEqualToString: display] ||
          ![[item objectForKey: @"children"] isEqualToString: [data objectForKey: @"children"]])
      {
        NSString *thumbnail = [data objectForKey: @"thumbnail"];

        currentRequest.changed = YES;
        
        if (thumbnail != nil && [thumbnail rangeOfString: @"${A1}"].length > 0)
        {
          NSDictionary *defaultMetadata = [NSMutableDictionary dictionaryWithCapacity: 0];
          NSDictionary *metadata = [_source metadataWithDefault: defaultMetadata];
          
          // Naim have asked us to cope with their server software being updated to a version that requires a different
          // URL for thumbnail coverart while the Naimnet.lua driver that accesses it hasn't been updated.  This requires
          // all sorts of hacking around.  This bit identifies an album thumbnail and replaces the old A2 suffix with a
          // new album-specific A4 suffix that the driver would use if they had installed it.
          if ([itemId hasPrefix: @"a."] && [thumbnail rangeOfString: @"${A2}"].length > 0)
          {
            NSMutableDictionary *newData = [[data mutableCopy] autorelease];
            
            thumbnail = [thumbnail stringByReplacingOccurrencesOfString: @"${A2}" withString: @"${A4}"];
            [newData setObject: thumbnail forKey: @"thumbnail"];
            data = newData;
          }

          if (metadata == defaultMetadata)
          {
            _metadataTimer = [[NSTimer timerWithTimeInterval: 10.0 target: self selector: @selector(retryMetadata) 
                                                    userInfo: nil repeats: YES] retain];
            [_netStreamsComms send: @"MENU_LIST 1,1,{{meta}}" to: _source.serviceName];
          }
          else if ([metadata count] > 0)
          {
            NSString *newThumb = thumbnail;
            NSEnumerator *keys = [metadata keyEnumerator];
            NSString *key;
            
            while ((key = [keys nextObject]) != nil)
            {
              newThumb = [newThumb stringByReplacingOccurrencesOfString: [NSString stringWithFormat: @"${%@}", key]
                                                             withString: [metadata objectForKey: key]];
            }
            
            if (newThumb != nil && ![newThumb isEqualToString: thumbnail])
            {
              if ([data isKindOfClass: [NSMutableDictionary class]])
                [(NSMutableDictionary *) data setObject: newThumb forKey: @"thumbnail"];
              else
              {
                NSMutableDictionary *newData = [[data mutableCopy] autorelease];
                
                [newData setObject: newThumb forKey: @"thumbnail"];
                data = newData;
              }
            }
          }
        }
        
        [block replaceObjectAtIndex: itemNum % REQUEST_BLOCK_SIZE withObject: data];
        //**/ NSLog( @"%@ (%@): Block %u changed: %@", self, _rootPath,
        //**/       (itemNum >> REQUEST_BLOCK_POWER_OF_2) << REQUEST_BLOCK_POWER_OF_2, block );
        
        if (itemNum == _currentIndex)
        {
          NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
          NSEnumerator *enumerator = [delegates objectEnumerator];
          id<ListDataDelegate> delegate;
          
          while ((delegate = [enumerator nextObject]))
          {
            if ([delegate respondsToSelector: @selector(currentItemForListData:changedFrom:to:at:)])
              [delegate currentItemForListData: self changedFrom: item to: data at: _currentIndex];
          }
        }
      }
    }
    else if (currentRequest.remaining == 1 &&
             itemNum == currentRequest.range.location + currentRequest.range.length - 2 &&
             [_source.controlType isEqualToString: @"NS_XIVA"])
    {
      // XiVA bug - if we ask for n items and there are actually exactly n-1 available, it returns
      // those n-1 but not the final index "-1" item that it should.  We spot this on handling the
      // repeat message so there will be a delay, but there's not much we can do about it...
      currentRequest.range = NSMakeRange( currentRequest.range.location,
                                         currentRequest.range.length - currentRequest.remaining );
      currentRequest.remaining = 0;
      currentRequest.pending = 0;
      currentRequest.changed = YES;
      if (itemCount == nil)
      {
        if (currentRequest.range.location + currentRequest.range.length < oldCount)
          _count = currentRequest.range.location + currentRequest.range.length;
      }
    }
  }
  
  if (_count != oldCount)
  {
    NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
    NSEnumerator *enumerator = [delegates objectEnumerator];
#if !defined(RESET_CURRENT_INDEX)
    NSUInteger oldIndex = _currentIndex;
#endif
    id<ListDataDelegate> delegate;
    NSRange changedRange;
    
    if (_count > oldCount)
      changedRange = NSMakeRange( oldCount, _count - oldCount );
    else
      changedRange = NSMakeRange( _count, oldCount - _count );
    
    // No play all and no sorting if there are no entries!
    if (_count == 0 || ((_listType & LIST_TYPE_FLAG_ALL_SONGS) != 0 && _count == 2))
    {
      _listType = LIST_TYPE_UNSORTED;
      _count = 0;
    }
    
    ((SectionData *) [_sectionData objectAtIndex: 28]).offset = _count;
    [self clearPendingRequestsBeyond: _count + 1];
     
#if !defined(RESET_CURRENT_INDEX)
    if (_currentIndex >= _count)
      _currentIndex = 0;
#endif

    while ((delegate = [enumerator nextObject]))
    {
#if !defined(RESET_CURRENT_INDEX)
      if (_currentIndex != oldIndex &&
          [delegate respondsToSelector: @selector(currentItemForListData:changedFrom:to:at:)])
        [delegate currentItemForListData: self changedFrom: [NSDictionary dictionary] to:
         [self itemAtIndex: _currentIndex] at: _currentIndex];
#endif

      if (_count > oldCount)
      {
        if ([delegate respondsToSelector: @selector(itemsInsertedInListData:range:)])
          [delegate itemsInsertedInListData: self range: changedRange];
      }
      else
      {
        if ([delegate respondsToSelector: @selector(itemsRemovedInListData:range:)])
          [delegate itemsRemovedInListData: self range: changedRange];
      }
    }
  }
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  BOOL ourMessage = ([messageType isEqualToString: @"MENU_RESP"] && 
                     [_rootPath compare: [data objectForKey:@"idpath"] options: NSCaseInsensitiveSearch] == NSOrderedSame);

  //NSLog( @"%@ (%@): received: %@ from: %@", self, _rootPath, messageType, source );
  
  if (ourMessage && _bogusResponse != nil)
  {
    // Handle erroneous duplicate response from ARQ driver (a -1 in response to a
    // request for a non-existent alpha section)
    NSInteger itemNum = [(NSString *) [data objectForKey: @"itemnum"] integerValue];
    
    ourMessage = (itemNum != -1);
    [_bogusResponse release];
    _bogusResponse = nil;
  }

  if (ourMessage && [_pendingRequests count] > 0)
  {
    DataRequest *currentRequest = [_pendingRequests objectAtIndex: 0];
    NSString *responseType = [data objectForKey: @"responseType"];
    BOOL processMoreRequests = YES;
    
    if ([responseType isEqualToString: @"song"] && _itemType != ITEM_TYPE_SONG)
    {
      // If we're not at the top level (where Random Playback is a "song") and
      // if we're not in one of the sorted song lists - All Songs, Songs or a
      // VTuner station list, then we're in some sort of album or playlist and
      // so the list is unsorted, whether in alphabetical order by accident or not.
      
      if (!(_isVTuner || [_rootPath rangeOfString: @"internet radio" options: NSCaseInsensitiveSearch].location != NSNotFound) && (_menuLevel != 3 || !([_itemType isEqualToString: @"All Songs"] || [_itemType isEqualToString: @"Songs"])))
        _listType = ((_listType & LIST_TYPE_FLAG_ALL_SONGS) | LIST_TYPE_UNSORTED);
      
      [_itemType release];
      _itemType = [ITEM_TYPE_SONG retain];
    }
    
    //**/NSLog( @"%@ (%@): processing: %@ from: %@ path: %@ _currentMessageHandle: %@ _menuRspHandle: %@",
    //**/      self, _rootPath, messageType, source, _rootPath, _currentMessageHandle, _menuRspHandle );
    
    if (currentRequest.isAlphaRequest)
      [self handleAlphaPositionMessage: data forRequest: currentRequest];
    else
      [self handleListResponse: data forRequest: currentRequest];
    
    if (currentRequest.remaining == 0)
    {
      if (_currentMessageHandle != nil)
      {
        //**/NSLog( @"%@ (%@): Cancel send every 2", self, _rootPath );
        [_netStreamsComms cancelSendEvery: _currentMessageHandle];
        _currentMessageHandle = nil;
      }
      
      [currentRequest retain];
      
      if ([_pendingRequests count] > 0)
      {
#if defined(DEBUG)
        //**/NSLog( @"%@ (%@): Remove current request", self, _rootPath );
#endif
        [_pendingRequests removeObjectAtIndex: 0];  
        NSLog( @"%@ (%@): pendingRequests - current request removed: %@", self, _rootPath, [_pendingRequests listRequests] );
      }
      
      if (_doRefreshWhenRequestComplete)
      {
        _doRefreshWhenRequestComplete = NO;
        processMoreRequests = NO;
        [self doRefresh];
      }
      
      if (currentRequest.changed)
      {
        NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
        NSEnumerator *enumerator = [delegates objectEnumerator];
        id<ListDataDelegate> delegate;
        
        if (!currentRequest.isAlphaRequest)
          [self checkBlockForAlphaSorting: currentRequest.range.location];
        
        while ((delegate = [enumerator nextObject]))
        {
          if ([delegate respondsToSelector: @selector(itemsChangedInListData:range:)])
            [delegate itemsChangedInListData: self range: currentRequest.range];
        }
      }
      
      [currentRequest release];
      
      if (processMoreRequests && [_pendingRequests count] > 0)
      {
        NSString *message;
        
        currentRequest = [_pendingRequests objectAtIndex: 0];
        if (currentRequest.isAlphaRequest)
          message = [NSString stringWithFormat: @"MENU_LIST 1,1,{{%@}},%C", _rootPath, 
                     (unichar) currentRequest.range.location];
        else
        {
          message = [NSString stringWithFormat: @"MENU_LIST %u,%u,{{%@}}",
                     currentRequest.range.location + _listOffset, 
                     currentRequest.range.location + _listOffset + currentRequest.subBlockSize - 1, _rootPath];
          currentRequest.pending = currentRequest.subBlockSize;
        }
          
        //**/NSLog( @"%@ (%@): Start send every 2: %@", self, _rootPath, message );
        _currentMessageHandle = [_netStreamsComms send: message to: _source.serviceName every: _source.retryInterval];
      }
    }
    else if (currentRequest.pending == 0)
    {
      NSUInteger baseIndex = currentRequest.range.location + _listOffset + currentRequest.range.length - currentRequest.remaining;
      NSString *message = [NSString stringWithFormat: @"MENU_LIST %u,%u,{{%@}}", baseIndex, baseIndex + currentRequest.subBlockSize - 1, _rootPath];

      if (currentRequest.changed)
      {
        NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
        NSEnumerator *enumerator = [delegates objectEnumerator];
        id<ListDataDelegate> delegate;
        
        while ((delegate = [enumerator nextObject]))
        {
          if ([delegate respondsToSelector: @selector(itemsChangedInListData:range:)])
            [delegate itemsChangedInListData: self range: currentRequest.range];
        }
      }
      
      //**/NSLog( @"%@ (%@): Start send every 2a: %@", self, _rootPath, message );
      currentRequest.pending = currentRequest.subBlockSize;
      if (_currentMessageHandle != nil)
      {
        //**/NSLog( @"%@ (%@): Cancel send every 2a", self, _rootPath );
        [_netStreamsComms cancelSendEvery: _currentMessageHandle];
      }
      _currentMessageHandle = [_netStreamsComms send: message to: _source.serviceName every: _source.retryInterval];
    }
  }
  else if ([messageType isEqualToString: @"MENU_RESP"] && 
           [@"meta" compare: [data objectForKey: @"idpath"] options: NSCaseInsensitiveSearch] == NSOrderedSame &&
           [@"1" isEqual: [data objectForKey: @"itemnum"]])
  {
    if (_metadataTimer != nil)
    {
      [_metadataTimer invalidate];
      [_metadataTimer release];
      _metadataTimer = nil;

      if ([data objectForKey: @"A1"] == nil || [data objectForKey: @"A2"] == nil || [data objectForKey: @"VERSION"] != nil)
      {
        // Either a new enough Naimnet.lua to not need the cover art hack or some other driver that doesn't
        // have the problem in the first place
        [self processNewMetadata: data];
      }
      else
      {
        // Naimnet.lua that isn't appending keytype=album where required.  We need to work out for ourselves
        // whether it is needed.
        if (_naimVersionHandler == nil)
        {
          _naimVersionHandler = [[NaimVersionHandler alloc] initWithMetadata: data delegate: self];
          [_naimVersionHandler getVersion];
        }
      }
    }
  }
}

- (void) retryMetadata
{
  [_netStreamsComms send: @"MENU_LIST 1,1,{{meta}}" to: _source.serviceName];  
}

- (void) processNewMetadata: (NSDictionary *) data
{
  [_source setMetadata: data];
  if (_naimVersionHandler != nil)
  {
    NaimVersionHandler *nvh = _naimVersionHandler;
    _naimVersionHandler = nil;
    [nvh release];
  }
  
  if ([data count] > 0)
  {
    for (NSMutableArray *block in [_content allValues])
    {
      NSInteger count = [block count];
      
      for (NSInteger i = 0; i < count; ++i)
      {
        id item = [block objectAtIndex: i];
        
        if ([item isKindOfClass: [NSDictionary class]])
        {
          NSDictionary *dict = (NSDictionary *) item;
          NSString *thumbnail = [dict objectForKey: @"thumbnail"];
          NSString *newThumb = thumbnail;
          NSEnumerator *keys = [data keyEnumerator];
          NSString *key;
          
          while ((key = [keys nextObject]) != nil)
          {
            newThumb = [newThumb stringByReplacingOccurrencesOfString: [NSString stringWithFormat: @"${%@}", key]
                                                           withString: [data objectForKey: key]];
          }
          
          if (newThumb != nil && ![newThumb isEqualToString: thumbnail])
          {
            if ([dict isKindOfClass: [NSMutableDictionary class]])
              [(NSMutableDictionary *) dict setObject: newThumb forKey: @"thumbnail"];
            else
            {
              NSMutableDictionary *newDict = [dict mutableCopy];
              
              [newDict setObject: newThumb forKey: @"thumbnail"];
              [block replaceObjectAtIndex: i withObject: newDict];
              [newDict release];
            }
          }
        }
      }
      
      //**/NSLog( @"%@ (%@): Block updated with new metadata: %@", self, _rootPath, block );
    }
    
    NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
    NSEnumerator *enumerator = [delegates objectEnumerator];
    id<ListDataDelegate> delegate;
    
    while ((delegate = [enumerator nextObject]))
    {
      if ([delegate respondsToSelector: @selector(itemsChangedInListData:range:)])
        [delegate itemsChangedInListData: self range: NSMakeRange( 0, _count )];
    }
  }
}

- (void) didReceiveMemoryWarning
{
#if 1
  // Clear out all but the last requested item, the block containing the 
  // currently selected item and the block in the current pending request (if any).
  // These may be the same block.
  
  NSArray *lastBlock;
  NSString *currentKey;
  NSArray *currentBlock;
  NSString *pendingKey;
  NSArray *pendingBlock;
  DataRequest *pendingRequest;
  
#if RESTORE_LAST_BLOCK
  if (_lastKey == nil)
    lastBlock = nil;
  else
    lastBlock = [[_content objectForKey: _lastKey] retain];
#else
  lastBlock = nil;
#endif

  if (_currentIndex >= _count)
  {
    currentKey = nil;
    currentBlock = nil;
  }
  else
  {
    currentKey = [NSString stringWithFormat: @"%u",
                  (_currentIndex >> REQUEST_BLOCK_POWER_OF_2) << REQUEST_BLOCK_POWER_OF_2];
    currentBlock = [[_content objectForKey: currentKey] retain];
  }
  
  if ([_pendingRequests count] == 0)
  {
    pendingRequest = nil;
    pendingKey = nil;
    pendingBlock = nil;
  }
  else
  {
    pendingRequest = [[_pendingRequests objectAtIndex: 0] retain];
    pendingKey = [NSString stringWithFormat: @"%u",
                  (pendingRequest.range.location >> REQUEST_BLOCK_POWER_OF_2) << REQUEST_BLOCK_POWER_OF_2];
    pendingBlock = [[_content objectForKey: pendingKey] retain];
    
  }

  [_content removeAllObjects];
  //**/NSLog( @"%@ (%@): Removed all blocks", self, _rootPath );
  if (currentBlock != nil)
  {
    [_content setObject: currentBlock forKey: currentKey];
    //**/NSLog( @"%@ (%@): Restored current block %@: %@", self, _rootPath, currentKey, currentBlock );
    [currentBlock release];
  }
  if (lastBlock != nil)
  {
    if (lastBlock != currentBlock)
    {
      [_content setObject: lastBlock forKey: _lastKey];
      //**/NSLog( @"%@ (%@): Restored last fetched block %@: %@", self, _rootPath, _lastKey, lastBlock );
    }
    [lastBlock release];
  }
  if (pendingBlock != nil)
  {
    if (pendingBlock != currentBlock && pendingBlock != lastBlock)
    {      
      [_content setObject: pendingBlock forKey: pendingKey];
      //**/NSLog( @"%@ (%@): Restored pending block %@: %@", self, _rootPath, pendingKey, pendingBlock );
    }
    [pendingBlock release];
  }
  if (pendingRequest != nil)
  {
    [_pendingRequests removeAllObjects];
    [_pendingRequests addObject: pendingRequest];
    [pendingRequest release];
  }
#else
  self._lastKey = nil;
  [_content removeAllObjects];
  [self clearAllPendingMessages];
#endif
}

// Local methods

- (NSMutableArray *) blockForIndex: (NSUInteger) index
{
  NSMutableArray *block = [self blockForIndex: index prioritised: YES];
  
  // Set up a pre-fetch of the next block in either direction, so that (we hope) it will be ready
  // and waiting by the time the user scrolls to it.  This shouldn't cause too much extra traffic
  // as unless we've just jumped to a position in the list, one of these blocks will already have
  // been fetched.
  
  index += REQUEST_BLOCK_SIZE;
  if (index < _count)
    [self blockForIndex: index prioritised: NO];
  
  if (index >= (2 * REQUEST_BLOCK_SIZE))
    [self blockForIndex: index - (2 * REQUEST_BLOCK_SIZE) prioritised: NO];
  
  return block;
}

- (NSMutableArray *) blockForIndex: (NSUInteger) index prioritised: (BOOL) prioritised
{
  NSUInteger baseIndex = (index >> REQUEST_BLOCK_POWER_OF_2) << REQUEST_BLOCK_POWER_OF_2;
  NSUInteger maxItems;
  NSMutableArray *block;
  
#if defined(DEBUG)
  //**/NSLog( @"%@ (%@): Block for index: %u\n%@", self, _rootPath, index, [self stackTraceToDepth: 10] );
#endif
  self.lastKey = [NSString stringWithFormat: @"%u", baseIndex];
  block = [_content objectForKey: _lastKey];
  if (_isVTuner)
    maxItems = REQUEST_MAX_ITEMS_VTUNER;
  else
    maxItems = REQUEST_MAX_ITEMS;
  
  if (block == nil)
  {
    NSUInteger count;
    
    block = [EMPTY_ARRAY mutableCopy];
    [_content setObject: block forKey: _lastKey];
    [block release];
    
    if (baseIndex != 0 || (_listType & LIST_TYPE_FLAG_ALL_SONGS) == 0)
      count = REQUEST_BLOCK_SIZE;
    else
    {
      // Special case of adding All Songs entries
      
      NSDictionary *item;
      
      count = REQUEST_BLOCK_SIZE - 2;
      baseIndex = 2;
      
      item = [NSDictionary dictionaryWithObjectsAndKeys:
              NSLocalizedString( @"Play All",
                                @"Title of browse list entry that plays all songs in the current browse list" ),
              @"display",
              @"0", @"children", 
              [NSArray arrayWithObjects:
               @"shuffle off",
               [NSString stringWithFormat: @"MENU_SEL {{%@}}", _rootPath], nil], @"mp-ns-actions",
              nil];
      [block replaceObjectAtIndex: 0 withObject: item];
      item = [NSDictionary dictionaryWithObjectsAndKeys:
              NSLocalizedString( @"Shuffle",
                                @"Title of browse list entry that shuffles and plays all songs in the current browse list" ),
              @"display",
              @"0", @"children", 
              [NSArray arrayWithObjects:
               @"shuffle on",
               [NSString stringWithFormat: @"MENU_SEL {{%@}}", _rootPath], nil], @"mp-ns-actions",
              nil];
      [block replaceObjectAtIndex: 1 withObject: item];
    }
    
    //**/NSLog( @"%@ (%@): Created block %@: %@", self, _rootPath, _lastKey, block );
     
    DataRequest *request = [DataRequest dataRequestWithRange: NSMakeRange( baseIndex, count ) subBlockSize: maxItems];
    
    if ([_pendingRequests count] > 0)
    {
#if defined(DEBUG)
      //**/NSLog( @"%@ (%@): Pending request added (%d, %d)", self, _rootPath, baseIndex, count );
#endif
      [_pendingRequests insertObject: request atIndex: 1];
    }
    else
    {
#if defined(DEBUG)
      //**/NSLog( @"%@ (%@): Immediate request sent (%d, %d)", self, _rootPath, baseIndex, count );
#endif
      NSString *message = [NSString stringWithFormat: @"MENU_LIST %u,%u,{{%@}}",
                           baseIndex + _listOffset, baseIndex + _listOffset + maxItems - 1, _rootPath];
      
      [_pendingRequests addObject: request];
      //**/NSLog( @"%@ (%@): Start send every 3: %@", self, _rootPath, message );

      request.pending = maxItems;
      _currentMessageHandle = [_netStreamsComms send: message to: _source.serviceName every: _source.retryInterval];
    }
    //**/NSLog( @"%@ (%@): pendingRequests added to by request for block %u (%u): %@", self, _rootPath, baseIndex, index, [_pendingRequests listRequests] );
  }
  else if (prioritised && [(NSDictionary *) [block objectAtIndex: 0] count] == 0)
  {
    // Currently pending high priority fetch - move its fetch request to the top of the queue, if necessary
    
    NSUInteger count = [_pendingRequests count];
    NSUInteger i;
    
    for (i = 0; i < count; ++i)
    {
      DataRequest *request = [_pendingRequests objectAtIndex: i];
      
      if (!request.isAlphaRequest && request.range.location == baseIndex)
      {
        if (i > 1)
        {
          [request retain];
          [_pendingRequests removeObjectAtIndex: i];
          [_pendingRequests insertObject: request atIndex: 1];
          [request release];
          //**/NSLog( @"%@ (%@): pendingRequests modified by request for block %u (%u): %@", self, _rootPath, baseIndex, index, [_pendingRequests listRequests] );
        }
        break;
      }
    }
  }
  
  return block;
}

- (BOOL) initAlphaSections
{
  BOOL isSorted = ((_listType & LIST_TYPE_UNSORTED) == 0);
  
  if (isSorted)
  {
    _listType |= LIST_TYPE_SORTED_WITH_SECTIONS;
    
    // And do this to alleviate troublesome "The" problems...
    if ((_indexedSections & (1 << ('T' - 'A'))) == 0 && !_isVTuner)
      [self sendAlphaRequestForLetter: 'T'];
  }
  
  return isSorted;
}

- (void) checkBlockForAlphaSorting: (NSUInteger) index
{
  if ((_listType & LIST_TYPE_UNSORTED) == 0)
  {
    NSUInteger baseIndex = (index >> REQUEST_BLOCK_POWER_OF_2) << REQUEST_BLOCK_POWER_OF_2;
    NSMutableArray *block = [_content objectForKey: [NSString stringWithFormat: @"%u", baseIndex]];
    
    if (block != nil)
    {
      NSUInteger i = (index % REQUEST_BLOCK_SIZE) + 1;
      float unsorted = 0;
      
      if (baseIndex == 0 && (_listType & LIST_TYPE_FLAG_ALL_SONGS) != 0)
        i += 2;
      
      BOOL prevThePrefix;
      NSString *prevTitle = SortCompareTitle( [block objectAtIndex: i - 1], &prevThePrefix );
      
      for ( ; i < REQUEST_BLOCK_SIZE; ++i)
      {
        BOOL thePrefix;
        NSString *title = SortCompareTitle( [block objectAtIndex: i], &thePrefix );
        
        if (title == nil)
          break;
        else
        {
          if ([title compare: prevTitle options: (NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch|NSWidthInsensitiveSearch)] == NSOrderedAscending &&
              (!prevThePrefix || [title compare: @"T" options: (NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch|NSWidthInsensitiveSearch)] == NSOrderedAscending) &&
              (!thePrefix || [@"T" compare: prevTitle options: (NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch|NSWidthInsensitiveSearch)] == NSOrderedAscending))
            ++unsorted;
          prevTitle = title;
          prevThePrefix = thePrefix;
        }
      }

      if (unsorted >= 4)
        _listType = ((_listType & LIST_TYPE_FLAG_ALL_SONGS) | LIST_TYPE_UNSORTED);
    }
  }
}

- (void) registerForData
{
  //**/NSLog( @"%@ (%@): Register", self, _rootPath );
  _menuRspHandle = [_netStreamsComms registerDelegate: self forMessage: @"MENU_RESP" from: _source.serviceName];
  
  // If we started an alpha indexing before, but didn't complete it (because
  // the user switched away from the view) complete it now
  if ((_listType & LIST_TYPE_SORTED_WITH_SECTIONS) != 0 && _indexedSections != 0x03FFFFFF)
    [self initAlphaSections];
  
  // Force initial fetch, if not already done.
  [self blockForIndex: 0];
}

- (void) clearPendingRequestsBeyond: (NSUInteger) listLength
{
  NSUInteger count = [_pendingRequests count];
  NSUInteger i;
  
  for (i = 1; i < count; )
  {
    DataRequest *request = [_pendingRequests objectAtIndex: i];
    
    if (request.isAlphaRequest || request.range.location < listLength)
      ++i;
    else
    {
      [_pendingRequests removeObjectAtIndex: i];
      --count;
    }
  }
  //**/NSLog( @"%@ (%@): pendingRequests modified by clearPendingRequestsBeyond: %@", self, _rootPath, [_pendingRequests listRequests] );
}

- (void) clearAllPendingMessages
{
  NSUInteger pendingCount = [_pendingRequests count];
  NSUInteger i;
  
#if defined(DEBUG)
  //**/NSLog( @"%@ (%@): Clearing all pending messages", self, _rootPath );
#endif
  //**/NSLog( @"%@ (%@): Deregister 2", self, _rootPath );
  [_netStreamsComms deregisterDelegate: _menuRspHandle];
  //**/NSLog( @"%@ (%@): Cancel send every 1", self, _rootPath );
  [_netStreamsComms cancelSendEvery: _currentMessageHandle];
  _menuRspHandle = nil;
  _currentMessageHandle = nil;
  [_indexRequestDelayTimer invalidate];
  _indexRequestDelayTimer = nil;
  
  // Clear any pending message requests and delete the associated uninitialised or
  // partly initialised blocks
  for (i = 0; i < pendingCount; ++i)
  {
    DataRequest *pendingRequest = (DataRequest *) [_pendingRequests objectAtIndex: i];
    
    if (!pendingRequest.isAlphaRequest)
    {
      NSRange pendingRange = pendingRequest.range;
      NSString *key = [NSString stringWithFormat: @"%u",
                       (pendingRange.location >> REQUEST_BLOCK_POWER_OF_2) << REQUEST_BLOCK_POWER_OF_2];
      
      [_content removeObjectForKey: key];
      //**/NSLog( @"%@ (%@): Removed pending block %@", self, _rootPath, key );
      if ([key isEqualToString: _lastKey])
        self.lastKey = nil;
#if RESET_CURRENT_INDEX
      if (_currentIndex >= pendingRange.location &&
          _currentIndex < pendingRange.location + pendingRange.length)
        _currentIndex = _count;
#endif
    }
  }
  [_pendingRequests removeAllObjects];
  //**/NSLog( @"%@ (%@): pendingRequests modified by clearAllPendingMessages: %@", self, _rootPath, [_pendingRequests listRequests] );
}

- (void) indexRequestDelayTimerFired: (NSTimer *) timer
{
  unichar c = (unichar) [(NSNumber *) [timer userInfo] integerValue];
  NSUInteger section = (c - 'A') + 2;
  NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<ListDataDelegate> delegate;
  NSRange allItems = NSMakeRange( 0, _count );
  NSUInteger count = [_sectionData count];
  NSUInteger i;
  
  _indexRequestDelayTimer = nil;
  for (i = 0; i < count; ++i)
  {
    SectionData *sectionData = [_sectionData objectAtIndex: i];
    
    if (i == section && sectionData.offset >= TEMP_SCROLL_OFFSET)
      sectionData.offset = PENDING_OFFSET;
    else if (sectionData.offset == TEMP_SCROLL_OFFSET)
      sectionData.offset = UNDETERMINED_OFFSET;
  }
  
  if (!_isVTuner)
    [self sendAlphaRequestForLetter: c];
  
  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(itemsChangedInListData:range:)])
      [delegate itemsChangedInListData: self range: allItems];
  }
}

- (void) sendAlphaRequestForLetter: (unichar) c
{
  DataRequest *request = [DataRequest dataRequestForLetter: c];
  
  if ([_pendingRequests count] > 0)
    [_pendingRequests insertObject: request atIndex: 1];
  else
  {
    NSString *prefixString = StringForLetter( c );
    NSString *message = [NSString stringWithFormat: @"MENU_LIST 1,1,{{%@}},%@", _rootPath, prefixString];
    
    //**/NSLog( @"%@ (%@): Start send every 1: %@", self, _rootPath, message );
    [_pendingRequests addObject: request];
    _currentMessageHandle = [_netStreamsComms send: message to: _source.serviceName every: _source.retryInterval];
  }
  //**/NSLog( @"%@ (%@): pendingRequests modified by sendAlphaRequestForLetter %C: %@", self, _rootPath, c, [_pendingRequests listRequests] );
}

static unichar LetterForString( NSString *string )
{
  unichar c;
  
  if (string == nil)
    c = 0;
  else if ([string length] == 0)
    c = '#';
  else
  {
    c = [string characterAtIndex: 0];
    if (c < 'A')
      c = '#';
    else if (c > 'Z')
    {
      if (c < 'a' || c > 'z')
        c = '#';
      else
        c = c & 0x00DF;
    }
  }
  
  return c;
}

@end

