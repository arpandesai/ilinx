//
//  MainNavigationController.m
//  iLinX
//
//  Created by mcf on 25/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "MainNavigationController.h"
#import "ConfigManager.h"
#import "ConfigProfile.h"
#import "CustomSlider.h"
#import "CustomViewController.h"
#import "DeprecationHelper.h"
#import "ExecutingMacroAlert.h"
#import "RootViewController.h"
#import "RotatableViewControllerProtocol.h"
#import "SettingsViewController.h"
#import "NLRoom.h"
#import "NLService.h"
#import "StandardPalette.h"

// Delay before repeating the volume change buttons
#define REPEAT_INITIAL_DELAY 1.5

// Delay between repeats once we've started repeating
#define REPEAT_SUBSEQUENT_DELAY 0.25

@interface MainNavigationController ()

- (void) disableVolumeUpdates;
- (void) enableVolumeUpdatesAfterDelay;
- (void) enableVolumeUpdates;
- (void) pressedSettings: (id) control;
- (void) setVolume: (id) control;
- (void) pressedMute: (id) control;
- (void) pressedVolumeUp: (id) control;
- (void) releasedVolumeUp: (id) control;
- (void) pressedVolumeDown: (id) control;
- (void) releasedVolumeDown: (id) control;
- (void) volumeRepeatTimerFired: (NSTimer *) timer;
- (void) settingsDismissed: (id) control;
- (void) pressedMacroButton: (id) control;
- (void) setAudioControlsForRenderer: (NLRenderer *) renderer;
- (void) iLinXSkinChangedNotification: (NSNotification *) notification;

@end

@implementation MainNavigationController

@synthesize executingMacroAlert = _executingMacroAlert;

- (void) loadView
{
#if DEBUG
  NSLog(@"#### MainNavigationController / loadView");
#endif
  [super loadView];

  _audioControls = [UIToolbar new];
  [_audioControls sizeToFit];

  CGRect mainViewBounds = self.view.bounds;
  CGFloat toolbarHeight = _audioControls.frame.size.height;

  [_audioControls setFrame:
   CGRectMake( CGRectGetMinX( mainViewBounds ),
              CGRectGetMinY( mainViewBounds ) + CGRectGetHeight( mainViewBounds ),
              CGRectGetWidth( mainViewBounds ),
              toolbarHeight )];

  // create the audio control buttons
  _slider = [[CustomSlider alloc] initWithFrame:
             CGRectMake( 0, 0, CGRectGetWidth( mainViewBounds ) - 120, _audioControls.bounds.size.height )
                                           tint: nil progressOnly: NO];
  _muted = [[UIImage imageNamed: @"Muted.png"] retain];
  _unmuted = [[UIImage imageNamed: @"Unmuted.png"] retain];
  _mute = [[UIBarButtonItem alloc] initWithImage: _unmuted style: UIBarButtonItemStylePlain
                                          target: self action: @selector(pressedMute:)];
  _volumeUp = [[UIButton buttonWithType: UIButtonTypeCustom] retain];
  [_volumeUp setImage: [UIImage imageNamed: @"VolumeUp.png"] forState: UIControlStateNormal];
  [_volumeUp addTarget: self action: @selector(pressedVolumeUp:) forControlEvents: UIControlEventTouchDown];
  [_volumeUp addTarget: self action: @selector(releasedVolumeUp:)
      forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
  _volumeUp.showsTouchWhenHighlighted = YES;
  [_volumeUp sizeToFit];

  _volumeDown = [[UIButton buttonWithType: UIButtonTypeCustom] retain];
  [_volumeDown setImage: [UIImage imageNamed: @"VolumeDown.png"] forState: UIControlStateNormal];
  [_volumeDown addTarget: self action: @selector(pressedVolumeDown:) forControlEvents: UIControlEventTouchDown];
  [_volumeDown addTarget: self action: @selector(releasedVolumeDown:)
      forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
  _volumeDown.showsTouchWhenHighlighted = YES;
  [_volumeDown sizeToFit];
  
  [_slider addTarget: self action: @selector(setVolume:) forControlEvents: UIControlEventValueChanged];
  [_slider addTarget: self action: @selector(disableVolumeUpdates) forControlEvents: UIControlEventTouchDown];
  [_slider addTarget: self action: @selector(enableVolumeUpdatesAfterDelay)
    forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
  _slider.minimumValue = 0;
  _slider.maximumValue = 100;
  _slider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  
  UIBarButtonItem *settings = [[UIBarButtonItem alloc] initWithImage: [UIImage imageNamed: @"Settings.png"]
                                                               style: UIBarButtonItemStylePlain
                                                              target: self action: @selector(pressedSettings:)];
  UIBarButtonItem *flex1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                                                         target: nil action: nil];
  UIBarButtonItem *flex2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                                                         target: nil action: nil];
  UIBarButtonItem *flex3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                                                         target: nil action: nil];
  UIBarButtonItem *volume = [[UIBarButtonItem alloc] initWithCustomView: _slider];
  UIBarButtonItem *volumeDown = [[UIBarButtonItem alloc] initWithCustomView: _volumeDown];
  UIBarButtonItem *volumeUp = [[UIBarButtonItem alloc] initWithCustomView: _volumeUp];

  _feedbackControls = [[NSArray arrayWithObjects: settings, flex1, volume, flex2, _mute, nil] retain];
  _noFeedbackControls = [[NSArray arrayWithObjects: settings, flex1, volumeDown, flex2, volumeUp, flex3, _mute, nil] retain];

  [settings release];
  [flex1 release];
  [flex2 release];
  [flex3 release];
  [volume release];
  [volumeDown release];
  [volumeUp release];
  
  [self setAudioControlsForRenderer: nil];
  _audioControls.autoresizesSubviews = YES;
  _audioControls.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;

  _macroButton = [UIButton buttonWithType: UIButtonTypeCustom];
  
#if defined(DEMO_BUILD)
  _macroButton.frame = mainViewBounds;
  _macroButton.enabled = NO;
  _macroButton.alpha = 0.1;
  [_macroButton setTitleLabelFont: [UIFont boldSystemFontOfSize: 80]];
  [_macroButton setTitle: NSLocalizedString( @"VIEW", @"iLinX View label overlay" ) forState: UIControlStateNormal];
  [_macroButton setTitleColor: [UIColor blackColor] forState: UIControlStateNormal];
#else
  [_macroButton addTarget: self action: @selector(pressedMacroButton:) forControlEvents: UIControlEventTouchUpInside];
  _macroButton.frame = CGRectMake( 130, 0, 60, 44 );
#endif
  [self.view addSubview: _macroButton];
  [self.view addSubview: _audioControls];

  _executingMacroAlert = [ExecutingMacroAlert new];
  [_executingMacroAlert loadViewUnderView: self.view atIndex: [self.view.subviews count]
                                 inBounds: self.view.bounds withNavigationController: self];

  self.view.backgroundColor = [StandardPalette standardTintColour];
  
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(iLinXSkinChangedNotification:) 
                                               name: [CustomViewController skinChangedNotificationKey] object: nil];
}

- (BOOL) shouldAutorotate
{
  return [self.topViewController respondsToSelector:@selector(implementedRotationOrientations)];
}

- (NSUInteger) supportedInterfaceOrientations
{
  id top = self.topViewController;
  
  if ([top respondsToSelector: @selector(implementedRotationOrientations)])
    return [top implementedRotationOrientations];
  else
    return UIInterfaceOrientationPortrait;
}

- (void) willRotateToInterfaceOrientation: (UIInterfaceOrientation) toInterfaceOrientation duration: (NSTimeInterval) duration
{
  _macroButton.hidden = UIInterfaceOrientationIsLandscape( toInterfaceOrientation );
  [super willRotateToInterfaceOrientation: toInterfaceOrientation duration: duration];
}

- (void) setMuteIcon
{
  if (_renderer != nil && !_renderer.noFeedback && !_renderer.mute)
    _mute.image = _unmuted;
  else 
    _mute.image = _muted;
}

- (void) setRenderer: (NLRenderer *) renderer
{
  if (renderer != _renderer)
  {
    if (_renderer != nil)
    {
      [_renderer removeDelegate: self];
      [_renderer release];
    }

    _renderer = [renderer retain];
    if (renderer == nil)
      _slider.value = 0;
    else
    {
      _slider.value = _renderer.volume;
      [_renderer addDelegate: self];
    }
  
    [self setAudioControlsForRenderer: renderer];
  }
}

- (void) setAudioControlsStyle: (UIBarStyle) style
{
  _audioControls.barStyle = style;
  if (style == UIBarStyleDefault)
  {
    [StandardPalette setTintForToolbar: _audioControls];
    if (_audioControls.barStyle == UIBarStyleDefault)
      _slider.tint = [UIColor whiteColor];
    else
      _slider.tint = nil;
  }
  else
  {
    _slider.tint = nil;
    _audioControls.tintColor = nil;
  }
  
#if defined(DEMO_BUILD)
  if (style == UIBarStyleDefault)
    [_macroButton setTitleColor: [UIColor blackColor] forState: UIControlStateNormal];
  else
    [_macroButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
#endif
}

- (void) showAudioControls: (BOOL) show
{  
  CGRect mainViewBounds = self.view.bounds;
  CGFloat toolbarHeight = _audioControls.frame.size.height;
  
  [UIView beginAnimations: @"ShowHideAudioControls" context: nil];
  [UIView setAnimationDuration: 0.5];

  if (show && !_visible)
  {
    [self.view bringSubviewToFront: _macroButton];
    [_audioControls setFrame:
     CGRectMake( CGRectGetMinX( mainViewBounds ),
                CGRectGetMinY( mainViewBounds ) + CGRectGetHeight( mainViewBounds ) - toolbarHeight,
                CGRectGetWidth( mainViewBounds ),
                toolbarHeight )];
  }
  else if (!show && _visible)
  {
    [_audioControls setFrame:
     CGRectMake( CGRectGetMinX( mainViewBounds ),
                CGRectGetMinY( mainViewBounds ) + CGRectGetHeight( mainViewBounds ),
                CGRectGetWidth( mainViewBounds ),
                toolbarHeight )];
  }
  
  [UIView commitAnimations];
  _visible = show;
}

- (void) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags
{
  if ((flags & NLRENDERER_VOLUME_CHANGED) != 0 && !_ignoreVolumeUpdates)
    _slider.value = renderer.volume;
  if ((flags & NLRENDERER_MUTE_CHANGED) != 0)
    [self setMuteIcon];
  if ((flags & NLRENDERER_NO_FEEDBACK_CHANGED) != 0)
    [self setAudioControlsForRenderer: renderer];
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

- (void) pressedSettings: (id) control
{
  if ([_audioControls superview] != self.view)
    [self settingsDismissed: control];
  else
  {
    UIBarStyle style;
    
    _savedStyle = self.navigationBar.barStyle;
    if (_savedStyle == UIBarStyleBlackTranslucent)
      style = UIBarStyleBlackOpaque;
    else
      style = _savedStyle;

    SettingsViewController *settingsViewController =
    [[SettingsViewController alloc] initWithTitle: NSLocalizedString( @"A/V Settings", @"Title for A/V settings dialog" )
                                         renderer: _renderer 
                                         barStyle: style
                                       doneTarget: self
                                     doneSelector: @selector(settingsDismissed:)];
    
    [_settingsController release];
    _settingsController = [[UINavigationController alloc]
                           initWithRootViewController: settingsViewController];
    [settingsViewController release];
    _settingsController.navigationBar.barStyle = style;
    if (style == UIBarStyleDefault)
      [StandardPalette setTintForNavigationBar: _settingsController.navigationBar];
    [self setAudioControlsStyle: style];
    [_settingsController.view addSubview: _audioControls];
    [self presentModalViewController: _settingsController animated: YES];
  }
}

- (void) setVolume: (id) control
{
  _renderer.volume = _slider.value;
}

- (void) pressedMute: (id) control
{
  if (_renderer.noFeedback)
    [_renderer toggleMute];
  else
  {
    _renderer.mute = (_mute.image == _unmuted);
    [self setMuteIcon];
  }
}

- (void) pressedVolumeUp: (id) control
{
  [_renderer volumeUp];
  _repeatIsUp = YES;
  [_volumeRepeatTimer invalidate];
  _volumeRepeatTimer = [NSTimer scheduledTimerWithTimeInterval: REPEAT_INITIAL_DELAY target: self
                                                      selector: @selector(volumeRepeatTimerFired:) userInfo: nil repeats: NO];
}

- (void) releasedVolumeUp: (id) control
{
  if (_repeatIsUp)
  {
    [_volumeRepeatTimer invalidate];
    _volumeRepeatTimer = nil;
  }
}

- (void) pressedVolumeDown: (id) control
{
  [_renderer volumeDown];
  _repeatIsUp = NO;
  [_volumeRepeatTimer invalidate];
  _volumeRepeatTimer = [NSTimer scheduledTimerWithTimeInterval: REPEAT_INITIAL_DELAY target: self
                                                      selector: @selector(volumeRepeatTimerFired:) userInfo: nil repeats: NO];
}

- (void) releasedVolumeDown: (id) control
{
  if (!_repeatIsUp)
  {
    [_volumeRepeatTimer invalidate];
    _volumeRepeatTimer = nil;
  }
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
                                                        selector: @selector(volumeRepeatTimerFired:) userInfo: nil repeats: NO];
  }
}

- (void) settingsDismissed: (id) control
{
  [self.view addSubview: _audioControls];
  [_settingsController dismissModalViewControllerAnimated: YES];
  [_settingsController release];
  _settingsController = nil;
  [self setAudioControlsStyle: _savedStyle];
}

- (void) pressedMacroButton: (id) control
{
  NSString *macroName = [[ConfigManager currentProfileData] titleBarMacro];

  if ([macroName length] > 0 && _renderer != nil)
  {
    NSTimeInterval delay;
    NLService *newUIScreen = [_renderer.room executeMacro: macroName 
                                     returnExecutionDelay: &delay];

    [_executingMacroAlert selectNewService: newUIScreen afterDelay: delay animated: NO];
  }
}

- (void) setAudioControlsForRenderer: (NLRenderer *) renderer
{
  if (renderer != nil && renderer.noFeedback)
  {
    if (_currentControls != _noFeedbackControls)
    {
      _audioControls.items = _noFeedbackControls;
      _currentControls = _noFeedbackControls;
      _slider.hidden = YES;
      _slider.enabled = NO;
      _volumeDown.hidden = NO;
      _volumeDown.enabled = YES;
      _volumeUp.hidden = NO;
      _volumeUp.enabled = YES;
    }
  }
  else
  {
    if (_currentControls != _feedbackControls)
    {
      _audioControls.items = _feedbackControls;
      _currentControls = _feedbackControls;
      _slider.hidden = NO;
      _slider.enabled = YES;
      _volumeDown.hidden = YES;
      _volumeDown.enabled = NO;
      _volumeUp.hidden = YES;
      _volumeUp.enabled = NO;
      [_volumeRepeatTimer invalidate];
      _volumeRepeatTimer = nil;
    }
  }
  
  [self setMuteIcon];
  for (UIBarItem *item in _audioControls.items)
    item.enabled = (renderer != nil);
}

- (void) iLinXSkinChangedNotification: (NSNotification *) notification
{
  UIAlertView *newSkinAlert = [[[UIAlertView alloc] 
                                initWithTitle: NSLocalizedString( @"Skin Changed", @"Title of skin changed pop-up" )
                                message: NSLocalizedString( @"Please quit, kill and restart iLinX to use new skin.", @"Message in skin changed pop-up" )
                                delegate: nil cancelButtonTitle: NSLocalizedString( @"OK", @"Title of acknowledge button on skin changed pop-up" )
                                otherButtonTitles: nil] autorelease];
  [newSkinAlert show];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [_ignoreVolumeUpdatesDebounceTimer invalidate];
  [_volumeRepeatTimer invalidate];
  [_renderer removeDelegate: self];
  [_audioControls release];
  [_feedbackControls release];
  [_noFeedbackControls release];
  [_slider release];
  [_muted release];
  [_unmuted release];
  [_mute release];
  [_volumeUp release];
  [_volumeDown release];
  [_renderer release];
  [_settingsController release];
  [_executingMacroAlert release];
  [super dealloc];
}

@end
