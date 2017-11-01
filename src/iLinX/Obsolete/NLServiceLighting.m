//
//  NLServiceLighting.m
//  iLinX
//
//  Created by mcf on 29/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLServiceLighting.h"

// How often, in seconds, to send the report registration request to ensure
// that it does not expire
#define REGISTRATION_RENEWAL_INTERVAL 30

// How often, in seconds, to query the status of the lights service
#define SERVICE_QUERY_INTERVAL 5

@interface NLServiceLighting ()

- (void) holdTimerFired: (NSTimer *) timer;
- (void) notifyDelegatesOfButton: (NSUInteger) button changed: (NSUInteger) changed;
- (void) deregisterFromNetStreams;

@end

@implementation NLServiceLighting

- (id) initWithServiceData: (NSDictionary *) serviceData room: (NLRoom *) room comms: (NetStreamsComms *) comms
{
  if (self = [super initWithServiceData: serviceData room: room comms: comms])
  {
    _buttons = [NSMutableArray new];
    _delegates = [NSMutableSet new];
  }

  return self;
}

- (void) parserDidStartElement: (NSString *) elementName attributes: (NSDictionary *) attributeDict
{
  if ([elementName isEqualToString: @"button"])
    [_buttons addObject: [attributeDict mutableCopy]];
}

- (void) addDelegate: (id<NLServiceLightingDelegate>) delegate
{
  if ([_delegates count] == 0)
  {
    NSUInteger i;

    //NSLog( @"Register" );
    _statusRspHandle = [_comms registerDelegate: self forMessage: @"REPORT" from: self.identifier];
    for (i =  0; i < [_buttons count]; ++i)
      [_comms send: @"STATUS" to: [[_buttons objectAtIndex: i] objectForKey: @"serviceName"]];
    
    _queryMsgHandle = [_comms send: @"STATUS" to: [NSString stringWithFormat: @"%@~all", self.identifier]
                             every: SERVICE_QUERY_INTERVAL];
    _registerMsgHandle = [_comms send: [NSString stringWithFormat: @"REGISTER ON,{{%@~all}}", self.identifier] to: nil
                                every: REGISTRATION_RENEWAL_INTERVAL];
  }
  
  [_delegates addObject: delegate];
}

- (void) removeDelegate: (id<NLServiceLightingDelegate>) delegate
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
      [button setObject: @"pushed" forKey: @"pushed"];
      [_comms send: @"button Press" to: [button objectForKey: @"serviceName"]];
      if (_holdTimer == nil)
      {
        NSMutableArray *pushedButtons = [[NSMutableArray arrayWithObject: button] retain];
        
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

- (void) releaseButton: (NSUInteger) buttonIndex
{
  if (buttonIndex < [_buttons count])
  {
    NSMutableDictionary *button = [_buttons objectAtIndex: buttonIndex];
    NSString *buttonState = [button objectForKey: @"pushed"];
    
    if ([buttonState isEqualToString: @"pushed"])
    {
      [button setObject: @"released" forKey: @"pushed"];
      [_comms send: @"button Release" to: [button objectForKey: @"serviceName"]];

      if (_holdTimer != nil)
      {
        NSMutableArray *pushedButtons = [_holdTimer userInfo];
        
        [pushedButtons removeObject: button];
        if ([pushedButtons count] == 0)
        {
          [_holdTimer invalidate];
          _holdTimer = nil;
          [pushedButtons release];
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
    
    [_comms send: @"button Hold" to: [button objectForKey: @"serviceName"]]; 
  }
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  NSString *type = [data objectForKey: @"type"];
  
  if ([type isEqualToString: @"state"])
  {
    NSMutableDictionary *button = nil;
    NSUInteger i;
    
    for (i = 0; i < [_buttons count]; ++i)
    {
      button = [_buttons objectAtIndex: i];
      if ([[button objectForKey: @"serviceName"] isEqualToString: source])
        break;
    }
    
    if (i < [_buttons count])
    {
      NSUInteger changed = 0;
      NSString *name = [data objectForKey: @"label"];
      NSString *indicatorState = [data objectForKey: @"indicatorState"];

      if (name != nil && ![name isEqualToString: [button objectForKey: @"display"]])
      {
        changed |= SERVICE_LIGHTING_NAME_CHANGED;
        [button setObject: name forKey: @"display"];
      }
      
      if (indicatorState != nil && ![indicatorState isEqualToString: [button objectForKey: @"indicator"]])
      {
        changed |= SERVICE_LIGHTING_INDICATOR_CHANGED;
        [button setObject: indicatorState forKey: @"indicator"];
      }

      if (changed != 0)
        [self notifyDelegatesOfButton: i changed: changed];
    }
  }
}

- (void) notifyDelegatesOfButton: (NSUInteger) button changed: (NSUInteger) changed
{
  NSEnumerator *enumerator = [_delegates objectEnumerator];
  id<NLServiceLightingDelegate> delegate;
  
  while ((delegate = [enumerator nextObject]))
    [delegate service: self button: button changed: changed];
}

- (void) deregisterFromNetStreams
{
  if (_holdTimer != nil)
  {
    NSMutableArray *pushedButtons = [_holdTimer userInfo];
    
    [_holdTimer invalidate];
    _holdTimer = nil;
    [pushedButtons release];
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
  [_buttons release];
  [_delegates release];
  [super dealloc];
}

@end
