//
//  ExecutingMacroAlertIPad.m
//  iLinX
//
//  Created by mcf on 28/08/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "ExecutingMacroAlertIpad.h"
#import "RootViewControllerIPad.h"


@interface ExecutingMacroAlertIPad ()

- (void) executingMacroTimeoutExpired: (NSTimer *) timer;
- (void) selectNewService: (NLService *) newService animated: (BOOL) animated;

@end

@implementation ExecutingMacroAlertIPad

- (id) initWithOwner: (RootViewControllerIPad *) owner
{
  if (self = [super init])
    _owner = [owner retain];
  
  return self;
}

- (void) loadViewUnderView: (RootViewControllerIPad *) owner service: (NLService *) service
  {
   // [self showExecutingMacroBanner: NO];
  }

- (void) selectNewService: (NLService *) newService afterDelay: (NSTimeInterval) delay animated: (BOOL) animated
{
  if (newService != nil)
  {
    if (delay == 0)
       [_owner selectService: newService animated: animated];
    
      //[self selectNewService: newService animated: animated Owner: _owner];
    else
    {
      // Show modal "waiting for execution" overlay
      [_owner showExecutingMacroBanner: YES];
      
      // and wait for the specified delay
      [self cancelExecutingMacroTimer];
      _animated = animated;
      _executingMacroTimer = 
      [NSTimer scheduledTimerWithTimeInterval: delay
                                       target: self selector: @selector(executingMacroTimeoutExpired:)
                                     userInfo: newService repeats: NO];
    }
  }
}

- (void) cancelExecutingMacroTimer
{
  if (_executingMacroTimer != nil)
  {
    [_executingMacroTimer invalidate];
    _executingMacroTimer = nil;
  }
}

- (void) executingMacroTimeoutExpired: (NSTimer *) timer
{
  NLService *newService = (NLService *) [timer userInfo];
  
  _executingMacroTimer = nil;
  [_owner showExecutingMacroBanner: NO];
  [self selectNewService: newService animated: _animated];
}

- (void) selectNewService: (NLService *) newService animated: (BOOL) animated
{
  [_owner selectService: newService animated: animated];
}

- (void) dealloc
{
  [super dealloc];
}

@end
