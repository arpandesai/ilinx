//
//  VideoSettingsViewControllerIPad.m
//  iLinX
//
//  Created by Tony Short on 30/09/2010.
//

#import <QuartzCore/CALayer.h>
#import "DisplaySettingsViewControllerIPad.h"
#import "NLService.h"

@implementation DisplaySettingsViewControllerIPad

- (id) initWithOwner: (RootViewControllerIPad *) owner service: (NLService *) service
{
  self = [super initWithOwner: owner service: service
                      nibName: @"DisplaySettingsViewIPad" bundle: nil];
  
  if (self != nil)
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
  
  // Video section
  if ([_settings numberOfSections] == 1)
    [_displayControlsView addNoControlsToView];		
  else
    [_displayControlsView addControlsToViewWithRenderer: _renderer];
  
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
    }
  }
}

- (void) dealloc
{
  [_renderer release];
  [_settings release]; 
  [_displayControlsView release];
  [super dealloc];
}

@end