//
//  ITSession.m
//  iLinX
//
//  Created by mcf on 19/10/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#import "AppStateNotification.h"
#import "ITSession.h"
#import "ITStatus.h"
#import "ITRemoteService.h"
#import "ITRequest.h"
#import "ITResponse.h"
#import "ITURLConnection.h"
#import "LicenceString.h"
#import "WeakReference.h"

#define SESSION_START_RETRY_TIME 2
#define SERVICE_RESOLVE_TIMEOUT 5

// Possible states
#define STATE_INVALID_LICENCE           11
#define STATE_RESOLVING_SERVICE         10
#define STATE_UNABLE_TO_RESOLVE_SERVICE 9
#define STATE_NOT_YET_PAIRED            8
#define STATE_LOGGING_IN                7
#define STATE_NO_NETWORK_CONNECTIVITY   6
#define STATE_UNABLE_TO_LOGIN           5
#define STATE_GETTING_DATABASE_ID       4
#define STATE_NO_DATABASE_ID            3
#define STATE_GETTING_MUSIC_ID          2
#define STATE_NO_MUSIC_ID               1
#define STATE_READY                     0

static const NSString *SEL_KEY = @"selector";
static const NSString *FOLLOWING_ACTION_KEY = @"following-action";
static NSString *ITUNES_LIBRARY_TYPE = @"_touch-able._tcp.";
static NSString *kITunesLibraryDataKey = @"iTunesLibraryData";
static NSArray *STATE_MESSAGES = nil;

static NSNetService *g_ourRemoteService = nil;
static NSUInteger g_remoteServiceUsageCount = 0;
static NSMutableDictionary *g_successfulLoginsSessionData = nil;
static NSMutableDictionary *g_allSessions = nil;

@interface ITSession ()

- (void) _reconnect;
- (void) _applicationToForeground;
- (void) _applicationToBackground;
- (void) waitAndStartSession;
- (void) startSessionAfterTimeout: (NSTimer *) timer;
- (void) handleServerInfoResponse: (ITResponse *) response;
- (void) handleLoginResponse: (ITResponse *) response;
- (void) handleFindDatabaseResponse: (ITResponse *) response;
- (void) handleFindMusicIdResponse: (ITResponse *) response;
- (void) handleActionResponse: (ITResponse *) response;
- (void) handleClearResponse: (ITResponse *) response withFollowingAction: (NSDictionary *) actionData;
- (void) resetData;
- (BOOL) checkLicence: (NSString *) licence;

@end

@implementation ITSession

@synthesize
  libraryId = _libraryId,
  databaseId = _databaseId,
  databasePersistentId = _databasePersistentId,
  sessionId = _sessionId,
  musicId = _musicId,
  musicIdAsUInt = _musicIdAsUInt,
  status = _status;

+ (ITSession *) sessionWithLibraryId: (NSString *) libraryId licence: (NSString *) licence
{
  WeakReference *sessionRef = [g_allSessions objectForKey: libraryId];
  ITSession *session;
  
  if (sessionRef == nil)
    session = [[[ITSession alloc] initWithLibraryId: libraryId licence: licence] autorelease];
  else
    session = (ITSession *) [sessionRef referencedObject];

  return session;
}

- (BOOL) isConnected
{
  return _musicId != nil;
}

- (BOOL) isPending
{
  return _errorState == STATE_RESOLVING_SERVICE ||
  _errorState == STATE_LOGGING_IN ||
  _errorState == STATE_GETTING_DATABASE_ID ||
  _errorState == STATE_GETTING_MUSIC_ID;
}

- (NSString *) errorMessage
{
  return [NSString stringWithFormat: [STATE_MESSAGES objectAtIndex: _errorState], _libraryId];
}

- (id) initWithLibraryId: (NSString *) libraryId licence: (NSString *) licence
{
  if ((self = [super init]) != nil)
  {
    if (STATE_MESSAGES == nil)
    {
      STATE_MESSAGES = [[NSArray arrayWithObjects:
                       NSLocalizedString( @"Processing root menu...", @"Message shown while preparing the root menu for display" ), 
                       NSLocalizedString( @"No root menu found in library %@", @"Error shown when unable to find the music id in an iTunes library" ),
                       NSLocalizedString( @"Getting menu for library %@...", @"Message shown when finding the music id in an iTunes library" ),
                       NSLocalizedString( @"No database found in library %@", @"Error shown when unable to find a database id for an iTunes library" ),
                       NSLocalizedString( @"Getting database in library %@...", @"Message shown when finding a database id for an iTunes library" ),
                       NSLocalizedString( @"Unable to login to library %@", @"Error shown when the initial login request fails" ),
                       NSLocalizedString( @"No network connection", @"Error shown if unable to connect to the library" ),
                       NSLocalizedString( @"Logging in to library %@...", @"Message shown when loggin in to an iTunes library" ),
                       NSLocalizedString( @"Please pair with library %@", @"Error shown if not yet paired with an iTunes library" ),
                       NSLocalizedString( @"Unable to find library %@", @"Error shown if unable to locate an iTunes service using Bonjour" ),
                       NSLocalizedString( @"Finding library %@...", @"Message shown when locating an iTunes service using Bonjour" ),
                       NSLocalizedString( @"Not licensed for library %@", @"Error shown if licence for iTunes library is not valid" ),
                       nil] retain];
    }
    
    // Add a weak reference to all new session objects to allow intercommunication
    if (g_allSessions == nil)
      g_allSessions = [NSMutableDictionary new];
    [g_allSessions setObject: [WeakReference weakReferenceForObject: self]
                      forKey: libraryId];
    if (g_successfulLoginsSessionData == nil)
      g_successfulLoginsSessionData = [NSMutableDictionary new];

    _libraryId = [libraryId retain];
    _status = [[ITStatus alloc] initWithSession: self];
    _pendingCalls = [NSMutableDictionary new];

    [AppStateNotification addWillEnterForegroundObserver: self selector: @selector(_applicationToForeground)];
    [AppStateNotification addDidEnterBackgroundObserver: self selector: @selector(_applicationToBackground)];

    if ([self checkLicence: licence])
    {
      _errorState = STATE_RESOLVING_SERVICE;
      [self startSessionAfterTimeout: nil];
    }
    else
    {
      _errorState = STATE_INVALID_LICENCE;
    }
  }

  return self;
}

- (void) play
{
  if (_errorState != STATE_INVALID_LICENCE)
  {
    if (_host == nil)
      [self waitAndStartSession];
    else if (_status.playStatus != ITSTATUS_STATE_PLAYING)
      [self doAction: [NSString stringWithFormat: @"%@/ctrl-int/1/play?session-id=%@",
                       [self getRequestBase], _sessionId]];
  }
}

- (void) pause
{
  if (_errorState != STATE_INVALID_LICENCE)
  {
    if (_host == nil)
      [self waitAndStartSession];
    else if (_status.playStatus != ITSTATUS_STATE_PAUSED)
      [self doAction: [NSString stringWithFormat: @"%@/ctrl-int/1/pause?session-id=%@",
                       [self getRequestBase], _sessionId]];
  }
}

- (void) stop
{
  if (_errorState != STATE_INVALID_LICENCE)
  {
    if (_host == nil)
      [self waitAndStartSession];
    else if (_status.playStatus != ITSTATUS_STATE_STOPPED)
      [self doAction: [NSString stringWithFormat: @"%@/ctrl-int/1/stop?session-id=%@",
                       [self getRequestBase], _sessionId]];
  }
}

- (void) togglePlayPause
{
  if (_errorState != STATE_INVALID_LICENCE)
  {
    [self doAction: [NSString stringWithFormat: @"%@/ctrl-int/1/playpause?session-id=%@",
                     [self getRequestBase], _sessionId]];
  }
}

- (void) playNextTrack
{
  if (_errorState != STATE_INVALID_LICENCE)
  {
    [self doAction: [NSString stringWithFormat: @"%@/ctrl-int/1/nextitem?session-id=%@",
                     [self getRequestBase], _sessionId]];
  }
}

- (void) playPreviousTrack
{
  if (_errorState != STATE_INVALID_LICENCE)
  {
    [self doAction: [NSString stringWithFormat: @"%@/ctrl-int/1/previtem?session-id=%@",
                     [self getRequestBase], _sessionId]];
  }
}

- (void) setProgressPosition: (NSUInteger) progressSeconds
{
  if (_errorState != STATE_INVALID_LICENCE)
  {
    [self doAction: [NSString stringWithFormat: @"%@/ctrl-int/1/setproperty?dacp.playingtime=%d&session-id=%@",
                     [self getRequestBase], progressSeconds * 1000, _sessionId]];
    [self.status adjustProgress: progressSeconds * 1000];
  }
}

- (void) setShuffle: (BOOL) shuffle
{
  if (_errorState != STATE_INVALID_LICENCE)
  {  
    NSUInteger shuffleMode;
  
    if (shuffle)
      shuffleMode = ITSTATUS_SHUFFLE_ON;
    else
      shuffleMode = ITSTATUS_SHUFFLE_OFF;

    [self doAction: [NSString stringWithFormat: @"%@/ctrl-int/1/setproperty?dacp.shufflestate=%d&session-id=%@",
                     [self getRequestBase], shuffleMode, _sessionId]];
  }
}

- (void) setRepeat: (NSUInteger) repeatMode
{
  if (_errorState != STATE_INVALID_LICENCE)
  {
    [self doAction: [NSString stringWithFormat: @"%@/ctrl-int/1/setproperty?dacp.repeatstate=%d&session-id=%@",
                    [self getRequestBase], repeatMode, _sessionId]];
  }
}

- (void) playAlbum: (NSString *) albumId fromTrack: (NSUInteger) trackNum
{
  if (_errorState != STATE_INVALID_LICENCE)
  {
    [self clearAndDoAction: [NSString stringWithFormat:
                             @"%@/ctrl-int/1/cue?command=play&query='daap.songalbumid:%@'&index=%d&sort=album&session-id=%@", 
                             [self getRequestBase], albumId, trackNum, _sessionId]];
  }
}

- (void) playArtist: (NSString *) artist
{
  if (_errorState != STATE_INVALID_LICENCE)
  {
    artist = [[artist stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
              stringByReplacingOccurrencesOfString: @"\\+" withString: @"%20"];
    [self clearAndDoAction: [NSString stringWithFormat:
                             @"%@/ctrl-int/1/cue?command=play&query='daap.songartist:%@'&index=0&sort=album&session-id=%@",
                             [self getRequestBase], artist, _sessionId]];
  }
}

- (void) playSearch: (NSString *) search fromTrack: (NSUInteger) trackNum
{
  if (_errorState != STATE_INVALID_LICENCE)
  {
    search = [[search stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
              stringByReplacingOccurrencesOfString: @"\\+" withString: @"%20"];
    [self clearAndDoAction: [NSString stringWithFormat:
                             @"%@/ctrl-int/1/cue?command=play&query=(('com.apple.itunes.mediakind:1','com.apple.itunes.mediakind:4','com.apple.itunes.mediakind:8')+('dmap.itemname:*%@*','daap.songartist:*%@*','daap.songalbum:*%@*'))&type=music&sort=name&index=%d&session-id=%@",
                             [self getRequestBase], search, search, search, trackNum, _sessionId]];
  }
}

- (void) relogin
{
  if ([_libraryId length] > 0)
  {
    WeakReference *sessionRef = [g_allSessions objectForKey: _libraryId];
    
    [(ITSession *) [sessionRef referencedObject] _reconnect];
  }
}

- (void) request: (ITRequest *) request succeededWithResponse: (ITResponse *) response
{
  id item = [_pendingCalls objectForKey: request];
  
  [request retain];
  if ([item isKindOfClass: [NSString class]])
    [self performSelector: NSSelectorFromString( item ) withObject: response];
  else if ([item isKindOfClass: [NSDictionary class]])
    [self performSelector: NSSelectorFromString( [item objectForKey: SEL_KEY] ) withObject: response withObject: item];
  
  [_pendingCalls removeObjectForKey: request];
  [request release];
}

- (void) request: (ITRequest *) request failedWithError: (NSError *) error
{
#ifdef DEBUG
  //**/NSLog( @"%@: request %@ failed: %@", self, request.requestString, error );
#endif

  id item = [_pendingCalls objectForKey: request];
  BOOL httpError = [[error domain] isEqualToString: [ITRequest requestErrorDomain]];
  NSUInteger errorCode = [error code];

  [request retain];
  if (httpError && errorCode >= 500 && [item isKindOfClass: [NSString class]] &&
      [(NSString *) item isEqualToString: NSStringFromSelector( @selector(handleLoginResponse:) )])
  {
    NSDictionary *libraryData = [[NSUserDefaults standardUserDefaults] objectForKey: kITunesLibraryDataKey];
    
    if (libraryData != nil)
    {
      NSMutableDictionary *newLibraryData = [libraryData mutableCopy];
    
      [newLibraryData removeObjectForKey: _libraryId];
      [[NSUserDefaults standardUserDefaults] setObject: newLibraryData forKey: kITunesLibraryDataKey];
      [[NSUserDefaults standardUserDefaults] synchronize];
      [newLibraryData release];
    }

    [_musicId release];
    _musicId = nil;
  }
  
  [_pendingCalls removeObjectForKey: request];
  [request release];

  if (_musicId == nil || (httpError && 
                          (errorCode == 403 /* HTTP Forbidden */ || errorCode == 406 /* Server error */)))
    [self waitAndStartSession];
}

- (NSString *) getRequestBase
{
  return _requestBase;
}

- (void) _reconnect
{
  if (_sessionStartTimer == nil && !_resolving)
  {
    [self resetData];
    [self startSessionAfterTimeout: nil];
  }
}

- (void) _applicationToForeground
{
  if (_errorState != STATE_INVALID_LICENCE)
  {
    _errorState = STATE_RESOLVING_SERVICE;
    [_iTunesService setDelegate: self];
    [self startSessionAfterTimeout: nil];
  }
}

- (void) _applicationToBackground
{
  if (_errorState != STATE_INVALID_LICENCE)
  {
    [self resetData];
    _errorState = STATE_NO_NETWORK_CONNECTIVITY;
  }
}

- (void) waitAndStartSession
{
  if (_sessionStartTimer == nil && !_resolving)
  {
    [self resetData];
    _sessionStartTimer = [NSTimer scheduledTimerWithTimeInterval: SESSION_START_RETRY_TIME
                                                          target: self selector: @selector(startSessionAfterTimeout:)
                                                        userInfo: nil repeats: NO];
  }
}

- (void) startSessionAfterTimeout: (NSTimer *) timer
{
  if (![NSThread isMainThread])
    [self performSelectorOnMainThread: @selector(startSessionAfterTimeout:) withObject: timer waitUntilDone: FALSE];
  else
  {
    NSInteger libraryIdLength = [_libraryId length];
    NSDictionary *sessionData;
    
    _sessionStartTimer = nil;
    if (libraryIdLength == 0)
      sessionData = nil;
    else
      sessionData = [g_successfulLoginsSessionData objectForKey: _libraryId];
    
    if (_ownsLoginInfo || (libraryIdLength > 0 && sessionData == nil))
    {
      _ownsLoginInfo = YES;
      [g_successfulLoginsSessionData setObject: [NSMutableDictionary dictionaryWithCapacity: 8] forKey: _libraryId];
      _resolving = YES;
      _errorState = STATE_RESOLVING_SERVICE;
      if (_iTunesService != nil)
        [_iTunesService stop];
      else
      {
        _iTunesService = [[[NSNetService alloc]
                           initWithDomain: @"local." type: ITUNES_LIBRARY_TYPE name: _libraryId] retain];
        [_iTunesService setDelegate: self];
      }
      [_iTunesService resolveWithTimeout: SERVICE_RESOLVE_TIMEOUT]; 
    }
    else if ([sessionData count] == 0)
    {
      [self waitAndStartSession];
    }
    else
    {
      _sessionId = [[sessionData objectForKey: @"sessionId"] retain];
      _databaseId = [[sessionData objectForKey: @"databaseId"] retain];
      _databasePersistentId = [[sessionData objectForKey: @"databasePersistentId"] retain];
      _musicId = [[sessionData objectForKey: @"musicId"] retain];
      _host = [[sessionData objectForKey: @"host"] retain];
      _requestBase = [[sessionData objectForKey: @"requestBase"] retain];
      _connection = [[ITURLConnection alloc] init];
      _errorState = STATE_READY;
    }
  }
}

- (void) netServiceDidResolveAddress: (NSNetService *) sender
{
  NSDictionary *libraryData = [[NSUserDefaults standardUserDefaults] objectForKey: kITunesLibraryDataKey];
  NSString *pairingGUID = [libraryData objectForKey: _libraryId];
  
#ifdef DEBUG
  //**/NSLog( @"%@: Resolved iTunes service: %@, host: %@, port: %d, addresses: %@", self, sender,
  //**/      [sender hostName], [sender port], [sender addresses] );
#endif
  _resolving = NO;

  if (pairingGUID == nil)
  {
    _errorState = STATE_NOT_YET_PAIRED;
    
    if (g_ourRemoteService == nil)
      g_ourRemoteService = [[ITRemoteService alloc] init];
    ++g_remoteServiceUsageCount;

    [self waitAndStartSession];
  }
  else
  {
    if (_errorState == STATE_NOT_YET_PAIRED && g_ourRemoteService != nil && --g_remoteServiceUsageCount == 0)
    {
      [g_ourRemoteService stop];
      [g_ourRemoteService release];
      g_ourRemoteService = nil;
    }

    _errorState = STATE_LOGGING_IN;
    [_host release];
    _host = [[sender hostName] retain];
    [_connection close];
    [_connection release];
    _connection = [[ITURLConnection alloc] init];
    [_requestBase release];
    _requestBase = nil;

    for (NSData *addrData in [sender addresses])
    {
      struct sockaddr_in *pAddr = (struct sockaddr_in *) [addrData bytes];
      
      if (pAddr->sin_family == AF_INET)
      {
        _requestBase = [[NSString stringWithFormat: @"http://%s:%d", inet_ntoa( pAddr->sin_addr ),
                         [sender port]] retain];
        break;
      }
    }
  
    if (_requestBase == nil)
      _requestBase = [[NSString stringWithFormat: @"http://%@:%d", [sender hostName], [sender port]] retain];

    ITRequest *request = [ITRequest allocRequest:
                          [NSString stringWithFormat: @"%@/server-info", [self getRequestBase]]
                                       connection: _connection
                                         delegate: self];
    
    [_pendingCalls setObject: NSStringFromSelector( @selector(handleServerInfoResponse:) ) forKey: request];
    [request release];
  }
}

- (void) netService: (NSNetService *) sender didNotResolve: (NSDictionary *) errorDict
{
#ifdef DEBUG
  //**/NSLog( @"Failed to resolve iTunes library service: %@, error: %@", _libraryId, errorDict );
#endif
  _resolving = NO;
  _errorState = STATE_UNABLE_TO_RESOLVE_SERVICE;
  [self waitAndStartSession];
}

- (void) doAction: (NSString *) action
{
  if (_host == nil)
    [self waitAndStartSession];
  else
  {
    ITRequest *request = [ITRequest allocRequest: action connection: _connection delegate: self];

    [_pendingCalls setObject: NSStringFromSelector( @selector(handleActionResponse:) ) forKey: request];
    [request release];
  }
}
  
- (void) clearAndDoAction: (NSString *) action
{
  if (_host == nil)
    [self waitAndStartSession];
  else
  {
    ITRequest *request = [ITRequest allocRequest: 
    [NSString stringWithFormat: @"%@/ctrl-int/1/cue?command=clear&session-id=%@",
     [self getRequestBase], _sessionId] connection: _connection delegate: self];
    NSDictionary *followUp = [NSDictionary dictionaryWithObjectsAndKeys:
                              NSStringFromSelector( @selector(handleClearResponse:withFollowingAction:) ), SEL_KEY,
                              action, FOLLOWING_ACTION_KEY,
                              nil];
    
    [_pendingCalls setObject: followUp forKey: request];
    [request release];
  }
}

- (void) handleServerInfoResponse: (ITResponse *) response
{
  NSDictionary *libraryData = [[NSUserDefaults standardUserDefaults] objectForKey: kITunesLibraryDataKey];
  NSString *pairingGUID = [libraryData objectForKey: _libraryId];
  
  // Don't actually do anything with the server response at the moment.
  // We are sending it because Apple Remote sends it and it may help in clearing an
  // error condition...

  ITRequest *request = [ITRequest allocRequest:
                        [NSString stringWithFormat: @"%@/login?pairing-guid=0x%@", [self getRequestBase], pairingGUID]
                                     connection: _connection
                                       delegate: self];
  
  [_pendingCalls setObject: NSStringFromSelector( @selector(handleLoginResponse:) ) forKey: request];
  [request release];
}

- (void) handleLoginResponse: (ITResponse *) response
{
  [_sessionId release];
  _sessionId = [[[response responseForKey: @"mlog"] numberStringForKey: @"mlid"] retain];
  
  if (_sessionId == nil)
  {
    _errorState = STATE_UNABLE_TO_LOGIN;
    [self waitAndStartSession];
  }
  else
  {
    ITRequest *request = [ITRequest allocRequest:
                          [NSString stringWithFormat: @"%@/databases?session-id=%@", [self getRequestBase], _sessionId]
                                       connection: _connection delegate: self];
  
    _errorState = STATE_GETTING_DATABASE_ID;
    [_pendingCalls setObject: NSStringFromSelector( @selector(handleFindDatabaseResponse:) ) forKey: request];
    [request release];
  }
}

- (void) handleFindDatabaseResponse: (ITResponse *) response
{
  ITResponse *dbEntry = [[[response responseForKey: @"avdb"] responseForKey: @"mlcl"]
                         responseForKey: @"mlit"];
  id databaseId = [dbEntry itemForKey: @"miid"];
  
  if (databaseId == nil || [dbEntry unsignedIntegerForKey: @"miid"] == 0)
  {
    _errorState = STATE_NO_DATABASE_ID;
    [self waitAndStartSession];
  }
  else
  {
    [_databaseId release];
    _databaseId = [[dbEntry numberStringForKey: @"miid"] retain];
    [_databasePersistentId release];
    _databasePersistentId = [[dbEntry numberStringForKey: @"mper"] retain];

    // fetch playlists to find the overall magic "Music" playlist
    ITRequest *request = [ITRequest allocRequest:
                          [NSString stringWithFormat: @"%@/databases/%@/containers?session-id=%@&meta=dmap.itemname,dmap.itemcount,dmap.itemid,dmap.persistentid,daap.baseplaylist,com.apple.itunes.special-playlist,com.apple.itunes.smart-playlist,com.apple.itunes.saved-genius,dmap.parentcontainerid,dmap.editcommandssupported,com.apple.itunes.jukebox-current,daap.songcontentdescription",
                           [self getRequestBase], _databaseId, _sessionId]
                                       connection: _connection delegate: self];
    
    _errorState = STATE_GETTING_MUSIC_ID;
    [_pendingCalls setObject: NSStringFromSelector( @selector(handleFindMusicIdResponse:) ) forKey: request];
    [request release];
  }
}

- (void) handleFindMusicIdResponse: (ITResponse *) response
{
  [_musicId release];
  _musicId = nil;

  for (ITResponse *resp in [[[response responseForKey: @"aply"] responseForKey: @"mlcl"] allItemsWithPrefix: @"mlit"])
  {
    if ([resp itemForKey: @"abpl"] != nil)
    {
      _musicId = [[resp numberStringForKey: @"miid"] retain];
      _musicIdAsUInt = [resp unsignedIntegerForKey: @"miid"];
      break;
    }
  }
  
  if (_musicId != nil)
  {
    NSMutableDictionary *sessionData = [g_successfulLoginsSessionData objectForKey: _libraryId];

    _errorState = STATE_READY;
    [sessionData setObject: _sessionId forKey: @"sessionId"];
    [sessionData setObject: _databaseId forKey: @"databaseId"];
    [sessionData setObject: _databasePersistentId forKey: @"databasePersistentId"];
    [sessionData setObject: _musicId forKey: @"musicId"];
    [sessionData setObject: _host forKey: @"host"];
    [sessionData setObject: _requestBase forKey: @"requestBase"];
    [_status fetchUpdate];
  }
  else
  {
    _errorState = STATE_NO_MUSIC_ID;
    [self waitAndStartSession];
  }
}

- (void) handleActionResponse: (ITResponse *) response
{
  if (_host == nil)
    [self waitAndStartSession];
}

- (void) handleClearResponse: (ITResponse *) response withFollowingAction: (NSDictionary *) actionData
{
  [self doAction: [actionData objectForKey: FOLLOWING_ACTION_KEY]];
}

- (void) resetData
{
  [_sessionId release];
  _sessionId = nil;
  [_databaseId release];
  _databaseId = nil;
  [_databasePersistentId release];
  _databasePersistentId = nil;
  [_musicId release];
  _musicId = nil;
  [_host release];
  _host = nil;
  [_requestBase release];
  _requestBase = nil;
  [_connection close];
  [_connection release];
  _connection = nil;
  if (_ownsLoginInfo)
    [[g_successfulLoginsSessionData objectForKey: _libraryId] removeAllObjects];
}

- (BOOL) checkLicence: (NSString *) licence
{
  return [[licence decodeAsiLinXLicenceString] isEqualToString: _libraryId];
}

- (void) dealloc
{
  [AppStateNotification removeObserver: self];

  [g_allSessions removeObjectForKey: _libraryId];
  if (_errorState == STATE_NOT_YET_PAIRED && g_ourRemoteService != nil && --g_remoteServiceUsageCount == 0)
  {
    [g_ourRemoteService stop];
    [g_ourRemoteService release];
    g_ourRemoteService = nil;
  }
  
  if (_ownsLoginInfo)
    [g_successfulLoginsSessionData removeObjectForKey: _libraryId];

  [_iTunesService setDelegate: nil];
  [_iTunesService stop];
  [_iTunesService release];
  [_libraryId release];
  [_pendingCalls release];
  [_status destroy];
  [_status release];
  [_sessionStartTimer invalidate];
  [self resetData];
  [super dealloc];
}

@end
