//
//  ITStatus.m
//  iLinX
//
//  Created by mcf on 19/10/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "ITStatus.h"
#import "ITRequest.h"
#import "ITResponse.h"
#import "ITSession.h"
#import "ITURLConnection.h"
#import "WeakReference.h"
#import "DebugTracing.h"

#define MAX_FAILURES 20 

#define PROGRESS_INTERVAL 0.5
#define KEEPALIVE_INTERVAL 1

@interface ITStatus ()

- (void) _progressTimerFired: (NSTimer *) timer;
- (void) _requestNextStatusChange;
- (void) _parseStatusUpdate: (ITResponse *) response;
- (void) _setProgressTimerForPlayStatus: (NSUInteger) playStatus;

@end

@implementation ITStatus

@synthesize
  repeatStatus = _repeatStatus,
  shuffleStatus = _shuffleStatus,
  playStatus = _playStatus,
  progressRemaining = _progressRemain,
  progressTotal = _progressTotal,
  trackName = _trackName,
  trackArtist = _trackArtist,
  trackAlbum = _trackAlbum,
  trackGenre = _trackGenre,
  albumId = _albumId,
  coverArtURL = _coverArtURL,
  revision = _revision,
  currentTrackIndex = _currentTrackIndex,
  totalTracks = _totalTracks,
  connected = _connected;

- (NSString *) nextTrackName
{
  if (_currentTrackIndex == 0 || _totalTracks < _currentTrackIndex)
    return @"";
  else if (_repeatStatus == ITSTATUS_REPEAT_SINGLE)
    return [[_currentPlaylist objectAtIndex: _currentTrackIndex - 1] stringForKey: @"minm"];
  else if (_repeatStatus == ITSTATUS_REPEAT_ALL && _currentTrackIndex == _totalTracks)
    return [[_currentPlaylist objectAtIndex: 0] stringForKey: @"minm"];
  else if (_currentTrackIndex < _totalTracks)
    return [[_currentPlaylist objectAtIndex: _currentTrackIndex] stringForKey: @"minm"];
  else
    return @"";
}

- (id) initWithSession: (ITSession *) session
{
  if ((self = [super init]) != nil)
  {
    _delegates = [NSMutableSet new];
    _session = session; // Don't retain as session retains us.
    _playStatus = ITSTATUS_STATE_STOPPED;
    _trackName = [@"" retain];
    _trackArtist = [@"" retain];
    _trackAlbum = [@"" retain];
    _trackGenre = [@"" retain];
    _albumId = [@"" retain];
    _nextStatusConnection = [[ITURLConnection alloc] init];
    _immediateConnection = [[ITURLConnection alloc] init];
    _revision = 1;
  }

  return self;
}

- (NSUInteger) progressCurrent
{
  return (_progressTotal - _progressRemain);
}

- (BOOL) failed
{
  return _failures > MAX_FAILURES;
}

- (void) addDelegate: (id<ITStatusDelegate>) delegate
{
  NSUInteger count = [_delegates count];

  [_delegates addObject: [WeakReference weakReferenceForObject: delegate]];
  //NSLog( @"ITStatus %@ addDelegate: %@, %@", self, delegate, [self stackTraceToDepth: 10] );
  if (count == 0)
    [self _requestNextStatusChange];
}

- (void) removeDelegate: (id<ITStatusDelegate>) delegate
{
  [_delegates removeObject: [WeakReference weakReferenceForObject: delegate]];
  //NSLog( @"ITStatus %@ removeDelegate: %@, %@", self, delegate, [self stackTraceToDepth: 10] );
}

- (void) notifyDelegates: (NSUInteger) updateFlags
{
  if ([_delegates count] > 0)
  {
    NSSet *fixedSet = [_delegates copy];
    
    [self retain];
    for (WeakReference *delegateRef in [_delegates allObjects])
      [(id<ITStatusDelegate>) [delegateRef referencedObject] iTunesStatus: self changed: updateFlags];

    [self release];
    [fixedSet release];
  }
}

- (void) adjustProgress: (NSUInteger) progress
{
  NSUInteger oldPlayStatus = _playStatus;
  
  _playStatus = 0;
  [_progressTimer invalidate];
  _progressTimer = nil;
  [_anchor release];
  _anchor = nil;
  _progressRemain = _progressTotal - progress;
  [self _setProgressTimerForPlayStatus: oldPlayStatus];
  _playStatus = oldPlayStatus;
}

- (void) fetchUpdate
{
  // using revision-number=1 will make sure we return instantly
  if (_session.sessionId != nil)
  {
    _immediateStatusRequest = [ITRequest allocRequest:
                      [NSString stringWithFormat: @"%@/ctrl-int/1/playstatusupdate?revision-number=1&session-id=%@",
                       [_session getRequestBase], _session.sessionId]
                                   connection: _immediateConnection
                                     delegate: self];
  }
}

- (void) destroy
{
  [_progressTimer invalidate];
  _progressTimer = nil;
}

- (void) _progressTimerFired: (NSTimer *) timer
{
  if (_progressTimer != nil && _playStatus == ITSTATUS_STATE_PLAYING)
  {
    NSUInteger elapsed = ([[NSDate date] timeIntervalSinceDate: _anchor] * 1000);
    NSUInteger oldRemain = _progressRemain;
      
    if (elapsed < _progressRemain)
      _progressRemain -= elapsed;
    else
      _progressRemain = 0;
    
    if (oldRemain != _progressRemain)
      [self notifyDelegates: ITSTATUS_UPDATE_PROGRESS];

    [_anchor release];
    _anchor = [[NSDate date] retain];
  }
}

- (void) _requestNextStatusChange
{
  if (_nextStatusRequest == nil && _session.sessionId != nil)
  {
    _nextStatusRequest = [ITRequest allocRequest: 
                          [NSString stringWithFormat: @"%@/ctrl-int/1/playstatusupdate?revision-number=%d&session-id=%@",
                           [_session getRequestBase], _revision, _session.sessionId]
                                      connection: _nextStatusConnection
                                        delegate: self];
  }
}

- (void) request: (ITRequest *) request failedWithError: (NSError *) error
{
#ifdef DEBUG
  NSLog( @"%@: request %@ failed: %@", self, request.requestString, error );
#endif
  if (_connected)
  {
    _connected = NO;
    [self notifyDelegates: ITSTATUS_CONNECTED];
  }
  
  if (request == _playlistRequest)
    _playlistRequest = nil;
  else 
  {
    if (request == _nextStatusRequest)
      _nextStatusRequest = nil;
    else
      _immediateStatusRequest = nil;

    [_session relogin];
    _revision = 1;
  }

  [request release];
}

- (void) request: (ITRequest *) request succeededWithResponse: (ITResponse *) response
{
  if (!_connected)
  {
    _connected = YES;
    [self notifyDelegates: ITSTATUS_CONNECTED];
  }
  
  _failures = 0;
  if (request == _playlistRequest)
  {
    [_currentPlaylist release];
    _currentPlaylist = [[[[response responseForKey: @"apso"] responseForKey: @"mlcl"] allItemsWithPrefix: @"mlit"] retain];
    
    if (_currentPlaylist != nil)
    {
      NSNumber *currentTrack = [NSNumber numberWithUnsignedInteger: _currentTrackInPlaylistId];

      _currentTrackIndex = 0;
      _totalTracks = [_currentPlaylist count];
      [_currentPlaylistIndexLookup release];
      _currentPlaylistIndexLookup = [[NSMutableDictionary dictionaryWithCapacity: _totalTracks] retain];

      for (NSUInteger i = 0; i < _totalTracks; ++i)
      {
        NSNumber *trackId = [[_currentPlaylist objectAtIndex: i] numberForKey: @"mcti"];
        
        if (trackId != nil)
        {
          [_currentPlaylistIndexLookup setObject: [NSNumber numberWithUnsignedInteger: i + 1] forKey: trackId];
          if ([trackId isEqualToNumber: currentTrack])
            _currentTrackIndex = i + 1;
        }
      }
    }

    _playlistRequest = nil;
    [self notifyDelegates: 0xFFFFFFFF];
  }
  else
  {
    if (request == _nextStatusRequest)
      _nextStatusRequest = nil;
    else
      _immediateStatusRequest = nil;
  
    [self _parseStatusUpdate: response];
  }

  [request release];
}

- (void) _parseStatusUpdate: (ITResponse *) response
{
  /*
   *  cmst  --+
   mstt   4      000000c8 == 200
   cmsr   4      00000079 == 121	[revisionnum, version control]
   caps   1      04 == 4		[3=paused, 4=playing]
   cash   1      01 == 1		[1=shuffle]
   carp   1      00 == 0		[repeat, 2=all, 1=only, 0=off]
   cavc   1      01 == 1
   caas   4      00000002 == 2
   caar   4      00000006 == 6
   canp   16     00000026000000ea0000010300000065
   cann   38     The Night of Your Life is When You Die
   cana   14     Capital Lights
   canl   19     This is an Outrage!
   cang   14     Christian Rock
   asai   8      df4b61d9be01973b	[album id]
   cmmk   4      00000001 == 1
   cant   4      00014813 == 83987
   cast   4      0002eb58 == 191320
   */
#if INDIVIDUAL_UPDATES
  NSUInteger updateType = 0;

#endif
  response = [response responseForKey: @"cmst"];
  _revision = [response unsignedIntegerForKey: @"cmsr"];
  
  NSUInteger playStatus = (NSUInteger) [response unsignedIntegerForKey: @"caps"];
  NSUInteger shuffleStatus = (NSUInteger) [response unsignedIntegerForKey: @"cash"];
  NSUInteger repeatStatus = (NSUInteger) [response unsignedIntegerForKey: @"carp"];
  BOOL shuffleChanged = (_shuffleStatus != shuffleStatus);
  
  // update state if changed
  if (playStatus != _playStatus || shuffleStatus != _shuffleStatus || repeatStatus != _repeatStatus)
  {
#if INDIVIDUAL_UPDATES
    updateType |= ITSTATUS_UPDATE_STATE;
#endif
    [self _setProgressTimerForPlayStatus: playStatus];
    _playStatus = playStatus;
    _shuffleStatus = shuffleStatus;
    _repeatStatus = repeatStatus;
  }
  
  NSString *trackName = [response stringForKey: @"cann"];
  NSString *trackArtist = [response stringForKey: @"cana"];
  NSString *trackAlbum = [response stringForKey: @"canl"];
  NSString *trackGenre = [response stringForKey: @"cang"];
  NSArray *trackData = [response arrayForKey: @"canp"];
  
  if (trackData == nil || [trackData count] <= 2)
  {
    _currentPlaylistId = 0;
    _currentTrackInPlaylistId = 0;
    _currentTrackIndex = 0;
    _totalTracks = 0;
    [_currentPlaylist release];
    _currentPlaylist = nil;
    [_currentPlaylistIndexLookup release];
    _currentPlaylistIndexLookup = nil;
    [_playlistRequest cancel];
    [_playlistRequest release];
    _playlistRequest = nil;
  }
  else
  {
    NSUInteger currentPlaylistId = [[trackData objectAtIndex: 1] unsignedIntegerValue];
    NSUInteger currentTrackInPlaylistId = [[trackData objectAtIndex: 2] unsignedIntegerValue];

    if (_currentPlaylist == nil || _currentPlaylistId != currentPlaylistId || shuffleChanged)
    {
      _currentPlaylistId = currentPlaylistId;
      _currentTrackInPlaylistId = currentTrackInPlaylistId;
      _currentTrackIndex = 0;
      _totalTracks = 0;
      [_currentPlaylist release];
      _currentPlaylist = nil;
      [_currentPlaylistIndexLookup release];
      _currentPlaylistIndexLookup = nil;

      if (_playlistRequest != nil)
      {
        [_playlistRequest cancel];
        [_playlistRequest release];
      }

#if 0
      if (currentPlaylistId == _session.musicIdAsUInt)
        _playlistRequest = nil;
      else
        _playlistRequest = [ITRequest allocRequest: 
                            [NSString stringWithFormat: @"%@/databases/%@/containers/%u/items?session-id=%@&meta=dmap.itemname,dmap.containeritemid",
                             [_session getRequestBase], _session.databaseId, currentPlaylistId, _session.sessionId]
                                         connection: _immediateConnection
                                           delegate: self];
#else
      _playlistRequest = nil;
#endif
#if INDIVIDUAL_UPDATES
      updateType |= ITSTATUS_UPDATE_TRACK;
#endif
    }
    else if (_currentTrackInPlaylistId != currentTrackInPlaylistId)
    {
      NSNumber *trackIndex = [_currentPlaylistIndexLookup objectForKey: [trackData objectAtIndex: 2]];
      
      _currentTrackInPlaylistId = currentTrackInPlaylistId;
      if (trackIndex == nil)
        _currentTrackIndex = 0;
      else
        _currentTrackIndex = [trackIndex unsignedIntegerValue];
#if INDIVIDUAL_UPDATES
      updateType |= ITSTATUS_UPDATE_TRACK;
#endif
    }
  }
  
  [_albumId release];
  _albumId = [[response numberStringForKey: @"asai"] retain];
  
  // update if track changed
  if (![trackName isEqualToString: _trackName] ||
      ![trackArtist isEqualToString: _trackArtist] ||
      ![trackAlbum isEqualToString: _trackAlbum] ||
      ![trackGenre isEqualToString: _trackGenre])
  {
#if INDIVIDUAL_UPDATES
    updateType |= ITSTATUS_UPDATE_TRACK|ITSTATUS_UPDATE_COVER;
#endif
    [_trackName release];
    _trackName = [trackName retain];
    [_trackArtist release];
    _trackArtist = [trackArtist retain];
    [_trackAlbum release];
    _trackAlbum = [trackAlbum retain];
    [_trackGenre release];
    _trackGenre = [trackGenre retain];
    
    // clear any coverart cache
    [_coverArtURL release];
    _coverArtURL = [[NSString stringWithFormat: @"%@/ctrl-int/1/nowplayingartwork?mw=640&mh=640&session-id=%@",
                    [_session getRequestBase], _session.sessionId] retain];
    
    // tell our progress updating thread about a new track
    // this makes sure he doesnt count progress from last song against this new one
    if (_playStatus == ITSTATUS_STATE_PLAYING)
    {
      [_anchor release];
      _anchor = [[NSDate date] retain];
    }
  }
  
  //NSUInteger oldRemain = _progressRemain;
  //NSUInteger oldTotal = _progressTotal;
  
  _progressTotal = [response unsignedIntegerForKey: @"cast"];
  if ([response itemForKey: @"cant"] == nil)
    _progressRemain = _progressTotal;
  else
    _progressRemain = [response unsignedIntegerForKey: @"cant"];
  //if (_progressRemain != oldRemain || _progressTotal != oldTotal)
  //  updateType |= ITSTATUS_UPDATE_PROGRESS;
  
  // send off updated event to gui

#if INDIVIDUAL_UPDATES
  [self notifyDelegates: updateType];
#else
  [self notifyDelegates: 0xFFFFFFFF];
#endif

  [self _requestNextStatusChange];
}

- (void) _setProgressTimerForPlayStatus: (NSUInteger) playStatus
{
  if (playStatus == ITSTATUS_STATE_PLAYING)
  {
    if (_anchor == nil)
      _anchor = [[NSDate date] retain];
    if (_playStatus != ITSTATUS_STATE_PLAYING)
      _progressTimer = [NSTimer scheduledTimerWithTimeInterval: PROGRESS_INTERVAL target: self
                                                      selector: @selector(_progressTimerFired:) userInfo: nil repeats: YES];    
  }
  else
  {
    if (_anchor != nil)
    {
      [_anchor release];
      _anchor = nil;
    }
    if (_playStatus != ITSTATUS_STATE_PAUSED)
    {
      [_progressTimer invalidate];
      _progressTimer = nil;
    }
  }
}

- (void) dealloc
{
  [_delegates release];
  [_trackName release];
  [_trackArtist release];
  [_trackAlbum release];
  [_trackGenre release];
  [_albumId release];
  [_progressTimer invalidate];
  [_immediateStatusRequest release];
  [_nextStatusRequest release];
  [_playlistRequest release];
  [_coverArtURL release];
  [_anchor release];
  [_immediateConnection close];
  [_immediateConnection release];
  [_nextStatusConnection close];
  [_nextStatusConnection release];
  [_currentPlaylist release];
  [_currentPlaylistIndexLookup release];
  [super dealloc];
}

@end
