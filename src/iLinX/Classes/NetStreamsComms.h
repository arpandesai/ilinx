//
//  NetStreamsComms.h
//  iLinX
//
//  Created by mcf on 19/12/2008.
//  Copyright 2008 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DebugTracing.h"

//DEFINITIONS:

#if defined(DEMO_BUILD)
# define NETSTREAMSCOMMS_PRODUCTION_ONLY(x) ((NetStreamsComms *) nil)
#else
# define NETSTREAMSCOMMS_PRODUCTION_ONLY(x) x
#endif

//CLASSES:

@class BroadcastPing;
@class FindRenderer;
@class NetStreamsComms;

//ERRORS:

NSString * const NetStreamsErrorDomain;

typedef enum
  {
    kNetStreamsCouldNotConnectToIPv4Address = 1,
    kNetStreamsCannotResolveHostName = 2,
    kNetStreamsNoSocketsAvailable = 3,
    kNetStreamsConnectTimedOut = 4,
    kNetStreamsSendFailed = 5,
    kNetStreamsConnectionClosed = 6,
    kNetStreamsCannotJoinMulticast = 7,
    kNetStreamsNetworkUnavailable = 8,
    kNetStreamsUnexpectedHTTPResponse = 9,
  } iLinXErrorCode;

//PROTOCOLS:

@protocol NetStreamsCommsDelegate <NSObject>
@optional
- (void) connected: (NetStreamsComms *) comms;
- (void) disconnected: (NetStreamsComms *) comms error: (NSError *) error;
- (void) receivedRaw: (NetStreamsComms *) comms data: (NSString *) netStreamsResponse;
- (void) discoveredService: (NetStreamsComms *) comms address: (NSString *) deviceAddress
                   netmask: (NSString *) netmask type: (NSString *) type
                   version: (NSString *) version name: (NSString *) name
                    permId: (NSString *) permId room: (NSString *) room;
- (void) discoveryComplete: (NetStreamsComms *) comms error: (NSError *) result;
@end

@protocol NetStreamsMsgDelegate <NSObject>

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data;

@end

//CLASS INTERFACES:

@interface NetStreamsComms : NSDebugObject
{
@public
  NSUInteger _magic;
@private
  id _delegate;
  NSString *_deviceAddress;
  CFSocketRef _ipv4socket;
  CFRunLoopSourceRef _ipv4source;
  NSString *_discoveryAddress;
  uint16_t _discoveryPort;
  CFSocketRef _discoverySocket;
  CFRunLoopSourceRef _discoverySource;
  NSString *_localAddress;
  NSString *_localNetMask;
  NSTimer *_connectTimer;
  NSTimer *_discoveryTimer;
  uint8_t _aliveFlag;
  BOOL _terminated;
  CFMutableDataRef _buffer;
  NSMutableDictionary *_listeners;
  NSMutableArray *_timedMessages;
  NSTimer *_timedMessagesTimer;
  NSMutableArray *_messageQueue;
  NSMutableArray *_messagesDuringNoConnection;
  BOOL _discoverOnRestart;
  BroadcastPing *_broadcastPing;
  FindRenderer *_findRenderer;
}

- (void) connect: (NSString *) device;
- (void) disconnect;
- (NSString *) connectedDeviceAddress;
- (void) discoverWithAddress: (NSString *) discoveryAddress andPort: (uint16_t) discoveryPort;
- (void) cancelDiscovery;
- (void) sendRaw: (NSString *) netStreamsCommand;
- (void) send: (NSString *) message to: (NSString *) destination;
- (id) send: (NSString *) message to: (NSString *) destination every: (NSTimeInterval) seconds;
- (void) cancelSendEvery: (id) handle;
- (id) registerDelegate: (id<NetStreamsMsgDelegate>) delegate
             forMessage: (NSString *) messageType from: (NSString *) source;
- (id) registerDelegate: (id<NetStreamsMsgDelegate>) delegate
             forMessage: (NSString *) messageType to: (NSString *) destination;
- (id) registerDelegate: (id<NetStreamsMsgDelegate>) delegate
             forMessage: (NSString *) messageType from: (NSString *) source to: (NSString *) destination;
- (void) deregisterDelegate: (id) handle;

// Assign a delegate to receive notifications of connection, disconnection and
// data received from the connected device.
@property(assign) id<NetStreamsCommsDelegate> delegate;

@end
