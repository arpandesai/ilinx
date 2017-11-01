//
//  NLSourceMediaServerNetStreams.m
//  iLinX
//
//  Created by mcf on 19/10/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "NLSourceMediaServerNetStreams.h"
#import "NLBrowseListNetStreamsRoot.h"
#include "StringEncoding.h"

#define _pcomms NETSTREAMSCOMMS_PRODUCTION_ONLY(_comms)

// Timeout for fetching metadata, in seconds
#define URL_FETCH_TIMEOUT 5

// How often, in seconds, to send the report registration request to ensure
// that it does not expire
#define REGISTRATION_RENEWAL_INTERVAL 30

@interface NLSourceMediaServerNetStreams ()

- (void) parser: (NSXMLParser *) parser didStartElement: (NSString *) elementName 
   namespaceURI: (NSString *) namespaceURI qualifiedName: (NSString *) qName attributes: (NSDictionary *) attributeDict;

@end


@implementation NLSourceMediaServerNetStreams

- (NLBrowseList *) browseMenu
{
  if (_browseMenu == nil)
  {
    NSString *browseScreen = [_sourceData objectForKey: @"browseScreen"];
    
    if (browseScreen == nil || ![browseScreen isEqualToString: @"0"])
    {
      _browseMenu = [[NLBrowseListNetStreamsRoot alloc]
                     initWithSource: self
                     title: NSLocalizedString( @"Media",
                                              @"Title of the top level menu of available browseable media on a media server" )
                     path: @"media" listCount: NSUIntegerMax addAllSongs: ADD_ALL_SONGS_CHILDREN_ONLY comms: _comms];
    }
  }
  
  return _browseMenu;
}

- (void) setTransportState: (NSUInteger) transportState
{
  NSString *cmd;
  
  switch (transportState)
  {
    case TRANSPORT_STATE_STOP:
      cmd = @"STOP";
      break;
    case TRANSPORT_STATE_PAUSE:
      cmd = @"PAUSE";
      break;
    case TRANSPORT_STATE_PLAY:
      cmd = @"PLAY";
      break;
    default:
      cmd = nil;
      break;
  }
  
  if (cmd != nil)
  {
    _transportState = transportState;
    [_pcomms send: cmd to: self.serviceName];
  }
}

- (void) setShuffle: (BOOL) shuffle
{
  if (_shuffle != shuffle)
  {
    _shuffle = shuffle;
    if (_shuffle)
      [_pcomms send: @"shuffle on" to: self.serviceName];
    else
      [_pcomms send: @"shuffle off" to: self.serviceName];
    _debounceShuffle = 2;
  }
}

- (NSUInteger) capabilities
{
  return (SOURCE_MEDIA_SERVER_CAPABILITY_SONG_COUNT|SOURCE_MEDIA_SERVER_CAPABILITY_NEXT_TRACK);
}

- (void) playNextTrack
{
  [_pcomms send: @"NEXT" to: self.serviceName];
}

- (void) playPreviousTrack
{
  [_pcomms send: @"PREV" to: self.serviceName];
}

- (void) activate
{
  [super activate];
  
  //NSLog( @"Register" );
  _statusRspHandle = [_comms registerDelegate: self forMessage: @"REPORT" from: self.serviceName];
  _registerMsgHandle = [_comms send: [NSString stringWithFormat: @"REGISTER ON,{{%@}}", self.serviceName]
                                 to: nil every: REGISTRATION_RENEWAL_INTERVAL];
}

- (void) deactivate
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
  
  [_extendedURL release];
  _extendedURL = nil;
  if (_extendedConnection != nil)
  {
    [_extendedConnection release];
    _extendedConnection = nil;
  }
  [_extendedData release];
  _extendedData = nil;
  
  [super deactivate];
}

- (NSDictionary *) metadata
{
  return _metadata;
}

- (NSDictionary *) metadataWithDefault: (NSDictionary *) metadata
{
  BOOL changed;

  @synchronized (self)
  {
    if (_metadata != nil)
      changed = NO;
    else
    {
      _metadata = [metadata retain];
      changed = YES;
    }
  }
  
  if (changed)
    [self notifyDelegates: SOURCE_MEDIA_SERVER_METADATA_CHANGED];

  return _metadata;
}

- (void) setMetadata: (NSDictionary *) metadata
{
  BOOL changed;

  @synchronized (self)
  {
    changed = (metadata != _metadata);
    if (changed)
    {
      [metadata retain];
      [_metadata release];
      _metadata = metadata;
    }
  }

  if (changed)
    [self notifyDelegates: SOURCE_MEDIA_SERVER_METADATA_CHANGED];
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  if ([[data objectForKey: @"type"] isEqualToString: @"source"])
  {
    NSUInteger changed = 0;
    NSString *song = [data objectForKey: @"song"];
    NSString *nextSong = [data objectForKey: @"next"];
    NSString *album = [data objectForKey: @"album"];
    NSString *artist = [data objectForKey: @"artist"];
    NSString *genre = [data objectForKey: @"genre"];
    NSString *coverArtURL = [data objectForKey: @"artwork"];
    NSString *timeStr = [data objectForKey: @"time"];
    NSString *elapsedStr = [data objectForKey: @"elapsed"];
    NSString *songIndexStr = [data objectForKey: @"sngPlIndex"];
    NSString *songTotalStr = [data objectForKey: @"sngPlTotal"];
    NSString *controlStateStr = [data objectForKey: @"controlState"];
    NSString *shuffleStr = [data objectForKey: @"shuffle"];
    NSString *extendedURL = [data objectForKey: @"extended"];
    NSString *datastampQueue = [data objectForKey: @"datastampQueue"];
    NSString *datastampLibrary = [data objectForKey: @"datastampLibrary"];
    NSString *songId = [data objectForKey: @"songId"];
    NSString *caption = [data objectForKey: @"caption"];
    BOOL extendedDataChanged = (extendedURL == nil || [extendedURL length] == 0);

    // Hack to cope with nasty behaviour of iPod dock where status messages are
    // put into the song title as well to get them to display on the TouchLinX UI.
    // We already handle this differently and so get rid of the caption.
    if ([caption isEqualToString: song])
      song = @"";

    if (extendedURL != nil && ![extendedURL isEqualToString: _extendedURL])
    {
      [_extendedURL release];
      _extendedURL = [extendedURL retain];
      NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString: _extendedURL] 
                                               cachePolicy: NSURLRequestUseProtocolCachePolicy
                                           timeoutInterval: URL_FETCH_TIMEOUT];
      
      if (_extendedConnection != nil)
      {
        [_extendedConnection cancel];
        [_extendedConnection release];
      }
      _extendedConnection = [[NSURLConnection alloc] initWithRequest: request delegate: self];
      extendedDataChanged = YES;
      _isNaim = ([_extendedURL rangeOfString: @"/TrackData/FileDelivery.vf?"].length > 0);
    }
    
    if (songId != nil && ![songId isEqualToString: _songId])
    {
      [_songId release];
      _songId = [songId retain];    
      changed |= SOURCE_MEDIA_SERVER_SONG_CHANGED;
      extendedDataChanged = YES;
    }
    
    if (song != nil && extendedDataChanged && ![song isEqualToString: _song])
    {
      [_song release];
      _song = [song retain];    
      changed |= SOURCE_MEDIA_SERVER_SONG_CHANGED;
    }
    
    if (nextSong != nil && ![nextSong isEqualToString: _nextSong])
    {
      [_nextSong release];
      _nextSong = [nextSong retain];
      changed |= SOURCE_MEDIA_SERVER_NEXT_SONG_CHANGED;
    }
    
    if (album != nil && extendedDataChanged && ![album isEqualToString: _album])
    {
      [_album release];
      _album = [album retain];
      changed |= SOURCE_MEDIA_SERVER_ALBUM_CHANGED;
    }
    
    if (artist != nil && extendedDataChanged && ![artist isEqualToString: _artist])
    {
      [_artist release];
      _artist = [artist retain];
      changed |= SOURCE_MEDIA_SERVER_ARTIST_CHANGED;
    }
    
    if (genre != nil && extendedDataChanged && ![genre isEqualToString: _genre])
    {
      [_genre release];
      _genre = [genre retain];
      changed |= SOURCE_MEDIA_SERVER_GENRE_CHANGED;
    }
    
    if (changed != 0)
    {
      // Some media servers send the same URL for all cover art and change the
      // image dynamically when the track changes.  So if any song details have
      // changed, assume the cover art has as well
      [_coverArtURL release];
      _coverArtURL = nil;
    }
    [self handleCoverArtURL: coverArtURL withChangeFlags: changed];
    
    if (timeStr != nil)
    {
      NSUInteger time = [timeStr integerValue];
      
      if (time != _time)
      {
        _time = time;
        changed |= SOURCE_MEDIA_SERVER_TIME_CHANGED;
      }
    }
    
    if (elapsedStr != nil)
    {
      NSUInteger elapsed = [elapsedStr integerValue];
      
      if (elapsed != _elapsed)
      {
        _elapsed = elapsed;
        if (_time == 0)
          _elapsedPercent = 0;
        else
          _elapsedPercent = _elapsed / (_time * 10.0);
        changed |= SOURCE_MEDIA_SERVER_ELAPSED_CHANGED;
      }
    }
    
    if (songIndexStr != nil)
    {
      NSUInteger songIndex = [songIndexStr integerValue];
      
      if (songIndex != _songIndex)
      {
        _songIndex = songIndex;
        changed |= SOURCE_MEDIA_SERVER_SONG_INDEX_CHANGED;
      }
    }
    
    if (songTotalStr != nil)
    {
      NSUInteger songTotal = [songTotalStr integerValue];
      
      if (songTotal != _songTotal)
      {
        _songTotal = songTotal;
        changed |= SOURCE_MEDIA_SERVER_SONG_TOTAL_CHANGED;
      }
    }
    
    if (controlStateStr != nil)
    {
      NSUInteger transportState = _transportState;
      
      [_controlState release];
      _controlState = [controlStateStr retain];
      
      if ([controlStateStr isEqualToString: @"STOP"])
        transportState = TRANSPORT_STATE_STOP;
      else if ([controlStateStr isEqualToString: @"PAUSE"])
        transportState = TRANSPORT_STATE_PAUSE;
      else if ([controlStateStr isEqualToString: @"PLAY"])
        transportState = TRANSPORT_STATE_PLAY;
      
      if (transportState != _transportState)
      {
        _transportState = transportState;
        changed |= SOURCE_MEDIA_SERVER_TRANSPORT_STATE_CHANGED;
      }
    }
    
    if (shuffleStr != nil)
    {
      if (_debounceShuffle > 0)
        --_debounceShuffle;
      else
      {
        BOOL shuffle = [shuffleStr isEqualToString: @"1"];
        
        if (shuffle != _shuffle)
        {
          _shuffle = shuffle;
          changed |= SOURCE_MEDIA_SERVER_SHUFFLE_CHANGED;
        }
      }
    }
    
    if (datastampQueue != nil && ![datastampQueue isEqualToString: _datastampQueue])
    {
      [_datastampQueue release];
      _datastampQueue = [datastampQueue retain];
      changed |= SOURCE_MEDIA_SERVER_PLAY_QUEUE_CHANGED;
    }
    
    if (datastampLibrary != nil && ![datastampLibrary isEqualToString: _datastampLibrary])
    {
      [_datastampLibrary release];
      _datastampLibrary = [datastampLibrary retain];
      changed |= SOURCE_MEDIA_SERVER_LIBRARY_CHANGED;
    }
    
    if (caption != nil)
    {
      BOOL docked = ([caption rangeOfString: @"dock" options: NSCaseInsensitiveSearch].length == 0);
      
      if (docked != _docked)
      {
        _docked = docked;
        changed |= SOURCE_MEDIA_SERVER_DOCKED_CHANGED;
      }
      
      if (![caption isEqualToString: _caption])
      {
        [_caption release];
        _caption = [caption retain];
        changed |= SOURCE_MEDIA_SERVER_CAPTION_CHANGED;
        if (!_docked || (changed & SOURCE_MEDIA_SERVER_DOCKED_CHANGED) != 0)
          [[self browseMenu] refresh];
      }
    }

    if (changed != 0)
      [self notifyDelegates: changed];
  }
}

- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response
{
  if (connection != _extendedConnection)
    [super connection: connection didReceiveResponse: response];
  else if ([response.MIMEType rangeOfString: @"text/xml"].length == 0)
  {
    [connection cancel];
    [self connection: connection didFailWithError: nil];
  }
}

- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) data
{
  if (connection != _extendedConnection)
    [super connection: connection didReceiveData: data];
  else if (_extendedData == nil)
    _extendedData = [data mutableCopy];
  else
    [_extendedData appendData: data];
}

- (void) connectionDidFinishLoading: (NSURLConnection *) connection
{
  if (connection != _extendedConnection)
    [super connectionDidFinishLoading: connection];
  else
  {
    CFStringEncoding encoding = StringEncodingFor( [_extendedData bytes], [_extendedData length] );
    NSStringEncoding nsEncoding;
    NSString *prefixString;
    NSMutableData *prefix;
    
    switch (encoding)
    {
      case kCFStringEncodingUTF8:
        prefixString = @"UTF-8";
        nsEncoding = NSUTF8StringEncoding;
        break;
      case kCFStringEncodingUTF16BE:
        prefixString = @"UTF-16BE";
        nsEncoding = NSUTF16BigEndianStringEncoding;
        break;
      case kCFStringEncodingUTF16LE:
        prefixString = @"UTF-16LE";
        nsEncoding = NSUTF16LittleEndianStringEncoding;
        break;
      default:
        // iPad XML parser appears not to recognize windows-1252 as an encoding name
        // (even though this worked on earlier iPhones) so we fudge it as ISO-8859-1.
        prefixString = @"ISO-8859-1";
        nsEncoding = NSWindowsCP1252StringEncoding;
        break;
    }
        
    prefixString = [NSString stringWithFormat: @"<?xml version=\"1.0\" encoding=\"%@\"?>", prefixString];
    prefix = [[prefixString dataUsingEncoding: nsEncoding] mutableCopy];
    
    [prefix appendData: _extendedData];
    [_extendedData release];
    _extendedData = prefix;
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData: _extendedData];
    NSString *oldSong = [_song retain];
    NSString *oldAlbum = [_album retain];
    NSString *oldArtist = [_artist retain];
    NSString *oldGenre = [_genre retain];
    NSUInteger changed = SOURCE_MEDIA_SERVER_SUB_GENRE_CHANGED|SOURCE_MEDIA_SERVER_COMPOSERS_CHANGED|
    SOURCE_MEDIA_SERVER_CONDUCTORS_CHANGED|SOURCE_MEDIA_SERVER_PERFORMERS_CHANGED;
    
    // Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
    [parser setDelegate: self];
    [parser setShouldProcessNamespaces: NO];
    [parser setShouldReportNamespacePrefixes: NO];
    [parser setShouldResolveExternalEntities: NO];
    
    [_subGenre release];
    _subGenre = nil;
    [_composers release];
    _composers = nil;
    [_conductors release];
    _conductors = nil;
    [_performers release];
    _performers = nil;
    
    [parser parse];
    NSError *error = [parser parserError];
    
    if (error != nil)
    {
      NSString *doc = [[NSString alloc] initWithData: _extendedData encoding: nsEncoding];
      
      NSLog( @"Extended info parse error: %@ for document: %@", error, doc );
      [doc release];
    }

    if (_composers != nil)
      [_composers sortUsingSelector: @selector(compare:)];
    if (_conductors != nil)
      [_conductors sortUsingSelector: @selector(compare:)];
    if (_performers != nil)
      [_performers sortUsingSelector: @selector(compare:)];
    if ((oldSong == nil && _song != nil) ||
        (oldSong != nil && ![oldSong isEqualToString: _song]))
      changed |= SOURCE_MEDIA_SERVER_SONG_CHANGED;
    if ((oldAlbum == nil && _album != nil) ||
        (oldAlbum != nil && ![oldAlbum isEqualToString: _album]))
      changed |= SOURCE_MEDIA_SERVER_ALBUM_CHANGED;
    if ((oldArtist == nil && _artist != nil) ||
        (oldArtist != nil && ![oldArtist isEqualToString: _artist]))
      changed |= SOURCE_MEDIA_SERVER_ARTIST_CHANGED;
    if ((oldGenre == nil && _genre != nil) ||
        (oldGenre != nil && ![oldGenre isEqualToString: _genre]))
      changed |= SOURCE_MEDIA_SERVER_GENRE_CHANGED;
    
    [_extendedData release];
    _extendedData = nil;
    [_extendedConnection release];
    _extendedConnection = nil;
    [parser release];
    [oldSong release];
    [oldAlbum release];
    [oldArtist release];
    [oldGenre release];
    
    [self notifyDelegates: changed];
  }
}

- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error
{
  if (connection != _extendedConnection)
    [super connection: connection didFailWithError: error];
  else
  {
    NSUInteger changed = 0;
    
    [_extendedData release];
    _extendedData = nil;
    [_extendedConnection release];
    _extendedConnection = nil;
    
    if (_subGenre != nil)
    {
      [_subGenre release];
      _subGenre = nil;
      changed |= SOURCE_MEDIA_SERVER_SUB_GENRE_CHANGED;
    }
    
    if (_composers != nil)
    {
      [_composers release];
      _composers = nil;
      changed |= SOURCE_MEDIA_SERVER_COMPOSERS_CHANGED;
    }
    
    if (_conductors != nil)
    {
      [_conductors release];
      _conductors = nil;
      changed |= SOURCE_MEDIA_SERVER_CONDUCTORS_CHANGED;
    }
    
    if (_performers != nil)
    {
      [_performers release];
      _performers = nil;
      changed |= SOURCE_MEDIA_SERVER_PERFORMERS_CHANGED;
    }
    
    if (changed != 0)
      [self notifyDelegates: changed];
  }
}

- (void) parser: (NSXMLParser *) parser didStartElement: (NSString *) elementName 
   namespaceURI: (NSString *) namespaceURI qualifiedName: (NSString *) qName attributes: (NSDictionary *) attributeDict
{
  NSString *name = [attributeDict objectForKey: @"name"];
  
  if (name != nil && [name length] > 0)
  {
    if (qName != nil)
      elementName = qName;
    
    if ([elementName isEqualToString: @"song"])
    {
      [_song release];
      _song = [name retain];
    }
    else if ([elementName isEqualToString: @"album"])
    {
      [_album release];
      _album = [name retain];
    }
    else if ([elementName isEqualToString: @"artist"])
    {
      [_artist release];
      _artist = [name retain];
    }
    else if ([elementName isEqualToString: @"genre"])
    {
      [_genre release];
      _genre = [name retain];
    }
    else if ([elementName isEqualToString: @"subgenre"])
    {
      [_subGenre release];
      _subGenre = [name retain];
    }
    else if ([elementName isEqualToString: @"composer"])
    {
      if (_composers == nil)
        _composers = [[NSMutableArray arrayWithObject: name] retain];
      else
        [_composers addObject: name];
    }
    else if ([elementName isEqualToString: @"conductor"])
    {
      if (_conductors == nil)
        _conductors = [[NSMutableArray arrayWithObject: name] retain];
      else
        [_conductors addObject: name];
    }
    else if ([elementName isEqualToString: @"performer"])
    {
      if (_performers == nil)
        _performers = [[NSMutableArray arrayWithObject: name] retain];
      else
        [_performers addObject: name];
    }
  }
}

- (void) dealloc
{
  [_browseMenu release];
  [_metadata release];
  [super dealloc];
}

@end
