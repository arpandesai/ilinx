    //
//  PlaceholderAVViewControllerIPad.m
//  iLinX
//
//  Created by mcf on 08/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "PlaceholderAVViewControllerIPad.h"
#import "AudioViewControllerIPad.h"
#import "NLSource.h"

@implementation PlaceholderAVViewControllerIPad

- (id) initWithOwner: (AudioViewControllerIPad *) owner service: (NLService *) service source: (NLSource *) source;
{
  self = [super initWithOwner: owner service: service source: source
                      nibName: @"PlaceholderAVViewControllerIPad" bundle: nil];

  return self;
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  _sourceTitle.text = [_source displayName];
}

- (void) dealloc
{
  [_sourceTitle release];
  [super dealloc];
}

@end
