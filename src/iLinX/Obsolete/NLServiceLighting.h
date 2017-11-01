//
//  NLServiceLighting.h
//  iLinX
//
//  Created by mcf on 29/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetStreamsComms.h"
#import "NLService.h"

#define SERVICE_LIGHTING_INDICATOR_CHANGED 0x0001
#define SERVICE_LIGHTING_NAME_CHANGED      0x0002

@class NLServiceLighting;

@protocol NLServiceLightingDelegate <NSObject>
- (void) service: (NLServiceLighting *) service button: (NSUInteger) button changed: (NSUInteger) changed;
@end


@interface NLServiceLighting : NLService <NetStreamsMsgDelegate>
{
@private
  NSMutableArray *_buttons;
  NSMutableSet *_delegates;
  id _statusRspHandle;
  id _registerMsgHandle;
  id _queryMsgHandle;
  NSTimer *_holdTimer;
}

- (void) addDelegate: (id<NLServiceLightingDelegate>) delegate;
- (void) removeDelegate: (id<NLServiceLightingDelegate>) delegate;

- (NSUInteger) buttonCount;
- (void) pushButton: (NSUInteger) buttonIndex;
- (void) releaseButton: (NSUInteger) buttonIndex;
- (NSString *) nameForButton: (NSUInteger) buttonIndex;
- (BOOL) indicatorPresentOnButton: (NSUInteger) buttonIndex;
- (BOOL) indicatorStateForButton: (NSUInteger) buttonIndex;

@end
