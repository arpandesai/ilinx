//
//  NLServiceHVAC.m
//  iLinX
//
//  Created by mcf on 13/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLServiceHVAC.h"

#define _pcomms NETSTREAMSCOMMS_PRODUCTION_ONLY(_comms)

// How often, in seconds, to send the report registration request to ensure
// that it does not expire
#define REGISTRATION_RENEWAL_INTERVAL 30

// How long, in seconds, to wait after registration before sending initial status query
#define INITIAL_SERVICE_QUERY_DELAY 0.25

// How often, in seconds, to query the status of the service until it responds
#define SERVICE_QUERY_INTERVAL 5

@interface NLServiceHVAC ()

- (CGFloat) heatSetPointMinInternal;
- (CGFloat) heatSetPointMaxInternal;
- (CGFloat) heatSetPointStepInternal;

@end

@implementation NLServiceHVAC

@synthesize
  capabilities = _capabilities,
  outsideTemperature = _outsideTemperature,
  outsideHumidity = _outsideHumidity,
  zoneTemperature = _zoneTemperature,
  zoneHumidity = _zoneHumidity,
  currentSetPointTemperature = _currentSetPointTemperature,
  heatSetPointTemperature = _heatSetPointTemperature,
  coolSetPointTemperature = _coolSetPointTemperature,
  temperatureScale = _temperatureScale,
  controlModes = _controlModes,
  controlModeTitles = _controlModeTitles,
  controlModeStates = _controlModeStates,
  currentStateHeader = _currentStateHeader,
  currentStateLine1 = _currentStateLine1,
  currentStateLine2WithIcon = _currentStateLine2WithIcon,
  currentStateLine2NoIcon = _currentStateLine2NoIcon,
  showIcon = _showIcon;

- (id) initWithServiceData: (NSDictionary *) serviceData room: (NLRoom *) room comms: (NetStreamsComms *) comms
{
  if ((self = [super initWithServiceData: serviceData room: room comms: comms]) != nil)
    _delegates = [NSMutableSet new];
  
  return self;
}

- (void) addDelegate: (id<NLServiceHVACDelegate>) delegate
{
  if ([_delegates count] == 0)
    [self registerForNetStreams];
  
  [_delegates addObject: delegate];
}

- (void) removeDelegate: (id<NLServiceHVACDelegate>) delegate
{
  NSUInteger oldCount = [_delegates count];
  
  if (oldCount > 0)
  {
    [_delegates removeObject: delegate];
    if ([_delegates count] == 0)
      [self deregisterFromNetStreams];
  }  
}

- (NSUInteger) buttonCountInControlMode: (NSUInteger) controlMode
{
  NSUInteger count;
  
  if (controlMode >= [_controlModeTitles count])
    count = 0;
  else
    count = [[_controlModeTitles objectAtIndex: controlMode] count];
  
  return count;
}

- (NSString *) nameForButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
  NSString *name;

  if (controlMode >= [_controlModeTitles count])
    name = nil;
  else
  {
    NSArray *modeTitles = [_controlModeTitles objectAtIndex: controlMode];
    
    if (buttonIndex >= [modeTitles count])
      name = nil;
    else
      name = [modeTitles objectAtIndex: buttonIndex];
  }
  
  return name;
}

- (BOOL) indicatorPresentOnButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
  BOOL present;
  
  if (controlMode >= [_controlModeStates count])
    present = NO;
  else
  {
    NSArray *modeStates = [_controlModeStates objectAtIndex: controlMode];
    
    if (buttonIndex >= [modeStates count])
      present = NO;
    else
    {
      NSString *stateValue = [modeStates objectAtIndex: buttonIndex];
      
      present = ([stateValue length] > 0);
    }
  }
  
  return present;
}

- (BOOL) indicatorStateForButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
  BOOL state;
  
  if (controlMode >= [_controlModeStates count])
    state = NO;
  else
  {
    NSArray *modeStates = [_controlModeStates objectAtIndex: controlMode];
    
    if (buttonIndex >= [modeStates count])
      state = NO;
    else
    {
      NSString *stateValue = [modeStates objectAtIndex: buttonIndex];
      
      state = ([stateValue length] > 0 && ![stateValue isEqualToString: @"0"]);
    }
  }
  
  return state;
}

- (CGFloat) heatSetPointMinInternal
{
  CGFloat value;
  
  if ([_temperatureScaleRaw isEqualToString: @"F"])
    value = 42;
  else if ([_temperatureScaleRaw isEqualToString: @"K"])
    value = 278;
  else
    value = 5;
  
  return value;
}

- (CGFloat) heatSetPointMaxInternal
{
  CGFloat value;
  
  if ([_temperatureScaleRaw isEqualToString: @"F"])
    value = 88;
  else if ([_temperatureScaleRaw isEqualToString: @"K"])
    value = 304;
  else
    value = 31;

  return value;
}

- (CGFloat) heatSetPointStepInternal
{
  return 1.0;
}

- (CGFloat) heatSetPointMin
{
  return [self heatSetPointMinInternal];
}

- (CGFloat) heatSetPointMax
{
  return [self heatSetPointMaxInternal];
}

- (CGFloat) heatSetPointStep
{
  return [self heatSetPointStepInternal];
}


- (void) setHeatSetPoint: (CGFloat) setPoint
{
  [_pcomms send: [NSString stringWithFormat: @"set heat %u", (NSUInteger) setPoint] to: self.serviceName];
  if (((CGFloat) (NSUInteger) setPoint) != setPoint)
  {
    _pendingUpdates = SERVICE_HVAC_HEAT_SETPOINT_CHANGED|SERVICE_HVAC_CURRENT_SETPOINT_CHANGED;
    [_comms send: @"STATUS" to: self.serviceName];
  }
}

- (void) raiseHeatSetPoint
{
  [_pcomms send: @"set heat up" to: self.serviceName];
}

- (void) lowerHeatSetPoint
{
  [_pcomms send: @"set heat down" to: self.serviceName];
}


// Unless overridden, these default to the same as the heat set point values
- (CGFloat) coolSetPointMin
{
  return [self heatSetPointMinInternal];
}

- (CGFloat) coolSetPointMax
{
  return [self heatSetPointMaxInternal];
}

- (CGFloat) coolSetPointStep
{
  return [self heatSetPointStepInternal];
}

- (void) setCoolSetPoint: (CGFloat) setPoint
{
  [_pcomms send: [NSString stringWithFormat: @"set cool %u", (NSUInteger) setPoint] to: self.serviceName];
  if (((CGFloat) (NSUInteger) setPoint) != setPoint)
  {
    _pendingUpdates = SERVICE_HVAC_COOL_SETPOINT_CHANGED|SERVICE_HVAC_CURRENT_SETPOINT_CHANGED;
    [_comms send: @"STATUS" to: self.serviceName];
  }
}

- (void) raiseCoolSetPoint
{
  [_pcomms send: @"set cool up" to: self.serviceName];
}

- (void) lowerCoolSetPoint
{
  [_pcomms send: @"set cool down" to: self.serviceName];
}

- (void) pushButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
}

- (void) releaseButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
  // All action is on the push
}

- (void) notifyDelegates: (NSUInteger) changed
{
  NSSet *delegates = [NSSet setWithSet: _delegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<NLServiceHVACDelegate> delegate;
  
  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(service:changed:)])
      [delegate service: self changed: changed];
  }
}

- (void) notifyDelegatesOfButton: (NSUInteger) button inControlMode: (NSUInteger) controlMode changed: (NSUInteger) changed
{
  NSSet *delegates = [NSSet setWithSet: _delegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<NLServiceHVACDelegate> delegate;
  
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
  _registerMsgHandle = [_comms send: [NSString stringWithFormat: @"REGISTER ON,{{%@}}", self.serviceName] to: nil
                              every: REGISTRATION_RENEWAL_INTERVAL];
  [self performSelector: @selector(registerQueryStatus) withObject: self afterDelay: INITIAL_SERVICE_QUERY_DELAY];
}

- (void) registerQueryStatus
{
  if (_statusRspHandle != nil && _queryMsgHandle == nil)
    _queryMsgHandle = [_comms send: @"STATUS" to: self.serviceName every: SERVICE_QUERY_INTERVAL];
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
  
  [self deregisterQueryStatus];
}

- (void) deregisterQueryStatus
{
  if (_queryMsgHandle != nil)
  {
    [_comms cancelSendEvery: _queryMsgHandle];
    _queryMsgHandle = nil;
  }
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  // Should be overridden by derived classes to handle type-specific status messages.  Sub-classes
  // should call super method to do this deregistration:
  
  if (_queryMsgHandle != nil && [[data objectForKey: @"type"] isEqualToString: @"state"])
    [self deregisterQueryStatus];
}

- (void) dealloc
{
  [self deregisterFromNetStreams];
  [_delegates release];
  [_outsideTemperature release];
  [_outsideHumidity release];
  [_zoneTemperature release];
  [_zoneHumidity release];
  [_currentSetPointTemperature release];
  [_heatSetPointTemperature release];
  [_coolSetPointTemperature release];
  [_temperatureScale release];
  [_temperatureScaleRaw release];
  [_controlModes release];
  [_controlModeTitles release];
  [_controlModeStates release];
  [_currentStateHeader release];
  [_currentStateLine1 release];
  [_currentStateLine2WithIcon release];
  [_currentStateLine2NoIcon release];
  [super dealloc];
}

@end
