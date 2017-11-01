//
//  ITSession.h
//  iLinX
//
//  Created by mcf on 19/10/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DebugTracing.h"
#import "ITRequest.h"

@class ITStatus;
@class ITURLConnection;

@interface ITSession : NSDebugObject <ITRequestDelegate, NSNetServiceDelegate>
{
@protected
  NSString *_libraryId;
  NSNetService *_iTunesService;
  NSString *_host;
  NSString *_requestBase;
  NSString *_sessionId;
  NSString *_databaseId;
  NSString *_databasePersistentId;
  NSString *_musicId;
  NSUInteger _musicIdAsUInt;
  NSMutableDictionary *_pendingCalls;
  ITURLConnection *_connection;
  ITStatus *_status;
  NSTimer *_sessionStartTimer;
  BOOL _resolving;
  NSUInteger _errorState;
  BOOL _ownsLoginInfo;
}

@property (readonly) NSString *libraryId;
@property (readonly) NSString *sessionId;
@property (readonly) NSString *databaseId;
@property (readonly) NSString *databasePersistentId;
@property (readonly) NSString *musicId;
@property (readonly) NSUInteger musicIdAsUInt;
@property (readonly) ITStatus *status;
@property (readonly) BOOL isConnected;
@property (readonly) BOOL isPending;
@property (readonly) NSString *errorMessage;

+ (ITSession *) sessionWithLibraryId: (NSString *) libraryId licence: (NSString *) licence;
- (id) initWithLibraryId: (NSString *) libraryId licence: (NSString *) licence;
- (void) play;
- (void) pause;
- (void) stop;
- (void) togglePlayPause;
- (void) playNextTrack;
- (void) playPreviousTrack;
- (void) setProgressPosition: (NSUInteger) progressSeconds;
- (void) setShuffle: (BOOL) shuffle;
- (void) setRepeat: (NSUInteger) repeatMode;
- (void) playAlbum: (NSString *) albumId fromTrack: (NSUInteger) trackNum;
- (void) playArtist: (NSString *) artist;
- (void) playSearch: (NSString *) search fromTrack: (NSUInteger) trackNum;
- (void) doAction: (NSString *) action;
- (void) clearAndDoAction: (NSString *) action;
- (NSString *) getRequestBase;
- (void) relogin;

@end
