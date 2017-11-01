//
//  AudioControlsViewIPad.m
//  iLinX
//
//  Created by Tony Short on 21/09/2010.
//

#import "AudioControlsViewIPad.h"

@interface AudioControlsViewIPad ()


- (void) disableVolumeUpdates;
- (void) enableVolumeUpdatesAfterDelay;
- (void) enableVolumeUpdates;
- (void) volumeRepeatTimerFired: (NSTimer *) timer;
- (void) showHideControls;

@end

@implementation AudioControlsViewIPad

- (void) setRenderer: (NLRenderer *) renderer
{
  if (_renderer != renderer)
  {
    if (_renderer != nil)
    {
      [_renderer removeDelegate: self];
      [_renderer release];
    }

    _renderer = [renderer retain];
    [_renderer addDelegate: self];
    [self showHideControls];
  }
}

- (void) enable
{
  _slider.enabled = _mute.enabled = _volDown.enabled = _volUp.enabled = YES;
}

- (void) disable
{
  _slider.enabled = _mute.enabled = _volDown.enabled = _volUp.enabled = NO;
}

- (void) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags
{
  _mute.selected = renderer.mute;
  
  if ((flags & NLRENDERER_NO_FEEDBACK_CHANGED) != 0)
    [self showHideControls];
  
  if ((flags & NLRENDERER_VOLUME_CHANGED) != 0 && !_ignoreVolumeUpdates)
    _slider.value = renderer.volume;
  
  if ((flags & NLRENDERER_MUTE_CHANGED) != 0)
    [self setMuteIcon];
}

- (void) setMuteIcon
{
  BOOL muted = (_renderer == nil || _renderer.noFeedback || _renderer.mute);
  
  _slider.showAlternateThumb = muted;
}

- (IBAction) setVolume: (UISlider *) slider
{
  if (_muteStartedTime == nil || [_muteStartedTime timeIntervalSinceNow] < -0.5)
    _renderer.volume = slider.value;
}

- (IBAction) disableVolumeUpdatesOnTouchDown: (id) sender
{
  [self disableVolumeUpdates];
  [_muteStartedTime release];
  _muteStartedTime = [[NSDate date] retain];
  _originalVolume = _slider.value;
}

- (IBAction) enableVolumeUpdatesOnTouchUp: (id) sender
{
  [self enableVolumeUpdatesAfterDelay];
  if (_muteStartedTime != nil)
  {
    if ([_muteStartedTime timeIntervalSinceNow] >= -0.5)
      _slider.value = _originalVolume;
    
    [_muteStartedTime release];
    _muteStartedTime = nil;
  }
}

- (IBAction) toggleMute: (UIButton *) button
{
  [_renderer toggleMute];
}

- (IBAction) cancelToggleMute: (UISlider *) slider
{
  [self enableVolumeUpdatesAfterDelay];
  [_muteStartedTime release];
  _muteStartedTime = nil;
}

- (IBAction) pressedVolumeUp: (id) control
{
  [_renderer volumeUp];
  _repeatIsUp = YES;
  [_volumeRepeatTimer invalidate];
  _volumeRepeatTimer = [NSTimer scheduledTimerWithTimeInterval: REPEAT_INITIAL_DELAY target: self
                                                      selector: @selector(volumeRepeatTimerFired:)
                                                      userInfo: nil repeats: NO];
}

- (IBAction) releasedVolumeUp: (id) control
{
  if (_repeatIsUp)
  {
    [_volumeRepeatTimer invalidate];
    _volumeRepeatTimer = nil;
  }
}

- (IBAction) pressedVolumeDown: (id) control
{
  [_renderer volumeDown];
  _repeatIsUp = NO;
  [_volumeRepeatTimer invalidate];
  _volumeRepeatTimer = [NSTimer scheduledTimerWithTimeInterval: REPEAT_INITIAL_DELAY target: self
                                                      selector: @selector(volumeRepeatTimerFired:)
                                                      userInfo: nil repeats: NO];
}

- (IBAction) releasedVolumeDown: (id) control
{
  if (!_repeatIsUp)
  {
    [_volumeRepeatTimer invalidate];
    _volumeRepeatTimer = nil;
  }
}

- (void) disableVolumeUpdates
{
  _ignoreVolumeUpdates = YES;
  [_ignoreVolumeUpdatesDebounceTimer invalidate];
  _ignoreVolumeUpdatesDebounceTimer = nil;
}

- (void) enableVolumeUpdatesAfterDelay
{
  _ignoreVolumeUpdatesDebounceTimer =
  [NSTimer scheduledTimerWithTimeInterval: 2.0 target: self selector: @selector(enableVolumeUpdates) 
                                 userInfo: nil repeats: NO];
}

- (void) enableVolumeUpdates
{
  _ignoreVolumeUpdatesDebounceTimer = nil;
  _ignoreVolumeUpdates = NO;
  [self renderer: _renderer stateChanged: NLRENDERER_VOLUME_CHANGED];
}

- (void) volumeRepeatTimerFired: (NSTimer *) timer
{
  if (_renderer != nil)
  {
    if (_repeatIsUp)
      [_renderer volumeUp];
    else
      [_renderer volumeDown];
    
    [_volumeRepeatTimer invalidate];
    _volumeRepeatTimer = [NSTimer scheduledTimerWithTimeInterval: REPEAT_SUBSEQUENT_DELAY target: self
                                                        selector: @selector(volumeRepeatTimerFired:) 
                                                        userInfo: nil repeats: NO];
  }
}

- (void) showHideControls
{
  _mute.hidden = NO;
  _slider.hidden = _renderer.noFeedback;
  _volDown.hidden = _volUp.hidden = !_renderer.noFeedback;
  [self setNeedsDisplay];
}

- (void) dealloc
{
  [_slider release];
  [_mute release];
  [_volDown release];
  [_volUp release];
  [_volumeRepeatTimer invalidate];
  [_muteStartedTime release];
  [_renderer release];
  [super dealloc];
}

@end
