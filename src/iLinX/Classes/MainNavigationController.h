//
//  NavigationController.h
//  iLinX
//
//  Created by mcf on 25/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLRenderer.h"

@class CustomSlider;
@class ExecutingMacroAlert;

@interface MainNavigationController : UINavigationController <NLRendererDelegate>
{
@private
  UIToolbar *_audioControls;
  UIBarStyle _savedStyle;
  CustomSlider *_slider;
  UIBarButtonItem *_mute;
  UIButton *_volumeUp;
  UIButton *_volumeDown;
  UIImage *_muted;
  UIImage *_unmuted;
  NSArray *_feedbackControls;
  NSArray *_noFeedbackControls;
  NSArray *_currentControls;
  NLRenderer *_renderer;
  BOOL _visible;
  BOOL _ignoreVolumeUpdates;
  NSTimer *_ignoreVolumeUpdatesDebounceTimer;
  NSTimer *_volumeRepeatTimer;
  BOOL _repeatIsUp;
  UINavigationController *_settingsController;
  UIButton *_macroButton;
  ExecutingMacroAlert *_executingMacroAlert;
}

@property (readonly) ExecutingMacroAlert *executingMacroAlert;

- (void) setRenderer: (NLRenderer *) renderer;
- (void) showAudioControls: (BOOL) show;
- (void) setAudioControlsStyle: (UIBarStyle) style;

@end
