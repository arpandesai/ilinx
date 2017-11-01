//
//  NLSourceTuner.m
//  iLinX
//
//  Created by mcf on 18/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLSourceTuner.h"
#import "NLBrowseListNetStreamsRoot.h"
#import "ArtworkRequest.h"

#define _pcomms NETSTREAMSCOMMS_PRODUCTION_ONLY(_comms)

// How often, in seconds, to send the report registration request to ensure
// that it does not expire
#define REGISTRATION_RENEWAL_INTERVAL 30

// Timeout for fetching artwork, in seconds
#define URL_FETCH_TIMEOUT 5

@interface NLSourceTuner ()

- (void) notifyDelegates: (NSUInteger) changed;
- (void) findExternalArtwork;
- (void) artworkFound: (UIImage *) image;
- (void) registerForNetStreams;
- (void) deregisterFromNetStreams;

- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response;
- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) data;
- (void) connectionDidFinishLoading: (NSURLConnection *) connection;
- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error;

@end

@implementation NLSourceTuner

@synthesize
  channelName = _channelName,
  channelNum = _channelNum,
  currentPreset = _currentPreset,
  band = _band,
  signalStrength = _signalStrength,
  bitrate = _bitrate,
  format = _format,
  stereo = _stereo,
  song = _song,
  artist = _artist,
  genre = _genre,
  artwork = _artwork,
  caption = _caption,
  frequency = _frequency,
  rescanComplete = _rescanComplete,
  stationsFound = _stationsFound;

- (id) initWithSourceData: (NSDictionary *) sourceData comms: (NetStreamsComms *) comms
{
  if (self = [super initWithSourceData: sourceData comms: comms])
    _sourceDelegates = [NSMutableSet new];

  return self;
}

- (NSUInteger) capabilities
{
  NSString *controlType = [self controlType];
  NSUInteger capabilities = 0;
  
  if (!([controlType isEqualToString: @"NOCTRL"] ||
        [controlType isEqualToString: @"IR"] ||
        [controlType isEqualToString: @"TUNER"]))
    capabilities |= SOURCE_TUNER_HAS_FEEDBACK;
  
  // Hack - NNT supports dynamic presets, but not direct tuning; everything else is the
  // reverse.  There ought to be a better way of doing this...

  if ([controlType isEqualToString: @"MULTI TUNER"])
    capabilities |= SOURCE_TUNER_HAS_DYNAMIC_PRESETS;
  else
    capabilities |= SOURCE_TUNER_HAS_DIRECT_TUNE;
  
  return capabilities;
}

- (NLBrowseList *) browseMenu
{
  if (_browseMenu == nil)
  {
    // Some tuners return all available channels as the content of the media menu; others return
    // top level entries with children (e.g. All Channels, Categories).  Assume that we're getting
    // all channels, hence the title; NLBrowseList class will cope if there are actually submenus
    _browseMenu = [[NLBrowseListNetStreamsRoot alloc]
                   initWithSource: self
                   title: NSLocalizedString( @"All Channels",
                                            @"Title of the top level menu of available browse items on a tuner" )
                   path: [self browseRootPath] listCount: NSUIntegerMax addAllSongs: ADD_ALL_SONGS_NO comms: _comms];
  }
  
  return _browseMenu;
}

- (NSString *) browseRootPath
{
  NSString *browseScreen = [_sourceData objectForKey: @"browseScreen"];
  NSString *rootPath;

  if ((([self capabilities] & SOURCE_TUNER_HAS_FEEDBACK) == 0) ||
      (browseScreen != nil && [browseScreen isEqualToString: @"0"]) ||
      ([[self controlType] isEqualToString: @"MULTI TUNER"] && ![_band isEqualToString: @"DAB"]))
    rootPath = nil;
  else
    rootPath = @"media";
  
  return rootPath;
}

- (NSString *) controlState
{
  return _controlState;
}

- (void) setIsCurrentSource: (BOOL) isCurrentSource
{
  if (isCurrentSource)
  {
    if (!_isCurrentSource && [_sourceDelegates count] == 0)
      [self registerForNetStreams];
  }
  else
  {
    if (_isCurrentSource && [_sourceDelegates count] == 0)
      [self deregisterFromNetStreams];
  }
  
  [super setIsCurrentSource: isCurrentSource];
}

- (void) addDelegate: (id<NLSourceTunerDelegate>) delegate
{
  if (!_isCurrentSource && [_sourceDelegates count] == 0)
    [self registerForNetStreams];
  
  [_sourceDelegates addObject: delegate];
}

- (void) removeDelegate: (id<NLSourceTunerDelegate>) delegate
{
  if ([_sourceDelegates count] > 0)
  {
    [_sourceDelegates removeObject: delegate];
    if (!_isCurrentSource && [_sourceDelegates count] == 0)
      [self deregisterFromNetStreams];
  }  
}

- (void) nextBand
{
  [_pcomms send: @"BAND NEXT" to: self.serviceName];
  [self ifNoFeedbackSetCaption: self.serviceName];
}

- (void) channelUp
{
  [_pcomms send: @"NEXT" to: self.serviceName];
  [self ifNoFeedbackSetCaption: self.serviceName];
}

- (void) channelDown
{
  [_pcomms send: @"PREV" to: self.serviceName];
  [self ifNoFeedbackSetCaption: self.serviceName];
}

- (void) tuneUp
{
  [_pcomms send: @"TUNE UP" to: self.serviceName];
  [self ifNoFeedbackSetCaption: self.serviceName];
}

- (void) tuneDown
{
  [_pcomms send: @"TUNE DN" to: self.serviceName];
  [self ifNoFeedbackSetCaption: self.serviceName];
}

- (void) seekUp
{
  [_pcomms send: @"SEEK UP" to: self.serviceName];
  [self ifNoFeedbackSetCaption: self.serviceName];
}

- (void) seekDown
{
  [_pcomms send: @"SEEK DN" to: self.serviceName];
  [self ifNoFeedbackSetCaption: self.serviceName];
}

- (void) scanUp
{
  [_pcomms send: @"SCAN UP" to: self.serviceName];
  [self ifNoFeedbackSetCaption: self.serviceName];
}

- (void) scanDown
{
  [_pcomms send: @"SCAN DN" to: self.serviceName];
  [self ifNoFeedbackSetCaption: self.serviceName];
}

- (void) presetUp
{
  [_pcomms send: @"PRESET UP" to: self.serviceName];
  [self ifNoFeedbackSetCaption: self.serviceName];
}

- (void) presetDown
{
  [_pcomms send: @"PRESET DN" to: self.serviceName];
  [self ifNoFeedbackSetCaption: self.serviceName];
}

- (void) selectPreset: (NSUInteger) preset
{
  [_pcomms send: [NSString stringWithFormat: @"PRESET %u", preset + 1] to: self.serviceName];
  [self ifNoFeedbackSetCaption: self.serviceName];
}

- (void) savePreset: (NSUInteger) preset withTitle: (NSString *) title
{
  [_pcomms send: [NSString stringWithFormat: @"MENU_UPDATE {{presets}},{{%@}},%u", title, preset + 1] to: self.serviceName];
  if (_browseMenu != nil && ((id<NLBrowseListRoot>) _browseMenu).presetsList != nil)
  {
    NLBrowseList *presetList = ((id<NLBrowseListRoot>) _browseMenu).presetsList;

    // The list will need refreshing, however it doesn't always update immediately on the tuner.  Unfortunately, there isn't
    // a reliable response to the MENU_UPDATE command that we can look for to trigger the refresh so the best we can do is
    // queue a few refreshes.
    [presetList refresh];
    [presetList performSelector: @selector(refresh) withObject: nil afterDelay: 2];
    [presetList performSelector: @selector(refresh) withObject: nil afterDelay: 5];
  }
}

- (void) clearAllPresets
{
  [_pcomms send: @"MENU_DELETE {{presets}},ALL" to: self.serviceName];
  if (_browseMenu != nil && ((id<NLBrowseListRoot>) _browseMenu).presetsList != nil)
  {
    NLBrowseList *presetList = ((id<NLBrowseListRoot>) _browseMenu).presetsList;
    
    // The list will need refreshing, however it doesn't always update immediately on the tuner.  Unfortunately, there isn't
    // a reliable response to the MENU_DELETE command that we can look for to trigger the refresh so the best we can do is
    // queue a few refreshes.
    [presetList refresh];
    [presetList performSelector: @selector(refresh) withObject: nil afterDelay: 2];
    [presetList performSelector: @selector(refresh) withObject: nil afterDelay: 5];
  }
}

- (void) setMono
{
  [_pcomms send: @"SET MONO" to: self.serviceName];
}

- (void) setStereo
{
  [_pcomms send: @"SET STEREO" to: self.serviceName];
}

- (void) setCaption: (NSString *) caption
{
  [_pcomms send: [NSString stringWithFormat: @"SET CAPTION {{%@}}", caption] to: self.serviceName];
}

- (void) ifNoFeedbackSetCaption: (NSString *) caption
{
  if (([self capabilities] & SOURCE_TUNER_HAS_FEEDBACK) == 0)
    [self setCaption: caption];
}

- (void) sendKey: (NSUInteger) key
{
  NSString *cmd;
  
  if (key == SOURCE_TUNER_KEY_ENTER)
    cmd = @"ENTER";
  else if (key == SOURCE_TUNER_KEY_CLEAR)
    cmd = @"CLEAR";
  else if (key < 10 || key == SOURCE_TUNER_KEY_A || key == SOURCE_TUNER_KEY_B)
    cmd = [NSString stringWithFormat: @"KEY %c", (char) (key + '0')];
  else
    cmd = nil;
  
  if (cmd != nil)
    [_pcomms send: cmd to: self.serviceName];
}

- (void) rescanChannels
{
  [_pcomms send: @"REFRESH" to: self.serviceName];
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  if ([[data objectForKey: @"type"] isEqualToString: @"source"])
  {
    NSUInteger changed = 0;
    NSString *channelName = [data objectForKey: @"channel"];
    NSString *channelNum = [data objectForKey: @"channelNum"];
    NSString *preset = [data objectForKey: @"preset"];
    NSString *band = [data objectForKey: @"band"];
    NSString *signalStrengthStr = [data objectForKey: @"strength"];
    NSString *antenna = [data objectForKey: @"antenna"];
    NSString *bitrate = [data objectForKey: @"bitrate"];
    NSString *format = [data objectForKey: @"format"];
    NSString *stereo = [data objectForKey: @"stereo"];
    NSString *song = [data objectForKey: @"song"];
    NSString *artist = [data objectForKey: @"artist"];
    NSString *genre = [data objectForKey: @"genre"];
    NSString *artworkURL = [data objectForKey: @"artwork"];
    NSString *caption = [data objectForKey: @"caption"];
    NSString *controlState = [data objectForKey: @"controlState"];
    NSString *completeStr = [data objectForKey: @"complete"];
    NSString *stationsFoundStr = [data objectForKey: @"found"];
    NSString *power = [data objectForKey: @"power"];
    NSString *frequency = [data objectForKey: @"frequency"];

    if (channelName != nil)
    {
      if ([channelName isEqualToString: @"NA"])
        channelName = @"";
      else
        channelName = [channelName stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
      if (![channelName isEqualToString: _channelName])
      {
        [_channelName release];
        _channelName = [channelName retain];
        changed |= SOURCE_TUNER_CHANNEL_NAME_CHANGED;
      }
    }

    if (channelNum != nil)
    {
      if ([channelNum isEqualToString: @"NA"])
        channelNum = @"";

      if (![channelNum isEqualToString: _channelNum])
      {
        [_channelNum release];
        _channelNum = [channelNum retain];
        changed |= SOURCE_TUNER_CHANNEL_NUM_CHANGED;
      }
    }
    
    if (preset != nil)
    {
      if ([preset isEqualToString: @"NA"])
        preset = @"";
      if (preset != _currentPreset)
      {
        [_currentPreset release];
        _currentPreset = [preset retain];
        changed |= SOURCE_TUNER_PRESET_CHANGED;
      }
    }

    if (band != nil)
    {
      if ([band isEqualToString: @"NA"])
        band = @"";
      if (![band isEqualToString: _band])
      {
        [_band release];
        _band = [band retain];
        changed |= SOURCE_TUNER_BAND_CHANGED;
        
        // The channels returned by some tuners (e.g. Naim) are dependent on the current
        // band, so discard the old browse list when the band changes.
        [_browseMenu release];
        _browseMenu = nil;
      }
    }
    
    if (signalStrengthStr != nil && [signalStrengthStr isEqualToString: @"NA"])
      signalStrengthStr = nil;
    if (signalStrengthStr != nil || antenna != nil)
    {
      NSUInteger signalStrength;
      
      if (signalStrengthStr != nil)
        signalStrength = [signalStrengthStr integerValue];
      else
      {
        if ([antenna hasPrefix: @"No"])
          signalStrength = 0;
        else if ([antenna hasPrefix: @"Weak"])
          signalStrength = 33;
        else if ([antenna hasPrefix: @"Good"])
          signalStrength = 67;
        else
          signalStrength = 100;
      }
      
      if (signalStrength != _signalStrength)
      {
        _signalStrength = signalStrength;
        changed |= SOURCE_TUNER_SIGNAL_STRENGTH_CHANGED;
      }
    }

    // Arcam T32 tuner reports bitrate in the artist field! 
    if (artist != nil && band != nil && bitrate == nil)
    {
      if ([band isEqualToString: @"DAB"])
      {
        if (format == nil)
          format = @"DIGITAL";
        if ([artist hasSuffix: @" kbps"] && [artist integerValue] > 0)
        {
          bitrate = [NSString stringWithFormat: @"%d000", [artist integerValue]];
          artist = nil;
        }
      }
      else
      {
        if (format == nil)
          format = @"";
        bitrate = @"";
      }
    }

    if (bitrate != nil)
    {
      if ([bitrate isEqualToString: @"NA"])
        bitrate = @"";
      if (![bitrate isEqualToString: _bitrate])
      {
        [_bitrate release];
        _bitrate = [bitrate retain];
        changed |= SOURCE_TUNER_BITRATE_CHANGED;
      }
    }
    
    if (format != nil)
    {
      if ([format isEqualToString: @"NA"])
        format = @"";
      if (![format isEqualToString: _format])
      {
        [_format release];
        _format = [format retain];
        changed |= SOURCE_TUNER_FORMAT_CHANGED;
      }
    }
    
    if (stereo != nil)
    {
      if ([stereo isEqualToString: @"NA"])
        stereo = @"";
      if (![stereo isEqualToString: _stereo])
      {
        [_stereo release];
        _stereo = [stereo retain];
        changed |= SOURCE_TUNER_STEREO_CHANGED;
      }
    }
    
    if (song != nil && ![song isEqualToString: _song])
    {
      [_song release];
      _song = [song retain];
      changed |= SOURCE_TUNER_SONG_CHANGED;
    }
    
    if (artist != nil && ![artist isEqualToString: _artist])
    {
      [_artist release];
      _artist = [artist retain];
      changed |= SOURCE_TUNER_ARTIST_CHANGED;
    }
    
    if (genre != nil && ![genre isEqualToString: _genre])
    {
      [_genre release];
      _genre = [genre retain];
      changed |= SOURCE_TUNER_GENRE_CHANGED;
    }

    if (caption != nil && ![caption isEqualToString: _caption])
    {
      [_caption release];
      _caption = [caption retain];
      changed |= SOURCE_TUNER_CAPTION_CHANGED;
    }
    
    if (frequency != nil && ![frequency isEqualToString: _frequency])
    {
      [_frequency release];
      _frequency = [frequency retain];
      changed |= SOURCE_TUNER_FREQUENCY_CHANGED;
    }
    
    // Arcam T32 again...
    if (controlState == nil && power != nil)
    {
      if ([power isEqualToString: @"1"])
        controlState = @"PLAY";
      else
        controlState = @"STOP";
    }
    if (controlState != nil && ![controlState isEqualToString: _controlState])
    {
      BOOL refresh = (_browseMenu != nil && _controlState != nil &&
                      ([_controlState isEqualToString: @"REFRESH"] || [controlState isEqualToString: @"REFRESH"]));

      [_controlState release];
      _controlState = [controlState retain];
      changed |= SOURCE_TUNER_CONTROL_STATE_CHANGED;
      if (refresh)
        [_browseMenu refresh];
    }

    
    if (artworkURL != nil && [artworkURL length] > 0 && ![artworkURL isEqualToString: _artworkURL])
    {
      [_artworkURL release];
      _artworkURL = [artworkURL retain];
      
      if ([[_artworkURL lowercaseString] hasSuffix: @".swf"])
        [self findExternalArtwork];
      else
      {
        if (_artworkConnection != nil)
        {
          [_artworkConnection cancel];
          [_artworkConnection release];
        }
        
        if ([artworkURL length] == 0)
        {
          [_oldArtworkData release];
          _oldArtworkData = nil;
          [_artworkData release];
          _artworkData = nil;
          [_artwork release];
          _artwork = nil;
          changed |= SOURCE_TUNER_ARTWORK_CHANGED;
        }
        else
        {
          NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString: _artworkURL] 
                                                   cachePolicy: NSURLRequestUseProtocolCachePolicy
                                               timeoutInterval: URL_FETCH_TIMEOUT];
          
          [_oldArtworkData release];
          _oldArtworkData = _artworkData;
          _artworkData = nil;
          
          _artworkConnection = [[NSURLConnection alloc] initWithRequest: request delegate: self];
        }
      }
    }
    else if ((artworkURL == nil || [artworkURL length] == 0) && 
             ((changed & SOURCE_TUNER_CHANNEL_NAME_CHANGED) != 0))
    {
      [self findExternalArtwork];
    }
        
    NSUInteger complete;
    NSUInteger stationsFound;
    
    if (controlState == nil || ![controlState isEqualToString: @"REFRESH"])
    {
      complete = 100;
      stationsFound = 0;
    }
    else
    {
      if (_artwork != nil)
      {
        [_artwork release];
        _artwork = nil;
        changed |= SOURCE_TUNER_ARTWORK_CHANGED;
      }

      if (completeStr == nil)
        complete = _rescanComplete;
      else
        complete = [completeStr integerValue];
      if (stationsFoundStr == nil)
        stationsFound = _stationsFound;
      else
        stationsFound = [stationsFoundStr integerValue];
    }
    
    if (complete != _rescanComplete)
    {
      _rescanComplete = complete;
      changed |= SOURCE_TUNER_RESCAN_COMPLETE_CHANGED;
    }
    
    if (stationsFound != _stationsFound)
    {
      _stationsFound = stationsFound;
      changed |= SOURCE_TUNER_STATIONS_FOUND_CHANGED;
    }
    
    if (([_browseMenu countOfList] != _listCount) && ([_browseMenu countOfList] != NSUIntegerMax))
    {
      _listCount = [_browseMenu countOfList];
      changed |= SOURCE_TUNER_LIST_COUNT_CHANGED;
    }
    
    if (changed != 0)
      [self notifyDelegates: changed];
  }
}

- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response
{
  if (connection == _artworkConnection)
  {
    // If it returns a not found type response, treat as a failure
    
    if ([response.MIMEType rangeOfString: @"image"].length == 0)
    {
      [connection cancel];
      [self connection: connection didFailWithError: nil];
    }
  }  
}

- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) data
{
  if (connection == _artworkConnection)
  {
    if (_artworkData == nil)
      _artworkData = [data mutableCopy];
    else
      [_artworkData appendData: data]; 
  }
}

- (void) connectionDidFinishLoading: (NSURLConnection *) connection
{
  if (connection == _artworkConnection)
  {
    BOOL changed;
    
    if (_artworkData == nil)
    {
      [self findExternalArtwork];
      changed = NO;
    }
    else if ([_artworkData isEqualToData: _oldArtworkData])
      changed = NO;
    else
    {
      _artwork = [[UIImage imageWithData: _artworkData] retain];
      changed = YES;
    }
    
    [_oldArtworkData release];
    _oldArtworkData = nil;
    [_artworkConnection release];
    _artworkConnection = nil;
    
    if (changed)
      [self notifyDelegates: SOURCE_TUNER_ARTWORK_CHANGED];
  }
}

- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error
{
  if (connection == _artworkConnection)
  {
    [_oldArtworkData release];
    _oldArtworkData = nil;
    [_artworkData release];
    _artworkData = nil;
    [_artworkConnection release];
    _artworkConnection = nil;
    [self findExternalArtwork];
  }
}

- (void) notifyDelegates: (NSUInteger) changed
{
  NSSet *delegates = [NSSet setWithSet: _sourceDelegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<NLSourceTunerDelegate> delegate;
  
  while ((delegate = [enumerator nextObject]))
    [delegate source: self stateChanged: changed];
}
       
- (void) findExternalArtwork
{
  NSString *artworkFile = _artworkURL;
  NSRange findStr = [artworkFile rangeOfString: @"." options: NSBackwardsSearch];
  
  if (findStr.length > 0)
  {
    artworkFile = [artworkFile substringToIndex: findStr.location];
    findStr = [artworkFile rangeOfString: @"/" options: NSBackwardsSearch];
    if (findStr.length > 0)
      artworkFile = [artworkFile substringFromIndex: findStr.location + 1];
  }

  NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys: 
    _channelName, @"channel",
    _channelNum, @"channelNum",
    _currentPreset, @"preset",
    _band, @"band",
    _bitrate, @"bitrate",
    _format, @"format",
    _stereo, @"stereo",
    _song, @"song",
    _artist, @"artist",
    _genre, @"genre",
    _artworkURL, @"artwork",
    _caption, @"caption",
    _controlState, @"controlState",
    artworkFile, @"artworkName",
                        nil];

  [_artworkData release];
  _artworkData = nil;
  [_oldArtworkData release];
  _oldArtworkData = nil;

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
  if (image != _artwork)
  {
    [_artwork release];
    _artwork = [image retain];
    [self notifyDelegates: SOURCE_TUNER_ARTWORK_CHANGED];
  }

  if (_artRequest != nil)
  {
    [_artRequest release];
    _artRequest = nil;
  }
}

- (void) registerForNetStreams
{
  _rescanComplete = 100;
  _channelName = [@"" retain];
  _channelNum = [@"" retain];
  _currentPreset = [@"" retain];
  _band = [@"" retain];
  _bitrate = [@"" retain];
  _format = [@"" retain];
  _stereo = [@"" retain];
  _song = [@"" retain];
  _artist = [@"" retain];
  _genre = [@"" retain];
  _artworkURL = [@"" retain];
  _caption = [@"" retain];
  _controlState = [@"" retain];

  //NSLog( @"Register" );
  _statusRspHandle = [_comms registerDelegate: self forMessage: @"REPORT" from: self.serviceName];
  _registerMsgHandle = [_comms send: [NSString stringWithFormat: @"REGISTER ON,{{%@}}", self.serviceName]
                                 to: nil every: REGISTRATION_RENEWAL_INTERVAL];
  
  // Send a one-off query of source status, because (at least on the NS01) when in a stopped
  // state, registering for the service doesn't produce any response
  [_comms send: @"QUERY SOURCE" to: self.serviceName];
}

- (void) deregisterFromNetStreams
{
  //NSLog( @"Deregister" );
  if (_statusRspHandle != nil)
  {
    [_comms deregisterDelegate: _statusRspHandle];
    _statusRspHandle = nil;
  }
  //NSLog( @"Cancel send every" );
  if (_registerMsgHandle != nil)
  {
    [_comms cancelSendEvery: _registerMsgHandle];
    [_comms send: [NSString stringWithFormat: @"REGISTER OFF,{{%@}}", self.serviceName] to: nil];
    _registerMsgHandle = nil;
  }
  [_channelName release];
  _channelName = nil;
  [_channelNum release];
  _channelNum = nil;
  [_currentPreset release];
  _currentPreset = nil;
  [_band release];
  _band = nil;
  _signalStrength = 0;
  [_bitrate release];
  _bitrate = nil;
  [_format release];
  _format = nil;
  [_stereo release];
  _stereo = nil;
  [_genre release];
  _genre = nil;
  [_artworkURL release];
  _artworkURL = nil;
  if (_artworkConnection != nil)
  {
    [_artworkConnection cancel];
    [_artworkConnection release];
    _artworkConnection = nil;
  }
  [_artworkData release];
  _artworkData = nil;
  [_oldArtworkData release];
  _oldArtworkData = nil;
  [_artwork release];
  _artwork = nil;
  [_artRequest release];
  _artRequest = nil;
  [_caption release];
  _caption = nil;
  [_frequency release];
  _frequency = nil;
  [_controlState release];
  _controlState = nil;
  _rescanComplete = 100;
  _stationsFound = 0;
}

- (void) resetListCount
{
  _listCount = 0;
}

- (void) dealloc
{
  if (_browseMenu != nil && ((id<NLBrowseListRoot>) _browseMenu).presetsList != nil)
    [NSObject cancelPreviousPerformRequestsWithTarget: ((id<NLBrowseListRoot>) _browseMenu).presetsList 
                                             selector: @selector(refresh) object: nil];
  [self deregisterFromNetStreams];
  [_sourceDelegates release];
  [super dealloc];
}

@end

