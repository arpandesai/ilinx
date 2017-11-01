//
//  NLServiceHVAC2.m
//  iLinX
//
//  Created by mcf on 16/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLServiceHVAC2.h"

#define _pcomms NETSTREAMSCOMMS_PRODUCTION_ONLY(_comms)

// How often, in seconds, to resend a status query message if we get no response
#define SERVICE_QUERY_INTERVAL 5

@interface NLServiceHVAC2 ()

- (void) checkControlMode: (NSUInteger) mode data: (NSDictionary *) data;
- (NSArray *) allocSplitAndCheckString: (NSString *) string againstArray: (NSArray *) array;

@end

@implementation NLServiceHVAC2

- (id) initWithServiceData: (NSDictionary *) serviceData room: (NLRoom *) room comms: (NetStreamsComms *) comms
{
  if ((self = [super initWithServiceData: serviceData room: room comms: comms]) != nil)
  {
    _capabilities = SERVICE_HVAC_HAS_OUTDOOR_TEMP;
    _temperatureScaleRaw = [@"C" retain];
    _temperatureScale = [@"°C" retain];
  }
  
  return self;
}


- (CGFloat) heatSetPointMax
{
  CGFloat value = [super heatSetPointMax];
  
  if ([_temperatureScaleRaw isEqualToString: @"C"] && value > 30)
    value = 30;
  
  return value;
}

- (void) pushButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
  if (controlMode < [_controlModes count])
    [_pcomms send: [NSString stringWithFormat: 
                    @"button press %@ %u", [_controlModes objectAtIndex: controlMode], buttonIndex + 1] 
               to: self.serviceName];
}

- (void) registerQueryStatus
{
  [super registerQueryStatus];

  if (_statusRspHandle != nil && _queryControlModesHandle == nil)
    _queryControlModesHandle = [_comms send: @"query controlmodes" to: self.serviceName every: SERVICE_QUERY_INTERVAL];
}

- (void) deregisterQueryStatus
{
  if (_queryControlModesHandle != nil)
  {
    [_comms cancelSendEvery: _queryControlModesHandle];
    _queryControlModesHandle = nil;
  }
  
  [super deregisterQueryStatus];
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  [super received: comms messageType: messageType from: source to: destination data: data];

  if ([[data objectForKey: @"type"] isEqualToString: @"state"])
  {
    NSString *zoneTemp = [data objectForKey: @"zoneTemp"];
    NSString *outdoorTemp = [data objectForKey: @"outdoorTemp"];
    NSString *setPointTemp = [data objectForKey: @"setPoint"];
    NSString *tempScale = [data objectForKey: @"scale"];
    NSString *controlModes = [data objectForKey: @"ControlModes"];
    NSString *stateHeader = [data objectForKey: @"currentState_header"];
    NSString *stateLine1 = [data objectForKey: @"currentState1"];
    NSString *stateLine2 = [data objectForKey: @"currentState2_withnoicon"];
    NSString *stateLine2i = [data objectForKey: @"currentState2_withicon"];
    NSString *showIconStr = [data objectForKey: @"currentState2_icon"];
    NSUInteger changed = _pendingUpdates;
    NSUInteger count;
    NSUInteger i;
    
    _pendingUpdates = 0;
    if (zoneTemp != nil && ![zoneTemp isEqualToString: _zoneTemperature])
    {
      changed |= SERVICE_HVAC_ZONE_TEMP_CHANGED;
      [_zoneTemperature release];
      _zoneTemperature = [zoneTemp retain];
    }
    
    if (outdoorTemp != nil && ![outdoorTemp isEqualToString: _outsideTemperature])
    {
      changed |= SERVICE_HVAC_OUTSIDE_TEMP_CHANGED;
      [_outsideTemperature release];
      _outsideTemperature = [outdoorTemp retain];
    }
    
    if (setPointTemp != nil && ![setPointTemp isEqualToString: _heatSetPointTemperature])
    {
      changed |= (SERVICE_HVAC_CURRENT_SETPOINT_CHANGED|SERVICE_HVAC_HEAT_SETPOINT_CHANGED);
      [_currentSetPointTemperature release];
      [_heatSetPointTemperature release];
      _currentSetPointTemperature = [setPointTemp retain];
      _heatSetPointTemperature = [setPointTemp retain];
    }
    
    if (tempScale != nil && ![tempScale isEqualToString: _temperatureScaleRaw])
    {
      changed |= SERVICE_HVAC_TEMP_SCALE_CHANGED;
      [_temperatureScaleRaw release];
      _temperatureScaleRaw = [tempScale retain];
      [_temperatureScale release];
      if ([tempScale isEqualToString: @"K"])
        _temperatureScale = [tempScale retain];
      else
        _temperatureScale = [[NSString stringWithFormat: @"°%@", tempScale] retain];
    }
    
    if (stateHeader != nil)
      stateHeader = NSLocalizedString( stateHeader, @"Localised version of HVAC2 state header" );
    if (stateHeader != nil && ![stateHeader isEqualToString: _currentStateHeader])
    {
      changed |= SERVICE_HVAC_STATE_HEADER_CHANGED;
      [_currentStateHeader release];
      _currentStateHeader = [stateHeader retain];
    }
  
    if (stateLine1 != nil)
      stateLine1 = NSLocalizedString( stateLine1, @"Localised version of HVAC2 state line 1" );
    if (stateLine1 != nil && ![stateLine1 isEqualToString: _currentStateLine1])
    {
      changed |= SERVICE_HVAC_STATE_LINE1_CHANGED;
      [_currentStateLine1 release];
      _currentStateLine1 = [stateLine1 retain];
    }
    
    if (stateLine2 != nil)
      stateLine2 = NSLocalizedString( stateLine2, @"Localised version of HVAC2 state line 2 (no icon)" );
    if (stateLine2 != nil && ![stateLine2 isEqualToString: _currentStateLine2NoIcon])
    {
      changed |= SERVICE_HVAC_STATE_LINE2_CHANGED;
      [_currentStateLine2NoIcon release];
      _currentStateLine2NoIcon = [stateLine2 retain];
    }
    
    if (stateLine2i != nil)
      stateLine2i = NSLocalizedString( stateLine2i, @"Localised version of HVAC2 state header" );
    if (stateLine2i != nil && ![stateLine2i isEqualToString: _currentStateLine2WithIcon])
    {
      changed |= SERVICE_HVAC_STATE_LINE2I_CHANGED;
      [_currentStateLine2WithIcon release];
      _currentStateLine2WithIcon = [stateLine2i retain];
    }
    
    if (showIconStr != nil)
    {
      BOOL showIcon = [showIconStr isEqualToString: @"YES"];
      
      if (showIcon != _showIcon)
      {
        changed |= SERVICE_HVAC_SHOW_ICON_CHANGED;
        _showIcon = showIcon;
      }
    }
    
    if (controlModes != nil)
    {
      NSArray *modes = [self allocSplitAndCheckString: controlModes againstArray: _controlModes];

      if (modes != nil)
      {
        changed |= SERVICE_HVAC_MODES_CHANGED;
        [_controlModes release];
        _controlModes = modes;
        count = [_controlModes count];
        
        [_controlModeTitles release];
        [_controlModeStates release];
        _controlModeTitles = [[NSMutableArray arrayWithCapacity: count] retain];
        _controlModeStates = [[NSMutableArray arrayWithCapacity: count] retain];
        for (i = 0; i < count; ++i)
        {
          [_controlModeTitles addObject: [NSArray array]];
          [_controlModeStates addObject: [NSArray array]];
        }
        
        // After the first time we've received control mode information, we no longer need to continuously request it.
        if (_queryControlModesHandle != nil)
        {
          [_comms cancelSendEvery: _queryControlModesHandle];
          _queryControlModesHandle = nil;
        }
      }
    }
    
    if (changed != 0)
      [self notifyDelegates: changed];

    count = [_controlModes count];
    for (i = 0; i < count; ++i)
      [self checkControlMode: i data: data];
  }
}

- (void) checkControlMode: (NSUInteger) mode data: (NSDictionary *) data
{
  NSString *modeName = [_controlModes objectAtIndex: mode];
  
  NSArray *oldTitles = [[_controlModeTitles objectAtIndex: mode] retain];
  NSArray *oldStates = [[_controlModeStates objectAtIndex: mode] retain];
  NSUInteger oldCount = [oldTitles count];
  NSArray *titles = [self allocSplitAndCheckString: 
                     [data objectForKey: [NSString stringWithFormat: @"ControlMode%@", modeName]] againstArray: oldTitles];
  NSArray *states = [self allocSplitAndCheckString: 
                     [data objectForKey: [NSString stringWithFormat: @"ControlMode%@FB", modeName]] againstArray: oldStates];
  
  // HACK HACK HACK!
  if (titles == nil && [modeName isEqualToString: @"LifeStyles"])
  {
    modeName = @"Lifestyles";
    [titles release];
    titles = [self allocSplitAndCheckString: 
              [data objectForKey: [NSString stringWithFormat: @"ControlMode%@", modeName]] againstArray: oldTitles];
    [states release];
    states = [self allocSplitAndCheckString: 
              [data objectForKey: [NSString stringWithFormat: @"ControlMode%@FB", modeName]] againstArray: oldStates];
  }

  NSUInteger count;
  NSUInteger i;
  NSUInteger changed = 0;

  // Ensure that we never have a length mismatch between the states and the titles arrays
  // If we have states but not titles, just junk the whole lot.  If we have titles but
  // not states, assume "off" for all states.
  if (titles != nil)
  {
    count = [titles count];
    if (states != nil && [states count] != count)
    {
      [states release];
      states = nil;
    }
    if (states == nil && [oldStates count] == 0)
    {
      NSString *allOff = @"";
      
      for (i = 0; i < count; ++i)
        allOff = [allOff stringByAppendingString: @",0"];

      states = [self allocSplitAndCheckString: allOff againstArray: nil];
    }
  }
  else if (states != nil)
  {
    count = [states count];
    if (count != oldCount)
    {
      [states release];
      states = nil;
      count = 0;
    }
  }
  else
    count = 0;

  if (titles != nil)
  {
    if (count != oldCount)
      changed |= SERVICE_HVAC_MODE_TITLES_CHANGED;
    [_controlModeTitles replaceObjectAtIndex: mode withObject: titles];
    [titles release];
  }
  if (states != nil)
  {
    if (count != oldCount)
      changed |= SERVICE_HVAC_MODE_STATES_CHANGED;
    [_controlModeStates replaceObjectAtIndex: mode withObject: states];
    [states release];
  }
  
  for (i = 0; i < count; ++i)
  {
    NSUInteger itemChanged = 0;

    if (titles != nil &&
        (i >= oldCount || ![[titles objectAtIndex: i] isEqualToString: [oldTitles objectAtIndex: i]]))
      itemChanged |= SERVICE_HVAC_MODE_TITLES_CHANGED;
    if (states != nil && 
        (i >= oldCount || ![[states objectAtIndex: i] isEqualToString: [oldStates objectAtIndex: i]]))
      itemChanged |= SERVICE_HVAC_MODE_STATES_CHANGED;

    if (itemChanged != 0)
    {
      [self notifyDelegatesOfButton: i inControlMode: mode changed: itemChanged];
      changed |= itemChanged;
    }
  }
  
  if (changed != 0)
    [self notifyDelegates: changed];
  
  [oldTitles release];
  [oldStates release];
}

- (NSArray *) allocSplitAndCheckString: (NSString *) string againstArray: (NSArray *) array
{
  if (string == nil)
    return nil;

  NSMutableArray *newArray = [[string componentsSeparatedByString: @","] mutableCopy];
  NSUInteger count;
  NSUInteger i;
  BOOL changed;
  
  [newArray removeObjectAtIndex: 0];
  count = [newArray count];
  changed = (count != [array count]);
  
  for (i = 0; i < count; ++i)
    [newArray replaceObjectAtIndex: i withObject:
     NSLocalizedString( [[newArray objectAtIndex: i] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]],
                                 @"Localised version of state title returned from HVAC2 driver" )];
  
  if (!changed)
  {
    for (i = 0; i < count; ++i)
    {
      if (![[newArray objectAtIndex: i] isEqualToString: [array objectAtIndex: i]])
      {
        changed = YES;
        break;
      }
    }
  }
  
  if (!changed)
  {
    [newArray release];
    newArray = nil;
  }
  
  return newArray;
}

@end
