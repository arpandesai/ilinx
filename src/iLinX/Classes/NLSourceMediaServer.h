//
//  NLSourceMediaServer.h
//  iLinX
//
//  Created by mcf on 27/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLSource.h"

// Flags indicating which source values have changed
#define SOURCE_MEDIA_SERVER_SONG_CHANGED            0x000001
#define SOURCE_MEDIA_SERVER_ALBUM_CHANGED           0x000002
#define SOURCE_MEDIA_SERVER_ARTIST_CHANGED          0x000004
#define SOURCE_MEDIA_SERVER_GENRE_CHANGED           0x000008
#define SOURCE_MEDIA_SERVER_COVER_ART_CHANGED       0x000010
#define SOURCE_MEDIA_SERVER_TIME_CHANGED            0x000020
#define SOURCE_MEDIA_SERVER_ELAPSED_CHANGED         0x000040
#define SOURCE_MEDIA_SERVER_SONG_INDEX_CHANGED      0x000080
#define SOURCE_MEDIA_SERVER_SONG_TOTAL_CHANGED      0x000100
#define SOURCE_MEDIA_SERVER_TRANSPORT_STATE_CHANGED 0x000200
#define SOURCE_MEDIA_SERVER_SHUFFLE_CHANGED         0x000400
#define SOURCE_MEDIA_SERVER_NEXT_SONG_CHANGED       0x000800
#define SOURCE_MEDIA_SERVER_SUB_GENRE_CHANGED       0x001000
#define SOURCE_MEDIA_SERVER_COMPOSERS_CHANGED       0x002000
#define SOURCE_MEDIA_SERVER_CONDUCTORS_CHANGED      0x004000
#define SOURCE_MEDIA_SERVER_PERFORMERS_CHANGED      0x008000
#define SOURCE_MEDIA_SERVER_PLAY_QUEUE_CHANGED      0x010000
#define SOURCE_MEDIA_SERVER_LIBRARY_CHANGED         0x020000
#define SOURCE_MEDIA_SERVER_REPEAT_CHANGED          0x040000
#define SOURCE_MEDIA_SERVER_DOCKED_CHANGED          0x080000
#define SOURCE_MEDIA_SERVER_CAPTION_CHANGED         0x100000
#define SOURCE_MEDIA_SERVER_PLAY_POSSIBLE_CHANGED   0x200000
#define SOURCE_MEDIA_SERVER_CONNECTED_CHANGED       0x400000
#define SOURCE_MEDIA_SERVER_METADATA_CHANGED        0x800000

// Possible values of the transport state 
#define TRANSPORT_STATE_STOP  0
#define TRANSPORT_STATE_PAUSE 1
#define TRANSPORT_STATE_PLAY  2

// Possible optional capabilities of media servers
#define SOURCE_MEDIA_SERVER_CAPABILITY_SONG_COUNT   0x00001
#define SOURCE_MEDIA_SERVER_CAPABILITY_NEXT_TRACK   0x00002
#define SOURCE_MEDIA_SERVER_CAPABILITY_REPEAT       0x00004
#define SOURCE_MEDIA_SERVER_CAPABILITY_POSITION     0x00008

@class NLSourceMediaServer;
@class ArtworkRequest;

@protocol NLSourceMediaServerDelegate <NSObject>
- (void) source: (NLSourceMediaServer *) source stateChanged: (NSUInteger) flags;
@end

@interface NLSourceMediaServer : NLSource
{
@protected
  NSMutableSet *_sourceDelegates;
  NSString *_song;
  NSString *_nextSong;
  NSString *_album;
  NSString *_artist;
  NSString *_genre;
  UIImage *_coverArt;
  NSUInteger _time;
  NSUInteger _elapsed;
  CGFloat _elapsedPercent;
  NSUInteger _songIndex;
  NSUInteger _songTotal;
  NSUInteger _transportState;
  NSString *_controlState;
  BOOL _shuffle;
  NSString *_subGenre;
  NSMutableArray *_composers;
  NSMutableArray *_conductors;
  NSMutableArray *_performers;
  NSString *_songId;
  NSString *_datastampQueue;
  NSString *_datastampLibrary;
  NSString *_coverArtURL;
  NSURLConnection *_coverArtConnection;
  NSMutableData *_coverArtData;
  NSData *_oldCoverArtData;
  ArtworkRequest *_artRequest;
  BOOL _isNaim;
  BOOL _docked;
  NSString *_caption;
}

@property (readonly) NSString *song;
@property (readonly) NSString *nextSong;
@property (readonly) NSString *album;
@property (readonly) NSString *artist;
@property (readonly) NSString *genre;
@property (readonly) UIImage *coverArt;
@property (readonly) NSUInteger time;
@property (assign) NSUInteger elapsed;
@property (readonly) CGFloat elapsedPercent;
@property (readonly) NSUInteger songIndex;
@property (readonly) NSUInteger songTotal;
@property (assign) NSUInteger transportState;
@property (assign) BOOL shuffle;
@property (assign) NSUInteger repeat;
@property (readonly) NSUInteger maxRepeat;
@property (readonly) NSString *subGenre;
@property (readonly) NSArray *composers;
@property (readonly) NSArray *conductors;
@property (readonly) NSArray *performers;
@property (readonly) NSString *songId;
@property (readonly) NSString *datastampQueue;
@property (readonly) NSString *datastampLibrary;
@property (readonly) NSUInteger capabilities;
@property (readonly) BOOL playNotPossible;
@property (readonly) BOOL docked;
@property (readonly) NSString *caption;
@property (readonly) BOOL connected;

- (id) initWithSourceData: (NSDictionary *) sourceData comms: (NetStreamsComms *) comms;

- (void) addDelegate: (id<NLSourceMediaServerDelegate>) delegate;
- (void) removeDelegate: (id<NLSourceMediaServerDelegate>) delegate;
- (void) playNextTrack;
- (void) playPreviousTrack;

// For use by child classes
- (void) notifyDelegates: (NSUInteger) changed;
- (void) handleCoverArtURL: (NSString *) coverArtURL withChangeFlags: (NSUInteger) changed;

// NSURLConnection delegate interface
- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response;
- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) data;
- (void) connectionDidFinishLoading: (NSURLConnection *) connection;
- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error;

@end
