//
//  MultiRoomViewControllerIPad.m
//  iLinX
//
//  Created by Tony Short on 30/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <QuartzCore/CALayer.h>
#import "MultiRoomViewControllerIPad.h"
#import "NLService.h"
#import "NLRoom.h"
#import "NLZone.h"
#import "NLZoneList.h"

@implementation MultiRoomViewControllerIPad

- (id) initWithOwner: (RootViewControllerIPad *) owner service: (NLService *) service
{
  self = [super initWithOwner: owner service: service
                      nibName: @"MultiRoomViewIPad" bundle: nil];
  
  if (self != nil)
    _renderer = [service.renderer retain];

  return self;
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  
  NSInteger yOffset = 100;
  
  // Multiroom section
  _multiRoomView.hidden = YES;
  _multiRoomView.renderer = _renderer;
  
  _inMultiRoom = [_renderer.room.zones countOfList] > 0;
  
  _multiRoomView.hidden = !_inMultiRoom;
  [_multiRoomView addMultiroomControlsToViewOffset:&yOffset];
  yOffset += 20;
  
  // Set off renderer
  [self renderer: _renderer stateChanged: 0xFFFFFFFF];
  [_renderer addDelegate: self];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_renderer removeDelegate: self];
  [super viewWillDisappear: animated];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  
  if (_choosingZone)
  {
    NLZone *newZone = _renderer.room.zones.listDataCurrentItem;
    
    if (newZone != nil &&
        !(_renderer.audioSessionActive && 
          [_renderer.audioSessionName compare: newZone.audioSessionName 
                                      options: NSCaseInsensitiveSearch] == NSOrderedSame))
      [_renderer multiRoomJoin: newZone];
    
    _choosingZone = NO;
  }
}

- (void) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags
{
  if ((flags & NLRENDERER_AUDIO_SESSION_CHANGED) != 0)
    _inMultiRoom = renderer.audioSessionActive;
  
  [_multiRoomView updateStateInMultiRoom: _inMultiRoom];
}

- (void) dealloc
{
  [_renderer release];
  [_multiRoomView release];
  [super dealloc];
}

@end