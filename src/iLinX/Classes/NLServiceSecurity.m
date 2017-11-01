//
//  NLServiceSecurity.m
//  iLinX
//
//  Created by mcf on 18/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLServiceSecurity.h"

// How often, in seconds, to send the report registration request to ensure
// that it does not expire
#define REGISTRATION_RENEWAL_INTERVAL 30

// How often, in seconds, to query the status of the service
#define SERVICE_QUERY_INTERVAL 5

@implementation NLServiceSecurity

@synthesize
  capabilities = _capabilities,
  controlModes = _controlModes,
  controlModeTitles = _controlModeTitles,
  errorMessage = _errorMessage,
  displayText = _displayText;

- (id) initWithServiceData: (NSDictionary *) serviceData room: (NLRoom *) room comms: (NetStreamsComms *) comms
{
  if (self = [super initWithServiceData: serviceData room: room comms: comms])
    _delegates = [NSMutableSet new];
  
  return self;
}

- (void) addDelegate: (id<NLServiceSecurityDelegate>) delegate
{
  if ([_delegates count] == 0)
    [self registerForNetStreams];
  
  [_delegates addObject: delegate];
}

- (void) removeDelegate: (id<NLServiceSecurityDelegate>) delegate
{
  NSUInteger oldCount = [_delegates count];
  
  if (oldCount > 0)
  {
    [_delegates removeObject: delegate];
    if ([_delegates count] == 0)
      [self deregisterFromNetStreams];
  }  
}

- (void) pressKeypadKey: (NSString *) keyName
{
}

- (void) releaseKeypadKey: (NSString *) keyName
{
}

- (NSUInteger) buttonCountInControlMode: (NSUInteger) controlMode
{
  NSUInteger count;
  
  if (_controlModeTitles == nil || controlMode >= [_controlModeTitles count])
    count = 0;
  else
    count = [[_controlModeTitles objectAtIndex: controlMode] count];
  
  return count;
}

- (NSUInteger) styleForControlMode: (NSUInteger) controlMode
{
  return SERVICE_SECURITY_MODE_TYPE_BUTTONS;
}

- (NSString *) nameForButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
  NSString *name;
  
  if (_controlModeTitles == nil || controlMode >= [_controlModeTitles count])
    name = nil;
  else
  {
    NSArray *titles = [_controlModeTitles objectAtIndex: controlMode];
    
    if (buttonIndex >= [titles count])
      name = nil;
    else
      name = [titles objectAtIndex: buttonIndex];
  }
  
  return name;
}

- (BOOL) isFlag: (NSUInteger) flag setForButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
  BOOL flagSet;
  
  if (_controlModeStates == nil || controlMode >= [_controlModeStates count])
    flagSet = NO;
  else
  {
    NSArray *states = [_controlModeStates objectAtIndex: controlMode];
    
    if (buttonIndex >= [states count])
      flagSet = NO;
    else
      flagSet = (([(NSNumber *) [states objectAtIndex: buttonIndex] unsignedIntegerValue] & flag) != 0);
  }
  
  return flagSet;
}

- (BOOL) isVisibleButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
  return [self isFlag: SERVICE_SECURITY_STATE_VISIBLE setForButton: buttonIndex inControlMode: controlMode];
}

- (BOOL) isEnabledButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
  return [self isFlag: SERVICE_SECURITY_STATE_ENABLED setForButton: buttonIndex inControlMode: controlMode];
}

- (BOOL) indicatorPresentOnButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
  return [self isFlag: SERVICE_SECURITY_STATE_HAS_INDICATOR setForButton: buttonIndex inControlMode: controlMode];
}

- (BOOL) indicatorStateForButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
  return [self isFlag: SERVICE_SECURITY_STATE_INDICATOR_ON setForButton: buttonIndex inControlMode: controlMode];
}

- (void) pushButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
}

- (void) releaseButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
}

- (void) notifyDelegates: (NSUInteger) changed
{
  NSSet *fixedDelegates = [NSSet setWithSet: _delegates];
  NSEnumerator *enumerator = [fixedDelegates objectEnumerator];
  id<NLServiceSecurityDelegate> delegate;
  
  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(service:changed:)])
      [delegate service: self changed: changed];
  }
}

- (void) notifyDelegatesOfButton: (NSUInteger) button inControlMode: (NSUInteger) controlMode changed: (NSUInteger) changed
{
  NSSet *fixedDelegates = [NSSet setWithSet: _delegates];
  NSEnumerator *enumerator = [fixedDelegates objectEnumerator];
  id<NLServiceSecurityDelegate> delegate;
  
  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(service:controlMode:button:changed:)])
      [delegate service: self controlMode: controlMode button: button changed: changed];
  }
}

- (void) registerForNetStreams
{
  //NSLog( @"Register" );
  _statusRspHandle = [_comms registerDelegate: self forMessage: @"REPORT" from: self.serviceName];
  _queryMsgHandle = [_comms send: @"STATUS" to: self.serviceName every: SERVICE_QUERY_INTERVAL];
  _registerMsgHandle = [_comms send: [NSString stringWithFormat: @"REGISTER ON,{{%@}}", self.serviceName] to: nil
                              every: REGISTRATION_RENEWAL_INTERVAL];
}

- (void) deregisterFromNetStreams
{
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
    [_comms send: [NSString stringWithFormat: @"REGISTER OFF,{{%@}}", self.serviceName] to: nil];
    _registerMsgHandle = nil;
  }
  if (_queryMsgHandle != nil)
  {
    [_comms cancelSendEvery: _queryMsgHandle];
    _queryMsgHandle = nil;
  }
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  // Does nothing.  Should be overridden by derived classes to handle type-specific status messages
}

- (void) dealloc
{
  [self deregisterFromNetStreams];
  [_delegates release];
  [_controlModes release];
  [_controlModeTitles release];
  [_controlModeStates release];
  [_errorMessage release];
  [_displayText release];
  [super dealloc];
}

@end
