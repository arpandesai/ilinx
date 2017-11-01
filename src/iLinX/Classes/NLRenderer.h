//
//  NLRenderer.h
//  iLinX
//
//  Created by mcf on 15/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetStreamsComms.h"

@class NLRenderer;
@class NLRoom;
@class NLZone;

#define NLRENDERER_VOLUME_CHANGED          0x0001
#define NLRENDERER_BALANCE_CHANGED         0x0002
#define NLRENDERER_BASS_CHANGED            0x0004
#define NLRENDERER_TREBLE_CHANGED          0x0008
#define NLRENDERER_LOUD_CHANGED            0x0010
#define NLRENDERER_BAND1_CHANGED           0x0020
#define NLRENDERER_BAND2_CHANGED           0x0040
#define NLRENDERER_BAND3_CHANGED           0x0080
#define NLRENDERER_BAND4_CHANGED           0x0100
#define NLRENDERER_BAND5_CHANGED           0x0200
#define NLRENDERER_MUTE_CHANGED            0x0400
#define NLRENDERER_AMP_ON_CHANGED          0x0800
#define NLRENDERER_AUDIO_SESSION_CHANGED   0x1000
#define NLRENDERER_PERMID_CHANGED          0x2000
#define NLRENDERER_NO_FEEDBACK_CHANGED     0x4000

// Assign this to bass, treble, volume, balance, loud, and bands to set to default values
#define NLRENDERER_DEFAULT_VALUE NSIntegerMax

@protocol NLRendererDelegate <NSObject>
- (void) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags;
@end

@interface NLRenderer : NSObject <NetStreamsMsgDelegate>
{
@private
  NSString *_serviceName;
  NSString *_displayName;
  NSString *_permId;
  NSString *_controlGroup;
  NLRoom *_room;
  NSMutableSet *_rendererDelegates;
  NSMutableSet *_activeDelegates;
  NetStreamsComms *_netStreamsComms;
  id _permIdRspHandle;
  id _statusRspHandle;
  id _registerMsgHandle;
  id _queryMsgHandle;
  NSUInteger _volume;
  NSUInteger _balance;
  NSUInteger _bass;
  NSUInteger _treble;
  NSInteger _loud;
  NSUInteger _band1;
  NSUInteger _band2;
  NSUInteger _band3;
  NSUInteger _band4;
  NSUInteger _band5;
  BOOL _mute;
  BOOL _ampOn;
  BOOL _audioSessionActive;
  NSString *_audioSessionName;
  NSString *_audioSessionDisplayName;
  BOOL _noFeedback;
  BOOL _settingsEnabled;
  NSMutableArray *_audioControls;
  NSMutableArray *_videoControls;
}

@property (readonly) NSString *serviceName;
@property (readonly) NSString *displayName;
@property (readonly) NSString *permId;
@property (readonly) NLRoom *room;
@property (nonatomic, retain) NSString *controlGroup;
@property (assign) NSUInteger volume;
@property (assign) NSUInteger balance;
@property (assign) NSUInteger bass;
@property (assign) NSUInteger treble;
@property (assign) NSInteger loud;
@property (assign) NSUInteger band1;
@property (assign) NSUInteger band2;
@property (assign) NSUInteger band3;
@property (assign) NSUInteger band4;
@property (assign) NSUInteger band5;
@property (assign) BOOL mute;
@property (readonly) BOOL ampOn;
@property (readonly) BOOL audioSessionActive;
@property (readonly) NSString *audioSessionName;
@property (readonly) NSString *audioSessionDisplayName;
@property (readonly) BOOL noFeedback;
@property (readonly) BOOL settingsEnabled;
@property (nonatomic, retain) NSMutableArray *audioControls;
@property (nonatomic, retain) NSMutableArray *videoControls;

- (id) initWithName: (NSString *) name room: (NLRoom *) room settingsEnabled: (BOOL) enabled comms: (NetStreamsComms *) comms;
- (void) ensureAmpOn;
- (void) toggleMute;
- (void) volumeUp;
- (void) volumeDown;
- (void) sendAudioControl: (NSUInteger) index;
- (void) sendVideoControl: (NSUInteger) index;
- (void) addDelegate: (id<NLRendererDelegate>) delegate;
- (void) addPassiveDelegate: (id<NLRendererDelegate>) delegate;
- (void) removeDelegate: (id<NLRendererDelegate>) delegate;

// MultiRoom session commands
- (void) multiRoomVolumeUp;
- (void) multiRoomVolumeDown;
- (void) multiRoomVolumeSync;
- (void) multiRoomVolumeMute;
- (void) multiRoomAllOff;
- (void) multiRoomJoin: (NLZone *) multiRoomZone;
- (void) multiRoomLeave;
- (void) multiRoomCancel;

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects;

@end
