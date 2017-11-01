//
//  NLServiceSecurity1.m
//  iLinX
//
//  Created by mcf on 18/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLServiceSecurity1.h"

#define _pcomms NETSTREAMSCOMMS_PRODUCTION_ONLY(_comms)

static NSArray *CONTROL_MODES = nil;

// How often, in seconds, to send the report registration request to ensure
// that it does not expire
#define REGISTRATION_RENEWAL_INTERVAL 30

@interface NLServiceSecurity1 ()

- (void) holdTimerFired: (NSTimer *) timer;
#if LOCAL_CONTROL_OF_DISPLAY
- (void) displayClearTimerFired: (NSTimer *) timer;
#endif

@end

@implementation NLServiceSecurity1

- (id) initWithServiceData: (NSDictionary *) serviceData room: (NLRoom *) room comms: (NetStreamsComms *) comms
{
  if (self = [super initWithServiceData: serviceData room: room comms: comms])
  {
    _capabilities = (SERVICE_SECURITY_HAS_STAR_HASH|SERVICE_SECURITY_HAS_CUSTOM_MODES|
                     SERVICE_SECURITY_HAS_POLICE|SERVICE_SECURITY_HAS_FIRE|SERVICE_SECURITY_HAS_AMBULANCE);
    
    if (CONTROL_MODES == nil)
      CONTROL_MODES = [[NSArray arrayWithObject: NSLocalizedString( @"Custom", @"Title of custom buttons view in security" )] retain];
  }
  
  return self;
}

#if defined(DEBUG)
#if 1
- (void) fakeNetStreams
{
  [self received: _comms messageType: @"REPORT" from: [NSString stringWithFormat: @"%@~1", self.serviceName] to: @"ALL"
            data: [NSDictionary dictionaryWithObjectsAndKeys:
                   @"state", @"type", 
                   @"1", @"visible", 
                   @"1", @"enabled",
                   @"0", @"indicatorState",
                   @"<", @"label",
                   nil]];
  [self received: _comms messageType: @"REPORT" from: [NSString stringWithFormat: @"%@~2", self.serviceName] to: @"ALL"
            data: [NSDictionary dictionaryWithObjectsAndKeys:
                   @"state", @"type", 
                   @"1", @"visible", 
                   @"1", @"enabled",
                   @"0", @"indicatorState",
                   @">", @"label",
                   nil]];
}
#endif
#endif

- (void) registerForNetStreams
{
  [super registerForNetStreams];

  //NSLog( @"Register" );
  _registerAllMsgHandle = [_comms send: [NSString stringWithFormat: @"REGISTER ON,{{%@~all}}", self.serviceName] to: nil
                              every: REGISTRATION_RENEWAL_INTERVAL];
#if defined(DEBUG)
#if 1
  [NSTimer scheduledTimerWithTimeInterval: 5.0 target: self selector: @selector(fakeNetStreams) userInfo: nil repeats: NO];
#endif
#endif
}

- (void) deregisterFromNetStreams
{
  //NSLog( @"Cancel send every" );
  if (_registerAllMsgHandle != nil)
  {
    [_comms cancelSendEvery: _registerAllMsgHandle];
    [_comms send: [NSString stringWithFormat: @"REGISTER OFF,{{%@~all}}", self.serviceName] to: nil];
    _registerAllMsgHandle = nil;
  }
  
  if (_buttonHoldTimer != nil)
  {
    [_buttonHoldTimer invalidate];
    _buttonHoldTimer = nil;
  }
  
#if LOCAL_CONTROL_OF_DISPLAY
  if (_displayClearTimer != nil)
  {
    [_displayClearTimer invalidate];
    _displayClearTimer = nil;
  }
#endif

  [super deregisterFromNetStreams];
}

- (void) pressKeypadKey: (NSString *) keyName
{
#if LOCAL_CONTROL_OF_DISPLAY
  [_displayClearTimer invalidate];
  if ([keyName length] > 1)
  {
    _displayClearTimer = nil;
    [_displayText release];
    _displayText = nil;
  }
  else
  {
    NSString *newText;
    
    if (_displayText == nil)
      newText = keyName;
    else
      newText = [_displayText stringByAppendingString: keyName];
    
    _displayClearTimer = [NSTimer
                          scheduledTimerWithTimeInterval: 5.0 target: self
                          selector: @selector(displayClearTimerFired:) userInfo: nil repeats: NO];
    [_displayText release];
    _displayText = [newText retain];
  }
#endif

  if ([keyName isEqualToString: @"#"])
    keyName = @"%23";
  
  [_buttonHoldTimer invalidate];
  _buttonHoldTimer = [NSTimer
                scheduledTimerWithTimeInterval: 0.5 target: self
                selector: @selector(holdTimerFired:) userInfo: keyName repeats: YES];

  [_pcomms send: [NSString stringWithFormat: @"button Press %@", keyName] to: self.serviceName];
  [self notifyDelegates: SERVICE_SECURITY_DISPLAY_TEXT_CHANGED];
}

- (void) releaseKeypadKey: (NSString *) keyName
{
  if ([keyName isEqualToString: @"#"])
    keyName = @"%23";
  
  [_buttonHoldTimer invalidate];
  _buttonHoldTimer = nil;
  
  [_pcomms send: [NSString stringWithFormat: @"button Release %@", keyName] to: self.serviceName];
}

- (void) holdTimerFired: (NSTimer *) timer
{
  [_pcomms send: [NSString stringWithFormat: @"button Hold %@", timer.userInfo] to: self.serviceName];  
}

#if LOCAL_CONTROL_OF_DISPLAY
- (void) displayClearTimerFired: (NSTimer *) timer
{
  _displayClearTimer = nil;
  [_displayText release];
  _displayText = nil;
  [self notifyDelegates: SERVICE_SECURITY_DISPLAY_TEXT_CHANGED];
}
#endif

- (void) pushButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
  if (controlMode == 0)
    [_pcomms send: @"BUTTON PRESS" to: [NSString stringWithFormat: @"%@~%u", self.serviceName, buttonIndex + 1]];
}

- (void) releaseButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode
{
  if (controlMode == 0)
    [_pcomms send: @"BUTTON RELEASE" to: [NSString stringWithFormat: @"%@~%u", self.serviceName, buttonIndex + 1]];
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  if ([[data objectForKey: @"type"] isEqualToString: @"state"])
  {
    NSRange subNodeStr = [source rangeOfString: @"~" options: NSBackwardsSearch];
    NSUInteger changed = 0;

    if ([source hasPrefix: self.serviceName] && subNodeStr.length > 0)
    {
      NSUInteger subNode = [[source substringFromIndex: NSMaxRange( subNodeStr )] integerValue];
      
      if (subNode > 0)
      {
        NSString *visibleStr = [data objectForKey: @"visible"];
        NSString *enabledStr = [data objectForKey: @"enabled"];
        NSString *indicatorStateStr = [data objectForKey: @"indicatorState"];
        NSString *label = [data objectForKey: @"label"];
        NSUInteger flags;

        if (_controlModes == nil)
        {
          NSUInteger capacity = 8;
          
          if (subNode > capacity)
            capacity = subNode;
          
          _controlModes = [CONTROL_MODES retain];
          _controlModeTitles = [[NSMutableArray arrayWithObject: [NSMutableArray arrayWithCapacity: capacity]] retain];
          _controlModeStates = [[NSMutableArray arrayWithObject: [NSMutableArray arrayWithCapacity: capacity]] retain];
          changed |= SERVICE_SECURITY_MODES_CHANGED;
        }
        
        NSMutableArray *titles = [_controlModeTitles objectAtIndex: 0];
        NSMutableArray *states = [_controlModeStates objectAtIndex: 0];
        NSUInteger count = [titles count];
        
        if (subNode > count)
        {
          NSUInteger i;
          
          for (i = count; i < subNode; ++i)
          {
            [titles addObject: @""];
            [states addObject: [NSNumber numberWithInteger: 0]];
          }
          changed |= SERVICE_SECURITY_MODE_STATES_CHANGED|SERVICE_SECURITY_MODE_TITLES_CHANGED;
        }
        --subNode;
        
        flags = [[states objectAtIndex: subNode] integerValue];
        
        if (visibleStr != nil)
        {
          BOOL visible = [visibleStr isEqualToString: @"1"];
          
          if (visible ^ ((flags & SERVICE_SECURITY_STATE_VISIBLE) != 0))
          {
            flags ^= SERVICE_SECURITY_STATE_VISIBLE;
            changed |= SERVICE_SECURITY_MODE_STATES_CHANGED;
          }
        }
        
        if (enabledStr != nil)
        {
          BOOL enabled = [enabledStr isEqualToString: @"1"];
          
          if (enabled ^ ((flags & SERVICE_SECURITY_STATE_ENABLED) != 0))
          {
            flags ^= SERVICE_SECURITY_STATE_ENABLED;
            changed |= SERVICE_SECURITY_MODE_STATES_CHANGED;
          }
        }
        
        if (indicatorStateStr != nil)
        {
          NSUInteger newFlags = (flags & ~(SERVICE_SECURITY_STATE_HAS_INDICATOR|SERVICE_SECURITY_STATE_INDICATOR_ON));
          BOOL hasIndicator = ![[indicatorStateStr lowercaseString] isEqualToString: @"none"]; 
          BOOL indicatorState = [indicatorStateStr isEqualToString: @"1"];
          
          if (hasIndicator)
          {
            newFlags |= SERVICE_SECURITY_STATE_HAS_INDICATOR;
            if (indicatorState)
              newFlags |= SERVICE_SECURITY_STATE_INDICATOR_ON;
          }
          
          if (newFlags != flags)
          {
            flags = newFlags;
            changed |= SERVICE_SECURITY_MODE_STATES_CHANGED;
          }
        }
        
        if ((changed & SERVICE_SECURITY_MODE_STATES_CHANGED) != 0)
          [states replaceObjectAtIndex: subNode withObject: [NSNumber numberWithInteger: flags]];
        
        if (label != nil && ![label isEqualToString: [titles objectAtIndex: subNode]])
        {
          [titles replaceObjectAtIndex: subNode withObject: label];
          changed |= SERVICE_SECURITY_MODE_TITLES_CHANGED;
        }
      }

      if (changed)
        [self notifyDelegatesOfButton: subNode inControlMode: 0 changed: changed];
    }
    else if ([source compare: self.serviceName options: NSCaseInsensitiveSearch] == NSOrderedSame)
    {
      NSString *errorMessage = [data objectForKey: @"ErrorMessage"];
      NSString *display = [data objectForKey: @"Display"];
      
      if (errorMessage != nil && ([errorMessage length] > 0 || ![errorMessage isEqualToString: _errorMessage]))
      {
        [_errorMessage release];
        _errorMessage = [errorMessage retain];
        changed |= SERVICE_SECURITY_ERROR_MESSAGE_CHANGED;
        if ([errorMessage length] > 0)
          [_comms send: @"set ClearError" to: self.serviceName];
      }
      
      if (display != nil && ![display isEqualToString: _displayText])
      {
        [_displayText release];
        _displayText = [display retain];
        changed |= SERVICE_SECURITY_DISPLAY_TEXT_CHANGED;
      }
    }
    
    if (changed)
      [self notifyDelegates: changed];
  }
}

@end
