//
//  NLServiceGeneric.h
//  iLinX
//
//  Created by mcf on 10/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetStreamsComms.h"
#import "NLService.h"

#define SERVICE_GENERIC_INDICATOR_CHANGED 0x0001
#define SERVICE_GENERIC_NAME_CHANGED      0x0002

@class NLServiceGeneric;

@protocol NLServiceGenericDelegate <NSObject>
- (void) service: (NLServiceGeneric *) service button: (NSUInteger) button changed: (NSUInteger) changed;
@end


@interface NLServiceGeneric : NLService <NetStreamsMsgDelegate>
{
@protected
  NSMutableDictionary *_waitingForStatus;
  NSMutableArray *_buttons;
  NSMutableSet *_delegates;
  NSTimer *_holdTimer;
  id _statusRspHandle;
  id _registerMsgHandle;
  id _queryMsgHandle;
}

- (void) addDelegate: (id<NLServiceGenericDelegate>) delegate;
- (void) removeDelegate: (id<NLServiceGenericDelegate>) delegate;

- (NSUInteger) buttonCount;
- (void) pushButton: (NSUInteger) buttonIndex;
- (void) releaseButton: (NSUInteger) buttonIndex;
- (NSString *) nameForButton: (NSUInteger) buttonIndex;
- (BOOL) indicatorPresentOnButton: (NSUInteger) buttonIndex;
- (BOOL) indicatorStateForButton: (NSUInteger) buttonIndex;

// Used by derived classes
- (void) notifyDelegatesOfButton: (NSUInteger) button changed: (NSUInteger) changed;
- (void) registerForNetStreams;
- (void) deregisterFromNetStreams;

@end
