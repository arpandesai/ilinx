//
//  NLServiceGenericIR.m
//  iLinX
//
//  Created by mcf on 10/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLServiceGenericIR.h"

// If we don't receive a response to our menu list message, assume a comms problem and retry
// after this interval (seconds).  See NLBrowseList.m for more comments.
#define NO_COMMS_RETRY_INTERVAL 5

@implementation NLServiceGenericIR

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  if (![messageType isEqualToString: @"MENU_RESP"] || ![[data objectForKey: @"responseType"] isEqualToString: @"preset"])
    [super received: comms messageType: messageType from: source to: destination data: data];
  else
  {
    if ([[data objectForKey: @"itemnum"] isEqualToString: @"-1"])
    {
      // End of list.  Notify any listeners of the change in buttons and then 
      // deregister from any further responses.  Notify the buttons in reverse
      // order so that if the screen needs to be revised for a new number of
      // buttons, this is done only once.
      
      NSUInteger count = [_buttons count];
      NSUInteger i;
      
      for (i = count; i > 0; --i)
        [self notifyDelegatesOfButton: i - 1 changed: SERVICE_GENERIC_NAME_CHANGED];

      [_comms deregisterDelegate: _menuRspHandle];
      _menuRspHandle = nil;
      [_comms cancelSendEvery: _menuMsgHandle];
      _menuMsgHandle = nil;
    }
    else
    {
      NSString *presetId = [data objectForKey: @"id"];
      NSUInteger count = [_buttons count];
      NSUInteger i;
      
      for (i = 0; i < count; ++i)
      {
        NSDictionary *button = [_buttons objectAtIndex: i];
        
        if ([[button objectForKey: @"id"] isEqualToString: presetId])
          break;
      }
      
      if (i == count)
        [_buttons addObject: data];
    }
  }
}

- (void) registerForNetStreams
{
  if ([_buttons count] == 0)
  {
    //NSLog( @"Register" );
    _menuRspHandle = [_comms registerDelegate: self forMessage: @"MENU_RESP" from: self.serviceName];
    _menuMsgHandle = [_comms send: @"MENU_LIST 1,1000,{{presets}}" to: self.serviceName every: NO_COMMS_RETRY_INTERVAL];
  }

  [super registerForNetStreams];  
}

- (void) deregisterFromNetStreams
{
  [super deregisterFromNetStreams];
  
  //NSLog( @"Deregister" );
  if (_menuRspHandle != nil)
  {
    [_comms deregisterDelegate: _menuRspHandle];
    _menuRspHandle = nil;
  }
  //NSLog( @"Cancel send every" );
  if (_menuMsgHandle != nil)
  {
    [_comms cancelSendEvery: _menuMsgHandle];
    _menuMsgHandle = nil;
  }
}

@end
