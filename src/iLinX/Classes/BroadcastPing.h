//
//  BroadcastPing.h
//  iLinX
//
//  Created by mcf on 28/03/2011.
//  Copyright 2011 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
#import <CFNetwork/CFNetwork.h>
#else
#import <CoreServices/CoreServices.h>
#endif

#include <AssertMacros.h>

#pragma mark * BroadcastPing

@protocol BroadcastPingDelegate;

@interface BroadcastPing : NSObject
{
  NSData *_hostAddress;
  CFHostRef _host;
  CFSocketRef _socket;
  
  id<BroadcastPingDelegate>  _delegate;
  uint16_t _identifier;                            // host byte order
  uint16_t _nextSequenceNumber;                    // host byte order
}

+ (BroadcastPing *) broadcastPingWithLocalAddress: (NSString *) localAddress netMask: (NSString *) netMask;

@property (nonatomic, assign, readwrite) id<BroadcastPingDelegate> delegate;

@property (nonatomic, assign, readonly)  uint16_t identifier;
@property (nonatomic, assign, readonly)  uint16_t nextSequenceNumber;

- (void) start;
// Starts the pinger object pinging.  You should call this after 
// you've setup the delegate and any ping parameters.

- (BOOL) sendPingWithData: (NSData *) data;
// Sends an actual ping.  Pass nil for data to use a standard 56 byte payload (resulting in a 
// standard 64 byte ping).  Otherwise pass a non-nil value and it will be appended to the 
// ICMP header.
//
// Do not try to send a ping before you receive the -broadcastPing: didStartWithAddress: delegate 
// callback.

- (void) stop;
// Stops the pinger object.  You should call this when you're done 
// pinging.

+ (const struct ICMPHeader *) icmpInPacket: (NSData *) packet;
// Given a valid IP packet contains an ICMP , returns the address of the ICMP header that 
// follows the IP header.  This doesn't do any significant validation of the packet.

@end

@protocol BroadcastPingDelegate <NSObject>

@optional

- (void) broadcastPing: (BroadcastPing *) pinger didStartWithAddress: (NSData *) address;
// Called after the BroadcastPing has successfully started up.  After this callback, you 
// can start sending pings via -sendPingWithData:

- (void) broadcastPing: (BroadcastPing *) pinger didFailWithError: (NSError *) error;
// If this is called, the BroadcastPing object has failed.  By the time this callback is 
// called, the object has stopped (that is, you don't need to call -stop yourself).

// IMPORTANT: On the send side the packet does not include an IP header. 
// On the receive side, it does.  In that case, use +[BroadcastPing icmpInPacket:] 
// to find the ICMP header within the packet.

- (void) broadcastPing: (BroadcastPing *) pinger didSendPacket: (NSData *) packet;
// Called whenever the BroadcastPing object has successfully sent a ping packet. 

- (void) broadcastPing: (BroadcastPing *) pinger didFailToSendPacket: (NSData *) packet error: (NSError *) error;
// Called whenever the BroadcastPing object tries and fails to send a ping packet.

- (void) broadcastPing: (BroadcastPing *) pinger didReceivePingResponsePacket: (NSData *) packet;
// Called whenever the BroadcastPing object receives an ICMP packet that looks like 
// a response to one of our pings (that is, has a valid ICMP checksum, has 
// an identifier that matches our identifier, and has a sequence number in 
// the range of sequence numbers that we've sent out).

- (void) broadcastPing: (BroadcastPing *) pinger didReceiveUnexpectedPacket: (NSData *) packet;
// Called whenever the BroadcastPing object receives an ICMP packet that does not 
// look like a response to one of our pings.

@end

#pragma mark * IP and ICMP On-The-Wire Format

// The following declarations specify the structure of ping packets on the wire.

// IP header structure:

struct IPHeader
{
  uint8_t     versionAndHeaderLength;
  uint8_t     differentiatedServices;
  uint16_t    totalLength;
  uint16_t    identification;
  uint16_t    flagsAndFragmentOffset;
  uint8_t     timeToLive;
  uint8_t     protocol;
  uint16_t    headerChecksum;
  uint8_t     sourceAddress[4];
  uint8_t     destinationAddress[4];
  // options...
  // data...
};
typedef struct IPHeader IPHeader;

__Check_Compile_Time(sizeof(IPHeader) == 20);
__Check_Compile_Time(offsetof(IPHeader, versionAndHeaderLength) == 0);
__Check_Compile_Time(offsetof(IPHeader, differentiatedServices) == 1);
__Check_Compile_Time(offsetof(IPHeader, totalLength) == 2);
__Check_Compile_Time(offsetof(IPHeader, identification) == 4);
__Check_Compile_Time(offsetof(IPHeader, flagsAndFragmentOffset) == 6);
__Check_Compile_Time(offsetof(IPHeader, timeToLive) == 8);
__Check_Compile_Time(offsetof(IPHeader, protocol) == 9);
__Check_Compile_Time(offsetof(IPHeader, headerChecksum) == 10);
__Check_Compile_Time(offsetof(IPHeader, sourceAddress) == 12);
__Check_Compile_Time(offsetof(IPHeader, destinationAddress) == 16);

// ICMP type and code combinations:
enum
{
  kICMPTypeEchoReply   = 0,           // code is always 0
  kICMPTypeEchoRequest = 8            // code is always 0
};

// ICMP header structure:

struct ICMPHeader
{
  uint8_t     type;
  uint8_t     code;
  uint16_t    checksum;
  uint16_t    identifier;
  uint16_t    sequenceNumber;
  // data...
};
typedef struct ICMPHeader ICMPHeader;

__Check_Compile_Time(sizeof(ICMPHeader) == 8);
__Check_Compile_Time(offsetof(ICMPHeader, type) == 0);
__Check_Compile_Time(offsetof(ICMPHeader, code) == 1);
__Check_Compile_Time(offsetof(ICMPHeader, checksum) == 2);
__Check_Compile_Time(offsetof(ICMPHeader, identifier) == 4);
__Check_Compile_Time(offsetof(ICMPHeader, sequenceNumber) == 6);
