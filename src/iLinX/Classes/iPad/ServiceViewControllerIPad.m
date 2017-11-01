    //
//  ServiceViewControllerIPad.m
//  iLinX
//
//  Created by mcf on 09/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "ServiceViewControllerIPad.h"
#import "RootViewControllerIPad.h"

@implementation ServiceViewControllerIPad

- (id) initWithOwner: (RootViewControllerIPad *) owner service: (NLService *) service
{
  return [self initWithOwner: owner service: service nibName: nil bundle: nil];
}

- (id) initWithOwner: (RootViewControllerIPad *) owner service: (NLService *) service
             nibName: (NSString *) nibName bundle: (NSBundle *) bundle
{
  if (self = [super initWithNibName: nibName bundle: bundle])
  {
    _owner = owner;
    _service = [service retain];
  }
  
  return self;
}

- (NLRoomList *) roomList
{
  return _owner.roomList;
}

- (NLService *) service
{
  return _service;
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
  // Overriden to allow any orientation.
  return YES;
}

- (void) dealloc
{
  [_service release];
  [super dealloc];
}

@end
