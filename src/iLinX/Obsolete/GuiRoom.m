//
//  GuiRoom.m
//  NetStreams
//
//  Created by mcf on 09/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "GuiRoom.h"


@implementation GuiRoom

@synthesize
  name = _name,
  screens = _screens,
  sources = _sources,
  renderer = _renderer;

- (void) dealloc
{
  [_name release];
  [_screens release];
  [_sources release];
  [_renderer release];
  [super dealloc];
}

@end
