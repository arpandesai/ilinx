//
//  NLSourceMediaServer.m
//  iLinX
//
//  Created by mcf on 27/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLSourceMediaServer.h"
#import "ArtworkRequest.h"

// Timeout for fetching cover art, in seconds
#define URL_FETCH_TIMEOUT 5

// Cover art returned by NetStreams devices when no cover art available
static NSString *DEFAULT_ART_STRING = @"/def_src_img_1.jpg";

static NSString *VALID_URL_CHARS =
@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789%-._~:/?#[]@!$&'()*+,;=";

@interface NLSourceMediaServer ()

- (void) findExternalArtwork;
- (void) artworkFound: (UIImage *) image;

@end


@implementation NLSourceMediaServer

@synthesize
  song = _song,
  nextSong = _nextSong,
  album = _album,
  artist = _artist,
  genre = _genre,
  coverArt = _coverArt,
  time = _time,
  elapsedPercent = _elapsedPercent,
  songIndex = _songIndex,
  songTotal = _songTotal,
  transportState = _transportState,
  shuffle = _shuffle,
  subGenre = _subGenre,
  composers = _composers,
  conductors = _conductors,
  performers = _performers,
  songId = _songId,
  datastampQueue = _datastampQueue,
  datastampLibrary = _datastampLibrary,
  docked = _docked,
  caption = _caption;

- (id) initWithSourceData: (NSDictionary *) sourceData comms: (NetStreamsComms *) comms
{
  if ((self = [super initWithSourceData: sourceData comms: comms]) != nil)
  {
    _sourceDelegates = [NSMutableSet new];
    //NSLog( @"Media server %@, new _sourceDelegates: %@, %@", self, _sourceDelegates, [self stackTraceToDepth: 10] );
    _docked = YES;
  }

  return self;
}

- (NSUInteger) elapsed
{
  NSUInteger elapsed = (_elapsed + 500) / 1000;
  
  if (elapsed > _time)
    elapsed = _time;
  
  return elapsed;
}

- (void) setElapsed: (NSUInteger) elapsed
{
}

- (void) setIsCurrentSource: (BOOL) isCurrentSource
{
  if (isCurrentSource)
  {
    if (!_isCurrentSource && [_sourceDelegates count] == 0)
      [self activate];
  }
  else
  {
    if (_isCurrentSource && [_sourceDelegates count] == 0)
      [self deactivate];
  }
  
  [super setIsCurrentSource: isCurrentSource];
}

- (NSString *) controlState
{
  return _controlState;
}

- (NSUInteger) capabilities
{
  return 0;
}

- (BOOL) playNotPossible
{
  return (_songIndex == 0 && _songTotal == 0 && _transportState == TRANSPORT_STATE_STOP &&
          _time == 0 && _elapsed == 0 && [_song length] == 0 && [_album length] == 0 && [_artist length] == 0);
}

- (BOOL) connected
{
  return YES;
}

- (NSUInteger) repeat
{
  return 0;
}

- (void) setRepeat: (NSUInteger) repeat
{
}

- (NSUInteger) maxRepeat
{
  return 0;
}

- (void) playNextTrack
{
  // Child class to override
}

- (void) playPreviousTrack
{
  // Child class to override
}

- (void) addDelegate: (id<NLSourceMediaServerDelegate>) delegate
{
  if (!_isCurrentSource && [_sourceDelegates count] == 0)
    [self activate];

  [_sourceDelegates addObject: delegate];
  //NSLog( @"Media server %@, add delegate: %@ (_sourceDelegates: %@), %@", self, delegate, _sourceDelegates, [self stackTraceToDepth: 10] );
}

- (void) removeDelegate: (id<NLSourceMediaServerDelegate>) delegate
{
  if ([_sourceDelegates count] > 0)
  {
    [_sourceDelegates removeObject: delegate];
    if (!_isCurrentSource && [_sourceDelegates count] == 0)
      [self deactivate];
  }  
  //NSLog( @"Media server %@, remove delegate: %@ (_sourceDelegates: %@), %@", self, delegate, _sourceDelegates, [self stackTraceToDepth: 10] );
}

- (void) notifyDelegates: (NSUInteger) changed
{
  NSSet *delegates = [NSSet setWithSet: _sourceDelegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<NLSourceMediaServerDelegate> delegate;
  
  while ((delegate = [enumerator nextObject]))
    [delegate source: self stateChanged: changed];
}

- (void) activate
{
  [super activate];
  _song = [@"" retain];
  _album = [@"" retain];
  _artist = [@"" retain];
  _genre = [@"" retain];
  _subGenre = [@"" retain];
}

- (void) deactivate
{
  [_song release];
  _song = nil;
  [_nextSong release];
  _nextSong = nil;
  [_album release];
  _album = nil;
  [_artist release];
  _artist = nil;
  [_genre release];
  _genre = nil;
  [_coverArt release];
  _coverArt = nil;
  [_subGenre release];
  _subGenre = nil;
  [_composers release];
  _composers = nil;
  [_conductors release];
  _conductors = nil;
  [_performers release];
  _performers = nil;
  [_caption release];
  _caption = nil;
  _time = 0;
  _elapsed = 0;
  _elapsedPercent = 0;
  _songIndex = 0;
  _songTotal = 0;
  _transportState = TRANSPORT_STATE_STOP;
  [_controlState release];
  _controlState = nil;
  _shuffle = NO;

  [_coverArtURL release];
  _coverArtURL = nil;
  if (_coverArtConnection != nil)
  {
    [_coverArtConnection cancel];
    [_coverArtConnection release];
    _coverArtConnection = nil;
  }
  [_coverArtData release];
  _coverArtData = nil;
  [_oldCoverArtData release];
  _oldCoverArtData = nil;
  [_artRequest release];
  _artRequest = nil;
  [super deactivate];
}

- (void) handleCoverArtURL: (NSString *) coverArtURL withChangeFlags: (NSUInteger) changed
{
  if ([coverArtURL rangeOfCharacterFromSet: 
       [NSCharacterSet characterSetWithCharactersInString: VALID_URL_CHARS]].length != [coverArtURL length])
    coverArtURL = [coverArtURL stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];

  if (coverArtURL != nil && ![coverArtURL isEqualToString: _coverArtURL])
  {
    [_coverArtURL release];
    _coverArtURL = [coverArtURL retain];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: _coverArtURL] 
                                             cachePolicy: NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval: URL_FETCH_TIMEOUT];
    
    [_oldCoverArtData release];
    _oldCoverArtData = _coverArtData;
    _coverArtData = nil;
    
    if (_coverArtConnection != nil)
    {
      [_coverArtConnection cancel];
      [_coverArtConnection release];
    }
    [request setValue: @"1" forHTTPHeaderField: @"Viewer-Only-Client"];
    _coverArtConnection = [[NSURLConnection alloc] initWithRequest: request delegate: self];
  }
  
  if ((_coverArtURL == nil || [_coverArtURL length] == 0 || [_coverArtURL rangeOfString: DEFAULT_ART_STRING].length > 0) &&
      (changed & (SOURCE_MEDIA_SERVER_SONG_CHANGED|SOURCE_MEDIA_SERVER_ALBUM_CHANGED|
                  SOURCE_MEDIA_SERVER_ARTIST_CHANGED|SOURCE_MEDIA_SERVER_GENRE_CHANGED|
                  SOURCE_MEDIA_SERVER_SUB_GENRE_CHANGED)) != 0)
  {
    [self findExternalArtwork];
  }
}

- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response
{
  if (connection == _coverArtConnection)
  {
    // If it returns a not found type response, treat as a failure
    
    if ([[response MIMEType] rangeOfString: @"image"].length == 0)
    {
#ifdef DEBUG
      NSString *type = [[response MIMEType] retain];
      
      [type release];
#endif
      [connection cancel];
      [self connection: connection didFailWithError: nil];
    }
  }  
}

- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) data
{
  if (connection == _coverArtConnection)
  {
    if (_coverArtData == nil)
      _coverArtData = [data mutableCopy];
    else
      [_coverArtData appendData: data]; 
  }
}

- (void) connectionDidFinishLoading: (NSURLConnection *) connection
{
  if (connection == _coverArtConnection)
  {
    BOOL changed;
    
    if (_coverArtData == nil)
    {
      changed = NO;
      [self findExternalArtwork];
    }
    else if ([_coverArtData isEqualToData: _oldCoverArtData])
      changed = NO;
    else
    {
      _coverArt = [[UIImage imageWithData: _coverArtData] retain];
      changed = YES;
    }
    
    [_oldCoverArtData release];
    _oldCoverArtData = nil;
    [_coverArtConnection release];
    _coverArtConnection = nil;
    
    if (changed)
      [self notifyDelegates: SOURCE_MEDIA_SERVER_COVER_ART_CHANGED];
  }
}

- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error
{
  if (connection == _coverArtConnection)
  {
    [_oldCoverArtData release];
    _oldCoverArtData = nil;
    [_coverArtData release];
    _coverArtData = nil;
    [_coverArtConnection release];
    _coverArtConnection = nil;
    
    [self findExternalArtwork];
  }
}

- (void) findExternalArtwork
{
  NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys: 
                        _song, @"song",
                        _album, @"album",
                        _artist, @"artist",
                        _genre, @"genre",
                        _subGenre, @"subGenre",
                        nil];
  
  [_coverArtData release];
  _coverArtData = nil;
  [_oldCoverArtData release];
  _oldCoverArtData = nil;
  
  if (_artRequest != nil)
  {
    [_artRequest invalidate];
    [_artRequest release];
    _artRequest = nil;
  }
  _artRequest = [[ArtworkRequest allocRequestImageForSource: self item: data target: self action: @selector(artworkFound:)] retain];
}

- (void) artworkFound: (UIImage *) image
{
  BOOL changed;
  
  if (image == nil)
  {
    UIImage *defaultCoverArt;
    
    if (_isNaim)
      defaultCoverArt = [UIImage imageNamed: @"DefaultCoverArtNaim.png"];
    else
      defaultCoverArt = [UIImage imageNamed: @"DefaultCoverArt.png"];
    
    if (_coverArt == defaultCoverArt)
      changed = NO;
    else
    {
      [_coverArt release];
      _coverArt = [defaultCoverArt retain];
      changed = YES;
    }
  }
  else if (image == _coverArt)
    changed = NO;
  else
  {
    [_coverArt release];
    _coverArt = [image retain];
    changed = YES;
  }
  
  if (_artRequest != nil)
  {
    [_artRequest release];
    _artRequest = nil;
  }
  
  if (changed)
    [self notifyDelegates: SOURCE_MEDIA_SERVER_COVER_ART_CHANGED];
}

- (void) dealloc
{
  //NSLog( @"Media server %@, dealloc %@", self, [self stackTraceToDepth: 10] );
  [self deactivate];
  [_sourceDelegates release];
  [super dealloc];
}

@end
