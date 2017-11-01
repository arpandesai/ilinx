//
//  NLSourceMediaServerITunes.m
//  iLinX
//
//  Created by mcf on 19/10/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "NLSourceMediaServerITunes.h"
#import "NLBrowseListITunesRoot.h"
#import "NetStreamsComms.h"
#import "ITStatus.h"
#import "ITSession.h"

#define _plibrarySession ((ITSession *) NETSTREAMSCOMMS_PRODUCTION_ONLY(_librarySession))

@interface NLSourceMediaServerITunes ()

- (void) setControlStateFromTransportState;

@end

@implementation NLSourceMediaServerITunes

+ (id) allocSourceWithSourceData: (NSDictionary *) sourceData libraryId: (NSString *) libraryId licence: (NSString *) licence
{
  return [[NLSourceMediaServerITunes alloc] initWithSourceData: sourceData libraryId: libraryId licence: licence];
}

- (id) initWithSourceData: (NSDictionary *) sourceData libraryId: (NSString *) libraryId licence: (NSString *) licence
{
  if ((self = [super initWithSourceData: sourceData comms: nil]) != nil)
  {
    _sourceData = [sourceData mutableCopy];
    [_sourceData setObject: @"MEDIASERVER" forKey: @"sourceControlType"];
    _librarySession = [[ITSession sessionWithLibraryId: libraryId licence: licence] retain];
    _controlState = [@"STOP" retain];
  }

  return self;
}

- (NLBrowseList *) browseMenu
{
  if (_browseMenu == nil)
  {
    //NSString *browseScreen = [_sourceData objectForKey: @"browseScreen"];
    
    //if (browseScreen == nil || ![browseScreen isEqualToString: @"0"])
    {
      _browseMenu = [[NLBrowseListITunesRoot alloc]
                     initWithSource: self
                     title: NSLocalizedString( @"Media",
                                              @"Title of the top level menu of available browseable media on a media server" )
                     session: _librarySession];
    }
  }

  return _browseMenu;
}

- (void) setTransportState: (NSUInteger) transportState
{
  NSUInteger oldTransportState = _transportState;

  switch (transportState)
  {
    case TRANSPORT_STATE_STOP:
      [_plibrarySession stop];
      _transportState = TRANSPORT_STATE_STOP;
      break;
    case TRANSPORT_STATE_PAUSE:
      [_plibrarySession pause];
      _transportState = TRANSPORT_STATE_PAUSE;
      break;
    case TRANSPORT_STATE_PLAY:
      [_plibrarySession play];
      _transportState = TRANSPORT_STATE_PLAY;
      break;
    default:
      break;
  }
  
  if (oldTransportState != _transportState)
    [self setControlStateFromTransportState];
}

- (void) setShuffle: (BOOL) shuffle
{
  if (_shuffle != shuffle)
  {
    _shuffle = shuffle;
    [_plibrarySession setShuffle: shuffle];
  }
}

- (BOOL) connected
{
  return _librarySession.status.connected;
}

- (NSUInteger) repeat
{
  return _repeat;
}

- (void) setRepeat: (NSUInteger) repeat
{
  if (repeat > 2)
    repeat = 0;
  _repeat = repeat;
  [_plibrarySession setRepeat: repeat];
}

- (NSUInteger) maxRepeat
{
  return 2;
}

- (void) setElapsed: (NSUInteger) elapsed
{
    _elapsed = elapsed * 1000;
    _elapsedPercent = elapsed * 100.0 / _time;
    [_plibrarySession setProgressPosition: elapsed];
}

- (NSUInteger) capabilities
{
  return (SOURCE_MEDIA_SERVER_CAPABILITY_REPEAT|SOURCE_MEDIA_SERVER_CAPABILITY_POSITION|
  SOURCE_MEDIA_SERVER_CAPABILITY_SONG_COUNT|SOURCE_MEDIA_SERVER_NEXT_SONG_CHANGED);
}

- (void) playNextTrack
{
  [_plibrarySession playNextTrack];
}

- (void) playPreviousTrack
{
  [_plibrarySession playPreviousTrack];
}

- (void) activate
{
  [super activate];
  [self iTunesStatus: _librarySession.status changed: 0xFFFFFFFF];
  //NSLog( @"Media server %@ register with iTunes: %@.%@, %@", self, _librarySession, _librarySession.status, [self stackTraceToDepth: 10] );
  [_librarySession.status addDelegate: self];
}

- (void) deactivate
{
  if (_librarySession != nil)
    [_librarySession.status removeDelegate: self];
  //NSLog( @"Media server %@ deregister from iTunes: %@.%@, %@", self, _librarySession, _librarySession.status, [self stackTraceToDepth: 10] );
  [super deactivate];
}

- (void) iTunesStatus: (ITStatus *) status changed: (NSUInteger) changeType
{
  BOOL playNotPossible = [self playNotPossible];
  NSUInteger changed = 0;

  if ((changeType & ITSTATUS_UPDATE_PROGRESS) != 0)
  {
    // Emulate NetStreams bizarreness of progress being in milliseconds but total time in seconds
    NSUInteger timeInSeconds = (status.progressTotal + 999) / 1000;

    if (timeInSeconds != _time)
    {
      _time = timeInSeconds;
      changed |= SOURCE_MEDIA_SERVER_TIME_CHANGED;
    }
    
    if (status.progressCurrent != _elapsed)
    {
      _elapsed = status.progressCurrent;
      _elapsedPercent = (_elapsed * 100.0) / status.progressTotal;
      changed |= SOURCE_MEDIA_SERVER_ELAPSED_CHANGED;
    }
  }

  if ((changeType & ITSTATUS_UPDATE_STATE) != 0)
  {
    BOOL shuffle = (status.shuffleStatus == ITSTATUS_SHUFFLE_ON);
    NSUInteger transportState;

    if (status.playStatus == ITSTATUS_STATE_PLAYING)
      transportState = TRANSPORT_STATE_PLAY;
    else if (status.playStatus == ITSTATUS_STATE_PAUSED)
      transportState = TRANSPORT_STATE_PAUSE;
    else
      transportState = TRANSPORT_STATE_STOP;
    
    if (transportState != _transportState)
    {
      _transportState = transportState;
      [self setControlStateFromTransportState];
      
      changed |= SOURCE_MEDIA_SERVER_TRANSPORT_STATE_CHANGED;
    }
    
    if (shuffle != _shuffle)
    {
      _shuffle = shuffle;
      changed |= SOURCE_MEDIA_SERVER_SHUFFLE_CHANGED;
    }
    
    if (status.repeatStatus != _repeat)
    {
      _repeat = status.repeatStatus;
      changed |= SOURCE_MEDIA_SERVER_REPEAT_CHANGED;
    }
  }
  
  if ((changeType & ITSTATUS_UPDATE_TRACK) != 0)
  {
    if (![status.trackName isEqualToString: _song])
    {
      [_song release];
      _song = [status.trackName retain];    
      changed |= SOURCE_MEDIA_SERVER_SONG_CHANGED;
    }
    
    if (![status.trackAlbum isEqualToString: _album])
    {
      [_album release];
      _album = [status.trackAlbum retain];
      changed |= SOURCE_MEDIA_SERVER_ALBUM_CHANGED;
    }
  
    if (![status.trackArtist isEqualToString: _artist])
    {
      [_artist release];
      _artist = [status.trackArtist retain];
      changed |= SOURCE_MEDIA_SERVER_ARTIST_CHANGED;
    }
    
    if (![status.trackGenre isEqualToString: _genre])
    {
      [_genre release];
      _genre = [status.trackGenre retain];
      changed |= SOURCE_MEDIA_SERVER_GENRE_CHANGED;
    }
    
    NSString *nextTrackName = status.nextTrackName;
    
    if (![nextTrackName isEqualToString: _nextSong])
    {
      [_nextSong release];
      _nextSong = [nextTrackName retain];
      changed |= SOURCE_MEDIA_SERVER_NEXT_SONG_CHANGED;
    }
    
    if (status.currentTrackIndex != _songIndex)
    {
      _songIndex = status.currentTrackIndex;
      changed |= SOURCE_MEDIA_SERVER_SONG_INDEX_CHANGED;
    }
    
    if (status.totalTracks != _songTotal)
    {
      _songTotal = status.totalTracks;
      changed |= SOURCE_MEDIA_SERVER_SONG_TOTAL_CHANGED;
    }

    // Datastamp queue
    // Datastamp library
  }
  
  if ((changeType & ITSTATUS_UPDATE_COVER) != 0)
  {
    // Hack to force the cover art to update.  The cover art URL is always
    // the same for iTunes, so set it to nil to make it appear it has changed.
    [_coverArtURL release];
    _coverArtURL = nil;
    [self handleCoverArtURL: status.coverArtURL withChangeFlags: changed];
  }
  
  if ((changeType & ITSTATUS_CONNECTED) != 0)
    changed |= SOURCE_MEDIA_SERVER_CONNECTED_CHANGED;
  
  if (playNotPossible != [self playNotPossible])
    changed |= SOURCE_MEDIA_SERVER_PLAY_POSSIBLE_CHANGED;
  
  if (changed != 0)
    [self notifyDelegates: changed];
}

- (void) setControlStateFromTransportState
{
  [_controlState release];
  if (_transportState == TRANSPORT_STATE_PLAY)
    _controlState = [@"PLAY" retain];
  else if (_transportState == TRANSPORT_STATE_PAUSE)
    _controlState = [@"PAUSE" retain];
  else
    _controlState = [@"STOP" retain];
}

- (void) dealloc
{
  [self deactivate];
  [_librarySession release];
  _librarySession = nil;
  [_browseMenu release];
  [super dealloc];
}

@end
