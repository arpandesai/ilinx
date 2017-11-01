    //
//  PlaceholderViewControllerIPad.m
//  iLinX
//
//  Created by mcf on 07/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "PlaceholderViewControllerIPad.h"
#import "NLService.h"

@implementation PlaceholderViewControllerIPad

- (id) initWithOwner: (RootViewControllerIPad *) owner service: (NLService *) service
{
  self = [super initWithOwner: owner service: service
                      nibName: @"PlaceholderViewControllerIPad" bundle: nil];
  
  return self;
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  
  _serviceTitle.text = [_service displayName];
  _unsupportedMessage.hidden = (_service == nil);
}

- (void) dealloc
{
  [_serviceTitle release];
  [_unsupportedMessage release];
  [super dealloc];
}

@end
