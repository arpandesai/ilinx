//
//  ITStatus.h
//  iLinX
//
//  Created by mcf on 19/10/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DebugTracing.h"
#import "ITRequest.h"

#define ITSTATUS_REPEAT_OFF    0
#define ITSTATUS_REPEAT_SINGLE 1
#define ITSTATUS_REPEAT_ALL    2

#define ITSTATUS_SHUFFLE_OFF   0
#define ITSTATUS_SHUFFLE_ON    1

#define ITSTATUS_STATE_STOPPED 2
#define ITSTATUS_STATE_PAUSED  3
#define ITSTATUS_STATE_PLAYING 4

#define ITSTATUS_UPDATE_PROGRESS  0x0001
#define ITSTATUS_UPDATE_STATE     0x0002
#define ITSTATUS_UPDATE_TRACK     0x0004
#define ITSTATUS_UPDATE_COVER     0x0008
#define ITSTATUS_CONNECTED        0x0010

@class ITSession;
@class ITStatus;
@class ITURLConnection;

@protocol ITStatusDelegate <NSObject>

- (void) iTunesStatus: (ITStatus *) status changed: (NSUInteger) changeType;

@end

@interface ITStatus : NSDebugObject <ITRequestDelegate>
{
@protected
  NSUInteger _repeatStatus;
  NSUInteger _shuffleStatus;
  NSUInteger _playStatus;
  NSString *_trackName;
  NSString *_trackArtist;
  NSString *_trackAlbum;
  NSString *_trackGenre;
  NSUInteger _progressTotal;
  NSUInteger _progressRemain;
  NSString * _albumId;
  ITSession *_session;
  NSTimer *_progressTimer;
  ITRequest *_immediateStatusRequest;
  ITRequest *_nextStatusRequest;
  ITRequest *_playlistRequest;
  NSUInteger _failures;
  NSUInteger _revision;
  NSString *_coverArtURL;
  NSDate *_anchor;
  NSMutableSet *_delegates;
  ITURLConnection *_nextStatusConnection;
  ITURLConnection *_immediateConnection;
  BOOL _updatesEnabled;
  NSUInteger _currentPlaylistId;
  NSUInteger _currentTrackInPlaylistId;
  NSArray *_currentPlaylist;
  NSMutableDictionary *_currentPlaylistIndexLookup;
  NSUInteger _currentTrackIndex;
  NSUInteger _totalTracks;
  BOOL _connected;
}

@property (readonly) NSUInteger repeatStatus;
@property (readonly) NSUInteger shuffleStatus;
@property (readonly) NSUInteger playStatus;
@property (readonly) NSString *trackName;
@property (readonly) NSString *trackArtist;
@property (readonly) NSString *trackAlbum;
@property (readonly) NSString *trackGenre;
@property (readonly) NSString *nextTrackName;
@property (readonly) NSUInteger progressCurrent;
@property (readonly) NSUInteger progressRemaining;
@property (readonly) NSUInteger progressTotal;
@property (readonly) NSUInteger currentTrackIndex;
@property (readonly) NSUInteger totalTracks;
@property (readonly) NSString *albumId;
@property (readonly) NSString *coverArtURL;
@property (readonly) NSUInteger revision;
@property (readonly) BOOL failed;
@property (readonly) BOOL connected;

- (id) initWithSession: (ITSession *) session;
- (void) addDelegate: (id<ITStatusDelegate>) delegate;
- (void) removeDelegate: (id<ITStatusDelegate>) delegate;
- (void) adjustProgress: (NSUInteger) progress;
- (void) fetchUpdate;
- (void) destroy;

@end
