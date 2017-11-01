//
//  AudioSettingsViewControllerIPad.m
//  iLinX
//
//  Created by Tony Short on 30/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <QuartzCore/CALayer.h>
#import "AudioSettingsViewControllerIPad.h"
#import "NLService.h"

@implementation AudioSettingsViewControllerIPad

- (id) initWithOwner: (RootViewControllerIPad *) owner service: (NLService *) service
{
  self = [super initWithOwner: owner service: service
                      nibName: @"AudioSettingsViewIPad" bundle: nil];
  
  if(self != nil)
    _renderer = [service.renderer retain];
  return self;
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  
  // Get settings
  if (_settings == nil || ![_settings rightSettingsForRenderer])
  {
    [_settings release];
    _settings = [SettingsControlsIPad allocSettingsControlsForRenderer: _renderer];
  }
  
  NSInteger yOffset = 0;
  
  // Audio section
  [_settings addControlsForSection: 0 toView: _settingsControlsView atYOffset: &yOffset];
  
  // Set off renderer
  [self renderer: _renderer stateChanged: 0xFFFFFFFF];
  [_renderer addDelegate: self];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_renderer removeDelegate: self];
  [super viewWillDisappear: animated];
}

- (void) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags
{
  if ((flags & NLRENDERER_PERMID_CHANGED) != 0)
  {
    if (![_settings rightSettingsForRenderer])
    {
      [_settings release];
      _settings = [SettingsControlsIPad allocSettingsControlsForRenderer: _renderer];
      
      NSInteger yOffset = 0;
      [_settings addControlsForSection: 0 toView: _settingsControlsView atYOffset: &yOffset];
    }
  }
}

- (void) dealloc 
{
  [_renderer release];
  [_settings release];
  [_settingsControlsView release];
  [super dealloc];
}

@end