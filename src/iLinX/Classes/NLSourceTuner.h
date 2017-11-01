//
//  NLSourceTuner.h
//  iLinX
//
//  Created by mcf on 18/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetStreamsComms.h"
#import "NLSource.h"

// Flags indicating which source values have changed
#define SOURCE_TUNER_CHANNEL_NAME_CHANGED    0x00001
#define SOURCE_TUNER_CHANNEL_NUM_CHANGED     0x00002
#define SOURCE_TUNER_PRESET_CHANGED          0x00004
#define SOURCE_TUNER_BAND_CHANGED            0x00008
#define SOURCE_TUNER_SIGNAL_STRENGTH_CHANGED 0x00010
#define SOURCE_TUNER_BITRATE_CHANGED         0x00020
#define SOURCE_TUNER_FORMAT_CHANGED          0x00040
#define SOURCE_TUNER_STEREO_CHANGED          0x00080
#define SOURCE_TUNER_SONG_CHANGED            0x00100
#define SOURCE_TUNER_ARTIST_CHANGED          0x00200
#define SOURCE_TUNER_GENRE_CHANGED           0x00400
#define SOURCE_TUNER_ARTWORK_CHANGED         0x00800
#define SOURCE_TUNER_CAPTION_CHANGED         0x01000
#define SOURCE_TUNER_CONTROL_STATE_CHANGED   0x02000
#define SOURCE_TUNER_RESCAN_COMPLETE_CHANGED 0x04000
#define SOURCE_TUNER_STATIONS_FOUND_CHANGED  0x08000
#define SOURCE_TUNER_LIST_COUNT_CHANGED      0x10000
#define SOURCE_TUNER_FREQUENCY_CHANGED       0x20000

@class ArtworkRequest;
@class NLSourceTuner;

@protocol NLSourceTunerDelegate <NSObject>
- (void) source: (NLSourceTuner *) source stateChanged: (NSUInteger) flags;
@end

// Key values that can be sent to the tuner.  Keys 0-9 are integers 0-9,
// these are additional special keys
#define SOURCE_TUNER_KEY_A     ('A' - '0')
#define SOURCE_TUNER_KEY_B     ('B' - '0')
#define SOURCE_TUNER_KEY_ENTER 0x10000
#define SOURCE_TUNER_KEY_CLEAR 0x10001

// Tuner capabilities
#define SOURCE_TUNER_HAS_FEEDBACK            0x0001
#define SOURCE_TUNER_HAS_DIRECT_TUNE         0x0002
#define SOURCE_TUNER_HAS_DYNAMIC_PRESETS     0x0004

@interface NLSourceTuner : NLSource <NetStreamsMsgDelegate>
{
@private
  NSMutableSet *_sourceDelegates;
  id _statusRspHandle;
  id _registerMsgHandle;
  NSString *_channelName;
  NSString *_channelNum;
  NSString *_currentPreset;
  NSString *_band;
  NSUInteger _signalStrength;
  NSString *_bitrate;
  NSString *_format;
  NSString *_stereo;
  NSString *_song;
  NSString *_artist;
  NSString *_genre;
  NSString *_artworkURL;
  NSUInteger _listCount;
  NSURLConnection *_artworkConnection;
  NSMutableData *_artworkData;
  NSData *_oldArtworkData;
  UIImage *_artwork;
  ArtworkRequest *_artRequest;
  NSString *_caption;
  NSString *_frequency;
  NSString *_controlState;
  NSUInteger _rescanComplete;
  NSUInteger _stationsFound;
  NLBrowseList *_browseMenu;
}

@property (readonly) NSString *channelName;
@property (readonly) NSString *channelNum;
@property (readonly) NSString *currentPreset;
@property (readonly) NSString *band;
@property (readonly) NSUInteger signalStrength;
@property (readonly) NSString *bitrate;
@property (readonly) NSString *format;
@property (readonly) NSString *stereo;
@property (readonly) NSString *song;
@property (readonly) NSString *artist;
@property (readonly) NSString *genre;
@property (readonly) UIImage *artwork;
@property (readonly) NSString *caption;
@property (readonly) NSString *frequency;
@property (readonly) NSUInteger rescanComplete;
@property (readonly) NSUInteger stationsFound;
@property (readonly) NSUInteger capabilities;

- (id) initWithSourceData: (NSDictionary *) sourceData comms: (NetStreamsComms *) comms;
- (void) addDelegate: (id<NLSourceTunerDelegate>) delegate;
- (void) removeDelegate: (id<NLSourceTunerDelegate>) delegate;
- (void) nextBand;
- (void) channelUp;
- (void) channelDown;
- (void) tuneUp;
- (void) tuneDown;
- (void) seekUp;
- (void) seekDown;
- (void) scanUp;
- (void) scanDown;
- (void) presetUp;
- (void) presetDown;
- (void) selectPreset: (NSUInteger) preset;
- (void) savePreset: (NSUInteger) preset withTitle: (NSString *) title;
- (void) clearAllPresets;
- (void) setMono;
- (void) setStereo;
- (void) setCaption: (NSString *) caption;
- (void) ifNoFeedbackSetCaption: (NSString *) caption;
- (void) sendKey: (NSUInteger) key;
- (void) rescanChannels;
- (void) resetListCount;
@end
