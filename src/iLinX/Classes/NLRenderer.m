//
//  NLRenderer.m
//  iLinX
//
//  Created by mcf on 15/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLRenderer.h"
#import "NLRoom.h"
#import "NLSource.h"
#import "NLSourceList.h"
#import "NLZone.h"
#import "GuiXmlParser.h"
#import "JavaScriptSupport.h"

#define _pcomms NETSTREAMSCOMMS_PRODUCTION_ONLY(_netStreamsComms)

// How often, in seconds, to send the report registration request to ensure
// that it does not expire
#define REGISTRATION_RENEWAL_INTERVAL 30

// How often, in seconds, to directly query the renderer status
#define NLRENDERER_QUERY_INTERVAL 30

@interface NLRenderer ()

- (void) _sendCommand: (NSString *) command;
- (void) _notifyDelegates: (NSUInteger) changed;
- (void) _deregisterFromNetStreams;
- (void) _cancelNetStreamsQueries;

@end

@implementation NLRenderer

@synthesize
  serviceName = _serviceName,
  displayName = _displayName,
  permId = _permId,
  room = _room,
  controlGroup = _controlGroup,
  ampOn = _ampOn,
  audioSessionActive = _audioSessionActive,
  audioSessionName = _audioSessionName,
  audioSessionDisplayName = _audioSessionDisplayName,
  noFeedback = _noFeedback,
  settingsEnabled = _settingsEnabled,
  audioControls = _audioControls,
  videoControls = _videoControls;

- (id) initWithName: (NSString *) name room: (NLRoom *) room settingsEnabled: (BOOL) enabled comms: (NetStreamsComms *) comms
{
  if (self = [super init])
  {
    _serviceName = [name retain];
    _displayName = [[GuiXmlParser stripSpecialAffixesFromString: name] retain];
    _controlGroup = nil;
    // Don't retain, because room retains us.
    _room = room;
    _settingsEnabled = enabled;
    _netStreamsComms = comms;
    _rendererDelegates = [NSMutableSet new];
    _activeDelegates = [NSMutableSet new];
    _balance = 50;
    _bass = 50;
    _treble = 50;
    _band1 = 50;
    _band2 = 50;
    _band3 = 50;
    _band4 = 50;
    _band5 = 50;
    
#if DEBUG
    //**/NSLog( @"Renderer created: %@ (%08X)", _displayName, self );
#endif
  }

  return self;
}

- (void) ensureAmpOn
{
  if (!_ampOn)
    [_netStreamsComms send: @"ACTIVE ON" to: _serviceName];
}

- (void) toggleMute
{
  [self ensureAmpOn];
  [self _sendCommand: @"MUTE TOGGLE"];
}

- (void) volumeUp
{
  [self ensureAmpOn];
  [self _sendCommand: @"LEVEL_UP VOL"];
}

- (void) volumeDown
{
  [self ensureAmpOn];
  [self _sendCommand: @"LEVEL_DN VOL"];
}

- (void) sendAudioControl: (NSUInteger) index
{
  if (_audioControls != nil && index < [_audioControls count])
  {
    NSDictionary *control = [_audioControls objectAtIndex: index];
    NSString *command = [control objectForKey: @"command"];
    
    if (command != nil)
    {
      if ([command characterAtIndex: 0] == '#')
        command = [command substringFromIndex: 1];
      
      [self ensureAmpOn];
      [_pcomms send: command to: [NSString stringWithFormat: @"%@~avr", _serviceName]];
    }
  }
}

- (void) sendVideoControl: (NSUInteger) index
{
  if (_videoControls != nil && index < [_videoControls count])
  {
    NSDictionary *control = [_videoControls objectAtIndex: index];
    NSString *command = [control objectForKey: @"command"];
    
    if (command != nil)
    {
      if ([command characterAtIndex: 0] == '#')
        command = [command substringFromIndex: 1];

      if (_permId != nil && [_permId hasPrefix: @"TH100"])
      {
        // THEATERLINX: for theaterlinx, this needs to go to the ~display subnode
        // #@Room 1 Player~display#MACRO {{#TEST 4}},{{NS_CUR_ROOM=Room 1}}
        [_pcomms send: command to: [NSString stringWithFormat: @"%@~display", _room.videoServiceName]];
      }
      else
      {
        // VIEWLINX
        // #@Room 1 Player#MACRO {{#TEST 1}},{{NS_CUR_ROOM=Room 1}}
        [_pcomms send: command to: _room.videoServiceName];
      }
    }
    else
    {
      // PANORAMA: no command defined, must be for Panorama then
      // #@Room 1 Player~Room 1#BUTTON PRESS 1
      [_pcomms send: [NSString stringWithFormat: @"BUTTON PRESS %@", [control objectForKey: @"id"]]
                 to: [NSString stringWithFormat: @"%@~%@", _room.videoServiceName, _room.serviceName]];
    }			
  }
}

- (NSUInteger) volume
{
  return _volume;
}

- (void) setVolume: (NSUInteger) volume
{
  [self ensureAmpOn];
  if (volume == NLRENDERER_DEFAULT_VALUE)
    [self _sendCommand: @"LEVEL_SET VOL DEFAULT"];
  else if (volume != _volume)
  {
    _volume = volume;
    [self _sendCommand: [NSString stringWithFormat: @"LEVEL_SET VOL,%u", volume]];
  }
}

- (NSUInteger) balance
{
  return _balance;
}

- (void) setBalance: (NSUInteger) balance
{
  [self ensureAmpOn];
  if (balance == NLRENDERER_DEFAULT_VALUE)
    [_pcomms send: @"LEVEL_SET BALANCE DEFAULT" to: _serviceName];
  else if (balance != _balance)
  {
    _balance = balance;
    [_pcomms send: [NSString stringWithFormat: @"LEVEL_SET BALANCE,%u", balance] to: _serviceName];
  }
}

- (NSUInteger) bass
{
  return _bass;
}

- (void) setBass: (NSUInteger) bass
{
  [self ensureAmpOn];
  if (bass == NLRENDERER_DEFAULT_VALUE)
    [_pcomms send: @"LEVEL_SET BASS DEFAULT" to: _serviceName];
  else if (bass != _bass)
  {
    _bass = bass;
    [_pcomms send: [NSString stringWithFormat: @"LEVEL_SET BASS,%u", bass] to: _serviceName];
  }
}

- (NSUInteger) treble
{
  return _treble;
}

- (void) setTreble: (NSUInteger) treble
{
  [self ensureAmpOn];
  if (treble == NLRENDERER_DEFAULT_VALUE)
    [_pcomms send: @"LEVEL_SET TREB DEFAULT" to: _serviceName];
  else if (treble != _treble)
  {
    _treble = treble;
    [_pcomms send: [NSString stringWithFormat: @"LEVEL_SET TREB,%u", treble] to: _serviceName];
  }
}

- (NSUInteger) band1
{
  return _band1;
}

- (void) setBand1: (NSUInteger) band1
{
  [self ensureAmpOn];
  if (band1 == NLRENDERER_DEFAULT_VALUE)
    [_pcomms send: @"LEVEL_SET band_1 DEFAULT" to: _serviceName];
  else if (band1 != _band1)
  {
    _band1 = band1;
    [_pcomms send: [NSString stringWithFormat: @"LEVEL_SET band_1,%u", band1] to: _serviceName];
  }
}

- (NSUInteger) band2
{
  return _band2;
}

- (void) setBand2: (NSUInteger) band2
{
  [self ensureAmpOn];
  if (band2 == NLRENDERER_DEFAULT_VALUE)
    [_pcomms send: @"LEVEL_SET band_2 DEFAULT" to: _serviceName];
  else if (band2 != _band2)
  {
    _band2 = band2;
    [_pcomms send: [NSString stringWithFormat: @"LEVEL_SET band_2,%u", band2] to: _serviceName];
  }
}

- (NSUInteger) band3
{
  return _band3;
}

- (void) setBand3: (NSUInteger) band3
{
  [self ensureAmpOn];
  if (band3 == NLRENDERER_DEFAULT_VALUE)
    [_pcomms send: @"LEVEL_SET band_3 DEFAULT" to: _serviceName];
  else if (band3 != _band3)
  {
    _band3 = band3;
    [_pcomms send: [NSString stringWithFormat: @"LEVEL_SET band_3,%u", band3] to: _serviceName];
  }
}

- (NSUInteger) band4
{
  return _band4;
}

- (void) setBand4: (NSUInteger) band4
{
  [self ensureAmpOn];
  if (band4 == NLRENDERER_DEFAULT_VALUE)
    [_pcomms send: @"LEVEL_SET band_4 DEFAULT" to: _serviceName];
  else if (band4 != _band4)
  {
    _band4 = band4;
    [_pcomms send: [NSString stringWithFormat: @"LEVEL_SET band_4,%u", band4] to: _serviceName];
  }
}

- (NSUInteger) band5
{
  return _band5;
}

- (void) setBand5: (NSUInteger) band5
{
  [self ensureAmpOn];
  if (band5 == NLRENDERER_DEFAULT_VALUE)
    [_pcomms send: @"LEVEL_SET band_5 DEFAULT" to: _serviceName];
  else if (band5 != _band5)
  {
    _band5 = band5;
    [_pcomms send: [NSString stringWithFormat: @"LEVEL_SET band_5,%u", band5] to: _serviceName];
  }
}

- (NSInteger) loud
{
  return _loud;
}

- (void) setLoud: (NSInteger) loud
{
  [self ensureAmpOn];
  if (loud == NLRENDERER_DEFAULT_VALUE)
    loud = 0;

  if (loud != _loud)
  {
    _loud = loud;
    [_pcomms send: [NSString stringWithFormat: @"LOUDNESS %d", loud] to: _serviceName];
  }
}

- (BOOL) mute
{
  return _mute;
}

- (void) setMute: (BOOL) mute
{
  [self ensureAmpOn];
  if (mute != _mute)
  {
    _mute = mute;
    if (mute)
      [self _sendCommand: @"MUTE ON"];
    else
      [self _sendCommand: @"MUTE OFF"];
  }
}

- (void) addDelegate: (id<NLRendererDelegate>) delegate
{
  [self addPassiveDelegate: delegate];

  if ([_activeDelegates count] == 0)
  {
    [_netStreamsComms send: [NSString stringWithFormat: @"QUERY SERVICE {{%@}}", _serviceName]
                        to: [NSString stringWithFormat: @"%@~root", _serviceName]];
    _registerMsgHandle = [_netStreamsComms send: [NSString stringWithFormat: @"REGISTER ON,{{%@}}", _serviceName]
                                             to: nil every: REGISTRATION_RENEWAL_INTERVAL];
    _queryMsgHandle = [_netStreamsComms send: [NSString stringWithFormat: @"QUERY RENDERER {{%@}}", _serviceName]
                                          to: _serviceName every: NLRENDERER_QUERY_INTERVAL];
  }

  [_activeDelegates addObject: delegate];
}

- (void) addPassiveDelegate: (id<NLRendererDelegate>) delegate
{
  if (_statusRspHandle == nil)
  {
    //NSLog( @"Register" );
    _statusRspHandle = [_netStreamsComms registerDelegate: self forMessage: @"REPORT" from: _serviceName];
    _permIdRspHandle = [_netStreamsComms registerDelegate: self forMessage: @"REPORT" from: @"*"];  
  }
  
  [_rendererDelegates addObject: delegate];
}

- (void) removeDelegate: (id<NLRendererDelegate>) delegate
{
  if ([_activeDelegates count] > 0)
  {
    [_activeDelegates removeObject: delegate];
    if ([_activeDelegates count] == 0)
      [self _cancelNetStreamsQueries];
  }

  if ([_rendererDelegates count] > 0)
  {
    [_rendererDelegates removeObject: delegate];
    if ([_rendererDelegates count] == 0)
      [self _deregisterFromNetStreams];
  }  
}

- (void) multiRoomVolumeUp
{
  if (_audioSessionActive)
    [_netStreamsComms send: @"LEVEL_UP VOL" to: _audioSessionName];
}

- (void) multiRoomVolumeDown
{
  if (_audioSessionActive)
    [_netStreamsComms send: @"LEVEL_DN VOL" to: _audioSessionName];
}

- (void) multiRoomVolumeSync
{
  if (_audioSessionActive)
  {
    if (_noFeedback)
      [_netStreamsComms send: @"LEVEL_SET VOL DEFAULT" to: _audioSessionName];
    else
      [_netStreamsComms send: [NSString stringWithFormat: @"LEVEL_SET VOL %u", _volume] to: _audioSessionName];
  }
}

- (void) multiRoomVolumeMute
{
  if (_audioSessionActive)
  {
    if (_mute)
      [_netStreamsComms send: @"MUTE OFF" to: _audioSessionName];
    else
      [_netStreamsComms send: @"MUTE ON" to: _audioSessionName];
  }
}

- (void) multiRoomAllOff
{
#if !defined(DEMO_BUILD)
  if (_audioSessionActive)
  {
    [_pcomms send: @"ACTIVE OFF" to: _audioSessionName];
    [_pcomms send: @"MULTIAUDIO LEAVE" to: _audioSessionName];
    _audioSessionActive = NO;
    [self _notifyDelegates: NLRENDERER_AUDIO_SESSION_CHANGED];
  }
#endif
}

- (void) multiRoomJoin: (NLZone *) zone
{
#if !defined(DEMO_BUILD)
  [_pcomms send: [NSString stringWithFormat: @"MULTIAUDIO JOIN {{%@}}", zone.audioSessionName] to: zone.serviceName];
  [_pcomms send: @"ACTIVE ON" to: zone.audioSessionName];
  [_pcomms send: @"MUTE OFF" to: zone.audioSessionName];
  [_pcomms send: @"LEVEL_SET VOL DEFAULT" to: zone.audioSessionName];
  [_pcomms send: [NSString stringWithFormat: @"SRC_SEL {{%@}}", _room.sources.currentSource.serviceName] to: zone.audioSessionName];
  [_pcomms send: [NSString stringWithFormat: @"MULTIAUDIO JOIN {{%@}}", zone.audioSessionName] to: _room.serviceName];
  [_audioSessionName release];
  _audioSessionName = [zone.audioSessionName retain];
  _audioSessionActive = YES;
  [self _notifyDelegates: NLRENDERER_AUDIO_SESSION_CHANGED];
#endif
}

- (void) multiRoomLeave
{
#if !defined(DEMO_BUILD)
  if (_audioSessionActive)
  {
    [_pcomms send: @"MULTIAUDIO LEAVE" to: _room.serviceName];
    _audioSessionActive = NO;
    [self _notifyDelegates: NLRENDERER_AUDIO_SESSION_CHANGED];
  }
#endif
}

- (void) multiRoomCancel
{
#if !defined(DEMO_BUILD)
  if (_audioSessionActive)
  {
    [_pcomms send: @"MULTIAUDIO LEAVE" to: _audioSessionName];
    _audioSessionActive = NO;
    [self _notifyDelegates: NLRENDERER_AUDIO_SESSION_CHANGED];
  }
#endif
}

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects
{
  if ((statusMask & JSON_RENDERER) == 0)
    return @"{}";
  else
    return [NSString stringWithFormat: @"{ displayName: \"%@\", serviceName: \"%@\", permId: \"%@\", "
          "volume: %u, balance: %u, bass: %u, treble: %u, loud: %d, "
          "band1: %u, band2: %u, band3: %u, band4: %u, band5: %u, mute: %u, ampOn: %u, "
          "audioSessionActive: %u, audioSessionName: \"%@\", audioSessionDisplayName: \"%@\", "
          "noFeedback: %u, settingsEnabled: %u }",
          [_displayName javaScriptEscapedString], [_serviceName javaScriptEscapedString], 
          [_permId javaScriptEscapedString], _volume, _balance, _bass, _treble, _loud, 
          _band1, _band2, _band3, _band4, _band5, (NSUInteger) _mute, (NSUInteger) _ampOn,
          (NSUInteger) _audioSessionActive, [_audioSessionName javaScriptEscapedString],
          [_audioSessionDisplayName javaScriptEscapedString], (NSUInteger) _noFeedback,
          (NSUInteger) _settingsEnabled];
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  NSString *type = [data objectForKey: @"type"];
  
  if ([type isEqualToString: @"state"])
  {
    NSString *serviceName = [data objectForKey: @"serviceName"];
    NSString *permId = [data objectForKey: @"permId"];
    
    if (permId == nil)
      permId = [data objectForKey: @"permid"];
    
    if (serviceName != nil && permId != nil)
    {
      if (_permId == nil && [serviceName compare: _serviceName
                                         options: NSCaseInsensitiveSearch] == NSOrderedSame)
      {
        _permId = [permId retain];
        [_netStreamsComms deregisterDelegate: _permIdRspHandle];
        _permIdRspHandle = nil;
        [self _notifyDelegates: NLRENDERER_PERMID_CHANGED];
      }
    }
    else if ([source compare: _serviceName options: NSCaseInsensitiveSearch] == NSOrderedSame)
    {
      NSUInteger changed = 0;
      NSString *volStr = [data objectForKey: @"vol"];
      NSString *balanceStr = [data objectForKey: @"balance"];
      NSString *bassStr = [data objectForKey: @"bass"];
      NSString *trebleStr = [data objectForKey: @"treb"];
      NSString *loudStr = [data objectForKey: @"loud"];
      NSString *band1Str = [data objectForKey: @"band_1"];
      NSString *band2Str = [data objectForKey: @"band_2"];
      NSString *band3Str = [data objectForKey: @"band_3"];
      NSString *band4Str = [data objectForKey: @"band_4"];
      NSString *band5Str = [data objectForKey: @"band_5"];
      NSString *muteStr = [data objectForKey: @"mute"];
      NSString *ampStr = [data objectForKey: @"ampOn"];
      NSString *audioSessionActiveStr = [data objectForKey: @"audioSessionActive"];
      NSString *audioSessionName = [data objectForKey: @"audioSession"];
      NSString *noFeedbackStr = [data objectForKey: @"noFeedback"];

      if (volStr != nil)
      {
        NSUInteger volume = [volStr integerValue];
        
        if (volume != _volume)
        {
          _volume = volume;
          changed |= NLRENDERER_VOLUME_CHANGED;
        }
      }
      
      if (balanceStr != nil)
      {
        NSUInteger balance = [balanceStr integerValue];
        
        if (balance != _balance)
        {
          _balance = balance;
          changed |= NLRENDERER_BALANCE_CHANGED;
        }
      }
      
      if (bassStr != nil)
      {
        NSUInteger bass = [bassStr integerValue];
        
        if (bass != _bass)
        {
          _bass = bass;
          changed |= NLRENDERER_BASS_CHANGED;
        }
      }
      
      if (trebleStr != nil)
      {
        NSUInteger treble = [trebleStr integerValue];
        
        if (treble != _treble)
        {
          _treble = treble;
          changed |= NLRENDERER_TREBLE_CHANGED;
        }
      }
      
      if (loudStr != nil)
      {
        NSInteger loud = [loudStr integerValue];
        
        if (loud == 255)
          loud = -1;
        if (loud != _loud)
        {
          _loud = loud;
          changed |= NLRENDERER_LOUD_CHANGED;
        }
      }
      
      if (band1Str != nil)
      {
        NSUInteger band1 = [band1Str integerValue];
        
        if (band1 != _band1)
        {
          _band1 = band1;
          changed |= NLRENDERER_BAND1_CHANGED;
        }
      }
      
      if (band2Str != nil)
      {
        NSUInteger band2 = [band2Str integerValue];
        
        if (band2 != _band2)
        {
          _band2 = band2;
          changed |= NLRENDERER_BAND2_CHANGED;
        }
      }
      
      if (band3Str != nil)
      {
        NSUInteger band3 = [band3Str integerValue];
        
        if (band3 != _band3)
        {
          _band3 = band3;
          changed |= NLRENDERER_BAND3_CHANGED;
        }
      }
      
      if (band4Str != nil)
      {
        NSUInteger band4 = [band4Str integerValue];
        
        if (band4 != _band4)
        {
          _band4 = band4;
          changed |= NLRENDERER_BAND4_CHANGED;
        }
      }
      
      if (band5Str != nil)
      {
        NSUInteger band5 = [band5Str integerValue];
        
        if (band5 != _band5)
        {
          _band5 = band5;
          changed |= NLRENDERER_BAND5_CHANGED;
        }
      }
      
      if (muteStr != nil)
      {
        BOOL mute = [muteStr isEqualToString: @"1"];
        
        if (mute != _mute)
        {
          _mute = mute;
          changed |= NLRENDERER_MUTE_CHANGED;
        }
      }
      
      if (ampStr != nil)
      {
        BOOL ampOn = [ampStr isEqualToString: @"1"];
        
        if (ampOn != _ampOn)
        {
          _ampOn = ampOn;
          changed |= NLRENDERER_AMP_ON_CHANGED;
        }
      }
      
      if (audioSessionActiveStr != nil)
      {
        BOOL audioSessionActive = [audioSessionActiveStr isEqualToString: @"1"];
        
        if (audioSessionActive != _audioSessionActive)
        {
          _audioSessionActive = audioSessionActive;
          changed |= NLRENDERER_AUDIO_SESSION_CHANGED;
        }
      }
      
      if (audioSessionName != nil &&
          [audioSessionName compare: _audioSessionName options: NSCaseInsensitiveSearch] != NSOrderedSame)
      {
        [_audioSessionName release]; 
        _audioSessionName = [audioSessionName retain];
        [_audioSessionDisplayName release];
        _audioSessionDisplayName = [[GuiXmlParser stripSpecialAffixesFromString: audioSessionName] retain];
        changed |= NLRENDERER_AUDIO_SESSION_CHANGED;
      }
      
      if (noFeedbackStr != nil)
      {
        BOOL noFeedback = [noFeedbackStr isEqualToString: @"1"];
        
        if (noFeedback != _noFeedback)
        {
          _noFeedback = noFeedback;
          changed |= NLRENDERER_NO_FEEDBACK_CHANGED;
        }
      }
      
      if (changed != 0)
        [self _notifyDelegates: changed];
    }
    
    if (_permId == nil)
    {
      // Occasionally our original request is lost; try again...
      [_netStreamsComms send: [NSString stringWithFormat: @"QUERY SERVICE {{%@}}", _serviceName]
                          to: [NSString stringWithFormat: @"%@~root", _serviceName]];
    }
  }
}

- (void) _sendCommand: (NSString *) command
{
  if (_controlGroup == nil)
    [_netStreamsComms send: command to: _serviceName];
  else
    [_netStreamsComms send: command to: _controlGroup];
}

- (void) _notifyDelegates: (NSUInteger) changed
{
  NSSet *delegates = [NSSet setWithSet: _rendererDelegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<NLRendererDelegate> delegate;
  
  while ((delegate = [enumerator nextObject]))
    [delegate renderer: self stateChanged: changed];
}

- (void) _deregisterFromNetStreams
{
  //NSLog( @"Deregister" );
  if (_statusRspHandle != nil)
  {
    [_netStreamsComms deregisterDelegate: _statusRspHandle];
    _statusRspHandle = nil;
  }
  if (_permIdRspHandle != nil)
  {
    [_netStreamsComms deregisterDelegate: _permIdRspHandle];
    _permIdRspHandle = nil;
  }

  [self _cancelNetStreamsQueries];
}
  
- (void) _cancelNetStreamsQueries
{
  //NSLog( @"Cancel send every" );
  if (_registerMsgHandle != nil)
  {
    [_netStreamsComms cancelSendEvery: _registerMsgHandle];
    [_netStreamsComms send: [NSString stringWithFormat: @"REGISTER OFF,{{%@}}", _serviceName] to: nil];
    _registerMsgHandle = nil;
  }
  if (_queryMsgHandle != nil)
  {
    [_netStreamsComms cancelSendEvery: _queryMsgHandle];
    _queryMsgHandle = nil;
  }
}

- (void) dealloc
{
#if DEBUG
  //**/NSLog( @"Renderer destroyed: %@ (%08X)", _displayName, self );
#endif
  [self _deregisterFromNetStreams];
  [_rendererDelegates release];
  [_serviceName release];
  [_displayName release];
  [_permId release];
  [_audioSessionName release];
  [_audioSessionDisplayName release];
  [_audioControls release];
  [_videoControls release];
  [super dealloc];
}

@end
