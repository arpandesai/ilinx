//
//  NLServiceGeneric.m
//  iLinX
//
//  Created by mcf on 10/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLServiceGeneric.h"

#define _pcomms NETSTREAMSCOMMS_PRODUCTION_ONLY(_comms)

// How often, in seconds, to send the report registration request to ensure
// that it does not expire
#define REGISTRATION_RENEWAL_INTERVAL 30

// How often, in seconds, to query the status of the lights service
#define SERVICE_QUERY_INTERVAL 5

@interface NLServiceGeneric ()

- (void) holdTimerFired: (NSTimer *) timer;
- (void) notifyDelegatesOfButton: (NSUInteger) button changed: (NSUInteger) changed;

@end

@implementation NLServiceGeneric

- (id) initWithServiceData: (NSDictionary *) serviceData room: (NLRoom *) room comms: (NetStreamsComms *) comms
{
  if (self = [super initWithServiceData: serviceData room: room comms: comms])
  {
    _waitingForStatus = [NSMutableDictionary new];
    _buttons = [NSMutableArray new];
    _delegates = [NSMutableSet new];
  }
  
  return self;
}

- (void) parserDidStartElement: (NSString *) elementName attributes: (NSDictionary *) attributeDict
{
  if ([elementName isEqualToString: @"button"])
  {
    NSMutableDictionary *copy = [attributeDict mutableCopy];
    
    // Lighting services always have state indicators on the buttons, so ensure
    // that they are always present by adding them, initialised to "off".
    if ([[self serviceType] isEqualToString: @"lighting"])
      [copy setObject: @"0" forKey: @"indicator"];

    [_buttons addObject: copy];
    [copy release];
  }
}

- (void) addDelegate: (id<NLServiceGenericDelegate>) delegate
{
  if ([_delegates count] == 0)
    [self registerForNetStreams];

  [_delegates addObject: delegate];
}

- (void) removeDelegate: (id<NLServiceGenericDelegate>) delegate
{
  NSUInteger oldCount = [_delegates count];
  
  if (oldCount > 0)
  {
    [_delegates removeObject: delegate];
    if ([_delegates count] == 0)
      [self deregisterFromNetStreams];
  }  
}

- (NSUInteger) buttonCount
{
  return [_buttons count];
}

- (void) pushButton: (NSUInteger) buttonIndex
{
  if (buttonIndex < [_buttons count])
  {
    NSMutableDictionary *button = [_buttons objectAtIndex: buttonIndex];
    NSString *buttonState = [button objectForKey: @"pushed"];
    
    if (buttonState == nil || ![buttonState isEqualToString: @"pushed"])
    {
      NSString *serviceName = [button objectForKey: @"serviceName"];
      
      if (serviceName == nil)
        [_pcomms send: [NSString stringWithFormat: @"MENU_SEL {{presets>%@}}", [button objectForKey: @"id"]] to: self.serviceName];
      else
      {
        [button setObject: @"pushed" forKey: @"pushed"];
        [_pcomms send: @"button Press" to: serviceName];
        if (_holdTimer == nil)
        {
          NSMutableArray *pushedButtons = [NSMutableArray arrayWithObject: button];
        
          _holdTimer = [NSTimer
                        scheduledTimerWithTimeInterval: 0.5 target: self
                        selector: @selector(holdTimerFired:) userInfo: pushedButtons repeats: TRUE];
        }
        else
        {
          NSMutableArray *pushedButtons = [_holdTimer userInfo];
        
          [pushedButtons addObject: button];
        }
      }
    }
  }
}

- (void) releaseButton: (NSUInteger) buttonIndex
{
  if (buttonIndex < [_buttons count])
  {
    NSMutableDictionary *button = [_buttons objectAtIndex: buttonIndex];
    NSString *buttonState = [button objectForKey: @"pushed"];
    
    if ([buttonState isEqualToString: @"pushed"])
    {
      [button setObject: @"released" forKey: @"pushed"];
      [_pcomms send: @"button Release" to: [button objectForKey: @"serviceName"]];
      
      if (_holdTimer != nil)
      {
        NSMutableArray *pushedButtons = [_holdTimer userInfo];
        
        [pushedButtons removeObject: button];
        if ([pushedButtons count] == 0)
        {
          [_holdTimer invalidate];
          _holdTimer = nil;
        }
      }
    }
  }
}

- (NSString *) nameForButton: (NSUInteger) buttonIndex
{
  NSString *name;
  
  if (buttonIndex >= [_buttons count])
    name = nil;
  else
    name = [[_buttons objectAtIndex: buttonIndex] objectForKey: @"display"];
  
  return name;
}

- (BOOL) indicatorPresentOnButton: (NSUInteger) buttonIndex
{
  BOOL present;
  
  if (buttonIndex >= [_buttons count])
    present = NO;
  else
  {
    NSMutableDictionary *button = [_buttons objectAtIndex: buttonIndex];
    NSString *indicator = [button objectForKey: @"indicator"];
    
    present = !(indicator == nil || [indicator isEqualToString: @"none"]);
  }  
  
  return present;
}

- (BOOL) indicatorStateForButton: (NSUInteger) buttonIndex
{
  BOOL on;
  
  if (buttonIndex >= [_buttons count])
    on = NO;
  else
  {
    NSMutableDictionary *button = [_buttons objectAtIndex: buttonIndex];
    NSString *indicator = [button objectForKey: @"indicator"];
    
    on = [indicator isEqualToString: @"1"];
  }  
  
  return on;
}

- (void) holdTimerFired: (NSTimer *) timer
{
  NSMutableArray *pushedButtons = [_holdTimer userInfo];
  NSUInteger count = [pushedButtons count];
  NSUInteger i;
  
  for (i = 0; i < count; ++i)
  {
    NSDictionary *button = [pushedButtons objectAtIndex: i];
    
    [_pcomms send: @"button Hold" to: [button objectForKey: @"serviceName"]]; 
  }
}

- (void) notifyDelegatesOfButton: (NSUInteger) button changed: (NSUInteger) changed
{
  NSSet *delegates = [NSSet setWithSet: _delegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<NLServiceGenericDelegate> delegate;
  
  while ((delegate = [enumerator nextObject]))
    [delegate service: self button: button changed: changed];
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  NSString *type = [data objectForKey: @"type"];
  
  if ([type isEqualToString: @"state"])
  {
    NSMutableDictionary *button = nil;
    id handle = [_waitingForStatus objectForKey: source];
    NSUInteger i;
    
    for (i = 0; i < [_buttons count]; ++i)
    {
      button = [_buttons objectAtIndex: i];
      if ([[button objectForKey: @"serviceName"] compare: source options: NSCaseInsensitiveSearch] == NSOrderedSame)
        break;
    }
    
    if (handle != nil)
    {
      [_comms cancelSendEvery: handle];
      [_waitingForStatus removeObjectForKey: source];
    }
    
    if (i < [_buttons count])
    {
      NSUInteger changed = 0;
      NSString *name = [data objectForKey: @"label"];
      NSString *indicatorState = [data objectForKey: @"indicatorState"];
      
      if (name != nil && ![name isEqualToString: [button objectForKey: @"display"]])
      {
        changed |= SERVICE_GENERIC_NAME_CHANGED;
        [button setObject: name forKey: @"display"];
      }
      
      if (indicatorState != nil && ![indicatorState isEqualToString: [button objectForKey: @"indicator"]])
      {
        changed |= SERVICE_GENERIC_INDICATOR_CHANGED;
        [button setObject: indicatorState forKey: @"indicator"];
      }
      
      if (changed != 0)
        [self notifyDelegatesOfButton: i changed: changed];
    }
  }
}

- (void) registerForNetStreams
{
  NSUInteger i;
  
  //NSLog( @"Register" );
  _statusRspHandle = [_comms registerDelegate: self forMessage: @"REPORT" from: self.identifier];
  _registerMsgHandle = [_comms send: [NSString stringWithFormat: @"REGISTER ON,{{%@~all}}", self.identifier] to: nil
                              every: REGISTRATION_RENEWAL_INTERVAL];

  for (i =  0; i < [_buttons count]; ++i)
  {
    NSString *serviceName = [[_buttons objectAtIndex: i] objectForKey: @"serviceName"];
    
    if (serviceName != nil)
      [_waitingForStatus setObject: [_comms send: @"STATUS" to: serviceName 
                                           every: REGISTRATION_RENEWAL_INTERVAL] forKey: serviceName];
  }

  _queryMsgHandle = [_comms send: @"STATUS" to: [NSString stringWithFormat: @"%@~all", self.identifier]
                           every: SERVICE_QUERY_INTERVAL];
}

- (void) deregisterFromNetStreams
{
  if ([_waitingForStatus count] > 0)
  {
    NSEnumerator *objEnumerator = [_waitingForStatus objectEnumerator];
    id handle;

    while ((handle = [objEnumerator nextObject]))
      [_comms cancelSendEvery: handle];
    
    [_waitingForStatus removeAllObjects];
  }
  
  if (_holdTimer != nil)
  {
    [_holdTimer invalidate];
    _holdTimer = nil;
  }

  //NSLog( @"Deregister" );
  if (_statusRspHandle != nil)
  {
    [_comms deregisterDelegate: _statusRspHandle];
    _statusRspHandle = nil;
  }
  //NSLog( @"Cancel send every" );
  if (_registerMsgHandle != nil)
  {
    [_comms cancelSendEvery: _registerMsgHandle];
    [_comms send: [NSString stringWithFormat: @"REGISTER OFF,{{%@~all}}", self.identifier] to: nil];
    _registerMsgHandle = nil;
  }
  if (_queryMsgHandle != nil)
  {
    [_comms cancelSendEvery: _queryMsgHandle];
    _queryMsgHandle = nil;
  }
}

- (void) dealloc
{
  [self deregisterFromNetStreams];
  [_waitingForStatus release];
  [_buttons release];
  [_delegates release];
  [super dealloc];
}

@end
