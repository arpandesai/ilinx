//
//  NLServiceSecurity.h
//  iLinX
//
//  Created by mcf on 18/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetStreamsComms.h"
#import "NLService.h"

#define SERVICE_SECURITY_ERROR_MESSAGE_CHANGED 0x0001
#define SERVICE_SECURITY_MODES_CHANGED         0x0002
#define SERVICE_SECURITY_MODE_TITLES_CHANGED   0x0004
#define SERVICE_SECURITY_MODE_STATES_CHANGED   0x0008
#define SERVICE_SECURITY_MODE_VISIBLE_CHANGED  0x0010
#define SERVICE_SECURITY_MODE_ENABLED_CHANGED  0x0020
#define SERVICE_SECURITY_DISPLAY_TEXT_CHANGED  0x0040

@class NLServiceSecurity;

@protocol NLServiceSecurityDelegate <NSObject>
@optional
- (void) service: (NLServiceSecurity *) service changed: (NSUInteger) changed;
- (void) service: (NLServiceSecurity *) service controlMode: (NSUInteger) controlMode
          button: (NSUInteger) button changed: (NSUInteger) changed;
@end

// Capabilities
#define SERVICE_SECURITY_HAS_CLEAR_ENTER      0x0001
#define SERVICE_SECURITY_HAS_STAR_HASH        0x0002
#define SERVICE_SECURITY_HAS_POLICE           0x0004
#define SERVICE_SECURITY_HAS_FIRE             0x0008
#define SERVICE_SECURITY_HAS_AMBULANCE        0x0010
#define SERVICE_SECURITY_HAS_CUSTOM_MODES     0x0020

// Control mode types
#define SERVICE_SECURITY_MODE_TYPE_BUTTONS    1
#define SERVICE_SECURITY_MODE_TYPE_LIST       2

// Control mode button states
#define SERVICE_SECURITY_STATE_VISIBLE        0x0001
#define SERVICE_SECURITY_STATE_ENABLED        0x0002
#define SERVICE_SECURITY_STATE_HAS_INDICATOR  0x0004
#define SERVICE_SECURITY_STATE_INDICATOR_ON   0x0008

@interface NLServiceSecurity : NLService <NetStreamsMsgDelegate>
{
@protected
  NSMutableSet *_delegates;
  NSUInteger _capabilities;
  NSArray *_controlModes;
  NSMutableArray *_controlModeTitles;
  NSMutableArray *_controlModeStates;
  id _statusRspHandle;
  id _registerMsgHandle;
  id _queryMsgHandle;
  NSString *_displayText;
  NSString *_errorMessage;
}

@property (readonly) NSUInteger capabilities;
@property (readonly) NSArray *controlModes;
@property (readonly) NSArray *controlModeTitles;
@property (readonly) NSString *errorMessage;
@property (readonly) NSString *displayText;

- (void) addDelegate: (id<NLServiceSecurityDelegate>) delegate;
- (void) removeDelegate: (id<NLServiceSecurityDelegate>) delegate;

- (void) pressKeypadKey: (NSString *) keyName;
- (void) releaseKeypadKey: (NSString *) keyName;
- (NSUInteger) buttonCountInControlMode: (NSUInteger) controlMode;
- (NSUInteger) styleForControlMode: (NSUInteger) controlMode;
- (NSString *) nameForButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode;
- (BOOL) isVisibleButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode;
- (BOOL) isEnabledButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode;
- (BOOL) indicatorPresentOnButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode;
- (BOOL) indicatorStateForButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode;
- (void) pushButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode;
- (void) releaseButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode;

// Used by derived classes
- (void) notifyDelegates: (NSUInteger) changed;
- (void) notifyDelegatesOfButton: (NSUInteger) button inControlMode: (NSUInteger) controlMode changed: (NSUInteger) changed;
- (void) registerForNetStreams;
- (void) deregisterFromNetStreams;

@end
