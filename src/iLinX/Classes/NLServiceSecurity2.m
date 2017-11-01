//
//  NLServiceSecurity2.m
//  iLinX
//
//  Created by mcf on 18/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLServiceSecurity2.h"

#define _pcomms NETSTREAMSCOMMS_PRODUCTION_ONLY(_comms)

static NSArray *CONTROL_MODES = nil;

@implementation NLServiceSecurity2

- (id) initWithServiceData: (NSDictionary *) serviceData room: (NLRoom *) room comms: (NetStreamsComms *) comms
{
  if (self = [super initWithServiceData: serviceData room: room comms: comms])
  {
    _capabilities = (SERVICE_SECURITY_HAS_CLEAR_ENTER|SERVICE_SECURITY_HAS_CUSTOM_MODES);
    
    if (CONTROL_MODES == nil)
      CONTROL_MODES = [[NSArray arrayWithObjects:
                        NSLocalizedString( @"Open Zones", @"Title of open zones view in Secant security" ),
                        NSLocalizedString( @"Bypass Zones", @"Title of bypassed zones view in Secant security" ),
                        nil] retain];
    
    _controlModes = [CONTROL_MODES retain];
    _controlModeTitles = [[NSMutableArray arrayWithObjects:
                          [NSMutableArray arrayWithCapacity: 10],
                          [NSMutableArray arrayWithCapacity: 16],
                           nil] retain];
    _controlModeStates = [[NSMutableArray arrayWithObjects:
                           [NSMutableArray arrayWithCapacity: 10],
                           [NSMutableArray arrayWithCapacity: 16],
                           nil] retain];
  }

  return self;
}

- (NSUInteger) styleForControlMode: (NSUInteger) controlMode
{
  if (controlMode == 0)
    return SERVICE_SECURITY_MODE_TYPE_LIST;
  else
    return SERVICE_SECURITY_MODE_TYPE_BUTTONS;
}

#if defined(DEBUG)
#if 1
- (void) fakeNetStreams
{
  [self received: _comms messageType: @"REPORT" from: self.serviceName to: @"ALL"
            data: [NSDictionary dictionaryWithObjectsAndKeys:
                   @"state", @"type", 
                   @"Disarmed", @"ArmingState",
                   @"Kitchen|Cinema|1|2|3|4|5|6|7|8|9|10", @"OpenZones",
                   @"Kitchen.Y|Living Room.N|Cinema.N|Master Bedroom.N|Dining Room.Y|Bedroom 2.N|Bedroom 3.N|Garage.Y", @"BypassedZones",
                   nil]];
  [self received: _comms messageType: @"REPORT" from: self.serviceName to: @"ALL"
            data: [NSDictionary dictionaryWithObjectsAndKeys:
                   @"state", @"type", 
                   @"Armed", @"ArmingState",
                   @"System is now armed", @"ErrorMessage",
                   nil]];
}
#endif
#endif

- (void) registerForNetStreams
{  
  [_comms send: @"set Observed 1" to: self.serviceName];
  [super registerForNetStreams];
#if defined(DEBUG)
#if 1
  [NSTimer scheduledTimerWithTimeInterval: 5.0 target: self selector: @selector(fakeNetStreams) userInfo: nil repeats: NO];
#endif
#endif
}

- (void) deregisterFromNetStreams
{
  if (_displayClearTimer != nil)
  {
    [_displayClearTimer invalidate];
    _displayClearTimer = nil;
    [_displayText release];
    _displayText = nil;
  }

  [super deregisterFromNetStreams];
}

- (void) pressKeypadKey: (NSString *) keyName
{
  NSUInteger changed = 0;

  if (_displayClearTimer != nil)
  {
    [_displayClearTimer invalidate];
    _displayClearTimer = nil;
  }

  if ([keyName isEqualToString: @"Enter"])
  {
    if (_password == nil || [_password length] == 0)
    {
      [_errorMessage release]; 
      _errorMessage = [NSLocalizedString( @"Please enter a pass code",
                                         @"Error message shown when enter pressed on Secant security with no code entered" ) retain];
      changed |= SERVICE_SECURITY_ERROR_MESSAGE_CHANGED;
    }
    else
    {
      NSString *upperArming = [_armingState uppercaseString];

      _displayClearTimer = [NSTimer
                            scheduledTimerWithTimeInterval: 5.0 target: self
                            selector: @selector(displayClearTimerFired:) userInfo: nil repeats: NO];
    
      if ([upperArming isEqualToString: @"ARMED"])
        [_pcomms send: [NSString stringWithFormat: @"set Disarm %@", _password] to: self.serviceName];
      else if ([upperArming isEqualToString: @"DISARMED"])
        [_pcomms send: [NSString stringWithFormat: @"set Arm %@", _password] to: self.serviceName];
      [_password release];
      _password = nil;
    }
  }
  else if ([keyName length] > 1)
  {
    if (_password != nil)
    {
      [_password release];
      _password = nil;
    }
    
    if (_displayText == nil || ![_displayText isEqualToString: _armingState])
    {
      [_displayText release];
      _displayText = [_armingState retain];
      changed |= SERVICE_SECURITY_DISPLAY_TEXT_CHANGED;
    }
  }
  else
  {
    NSString *newText;
    
    if (_password == nil)
      newText = keyName;
    else
      newText = [_password stringByAppendingString: keyName];
    
    [_password release];
    _password = [newText retain];
    [_displayText release];
    _displayText = [newText retain];
    changed |= SERVICE_SECURITY_DISPLAY_TEXT_CHANGED;

    _displayClearTimer = [NSTimer
                          scheduledTimerWithTimeInterval: 20.0 target: self
                          selector: @selector(displayClearTimerFired:) userInfo: nil repeats: NO];
  }
  
  if (changed != 0)
    [self notifyDelegates: changed];
}

- (void) displayClearTimerFired: (NSTimer *) timer
{
  _displayClearTimer = nil;
  [_password release];
  _password = nil;
  [_displayText release];
  _displayText = [_armingState retain];
  [self notifyDelegates: SERVICE_SECURITY_DISPLAY_TEXT_CHANGED];
}

- (void) pushButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
  // Nothing on press
}

- (void) releaseButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
  if (controlMode == 1 && [_controlModeStates count] > 1)
  {
    NSMutableArray *currentStates = [_controlModeStates objectAtIndex: 1];
    
    if (buttonIndex < [currentStates count])
    {
      NSUInteger currentState = [[currentStates objectAtIndex: buttonIndex] integerValue];
      
      if ((currentState & (SERVICE_SECURITY_STATE_ENABLED|SERVICE_SECURITY_STATE_HAS_INDICATOR)) == 
        (SERVICE_SECURITY_STATE_ENABLED|SERVICE_SECURITY_STATE_HAS_INDICATOR))
      {
        if ((currentState & SERVICE_SECURITY_STATE_INDICATOR_ON) == 0)
          [_pcomms send: [NSString stringWithFormat: @"set BypassOn %u", buttonIndex + 1] to: self.serviceName];
        else
          [_pcomms send: [NSString stringWithFormat: @"set BypassOff %u", buttonIndex + 1] to: self.serviceName];
      }
    }
  }
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  if ([[data objectForKey: @"type"] isEqualToString: @"state"])
  {
    NSString *errorMessage = [data objectForKey: @"ErrorMessage"];
    NSString *armingState = [data objectForKey: @"ArmingState"];
    NSString *openZones = [data objectForKey: @"OpenZones"];
    NSString *bypassedZones = [data objectForKey: @"BypassedZones"];
    NSUInteger changed = 0;
      
    if (errorMessage != nil && ([errorMessage length] > 0 || ![errorMessage isEqualToString: _errorMessage]))
    {
      [_errorMessage release];
      _errorMessage = [errorMessage retain];
      changed |= SERVICE_SECURITY_ERROR_MESSAGE_CHANGED;
      if ([errorMessage length] > 0)
        [_comms send: @"set ClearError" to: self.serviceName];
    }
    
    if (armingState != nil && ![armingState isEqualToString: _armingState])
    {
      if ([_displayText isEqualToString: _armingState])
      {
        [_displayText release];
        _displayText = [armingState retain];
      }

      [_armingState release];
      _armingState = [armingState retain];
    }
    
    if (_armingState != nil && _displayText == nil)
    {
      _displayText = [_armingState retain];
      changed |= SERVICE_SECURITY_DISPLAY_TEXT_CHANGED;
    }

    if (openZones != nil && ![openZones isEqualToString: _openZones])
    {
      NSArray *openZoneData = [openZones componentsSeparatedByString: @"|"];
      NSUInteger newCount = [openZoneData count];
      NSArray *currentTitles = [[_controlModeTitles objectAtIndex: 0] retain];
      NSUInteger oldCount = [currentTitles count];
      NSMutableArray *currentStates = [_controlModeStates objectAtIndex: 0];

      [_openZones release];
      _openZones = [openZones retain];
      changed |= SERVICE_SECURITY_MODE_TITLES_CHANGED;

      if (newCount != [currentTitles count])
      {
        NSUInteger statesCount = [currentStates count];
        NSUInteger i;
                
        [_controlModeTitles replaceObjectAtIndex: 0 withObject: openZoneData];
        if (oldCount < newCount)
        {
          for (i = 0; i < oldCount; ++i)
          {
            if (![[currentTitles objectAtIndex: i] isEqualToString: [openZoneData objectAtIndex: i]])
              [self notifyDelegatesOfButton: i inControlMode: 0 changed: SERVICE_SECURITY_MODE_TITLES_CHANGED];
          }
          for (i = oldCount; i < newCount; ++i)
          {
            if (i >= statesCount)
              [currentStates addObject: [NSNumber numberWithInteger: SERVICE_SECURITY_STATE_VISIBLE]];
            [self notifyDelegatesOfButton: i inControlMode: 0 changed: 
             SERVICE_SECURITY_MODE_TITLES_CHANGED|SERVICE_SECURITY_MODE_STATES_CHANGED];
          }
          changed |= SERVICE_SECURITY_MODE_STATES_CHANGED;
        }
        else
        {
          for (i = 0; i < newCount; ++i)
          {
            if (![[currentTitles objectAtIndex: i] isEqualToString: [openZoneData objectAtIndex: i]])
              [self notifyDelegatesOfButton: i inControlMode: 0 changed: SERVICE_SECURITY_MODE_TITLES_CHANGED];
          }          
        }
      }
      
      [currentTitles release];
    }
    
    if (bypassedZones != nil && ![bypassedZones isEqualToString: _bypassedZones])
    {
      NSArray *bypassedZoneData = [bypassedZones componentsSeparatedByString: @"|"];
      NSUInteger newCount = [bypassedZoneData count];
      NSArray *currentTitles = [[_controlModeTitles objectAtIndex: 1] retain];
      NSUInteger oldCount = [currentTitles count];
      NSMutableArray *currentStates = [[_controlModeStates objectAtIndex: 1] retain];
      
      [_bypassedZones release];
      _bypassedZones = [bypassedZones retain];
      
      if (newCount != [currentTitles count])
      {
        NSMutableArray *newTitles = [NSMutableArray arrayWithCapacity: newCount];
        NSMutableArray *newStates = [NSMutableArray arrayWithCapacity: newCount];
        NSUInteger i;
        
        for (i = 0; i < newCount; ++i)
        {
          NSArray *buttonInfo = [[bypassedZoneData objectAtIndex: i] componentsSeparatedByString: @"."];
          NSUInteger buttonInfoCount = [buttonInfo count];
          NSUInteger state;
          
          if (buttonInfoCount > 0)
            [newTitles addObject: [buttonInfo objectAtIndex: 0]];
          else
            [newTitles addObject: @""];
          if (buttonInfoCount < 2)
            state = SERVICE_SECURITY_STATE_VISIBLE;
          else
          {
            state = SERVICE_SECURITY_STATE_VISIBLE|SERVICE_SECURITY_STATE_ENABLED|SERVICE_SECURITY_STATE_HAS_INDICATOR;
            if ([[buttonInfo objectAtIndex: 1] isEqualToString: @"Y"])
              state |= SERVICE_SECURITY_STATE_INDICATOR_ON;
          }
          [newStates addObject: [NSNumber numberWithInteger: state]];
        }
        
        [_controlModeTitles replaceObjectAtIndex: 1 withObject: newTitles];
        [_controlModeStates replaceObjectAtIndex: 1 withObject: newStates];

        if (oldCount < newCount)
        {
          for (i = 0; i < oldCount; ++i)
          {
            NSUInteger buttonChanged = 0;
            
            if (![[currentTitles objectAtIndex: i] isEqualToString: [newTitles objectAtIndex: i]])
              buttonChanged |= SERVICE_SECURITY_MODE_TITLES_CHANGED;
            if (![[currentStates objectAtIndex: i] isEqual: [newStates objectAtIndex: i]])
              buttonChanged |= SERVICE_SECURITY_MODE_STATES_CHANGED;
            if (buttonChanged != 0)
              [self notifyDelegatesOfButton: i inControlMode: 1 changed: buttonChanged];
          }
          for (i = oldCount; i < newCount; ++i)
          {
            [self notifyDelegatesOfButton: i inControlMode: 1 changed: 
             SERVICE_SECURITY_MODE_TITLES_CHANGED|SERVICE_SECURITY_MODE_STATES_CHANGED];
          }
          changed |= (SERVICE_SECURITY_MODE_STATES_CHANGED|SERVICE_SECURITY_MODE_TITLES_CHANGED);
        }
        else
        {
          if (oldCount != newCount)
            changed |= (SERVICE_SECURITY_MODE_STATES_CHANGED|SERVICE_SECURITY_MODE_TITLES_CHANGED);

          for (i = 0; i < newCount; ++i)
          {
            NSUInteger buttonChanged = 0;
            
            if (![[currentTitles objectAtIndex: i] isEqualToString: [newTitles objectAtIndex: i]])
              buttonChanged |= SERVICE_SECURITY_MODE_TITLES_CHANGED;
            if (![[currentStates objectAtIndex: i] isEqual: [newStates objectAtIndex: i]])
              buttonChanged |= SERVICE_SECURITY_MODE_STATES_CHANGED;
            if (buttonChanged != 0)
            {
              [self notifyDelegatesOfButton: i inControlMode: 1 changed: buttonChanged];
              changed |= buttonChanged;
            }
          }
        }
      }
      
      [currentTitles release];
      [currentStates release];
    }
    
    if (changed)
      [self notifyDelegates: changed];
  }
}

- (void) dealloc
{
  [_password release];
  [_armingState release];
  [_openZones release];
  [_bypassedZones release];
  [super dealloc];
}

@end
