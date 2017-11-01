//
//  AudioSubViewControllerIPad.m
//  iLinX
//
//  Created by mcf on 09/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "AudioSubViewControllerIPad.h"
#import "AudioViewControllerIPad.h"
#import "NLSource.h"
#import "PseudoBarButton.h"

@implementation AudioSubViewControllerIPad

- (id) initWithOwner: (AudioViewControllerIPad *) owner service: (NLService *) service source: (NLSource *) source
{
  return [self initWithOwner: owner service: service source: source nibName: nil bundle: nil];
}

- (id) initWithOwner: (AudioViewControllerIPad *) owner service: (NLService *) service source: (NLSource *) source
             nibName: (NSString *) nibName bundle: (NSBundle *) bundle
{
  if (self = [super initWithNibName: nibName bundle: bundle])
  {
    _owner = owner;
    _service = [service retain];
    _source = [source retain];
  }
  
  return self;
}

- (NLService *) service
{
  return _service;
}

- (NLSource *) source
{
  return _source;
}


- (IBAction) sourcesPressed: (UIControl *) button
{
  [_owner presentSourcesPopoverFromButton: button
                 permittedArrowDirections: UIPopoverArrowDirectionAny animated: YES];
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  
  _sourcesButton.title = _source.displayName;
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
  // Overriden to allow any orientation.
  return YES;
}

- (void) dealloc
{
  [_sourcesButton release];
  [_service release];
  [_source release];
  [super dealloc];
}

@end
