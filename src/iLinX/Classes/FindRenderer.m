//
//  FindRenderer.m
//  iLinX
//
//  Created by mcf on 31/03/2011.
//  Copyright 2011 Micropraxis Ltd. All rights reserved.
//

#import "FindRenderer.h"

@interface  FindRenderer ()
 
- (void) _deregister;

@end

@implementation FindRenderer

- (id) initWithParent: (NetStreamsComms *) parent address: (NSString *) address
       defaultNetMask: (NSString *) defaultNetMask delegate: (id<NetStreamsCommsDelegate>) delegate
{
  if ((self = [super init]) != nil)
  {
    _parent = parent;
    _delegate = delegate;
    
    // No point in doing anything if it doesn't!
    if ([_delegate respondsToSelector: @selector(discoveredService:address:netmask:type:version:name:permId:room:)])
    {
      _rendererQueue = [NSMutableSet new];
      _defaultNetMask = [defaultNetMask retain];
      _comms = [[NetStreamsComms alloc] init];
      _comms.delegate = self;
      [_comms connect: address];
    }
  }

  return self;
}

// #@ALL#QUERY RENDERER
// #@<local-addr>:<renderer service>#REPORT {{ ... }}
// #@<renderer service>~root#QUERY NETWORK
// #@<local-addr>:<root service>#REPORT {{<report type="state" DHCP_EN="0|1" staticIP_EN="0|1" IP="ip" IPMask="ipmask" gatewayIP="gateway"/>}}
// #@<renderer service>~root#QUERY SERVICE {{<renderer service>}}
// #@<local-addr>:<root service>#REPORT {{<report type="state" serviceName="..." serviceType="..." IP="..." permId="..."
- (void) connected: (NetStreamsComms *) comms
{
  _responseHandle = [_comms registerDelegate: self forMessage: @"REPORT" from: @"*"];
  [_comms send: @"QUERY RENDERER" to: @"ALL"];
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  if ([data objectForKey: @"vol"] != nil)
  {
    if (_rendererService == nil)
    {
      _rendererService = [source retain];
      [_comms send: @"QUERY NETWORK" to: [_rendererService stringByAppendingString: @"~root"]];
    }
    else
    {
      [_rendererQueue addObject: source];
    }
  }
  else if (_rendererService != nil)
  {
    // We've found the renderer, so we're now only interested in responses related to that renderer
    NSString *dhcpEn = [data objectForKey: @"DHCP_EN"];
    NSString *address = [data objectForKey: @"IP"];
    
    if (dhcpEn != nil)
    {
      NSString *staticEn = [data objectForKey: @"staticIP_EN"];
      
      if ([staticEn isEqualToString: @"1"])
      {
        // If we are on static IP configuration, we can trust the network parameters.
        NSString *netmask = [data objectForKey: @"IPMask"];

        //[self _deregister];
        [self retain];
        [_delegate discoveredService: _parent address: address netmask: netmask type: @"audio/renderer"
                             version: nil name: _rendererService permId: source 
                                room: [_rendererService stringByReplacingOccurrencesOfString: @" Player" withString: @""]];
        [self release];
      }
      else
      {
        // If we are on DHCP or AutoIP, query the service to get its current IP address
        [_comms send: [NSString stringWithFormat: @"QUERY SERVICE {{%@}}", _rendererService] 
                  to: [_rendererService stringByAppendingString: @"~root"]];
      }
    }
    else if (address != nil)
    {
      // Use the default netmask, which is our own.  This is reasonable because if we're not
      // on the same sub-net as the renderer then we've no chance of connecting to it anyway.
      //[self _deregister];
      [self retain];
      [_delegate discoveredService: _parent address: address netmask: _defaultNetMask type: [data objectForKey: @"serviceType"]
                           version: nil name: _rendererService permId: [data objectForKey: @"permId"] 
                              room: [data objectForKey: @"roomName"]];
      [self release];
    }
    
    if ([_rendererQueue count] == 0)
      [self _deregister];
    else
    {
      [_rendererService release];
      _rendererService = [[_rendererQueue anyObject] retain];
      [_rendererQueue removeObject: _rendererService];
      [_comms send: @"QUERY NETWORK" to: [_rendererService stringByAppendingString: @"~root"]];
    }
  }
}

- (void) _deregister
{
  _comms.delegate = nil;
  if (_responseHandle != nil)
  {
    [_comms deregisterDelegate: _responseHandle];
    _responseHandle = nil;
    [_comms disconnect];
  }
}

- (void) dealloc
{
  [self _deregister];
  [_comms release];
  [_rendererService release];
  [_defaultNetMask release];
  [_rendererQueue release];
  [super dealloc];
}

@end
