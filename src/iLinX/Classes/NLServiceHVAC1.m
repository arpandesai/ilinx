//
//  NLServiceHVAC1.m
//  iLinX
//
//  Created by mcf on 16/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLServiceHVAC1.h"

#define _pcomms NETSTREAMSCOMMS_PRODUCTION_ONLY(_comms)

// How often, in seconds, to send the report registration request to ensure
// that it does not expire
#define REGISTRATION_RENEWAL_INTERVAL 30

// How often, in seconds, to query the status of the service
#define SERVICE_QUERY_INTERVAL 5

@interface NLServiceHVAC1 ()

- (NSString *) formatTemp: (NSString *) temp;

@end

@implementation NLServiceHVAC1

- (id) initWithServiceData: (NSDictionary *) serviceData room: (NLRoom *) room comms: (NetStreamsComms *) comms
{
  if ((self = [super initWithServiceData: serviceData room: room comms: comms]) != nil)
  {
    _capabilities = SERVICE_HVAC_HAS_COOLING;
    _temperatureScaleRaw = [@"F" retain];
    _temperatureScale = [@"°F" retain];
    _controlModes = [[NSArray arrayWithObjects: 
                      NSLocalizedString( @"Mode", @"Title of Aprilaire HVAC mode control view" ),
                      NSLocalizedString( @"Fan", @"Title of Aprilaire HVAC Fan control view" ), nil] retain];
    _controlModeTitles = [[NSMutableArray arrayWithObjects:
                           [NSArray arrayWithObjects: 
                            NSLocalizedString( @"Off", @"Aprilaire control mode off button title" ),
                            NSLocalizedString( @"Auto", @"Aprilaire auto control mode button title" ),
                            NSLocalizedString( @"Cool", @"Aprilaire cool control mode button title" ),
                            NSLocalizedString( @"Heat", @"Aprilaire heat control mode button title" ),
                            NSLocalizedString( @"EM.H", @"Aprilaire EM.H control mode button title" ),
                            nil],
                           [NSArray arrayWithObjects: 
                            NSLocalizedString( @"On", @"HVAC fan on button title" ),
                            NSLocalizedString( @"Auto", @"HVAC fan auto button title" ), nil],
                           nil] retain];
    _controlModeStates = [[NSMutableArray arrayWithObjects:
                           [NSMutableArray arrayWithObjects: @"0", @"0", @"0", @"0", @"0", nil ],
                           [NSMutableArray arrayWithObjects: @"0", @"0", nil ],
                           nil] retain];
    _currentStateHeader = NSLocalizedString( @"Mode", @"Title of the mode area on the Aprilaire HVAC display" );
    _currentStateLine1 = [[_controlModeTitles objectAtIndex: 0] objectAtIndex: 0];
    _currentStateLine2WithIcon = @"";
    _currentStateLine2NoIcon = @"";
    _showIcon = YES;
    _fanMode = 2;
  }
  
  return self;
}

- (void) parserDidStartElement: (NSString *) elementName attributes: (NSDictionary *) attributeDict
{
  if ([elementName isEqualToString: @"indicator"])
  {
    if ([[attributeDict objectForKey: @"id"] isEqualToString: @"ID-HUM"])
      _capabilities |= SERVICE_HVAC_HAS_INDOOR_HUMIDITY;
    else if ([[attributeDict objectForKey: @"id"] isEqualToString: @"OD-TMP"])
    {
      _outdoorTempService = [[attributeDict objectForKey: @"serviceName"] retain];
      _outdoorTempField = [[attributeDict objectForKey: @"field"] retain];
      if (_outdoorTempService == nil && _outdoorTempField == nil)
      {
        [_outdoorTempService release];
        [_outdoorTempField release];
        _outdoorTempService = nil;
        _outdoorTempField = nil;
      }
      _capabilities |= SERVICE_HVAC_HAS_OUTDOOR_TEMP;
    }
    else if ([[attributeDict objectForKey: @"id"] isEqualToString: @"OD-HUM"])
    {
      _outdoorHumidityService = [[attributeDict objectForKey: @"serviceName"] retain];
      _outdoorHumidityField = [[attributeDict objectForKey: @"field"] retain];
      if (_outdoorHumidityService == nil && _outdoorHumidityField == nil)
      {
        [_outdoorHumidityService release];
        [_outdoorHumidityField release];
        _outdoorHumidityService = nil;
        _outdoorHumidityField = nil;
      }
      _capabilities |= SERVICE_HVAC_HAS_OUTDOOR_HUMIDITY;
    }
  }
}

- (CGFloat) heatSetPointMin
{
  if (_setHeatEnabled)
    return [super heatSetPointMin];
  else
    return [_heatSetPointTemperature floatValue];
}

- (CGFloat) heatSetPointMax
{
  if (_setHeatEnabled)
    return [super heatSetPointMax];
  else
    return [_heatSetPointTemperature floatValue];
}

- (CGFloat) coolSetPointMin
{
  if (_setCoolEnabled)
    return [super coolSetPointMin];
  else
    return [_coolSetPointTemperature floatValue];
}

- (CGFloat) coolSetPointMax
{
  if (_setCoolEnabled)
    return [super coolSetPointMax];
  else
    return [_coolSetPointTemperature floatValue];
}

- (BOOL) indicatorStateForButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
  BOOL state;
  
  if (controlMode == 0)
    state = (buttonIndex == _hvacMode);
  else if (controlMode == 1)
    state = (buttonIndex == _fanMode);
  else
    state = NO;

  return state;
}

- (void) pushButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
  NSUInteger buttonId = (controlMode * 5) + buttonIndex;
  NSString *cmd;
  
  switch (buttonId)
  {
    case 0:
      cmd = @"set mode off";
      break;
    case 1:
      cmd = @"set mode auto";
      break;
    case 2:
      cmd = @"set mode cool";
      break;
    case 3:
      cmd = @"set mode heat";
      break;
    case 4:
      cmd = @"set mode eheat";
      break;
    case 5:
      cmd = @"set fanMode on";
      break;
    case 6:
      cmd = @"set fanMode auto";
      break;
    default:
      cmd = nil;
      break;
  }
  
  if (cmd != nil)
  {
    [_pcomms send: cmd to: self.serviceName];
    // Not all modes appear to be supported by all HVAC systems, however a) there's no way of 
    // determining this and b) the behaviour of the system when sent an unsupported message is
    // to ignore it.  We therefore send a STATUS to find out what happened.
    _pendingUpdates = SERVICE_HVAC_MODE_STATES_CHANGED;
    [_comms send: @"STATUS" to: self.serviceName];
  }
}


#if defined(DEBUG)
#if 1
- (void) fakeNetStreams
{
  [self received: _comms messageType: @"REPORT" from: self.serviceName to: @"ALL"
            data: [NSDictionary dictionaryWithObjectsAndKeys:
                   @"state", @"type", 
                   @"66.2", @"temperature", 
                   @"49.1", @"outdoorTemperature",
                   @"42%", @"humidity",
                   @"29%", @"outdoorHumidity",
                   @"68.0", @"current",
                   @"68.0", @"heat",
                   @"72.0", @"cool",
                   @"F", @"scale",
                   @"AUTO", @"mode",
                   @"1", @"fan",
                   @"AUTO", @"fanMode",
                   nil]];
}
#endif
#endif

- (void) registerForNetStreams
{
  [super registerForNetStreams];
  
  if (_outdoorTempService != nil && 
      [_outdoorTempService compare: self.serviceName options: NSCaseInsensitiveSearch] != NSOrderedSame)
  {
    _outdoorTempStatusRspHandle = [_comms registerDelegate: self forMessage: @"REPORT" from: _outdoorTempService];
    _outdoorTempRegisterMsgHandle = [_comms send: [NSString stringWithFormat: @"REGISTER ON,{{%@}}", _outdoorTempService] to: nil
                                           every: REGISTRATION_RENEWAL_INTERVAL];
  }
  
  if (_outdoorHumidityService != nil && 
      [_outdoorHumidityService compare: self.serviceName options: NSCaseInsensitiveSearch] != NSOrderedSame &&
      [_outdoorHumidityService compare: _outdoorTempService options: NSCaseInsensitiveSearch] != NSOrderedSame)
  {
    _outdoorHumidityStatusRspHandle = [_comms registerDelegate: self forMessage: @"REPORT" from: _outdoorHumidityService];
    _outdoorHumidityRegisterMsgHandle = [_comms send: [NSString stringWithFormat: @"REGISTER ON,{{%@}}", _outdoorHumidityService] to: nil
                                               every: REGISTRATION_RENEWAL_INTERVAL]; 
  }

#if defined(DEBUG)
#if 1
  [NSTimer scheduledTimerWithTimeInterval: 5.0 target: self selector: @selector(fakeNetStreams) userInfo: nil repeats: NO];
#endif
#endif
}

- (void) registerQueryStatus
{
  [super registerQueryStatus];
  
  if (_outdoorTempStatusRspHandle != nil && _outdoorTempQueryMsgHandle == nil)
    _outdoorTempQueryMsgHandle = [_comms send: @"STATUS" to: _outdoorTempService every: SERVICE_QUERY_INTERVAL];
  
  if (_outdoorHumidityStatusRspHandle != nil && _outdoorHumidityQueryMsgHandle == nil) 
    _outdoorHumidityQueryMsgHandle = [_comms send: @"STATUS" to: _outdoorHumidityService every: SERVICE_QUERY_INTERVAL];
}

- (void) deregisterFromNetStreams
{
  if (_outdoorTempStatusRspHandle != nil)
  {
    [_comms deregisterDelegate: _outdoorTempStatusRspHandle];
    _outdoorTempStatusRspHandle = nil;
  }
  
  if (_outdoorTempRegisterMsgHandle != nil)
  {
    [_comms cancelSendEvery: _outdoorTempRegisterMsgHandle];
    _outdoorTempRegisterMsgHandle = nil;
  }
  
  if (_outdoorHumidityStatusRspHandle != nil)
  {
    [_comms deregisterDelegate: _outdoorHumidityStatusRspHandle];
    _outdoorHumidityStatusRspHandle = nil;
  }
  
  if (_outdoorHumidityRegisterMsgHandle != nil)
  {
    [_comms cancelSendEvery: _outdoorHumidityRegisterMsgHandle];
    _outdoorHumidityRegisterMsgHandle = nil;
  }
  
  [super deregisterFromNetStreams];
}

- (void) deregisterQueryStatus
{
  if (_outdoorTempQueryMsgHandle != nil)
  {
    [_comms cancelSendEvery: _outdoorTempQueryMsgHandle];
    _outdoorTempQueryMsgHandle = nil;
  }
  
  if (_outdoorHumidityQueryMsgHandle != nil)
  {
    [_comms cancelSendEvery: _outdoorHumidityQueryMsgHandle];
    _outdoorHumidityQueryMsgHandle = nil;
  }
  
  [super deregisterQueryStatus];
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  [super received: comms messageType: messageType from: source to: destination data: data];
  
  if ([[data objectForKey: @"type"] isEqualToString: @"state"])
  {
    NSUInteger changed = _pendingUpdates;

    _pendingUpdates = 0;
    if ([source compare: self.serviceName options: NSCaseInsensitiveSearch] == NSOrderedSame)
    {
      NSString *zoneTemp = [self formatTemp: [data objectForKey: @"temperature"]];
      NSString *outdoorTemp = [self formatTemp: [data objectForKey: @"outdoorTemperature"]];
      NSString *zoneHumidity = [data objectForKey: @"humidity"];
      NSString *outdoorHumidity = [data objectForKey: @"outdoorHumidity"];
      NSString *setPointTemp = [self formatTemp: [data objectForKey: @"current"]];
      NSString *heatSetPointTemp = [self formatTemp: [data objectForKey: @"heat"]];
      NSString *coolSetPointTemp = [self formatTemp: [data objectForKey: @"cool"]];
      NSString *tempScale = [data objectForKey: @"scale"];
      NSString *stateLine1 = [data objectForKey: @"mode"];
      NSString *fanOnStr = [data objectForKey: @"fan"];
      NSString *fanModeStr = [data objectForKey: @"fanMode"];
      
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
      
      if (zoneHumidity != nil && ![zoneHumidity isEqualToString: _zoneHumidity])
      {
        changed |= SERVICE_HVAC_ZONE_HUMIDITY_CHANGED;
        [_zoneHumidity release];
        _zoneHumidity = [zoneHumidity retain];
      }
      
      if (outdoorHumidity != nil && ![outdoorHumidity isEqualToString: _outsideHumidity])
      {
        changed |= SERVICE_HVAC_OUTSIDE_HUMIDITY_CHANGED;
        [_outsideHumidity release];
        _outsideHumidity = [outdoorHumidity retain];
      }
      
      if (setPointTemp != nil && ![setPointTemp isEqualToString: _currentSetPointTemperature])
      {
        changed |= SERVICE_HVAC_CURRENT_SETPOINT_CHANGED;
        [_currentSetPointTemperature release];
        _currentSetPointTemperature = [setPointTemp retain];
      }
      
      if (heatSetPointTemp != nil && ![heatSetPointTemp isEqualToString: _heatSetPointTemperature])
      {
        changed |= SERVICE_HVAC_HEAT_SETPOINT_CHANGED;
        [_heatSetPointTemperature release];
        _heatSetPointTemperature = [heatSetPointTemp retain];
      }
      
      if (coolSetPointTemp != nil && ![coolSetPointTemp isEqualToString: _coolSetPointTemperature])
      {
        changed |= SERVICE_HVAC_COOL_SETPOINT_CHANGED;
        [_coolSetPointTemperature release];
        _coolSetPointTemperature = [coolSetPointTemp retain];
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
      
      if (stateLine1 != nil)
      {
        NSUInteger hvacMode;
        
        if ([stateLine1 isEqualToString: @"OFF"])
        {
          hvacMode = 0;
          _setHeatEnabled = NO;
          _setCoolEnabled = NO;
        }
        else if ([stateLine1 isEqualToString: @"AUTO"])
        {
          hvacMode = 1;
          _setHeatEnabled = YES;
          _setCoolEnabled = YES;
        }
        else if ([stateLine1 isEqualToString: @"COOL"])
        {
          hvacMode = 2;
          _setHeatEnabled = NO;
          _setCoolEnabled = YES;
        }
        else if ([stateLine1 isEqualToString: @"HEAT"])
        {
          hvacMode = 3;
          _setHeatEnabled = YES;
          _setCoolEnabled = NO;
        }
        else if ([stateLine1 isEqualToString: @"EHEAT"])
        {
          hvacMode = 4;
          _setHeatEnabled = YES;
          _setCoolEnabled = NO;
        }
        else
          hvacMode = _hvacMode;
        
        if (hvacMode != _hvacMode)
        {
          NSUInteger oldMode = _hvacMode;
          
          _hvacMode = hvacMode;
          [[_controlModeStates objectAtIndex: 0] replaceObjectAtIndex: oldMode withObject: @"0"];
          [[_controlModeStates objectAtIndex: 0] replaceObjectAtIndex: hvacMode withObject: @"1"];
          [self notifyDelegatesOfButton: oldMode inControlMode: 0 changed: SERVICE_HVAC_MODE_STATES_CHANGED];
          [self notifyDelegatesOfButton: _hvacMode inControlMode: 0 changed: SERVICE_HVAC_MODE_STATES_CHANGED];
          changed |= SERVICE_HVAC_MODE_STATES_CHANGED;
        }

        stateLine1 = NSLocalizedString( stateLine1, @"Localised version of HVAC state" );
      }
      
      if (stateLine1 != nil && ![stateLine1 isEqualToString: _currentStateLine1])
      {
        changed |= SERVICE_HVAC_STATE_LINE1_CHANGED;
        [_currentStateLine1 release];
        _currentStateLine1 = [stateLine1 retain];
      }
      
      if (fanOnStr != nil)
      {
        BOOL fanOn = [fanOnStr isEqualToString: @"1"];
        
        if (fanOn != _fanOn)
        {
          _fanOn = fanOn;
          changed |= SERVICE_HVAC_STATE_LINE2I_CHANGED;
        }
      }
      if (fanModeStr != nil)
      {
        NSUInteger fanMode;

        if ([fanModeStr isEqualToString: @"ON"])
          fanMode = 0;
        else if ([fanModeStr isEqualToString: @"AUTO"])
          fanMode = 1;
        else
          fanMode = 2;
        
        if (fanMode != _fanMode)
        {
          NSUInteger oldMode = _fanMode;
          
          _fanMode = fanMode;
          if (oldMode < 2)
            [[_controlModeStates objectAtIndex: 1] replaceObjectAtIndex: oldMode withObject: @"0"];
          if (fanMode < 2)
            
            [[_controlModeStates objectAtIndex: 1] replaceObjectAtIndex: fanMode withObject: @"1"];
          [self notifyDelegatesOfButton: oldMode inControlMode: 1 changed: SERVICE_HVAC_MODE_STATES_CHANGED];
          [self notifyDelegatesOfButton: _fanMode inControlMode: 1 changed: SERVICE_HVAC_MODE_STATES_CHANGED];          
          changed |= (SERVICE_HVAC_STATE_LINE2I_CHANGED|SERVICE_HVAC_MODE_STATES_CHANGED);
        }
      }
      
      if ((changed & SERVICE_HVAC_STATE_LINE2I_CHANGED) != 0)
      {
        NSString *fanStatus;
        
        if (_fanOn)
          fanStatus = NSLocalizedString( @"On", @"Status shown when fan is on" );
        else
          fanStatus = NSLocalizedString( @"Off", @"Status shown when fan is off" );
        if (_fanMode == 1)
          fanStatus = [NSString stringWithFormat: 
                       NSLocalizedString( @"%@ (Auto)", 
                                         @"Status shown when fan is in auto mode; variable is on or off" ), 
                       fanStatus];
        [_currentStateLine2WithIcon release];
        _currentStateLine2WithIcon = [fanStatus retain];
      }
    }

    if (_outdoorTempService != nil && 
        [source compare: _outdoorTempService options: NSCaseInsensitiveSearch] == NSOrderedSame)
    {
      NSString *outdoorTemp = [data objectForKey: _outdoorTempField];
      
      if (outdoorTemp != nil && ![outdoorTemp isEqualToString: _outsideTemperature])
      {
        changed |= SERVICE_HVAC_OUTSIDE_TEMP_CHANGED;
        [_outsideTemperature release];
        _outsideTemperature = [outdoorTemp retain];
      }
    }
    
    if (_outdoorHumidityService != nil && 
        [source compare: _outdoorHumidityService options: NSCaseInsensitiveSearch] == NSOrderedSame)
    {
      NSString *outdoorHumidity = [data objectForKey: _outdoorHumidityField];
      
      if (outdoorHumidity != nil && ![outdoorHumidity isEqualToString: _outsideHumidity])
      {
        changed |= SERVICE_HVAC_OUTSIDE_HUMIDITY_CHANGED;
        [_outsideHumidity release];
        _outsideHumidity = [outdoorHumidity retain];
      }
    }
    
    if (changed != 0)
      [self notifyDelegates: changed];
  }
}

- (NSString *) formatTemp: (NSString *) temp
{
  if (temp != nil && [temp rangeOfString: @"."].length == 0)
    temp = [temp stringByAppendingString: @".0"];
  
  return temp;
}

- (void) dealloc
{
  [_outdoorTempService release];
  [_outdoorTempField release];
  [_outdoorHumidityService release];
  [_outdoorHumidityField release];
  [super dealloc];
}

@end
