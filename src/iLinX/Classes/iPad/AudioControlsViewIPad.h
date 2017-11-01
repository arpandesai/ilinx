//
//  AudioControlsViewIPad.h
//  iLinX
//
//  Created by Tony Short on 21/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomSliderIPad.h"
#import "NLRenderer.h"

// Delay before repeating the volume change buttons
#define REPEAT_INITIAL_DELAY 1.5

// Delay between repeats once we've started repeating
#define REPEAT_SUBSEQUENT_DELAY 0.25

@interface AudioControlsViewIPad : UIView <NLRendererDelegate>
{
  NLRenderer *_renderer;
  
  IBOutlet CustomSliderIPad *_slider;
  IBOutlet UIButton *_mute;
  IBOutlet UIButton *_volDown;
  IBOutlet UIButton *_volUp;
  
  BOOL _ignoreVolumeUpdates;
  NSTimer *_ignoreVolumeUpdatesDebounceTimer;
  NSDate *_muteStartedTime;
  CGFloat _originalVolume;
  
  NSTimer *_volumeRepeatTimer;
  BOOL _repeatIsUp;
}

- (void) setRenderer: (NLRenderer *) renderer;
- (void) enable;
- (void) disable;

- (IBAction) setVolume: (UISlider *) slider;
- (IBAction) toggleMute: (UIButton *) button;
- (IBAction) cancelToggleMute: (UISlider *) slider;
- (IBAction) disableVolumeUpdatesOnTouchDown: (id) sender;
- (IBAction) enableVolumeUpdatesOnTouchUp: (id) sender;
- (void) setMuteIcon;

- (IBAction) pressedVolumeUp: (id) control;
- (IBAction) releasedVolumeUp: (id) control;
- (IBAction) pressedVolumeDown: (id) control;
- (IBAction) releasedVolumeDown: (id) control;

@end
