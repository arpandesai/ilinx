	//
//  NetStreamsComms.m
//  iLinX
//
//  Created by mcf on 19/12/2008.
//  Copyright 2008-9 Micropraxis Ltd. All rights reserved.
//

#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/ip.h>
//#include <netinet/igmp.h>
#include <netinet/tcp.h>	
#include <arpa/inet.h>
#include <ifaddrs.h>
#include <netdb.h>
#include <unistd.h>
#include <CFNetwork/CFSocketStream.h>

#include <sys/param.h>
#include <sys/file.h>
#include <sys/sysctl.h>

#include <net/if.h>
#include <net/if_dl.h>
#include "if_ether.h"
#include "if_types.h"
#include "route.h"


#import "AppStateNotification.h"
#import "BroadcastPing.h"
#import "FindRenderer.h"
#import "NetStreamsComms.h"
#import "ResponseXmlParser.h"
#include "StringEncoding.h"

#if defined(DEBUG)
// Set to 1 to log raw message traffic
#  define LOG_TRAFFIC 1
// Set to 1 to ignore heartbeat and music status messages when logging traffic
#  define LOG_TRAFFIC_IGNORE_HEARTBEAT 1
#  define LOG_TRAFFIC_IGNORE_PLAYER_STATUS 0
#  define LOG_LOW_LEVEL 0
#  define LOG_CREATION 0
#  define LOG_DISCOVERY 1
#endif
#  define LOG_DISCOVERY 1

static void NetStreamsSocketCallBack( CFSocketRef s, CFSocketCallBackType callbackType,
                                        CFDataRef address, const void *data, void *info );
static void DiscoverySocketCallBack( CFSocketRef s, CFSocketCallBackType callbackType,
                                     CFDataRef address, const void *data, void *info );
//static void SendIGMPv2Join( struct ip_mreq *pMReq );

// Time in seconds allowed for setting up the discovery multicast
#define MULTICAST_CONNECT_TIMEOUT 1

// Time in seconds allowed for joining the discovery multicast group
#define MULTICAST_GROUP_JOIN_DELAY 3

// Maximum time in seconds to wait for a response to a discovery message
#define MULTICAST_DISCOVERY_TIMEOUT 30

// Number of times we send the discovery message during discovery
#define MULTICAST_DISCOVERY_REPEAT_COUNT 3

// Time in seconds to try to connect to the device before timing out
#define DEVICE_CONNECT_TIMEOUT 10

// Time in seconds between sending a heartbeat message to keep the connection open
#define DEVICE_HEARTBEAT_INTERVAL 1

// Default time in seconds to wait for a response to a message
#define MESSAGE_TIMEOUT_INTERVAL 3

// Maximum amount of time in seconds we can wait before we *must* send a ping
// to avoid NetStreams closing down the connection
#define MAXIMUM_DEVICE_HEARTBEAT_INTERVAL 20

// Time in seconds to wait for a data send to complete
#define DEVICE_SEND_TIMEOUT 0.2

// Time in seconds to wait for the next MENU_RESP in a sequence
#define NEXT_MENU_RESP_INTERVAL 0.2

// The port on which all iLinX devices respond for ASCII commands
#define NETSTREAMS_ASCII_PORT 15000

// Standard broadcast address to use for discovery messages (as well as the
// user defined multicast address)
#define IPV4_BROADCAST_ADDR 0xFFFFFFFF

// The maximum length of a iLinX ASCII message
#define MAX_MSG_LENGTH 1000

// Discovery message magic tag
#define DISCOVERY_MAGIC             0xcdab

// Discovery message item data types
#define DISCOVERY_DATA_TYPE_INT     0x00
#define DISCOVERY_DATA_TYPE_STRING  0x01
#define DISCOVERY_DATA_TYPE_BUNDLE  0x02

// Discovery message item types
#define DISCOVERY_DATA_IP_ADDRESS   0x0000
#define DISCOVERY_DATA_PERM_ID      0x0002
#define DISCOVERY_DATA_NAME         0x0003
#define DISCOVERY_DATA_ROOM         0x0004  // except for service type "root", where this is a duplicate of the permid
#define DISCOVERY_DATA_SERVICETYPE  0x0005
#define DISCOVERY_DATA_VERSION      0x000f
#define DISCOVERY_DATA_NETMASK      0x0010

#define COMMS_MAGIC 0xda783fc2

NSString * const NetStreamsErrorDomain = @"NetStreamsErrorDomain";

// Local class for recording message delegates
@interface MsgDelegate : NSObject
{
  NSString *_messageType;
  id<NetStreamsMsgDelegate> _delegate;
}

@property (nonatomic, retain) NSString *messageType;
@property (assign) id<NetStreamsMsgDelegate> delegate;

@end

@implementation MsgDelegate

@synthesize
  messageType = _messageType,
  delegate = _delegate;

- (id) initWithType: (NSString *) type delegate: (id<NetStreamsMsgDelegate>) delegate
{
  if ((self = [super init]) != nil)
  {
    self.messageType = type;
    self.delegate = delegate;
  }
  
  return self;
}

- (void) dealloc
{
  [_messageType release];
  [super dealloc];
}

@end

// Local class for recording timed messages
@interface TimedMessage : NSObject
{
  NSString *_message;
  NSTimeInterval _interval;
  NSDate *_nextSendTime;
}

@property (nonatomic, retain) NSString *message;
@property (assign) NSTimeInterval interval;
@property (nonatomic, retain) NSDate *nextSendTime;

@end

@implementation TimedMessage

@synthesize
  message = _message,
  interval = _interval,
  nextSendTime = _nextSendTime;

- (id) initWithMessage: (NSString *) message interval: (NSTimeInterval) interval
{
  if ((self = [super init]) != nil)
  {
    self.message = message;
    self.interval = interval;
    self.nextSendTime = [NSDate dateWithTimeIntervalSinceNow: interval];
  }
  
  return self;
}

- (void) setNextInterval
{
  self.nextSendTime = [NSDate dateWithTimeIntervalSinceNow: _interval];
}

- (NSComparisonResult) compare: (TimedMessage *) other
{
  return [_nextSendTime compare: other.nextSendTime];
}

- (void) dealloc
{
  [_message release];
  [_nextSendTime release];
  [super dealloc];
}

@end


// Private properties and methods
@interface NetStreamsComms ()
@property (nonatomic,retain) NSString* deviceAddress;
@property (assign) CFSocketRef ipv4socket;

+ (NSString *) formatMessage: (NSString *) message to: (NSString *) destination;
- (void) queueOrSendRaw: (NSString *) message;
- (void) queueOrSendRaw: (NSString *) message timeout: (NSTimeInterval) timeout;
- (void) resetTimedMessages;
- (void) timedMessageTimerFired: (NSTimer *) timer;
- (void) initialiseConnection;
- (void) doConnect;
- (NSString *) idPathFrom: (NSString *) string;
- (void) receivedData: (CFDataRef) data;
- (void) dispatchMessage: (NSString *) message;
- (void) handleNoConnection: (NSError *) error;
- (void) connectTimerFired: (NSTimer *) timer;
- (void) discoveryData: (CFDataRef) data;
- (void) discoveryComplete: (NSError *) error;
- (void) discoveryTimeoutFired: (NSTimer *) timer;
- (void) applicationToForeground;
- (void) applicationToBackground;

@end

@implementation NetStreamsComms

@synthesize
  delegate = _delegate,
  deviceAddress = _deviceAddress,
  ipv4socket = _ipv4socket;

- (id) init
{
  if ((self = [super init]) != nil)
  {
#if LOG_CREATION
    NSLog( @"NetStreamsComms created: %@", self );
#endif
    _magic = COMMS_MAGIC;
    _buffer = CFDataCreateMutable( kCFAllocatorDefault, 0 );
    _aliveFlag = 0;
    _ipv4socket = NULL;
    _ipv4source = NULL;
    _discoverySocket = NULL;
    _discoverySource = NULL;
    _connectTimer = nil;
    _terminated = NO;
    _delegate = nil;
    _deviceAddress = nil;
    _listeners = [NSMutableDictionary new];
    _timedMessages = [NSMutableArray new];
    _messageQueue = [NSMutableArray new];
    _messagesDuringNoConnection = [NSMutableArray new];
  }
  
  [AppStateNotification addWillEnterForegroundObserver: self selector: @selector(applicationToForeground)];
  [AppStateNotification addDidEnterBackgroundObserver: self selector: @selector(applicationToBackground)];

  return self;
}

- (void) dealloc
{
#if LOG_CREATION
  NSLog( @"NetStreamsComms destroyed: %@", self );
#endif
  
  [AppStateNotification removeObserver: self];

  _magic = 0;
  [self disconnect];

  if (_buffer != NULL)
    CFRelease( _buffer );
  
  [_listeners release];
  [_timedMessages release];
  [_messageQueue release];
  [_messagesDuringNoConnection release];
  [_discoveryAddress release];
  [_localAddress release];
  [_localNetMask release];
  [_findRenderer release];
  [_broadcastPing release];
  [super dealloc];
}

- (void) connect: (NSString *) deviceAddress
{
  self.deviceAddress = deviceAddress;
  _terminated = FALSE;
  [self doConnect];
  
  _connectTimer = [NSTimer
                   scheduledTimerWithTimeInterval: (NSTimeInterval) DEVICE_HEARTBEAT_INTERVAL
                   target: self selector: @selector(connectTimerFired:) userInfo: nil repeats: TRUE];
}

- (void) disconnect
{
  _terminated = TRUE;
  if (_connectTimer != nil)
  {
    [_connectTimer invalidate];
    _connectTimer = nil;
  }
  
  if (_discoveryTimer != nil)
  {
    if ([_discoveryTimer isValid])
      [_discoveryTimer invalidate];
    [_discoveryTimer release];
    _discoveryTimer = nil;
  }

  [self handleNoConnection: nil];
  if (_discoverySocket != NULL)
    [self discoveryComplete: nil];
}

- (NSString *) connectedDeviceAddress
{
  return _deviceAddress;
}

- (void) discoverWithAddress: (NSString *) discoveryAddress andPort: (uint16_t) discoveryPort
{
  CFSocketContext socketCtxt = { 0, self, NULL, NULL, NULL };
  NSError *pError = NULL;
  
#if LOG_DISCOVERY
  NSLog( @"NetStreamComms %@: starting discovery on: %@:%u", self, discoveryAddress, discoveryPort );
#endif
  [_discoveryAddress release];
  _discoveryAddress = [discoveryAddress retain];
  [_localAddress release];
  _localAddress = nil;
  [_localNetMask release];
  _localNetMask = nil;
  _discoveryPort = discoveryPort;
  _discoverySocket = CFSocketCreate( kCFAllocatorDefault, PF_INET, SOCK_DGRAM, IPPROTO_UDP, 
    kCFSocketDataCallBack, (CFSocketCallBack) &DiscoverySocketCallBack, &socketCtxt );
  
  if (_discoverySocket == NULL)
  {
#if LOG_DISCOVERY
    NSLog( @"NetStreamComms %@: failed to create discovery socket", self );
#endif
    // Signal end of discovery with error
    pError = [[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                          code: kNetStreamsNoSocketsAvailable
                                    userInfo: [NSDictionary dictionaryWithObject: NSLocalizedString( @"No resources to connect to network",
                                                                                          @"Error shown if unable to create a socket" )
                                                                forKey: NSLocalizedDescriptionKey]];
  }
  else
  {
#if LOG_DISCOVERY
    NSLog( @"NetStreamComms %@: created discovery socket", self );
#endif
    int yes = 1;
    struct sockaddr_in addr4;
    const char *pDiscovery = [discoveryAddress UTF8String];
    
    setsockopt( CFSocketGetNative( _discoverySocket ), SOL_SOCKET, SO_REUSEADDR, (void *) &yes, sizeof(yes) );
    setsockopt( CFSocketGetNative( _discoverySocket ), SOL_SOCKET, SO_NOSIGPIPE, (void *) &yes, sizeof(yes) );
    
#if LOG_DISCOVERY
    NSLog( @"NetStreamComms %@: set discovery socket re-use option", self );
#endif
    memset( &addr4, 0, sizeof(addr4) );
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons( NETSTREAMS_ASCII_PORT );
    addr4.sin_addr.s_addr = inet_addr( pDiscovery );
    
    if (addr4.sin_addr.s_addr == INADDR_NONE)
    {
#if LOG_DISCOVERY
      NSLog( @"NetStreamComms %@: resolving discovery socket address", self );
#endif
      struct hostent *pHost = gethostbyname( pDiscovery );
      
      if (pHost == NULL)
      {
#if LOG_DISCOVERY
        NSLog( @"NetStreamComms %@: unable to discovery socket address", self );
#endif
        pError = [[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                            code: kNetStreamsCannotResolveHostName
                                        userInfo: [NSDictionary dictionaryWithObject: NSLocalizedString( @"Unable to resolve broadcast address",
                                                                                              @"Error shown if unable to resolve address given in broadcast address setting" )
                                                                    forKey: NSLocalizedDescriptionKey]];
      }
      else
      {
#if LOG_DISCOVERY
        NSLog( @"NetStreamComms %@: resolved discovery socket address", self );
#endif
        memcpy( &addr4.sin_addr, pHost->h_addr_list[0], pHost->h_length );
      }
    }
    
    if (pError == NULL)
    {
      struct ip_mreq mreq;
      int multicastAdd;
      int broadcastAdd;
      
#if LOG_DISCOVERY
      NSLog( @"NetStreamComms %@: enabling (%d) broadcast on discovery socket", self, yes );
#endif
      broadcastAdd = setsockopt( CFSocketGetNative( _discoverySocket ), SOL_SOCKET, SO_BROADCAST, (void *) &yes, sizeof(yes) );

      memset( &mreq, 0, sizeof(mreq) );
      memcpy( &mreq.imr_multiaddr, &addr4.sin_addr, sizeof(addr4.sin_addr) );
      mreq.imr_interface.s_addr = INADDR_ANY;
      //SendIGMPv2Join( &mreq );
#if LOG_DISCOVERY
      NSLog( @"NetStreamComms %@: enable broadcast returned %d; adding discovery socket to multicast group: %d.%d.%d.%d", self, 
            broadcastAdd, mreq.imr_multiaddr.s_addr&0xFF, (mreq.imr_multiaddr.s_addr>>8)&0xFF,
            (mreq.imr_multiaddr.s_addr>>16)&0xFF, (mreq.imr_multiaddr.s_addr>>24)&0xFF );
#endif
      multicastAdd = setsockopt( CFSocketGetNative( _discoverySocket ), IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq, sizeof(mreq) );
      
#if LOG_DISCOVERY
      NSLog( @"NetStreamComms %@: discovery init multicast: %d, broadcast: %d", self, multicastAdd, broadcastAdd );
#endif

      if (multicastAdd < 0 && broadcastAdd < 0)
        pError = [[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                            code: kNetStreamsCannotJoinMulticast
                                        userInfo: [NSDictionary dictionaryWithObject: NSLocalizedString( @"Not allowed to broadcast",
                                                                                              @"Error shown if unable to join a multicast group" )
                                                                    forKey: NSLocalizedDescriptionKey]];
    }
    
    if (pError == NULL)
    {
      // Set ourselves to receive on the discovery announcement port.  Theoretically we shouldn't need
      // to go through this rigamarole of registering for multicast receive on a specific port because
      // replies should be sent to any arbitrary address specified in the SOLICIT message, however some
      // older systems ignore this and only send their replies on the pre-defined discovery address
      // and port.  Hence this.
      struct sockaddr_in localAddr;
      NSData *localAddrData;
      
      memset( &localAddr, 0, sizeof(localAddr) );
      localAddr.sin_len = sizeof(localAddr);
      localAddr.sin_family = AF_INET;
      localAddr.sin_port = htons( discoveryPort );
      localAddr.sin_addr.s_addr = INADDR_ANY;
      localAddrData = [NSData dataWithBytes: &localAddr length: sizeof(localAddr)];
      
#if LOG_DISCOVERY
      NSLog( @"NetStreamComms %@: setting discovery socket local address", self );
#endif
      if (CFSocketSetAddress( _discoverySocket, (CFDataRef) localAddrData ) != kCFSocketSuccess)
      {
#if LOG_DISCOVERY
        NSLog( @"NetStreamComms %@: failed to set discovery socket local address", self );
#endif
        pError = [[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                            code: kNetStreamsCannotJoinMulticast
                                        userInfo: [NSDictionary dictionaryWithObject: NSLocalizedString( @"Unable to receive broadcast",
                                                                                              @"Error shown if unable to list on the specified broadcast port" )
                                                                    forKey: NSLocalizedDescriptionKey]];
      }
      else if (_localAddress == nil)
      {
        struct ifaddrs *interfaces = NULL;
        struct ifaddrs *temp_addr = NULL;
#if TARGET_IPHONE_SIMULATOR
        struct ifaddrs *wired_addr = NULL;
#endif
        int success = getifaddrs( &interfaces );
        
        if (success == 0)
        {
          for (temp_addr = interfaces; temp_addr != NULL; temp_addr = temp_addr->ifa_next)
          {
            if (temp_addr->ifa_addr->sa_family == AF_INET)
            {
              // Check if interface is en0 which is the wifi connection on the iPhone
#if TARGET_IPHONE_SIMULATOR
              if ([[NSString stringWithUTF8String: temp_addr->ifa_name] isEqualToString: @"en1"])
#else
              if ([[NSString stringWithUTF8String: temp_addr->ifa_name] isEqualToString: @"en0"])
#endif
              {
                _localAddress = [[NSString stringWithUTF8String: inet_ntoa( ((struct sockaddr_in *) temp_addr->ifa_addr)->sin_addr )] retain];
                _localNetMask = [[NSString stringWithUTF8String: inet_ntoa( ((struct sockaddr_in *) temp_addr->ifa_netmask)->sin_addr )] retain];
                break;
              }
#if TARGET_IPHONE_SIMULATOR
              else if ([[NSString stringWithUTF8String: temp_addr->ifa_name] isEqualToString: @"en0"])
                wired_addr = temp_addr;
#endif
            }
          }
          
#if TARGET_IPHONE_SIMULATOR
          if ((_localAddress == nil || _localNetMask == nil) && wired_addr != NULL)
          {
            _localAddress = [[NSString stringWithUTF8String: inet_ntoa( ((struct sockaddr_in *) wired_addr->ifa_addr)->sin_addr )] retain];
            _localNetMask = [[NSString stringWithUTF8String: inet_ntoa( ((struct sockaddr_in *) wired_addr->ifa_netmask)->sin_addr )] retain];      
          }
#endif
        }
        
        freeifaddrs( interfaces );
      }
    }

    // Trap the case of WiFi being switched off.  We can't discover if that's the case
    if (pError == NULL && (_localAddress == nil || _localNetMask == nil))
    {
      pError = [[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                          code: kNetStreamsNetworkUnavailable
                                      userInfo: [NSDictionary dictionaryWithObject: NSLocalizedString( @"No network available for discovery (is WiFi disabled?)",
                                                                                                      @"Error shown if WiFi appears to be unavailable" )
                                                                            forKey: NSLocalizedDescriptionKey]];
    }

    if (pError == NULL)
    {
      NSData *address4 = [NSData dataWithBytes: &addr4 length: sizeof(addr4)];

#if LOG_DISCOVERY
      NSLog( @"NetStreamComms %@: adding discovery socket to run loop", self );
#endif
      // All OK, set up the run loop sources for the socket
      CFRunLoopRef cfrl = CFRunLoopGetCurrent();
      
      _discoverySource = CFSocketCreateRunLoopSource( kCFAllocatorDefault, _discoverySocket, 0 );
      CFRunLoopAddSource( cfrl, _discoverySource, kCFRunLoopCommonModes );
      CFRelease( _discoverySource );
      _discoverySource = NULL;
      
#if LOG_DISCOVERY
      NSLog( @"NetStreamComms %@: creating and starting broadcast ping object", self );
#endif
      _broadcastPing = [[BroadcastPing broadcastPingWithLocalAddress: _localAddress netMask: _localNetMask] retain];
      [_broadcastPing start];
      [_broadcastPing sendPingWithData: nil];
      
#if LOG_DISCOVERY
      NSLog( @"NetStreamComms %@: ready for discovery on: %@:%u", self, discoveryAddress, discoveryPort );
#endif
      // Set up a timer to start discovery after waiting for a bit to be sure we've joined the multicast
      // group OK
      
      _discoveryTimer = [[NSTimer
                         scheduledTimerWithTimeInterval: (NSTimeInterval) MULTICAST_GROUP_JOIN_DELAY
                         target: self selector: @selector(sendDiscoveryTimeoutFired:) 
                         userInfo: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    address4, @"addr", 
                                    [NSNumber numberWithInt: MULTICAST_DISCOVERY_REPEAT_COUNT], @"count", nil]
                         repeats: FALSE] retain];
    }
  }

  if (pError != NULL)
  {
    [self discoveryComplete: pError];
    [pError release];
  }
}

- (BOOL) _sendDiscoveryMessageTo: (id) discoveryAddress respondTo: (NSString *) address
{
  NSString *discoveryMsg = [NSString stringWithFormat: @"#@ALL:AFRIEND#SOLICIT %@,%u,ALL",
                            address, (unsigned int) _discoveryPort];
  CFIndex msgLength = [discoveryMsg lengthOfBytesUsingEncoding: NSUTF8StringEncoding];
  CFMutableDataRef message = CFDataCreateMutable( kCFAllocatorDefault, msgLength + 1 );
  uint8_t nul = 0;
  struct sockaddr_in broadcastAddr;
  CFSocketError broadcastResult;
  CFSocketError multicastResult;
  
  memset( &broadcastAddr, 0, sizeof(broadcastAddr) );
  broadcastAddr.sin_len = sizeof(broadcastAddr);
  broadcastAddr.sin_family = AF_INET;
  broadcastAddr.sin_port = htons( NETSTREAMS_ASCII_PORT );
  broadcastAddr.sin_addr.s_addr = IPV4_BROADCAST_ADDR;
  
  CFDataAppendBytes( message, (const uint8_t *) [discoveryMsg UTF8String], msgLength );
  CFDataAppendBytes( message, &nul, 1 );
  
#if LOG_DISCOVERY
  NSLog( @"NetStreamComms %@: sending discovery messages with response address: %@", self, address );
#endif
  
  broadcastResult = CFSocketSendData( _discoverySocket, 
                                     (CFDataRef) [NSData dataWithBytes: &broadcastAddr length: sizeof(broadcastAddr)],
                                     message, DEVICE_SEND_TIMEOUT );
  multicastResult = CFSocketSendData( _discoverySocket, (CFDataRef) discoveryAddress, message, DEVICE_SEND_TIMEOUT );
  
#if LOG_DISCOVERY
  NSLog( @"NetStreamComms %@: sent discovery messages (broadcast: %ld, multicast: %ld)", self, broadcastResult, multicastResult );
#endif
  
  CFRelease( message );

  return (broadcastResult == kCFSocketSuccess || multicastResult == kCFSocketSuccess);
}

- (NSArray *) _netstreamsDevices
{
  NSMutableArray *devices = [NSMutableArray arrayWithCapacity: 16];
  int mib[6];
  size_t needed;
  char *lim, *buf;
  
  mib[0] = CTL_NET;
  mib[1] = PF_ROUTE;
  mib[2] = 0;
  mib[3] = AF_INET;
  mib[4] = NET_RT_FLAGS;
  mib[5] = RTF_LLINFO;
  
  if (sysctl( mib, 6, NULL, &needed, NULL, 0 ) >= 0)
  {
    if ((buf = malloc( needed )) != NULL)
    {
      if (sysctl( mib, 6, buf, &needed, NULL, 0 ) >= 0)
      {
        struct rt_msghdr *rtm;

        lim = buf + needed;
        for (char *next = buf; next < lim; next += rtm->rtm_msglen)
        {
          rtm = (struct rt_msghdr *) next;
          struct sockaddr_inarp *sin = (struct sockaddr_inarp *) (rtm + 1);
          struct sockaddr_dl *sdl = (struct sockaddr_dl *) (sin + 1);

          if (sdl->sdl_alen > 0)
          {
            uint32_t ipaddr = ntohl( sin->sin_addr.s_addr );
            u_char *mac = (u_char *) LLADDR( sdl );
            
            //NSLog( @"%x:%x:%x:%x:%x:%x -> %@", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5], [devices lastObject] );

            // NetStreams MAC address.  Add to front of list as most likely candidates
            if (mac[0] == 0x00 && mac[1] == 0x11 && mac[2] == 0x61)
              [devices insertObject: [NSString stringWithFormat: @"%u.%u.%u.%u",
                                     (ipaddr >> 24) & 0xFF, (ipaddr >> 16) & 0xFF, (ipaddr >> 8) & 0xFF, ipaddr & 0xFF]
               atIndex: 0];

            // ClearOne MAC address.  Add to end of list just in case ClearOne switch to
            // using their vendor code in future.
            else if (mac[0] == 0x00 && mac[1] == 0x90 && mac[2] == 0x79)
              [devices addObject: [NSString stringWithFormat: @"%u.%u.%u.%u",
                                   (ipaddr >> 24) & 0xFF, (ipaddr >> 16) & 0xFF, (ipaddr >> 8) & 0xFF, ipaddr & 0xFF]];
          }
        }
      }
      
      free( buf );
    }
  }
  
  return devices;
}

- (void) sendDiscoveryTimeoutFired: (NSTimer *) timer
{
#if LOG_DISCOVERY
  NSLog( @"NetStreamComms %@: send discovery timeout fired", self );
#endif
  [_discoveryTimer release];
  _discoveryTimer = nil;

  if (_findRenderer == nil)
  {
    NSArray *netstreamsDevices = [self _netstreamsDevices];
    // Attempt to find a SpeakerLinX this way
    
    if ([netstreamsDevices count] > 0)
      _findRenderer = [[FindRenderer alloc] initWithParent: self address: [netstreamsDevices objectAtIndex: 0]
                                            defaultNetMask: _localNetMask delegate: _delegate];
  }

  // and send the discovery message
  NSMutableDictionary *userInfo = (NSMutableDictionary *) [timer userInfo];
  BOOL multicastResponse = [self _sendDiscoveryMessageTo: [userInfo objectForKey: @"addr"] respondTo: _discoveryAddress];
  BOOL unicastResponse = (_localAddress != nil && [self _sendDiscoveryMessageTo: [userInfo objectForKey: @"addr"] respondTo: _localAddress]);
  BOOL broadcastPingResponse = [_broadcastPing sendPingWithData: nil];
    
  if (multicastResponse || unicastResponse || broadcastPingResponse || _findRenderer != nil)
  {
    int count = [[userInfo objectForKey: @"count"] intValue] - 1;
      
    if (count <= 0)
    {
      _discoveryTimer = [[NSTimer
                         scheduledTimerWithTimeInterval: (NSTimeInterval) (MULTICAST_DISCOVERY_TIMEOUT / MULTICAST_DISCOVERY_REPEAT_COUNT)
                         target: self selector: @selector(discoveryTimeoutFired:) userInfo: nil repeats: FALSE] retain];
    }
    else
    {
      [userInfo setObject: [NSNumber numberWithInt: count] forKey: @"count"];
      _discoveryTimer = [[NSTimer
                         scheduledTimerWithTimeInterval: (NSTimeInterval) (MULTICAST_DISCOVERY_TIMEOUT / MULTICAST_DISCOVERY_REPEAT_COUNT)
                         target: self selector: @selector(sendDiscoveryTimeoutFired:) userInfo: userInfo repeats: FALSE] retain];
    }
  }
  else
  {
    // Report the completion (and failure) of discovery
      
    NSError *error = [[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                                code: kNetStreamsSendFailed 
                                            userInfo: [NSDictionary 
                                                       dictionaryWithObject: NSLocalizedString( @"Failed to send broadcast",
                                                                                               @"Error shown if unable to send the broadcast message" )
                                                       forKey: NSLocalizedDescriptionKey]];
    
    [self discoveryComplete: error];
    [error release];
  }
}

- (void) cancelDiscovery
{
#if LOG_DISCOVERY
  NSLog( @"NetStreamComms %@: discovery cancelled", self );
#endif
  // Cancel discovery by forcing early firing of the timeout
  [self discoveryTimeoutFired: _discoveryTimer];
}

- (void) sendRaw: (NSString *) netStreamsCommand
{
  if (!_terminated)
  {
    if (_ipv4socket == NULL)
    {
#if LOG_TRAFFIC
#if LOG_TRAFFIC_IGNORE_HEARTBEAT
      if ([netStreamsCommand rangeOfString: @"PING"].length == 0)
#endif
        NSLog( @"Queuing to send later: %@", netStreamsCommand );
#endif
      [_messagesDuringNoConnection addObject: netStreamsCommand];
    }
    else
    {
#if LOG_TRAFFIC
#if LOG_TRAFFIC_IGNORE_HEARTBEAT
      if ([netStreamsCommand rangeOfString: @"PING"].length == 0)
#endif
        NSLog( @"Sending: %@", netStreamsCommand );
#endif
      CFIndex msgLength = [netStreamsCommand lengthOfBytesUsingEncoding: NSUTF8StringEncoding];
      uint8_t nul = 0;
      CFMutableDataRef message = CFDataCreateMutable( kCFAllocatorDefault, msgLength + 1 );
      
      CFDataAppendBytes( message, (const uint8_t *) [netStreamsCommand UTF8String], msgLength );
      CFDataAppendBytes( message, &nul, 1 );
      
      // And send it off
      // TODO: Pass the error code as user info.
      CFSocketError err = CFSocketSendData( _ipv4socket, NULL, message, DEVICE_SEND_TIMEOUT );
      
      if (err == kCFSocketSuccess)
      {
        // Now only reset _aliveFlag on successful receipt of data as we can have a valid socket
        // that is blocked at the other end due to retries.  Sending #PING as the heartbeat
        // message ensures that we have a regular supply of received messages.
        //_aliveFlag = 0;
      }
      else
      {
        [self handleNoConnection: [[[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                                              code: kNetStreamsSendFailed
                                                          userInfo: [NSDictionary dictionaryWithObject: NSLocalizedString( @"Unable to send message", @"Error shown if unable to send a NetStreams message" )
                                                                                                forKey: NSLocalizedDescriptionKey]] autorelease]];
      }
      
      CFRelease( message );
    }
  }
}

- (void) send: (NSString *) message to: (NSString *) destination
{
  [self queueOrSendRaw: [NetStreamsComms formatMessage: message to: destination]];
}

- (id) send: (NSString *) message to: (NSString *) destination every: (NSTimeInterval) seconds
{
  NSString *rawMessage = [NetStreamsComms formatMessage: message to: destination];
  TimedMessage *timedMessage = [[TimedMessage alloc] initWithMessage: rawMessage interval: seconds];
  NSTimeInterval timeout = (seconds - 1);
  
  if (timeout < MESSAGE_TIMEOUT_INTERVAL)
    timeout = MESSAGE_TIMEOUT_INTERVAL;

  // Send immediately and then queue to be sent again after the specified interval
  [self queueOrSendRaw: rawMessage timeout: timeout];
  [_timedMessages addObject: timedMessage];
  [_timedMessages sortUsingSelector: @selector(compare:)];
  [timedMessage release];
  [self resetTimedMessages];
  
  return timedMessage;
}

- (void) cancelSendEvery: (id) handle
{
  TimedMessage *timedMsg = (TimedMessage *) handle;
  NSUInteger count = [_messageQueue count];
  NSUInteger i;
  
  // If we haven't yet sent this message, don't!
  for (i = 1; i < count; ++i)
  {
    if ([[[_messageQueue objectAtIndex: i] objectAtIndex: 0] isEqualToString: timedMsg.message])
    {
      [_messageQueue removeObjectAtIndex: i];
      break;
    }
  }
  
  [_timedMessages removeObjectIdenticalTo: handle];
}

- (id) registerDelegate: (id<NetStreamsMsgDelegate>) delegate
             forMessage: (NSString *) messageType from: (NSString *) source
{
  return [self registerDelegate: delegate forMessage: messageType from: source to: @"*"];
}

- (id) registerDelegate: (id<NetStreamsMsgDelegate>) delegate
             forMessage: (NSString *) messageType to: (NSString *) destination
{
  return [self registerDelegate: delegate forMessage: messageType from: @"*" to: destination];
}

- (id) registerDelegate: (id<NetStreamsMsgDelegate>) delegate
             forMessage: (NSString *) messageType from: (NSString *) source to: (NSString *) destination
{
  NSString *key = [NSString stringWithFormat: @"%@:%@:%@", source, destination, messageType];
  MsgDelegate *msgDelegate = [[MsgDelegate alloc] initWithType: key delegate: delegate];
  NSMutableArray *listenersForThisMessage = [_listeners objectForKey: key];
  
  if (listenersForThisMessage != nil)
    [listenersForThisMessage addObject: msgDelegate];
  else
  {
    listenersForThisMessage = [NSMutableArray arrayWithObject: msgDelegate];
    [_listeners setValue: listenersForThisMessage forKey: key];
  }
  
  [msgDelegate release];
  
  return msgDelegate;
}

- (void) deregisterDelegate: (id) handle
{
  if (handle != nil)
  {
    // Retain needed to avoid key being invalidated when handle is disposed of
    NSString *key = [((MsgDelegate *) handle).messageType retain];
    NSMutableArray *listenersForThisMessage = [_listeners objectForKey: key];
  
    if (key != nil && listenersForThisMessage != nil)
    {
      [listenersForThisMessage removeObjectIdenticalTo: handle];
      if ([listenersForThisMessage count] == 0)
        [_listeners removeObjectForKey: key];
    }
    
    [key release];
  }
}

// Local private methods

+ (NSString *) formatMessage: (NSString *) message to: (NSString *) destination
{
  if (destination == nil)
    return [NSString stringWithFormat: @"#%@", message];
  else
    return [NSString stringWithFormat: @"#@%@#%@", destination, message];
}

// At least some iLinX devices cannot cope with having more than one list request outstanding
// so we check for whether this is a list related message and queue it for sending later if there
// is already a list message being processed.
- (void) queueOrSendRaw: (NSString *) message
{
  [self queueOrSendRaw: message timeout: MESSAGE_TIMEOUT_INTERVAL];
}

- (void) queueOrSendRaw: (NSString *) message timeout: (NSTimeInterval) timeout
{
  //NSLog( @"Request send: %@", message );
  if ([message rangeOfString: @"MENU_LIST"].length == 0)
    [self sendRaw: message];
  else
  {
    NSUInteger count = [_messageQueue count];
    NSUInteger timeoutRepeatCount = 0;
    NSArray *msg;
    
    while (timeout > MAXIMUM_DEVICE_HEARTBEAT_INTERVAL)
    {
      ++timeoutRepeatCount;
      timeout -= MAXIMUM_DEVICE_HEARTBEAT_INTERVAL;
    }

    msg = [NSMutableArray arrayWithObjects: 
           message, 
           [NSNumber numberWithDouble: timeout],
           [NSNumber numberWithUnsignedInteger: timeoutRepeatCount],
           nil];

    if (count == 0)
    {      
      [_messageQueue addObject: msg];
      [self sendRaw: message];
      // Use heartbeat timer to handle this request timing out 
      [_connectTimer setFireDate: [NSDate dateWithTimeIntervalSinceNow: timeout]];
    }
    else
    {
      NSUInteger i;
      
      for (i = 1; i < count; ++i)
      {
        if ([[[_messageQueue objectAtIndex: i] objectAtIndex: 0] isEqualToString: message])
          break;
      }
      if (i == count)
        [_messageQueue addObject: msg];
    }
  }
}

// Start / reset timed messages
- (void) resetTimedMessages
{
  if ([_timedMessages count] > 0)
  {
    NSDate *nextSendTime = ((TimedMessage *) [_timedMessages objectAtIndex: 0]).nextSendTime;
    
    if (![_timedMessagesTimer isValid] ||
      [nextSendTime compare: [_timedMessagesTimer fireDate]] != NSOrderedAscending)
    {
      NSTimeInterval timeToNextFire = [nextSendTime timeIntervalSinceNow];
      
      if (timeToNextFire <= 0)
        [self timedMessageTimerFired: nil];
      else
      {
        if ([_timedMessagesTimer isValid])
          [_timedMessagesTimer invalidate];
        [_timedMessagesTimer release];
        _timedMessagesTimer = [[NSTimer scheduledTimerWithTimeInterval: timeToNextFire
          target: self selector: @selector(timedMessageTimerFired:) userInfo: nil repeats: FALSE] retain];
      }
    }
  }
}

- (void) timedMessageTimerFired: (NSTimer *) timer
{
#if LOG_LOW_LEVEL
  NSLog( @"NetStreamsComms timedMessageTimerFired: %@", self );
#endif
  NSUInteger count = [_timedMessages count];

  if (count == 0)
  {
    if ([_timedMessagesTimer isValid])
      [_timedMessagesTimer invalidate];
    [_timedMessagesTimer release];
    _timedMessagesTimer = nil;
  }
  else
  {
    NSUInteger i;
    NSDate *nextSendTime;
  
    for (i = 0; i < count; ++i)
    {
      TimedMessage *timedMessage = (TimedMessage *) [_timedMessages objectAtIndex: i];
    
      nextSendTime = timedMessage.nextSendTime;
      //NSLog( @"Checking timed message: %@ to be sent at %d",
      //      timedMessage.message, [nextSendTime timeIntervalSinceNow] );
      
      if ([nextSendTime timeIntervalSinceNow] > 0)
        break;
      else
      {
        [self queueOrSendRaw: timedMessage.message];
        [timedMessage setNextInterval];
      }
    }
  
    if (i != count)
      [_timedMessages sortUsingSelector: @selector(compare:)];
    nextSendTime = ((TimedMessage *) [_timedMessages objectAtIndex: 0]).nextSendTime;
  
    if ([_timedMessagesTimer isValid])
      [_timedMessagesTimer invalidate];
    [_timedMessagesTimer release];
    _timedMessagesTimer = [[NSTimer scheduledTimerWithTimeInterval: [nextSendTime timeIntervalSinceNow]
      target: self selector: @selector(timedMessageTimerFired:) userInfo: nil repeats: FALSE] retain];
  }
}

- (void) doConnect
{
  CFSocketContext socketCtxt = { 0, self, NULL, NULL, NULL };
  NSError *pError = NULL;
  CFSocketRef socket;

  socket = CFSocketCreate( kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, 
                               kCFSocketConnectCallBack|kCFSocketDataCallBack,
                               (CFSocketCallBack) &NetStreamsSocketCallBack, &socketCtxt );
  
  if (socket == NULL)
    pError = [[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                        code: kNetStreamsNoSocketsAvailable
                                    userInfo: [NSDictionary dictionaryWithObject: NSLocalizedString( @"No resources to connect to network",
                                                                                          @"Error shown if unable to create a socket" )
                                                                forKey: NSLocalizedDescriptionKey]];
  else
  {
    int yes = 1;
    struct sockaddr_in addr4;
    const char *pDevice = [[self deviceAddress] UTF8String];
    
    setsockopt( CFSocketGetNative( socket ), SOL_SOCKET, SO_REUSEADDR, (void *) &yes, sizeof(yes) );
    setsockopt( CFSocketGetNative( socket ), SOL_SOCKET, SO_KEEPALIVE, (void *) &yes, sizeof(yes) );
    setsockopt( CFSocketGetNative( socket ), SOL_SOCKET, SO_NOSIGPIPE, (void *) &yes, sizeof(yes) );
    setsockopt( CFSocketGetNative( socket ), IPPROTO_TCP, TCP_NODELAY, (void *) &yes, sizeof(yes) );
    
    memset( &addr4, 0, sizeof(addr4) );
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons( NETSTREAMS_ASCII_PORT );
    addr4.sin_addr.s_addr = inet_addr( pDevice );
    
    if (addr4.sin_addr.s_addr == INADDR_NONE)
    {
      struct hostent *pHost = gethostbyname( pDevice );
      
      if (pHost == NULL)
        pError = [[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                            code: kNetStreamsCannotResolveHostName 
                                        userInfo: [NSDictionary dictionaryWithObject: NSLocalizedString( @"Cannot resolve direct connect host name",
                                                                                              @"Error shown if unable to resolve a host name" )
                                                                    forKey: NSLocalizedDescriptionKey]];
      else
        memcpy( &addr4.sin_addr, pHost->h_addr_list[0], pHost->h_length );
    }
    
    if (pError == NULL)
    {
      NSData *address4 = [NSData dataWithBytes: &addr4 length: sizeof(addr4)];
      
      // TODO: Pass the error code as user info.
      if (CFSocketConnectToAddress( socket, (CFDataRef) address4, -DEVICE_CONNECT_TIMEOUT ) != kCFSocketSuccess)
        pError = [[NSError alloc] initWithDomain: NetStreamsErrorDomain 
                                            code: kNetStreamsCouldNotConnectToIPv4Address
                                        userInfo: [NSDictionary dictionaryWithObject: [NSString stringWithFormat: 
                                                                             NSLocalizedString( @"Unable to connect to %s",
                                                                                               @"Error shown if unable to connect to chosen NetStreams device" ),
                                                                             pDevice]
                                                                    forKey: NSLocalizedDescriptionKey]];
      else
      {
        // All OK, set up the run loop sources for the socket
        CFRunLoopRef cfrl = CFRunLoopGetCurrent();
        
        _ipv4source = CFSocketCreateRunLoopSource( kCFAllocatorDefault, socket, 0 );
        CFRunLoopAddSource( cfrl, _ipv4source, kCFRunLoopCommonModes );
        CFRelease( _ipv4source );
        _ipv4source = NULL;
      }
    }
  }
  
  if (pError != NULL)
  {
    if (socket != NULL)
    {
      CFSocketInvalidate( socket );
      CFRelease( socket );
    }

    [self handleNoConnection: pError];
    [pError release];
  }
}

// Connection failed for reason given by error.  Clean up and try again later.
- (void) handleNoConnection: (NSError *) error
{
  // Failed to connect to the device.  Report the problem, wait a bit and then try again.
  if (_ipv4socket != NULL)
  {
    if (_ipv4source != NULL)
    {
      CFRunLoopRef cfrl = CFRunLoopGetCurrent();
      
      CFRunLoopRemoveSource( cfrl, _ipv4source, 0 );
      CFRelease( _ipv4source );
      _ipv4source = NULL;
    }
    
    CFSocketInvalidate( _ipv4socket );
    CFRelease( _ipv4socket );
    _ipv4socket = NULL;        
#if LOG_TRAFFIC
    NSLog( @"%@: Disconnected from: %@", self, [self deviceAddress] );
#endif
  }
  
  if (_timedMessagesTimer != nil)
  {
    if ([_timedMessagesTimer isValid])
      [_timedMessagesTimer invalidate];
    [_timedMessagesTimer release];
    _timedMessagesTimer = nil;
  }
  
  if (_delegate != nil)
  {
    if ([_delegate respondsToSelector: @selector(disconnected:error:)])
      [_delegate disconnected: self error: error];
  }
}

// Delay between connection attempts has expired.  Retry connecting.
- (void) connectTimerFired: (NSTimer *) timer
{
#if LOG_LOW_LEVEL
  NSLog( @"NetStreamsComms connectTimerFired: %@", self );
#endif
  if (_terminated)
  {
    [timer invalidate];
    _connectTimer = nil;    
  }
  else if (_ipv4socket == NULL)
  {
    [self doConnect];    
  }
  else if (!CFSocketIsValid( _ipv4socket ) || ++_aliveFlag >= 2)
  {
    [self handleNoConnection: [[[NSError alloc]
                               initWithDomain: NetStreamsErrorDomain 
                               code: kNetStreamsConnectionClosed 
                               userInfo: [NSDictionary dictionaryWithObject: NSLocalizedString( @"Timed out trying to connect",
                                                                                     @"Error shown if unable to connect to a device" )
                                                           forKey: NSLocalizedDescriptionKey]] autorelease]];
        
    // Then try to connect again
    
    [self doConnect];
  }
  else
  {
    // Keep the connection alive.  If there is a list message queued, we've timed out
    // waiting for the response, so remove it.  Then by preference, send the next waiting
    // list message or just a heartbeat message to keep things alive if nothing else
    // is waiting.
    BOOL stillWaiting = NO;
    NSTimeInterval pingInterval = DEVICE_HEARTBEAT_INTERVAL;

    if ([_messageQueue count] > 0)
    {
      NSMutableArray *msg = [_messageQueue objectAtIndex: 0];
      NSUInteger timeoutRepeatCount = [[msg objectAtIndex: 2] unsignedIntegerValue];

      if (timeoutRepeatCount == 0)
        [_messageQueue removeObjectAtIndex: 0];
      else
      {
        [msg replaceObjectAtIndex: 2 withObject: [NSNumber numberWithUnsignedInteger: timeoutRepeatCount - 1]];
        pingInterval = [[msg objectAtIndex: 1] doubleValue];
        stillWaiting = YES;
      }
    }

    if ([_messageQueue count] > 0 && !stillWaiting)
    {
      NSArray *msg = [_messageQueue objectAtIndex: 0];

      [self sendRaw: [msg objectAtIndex: 0]];
      pingInterval = [[msg objectAtIndex: 1] doubleValue];
    }

    // Always send the ping - the MENU_LIST messages are not a reliable indicator of the general
    // connection status as they may fail either due to the driver being stuck or the host SpeakerLinX
    // being broken, which isn't the same as our SpeakerLinX being unresponsive.
    [self sendRaw: @"#PING"];
    [_connectTimer setFireDate: [NSDate dateWithTimeIntervalSinceNow: pingInterval]];
  }
}

- (void) initialiseConnection
{
#if LOG_TRAFFIC
  NSLog( @"%@: Connected to: %@", self, [self deviceAddress] );
#endif
  _aliveFlag = 0;
   
  for (NSString *message in _messagesDuringNoConnection)
    [self sendRaw: message];
  [_messagesDuringNoConnection removeAllObjects];
  // Just in case any of the outstanding messages was a MENU_LIST, give it a reasonable time
  // to respond
  [_connectTimer setFireDate: [NSDate dateWithTimeIntervalSinceNow: MESSAGE_TIMEOUT_INTERVAL]];

  if (_delegate != nil)
  {
    if ([_delegate respondsToSelector: @selector(connected:)])
      [_delegate connected: self];
  }
  
  [self resetTimedMessages];
}

- (NSString *) idPathFrom: (NSString *) string
{
  NSString *path = nil;

  if ([string rangeOfString: @"MENU_LIST"].length > 0)
  {
    NSRange start = [string rangeOfString: @"{{"];
    
    if (start.length == 0)
    {
      NSArray *components = [string componentsSeparatedByString: @","];
      
      path = [components lastObject];
    }
    else
    {
      start.location += start.length;
      start.length = [string length] - start.location;
      
      NSRange end = [string rangeOfString: @"}}" options: 0 range: start];
      
      if (end.length > 0)
        path = [string substringWithRange: NSMakeRange( start.location, end.location - start.location )];      
    }
  }
  else
  {
    NSRange start = [string rangeOfString: @"idpath=\""];
    
    if (start.length > 0)
    {
      start.location += start.length;
      start.length = [string length] - start.location;
      
      NSRange end = [string rangeOfString: @"\"" options: 0 range: start];
      
      if (end.length > 0)
        path = [string substringWithRange: NSMakeRange( start.location, end.location - start.location )];
    }
  }
  
  path = [path lowercaseString];
  
  return path;
}

- (void) receivedData: (CFDataRef) data
{
  [self retain];
  _aliveFlag = 0;
  
  //NSLog( @"Received %u bytes", CFDataGetLength( data ) );
  
  if (_buffer != NULL && !_terminated)
  {
    const uint8_t *pData = CFDataGetBytePtr( data );
    CFIndex len = CFDataGetLength( data );
    CFIndex i = 0;
    CFIndex msgBegin = -1;
    CFIndex cmdBegin = -1;
    CFIndex msgEnd = -1;
    
    if (CFDataGetLength( _buffer ) != 0)
    {
      CFDataAppendBytes( _buffer, pData, len );
      pData = CFDataGetBytePtr( _buffer );
      len = CFDataGetLength( _buffer );
    }
    
    while (i < len)
    {
      // Find a valid message; that is, #@...#...\0
      for ( ; i < len; ++i)
      {
        if (msgBegin == -1)
        {
          if (i + 1 < len && pData[i] == '#' && pData[i+1] == '@')
            msgBegin = i;
        }
        else if (cmdBegin == -1)
        {
          if (pData[i] == '#')
            cmdBegin = i;
          else if (pData[i] == 0)
            msgBegin = -1;
        }
        else if (pData[i] == 0)
        {
          msgEnd = i++;
          break;
        }
      }
      
      if (msgEnd != -1)
      {
        CFIndex msgLength = msgEnd + 1 - msgBegin;
        
        if (msgLength <= MAX_MSG_LENGTH)
        {
          // We have an apparently valid message.  Convert to a string and send to our delegate(s).
#if LOG_TRAFFIC
          if (1
#if LOG_TRAFFIC_IGNORE_PLAYER_STATUS
              && (strstr( (char *) pData + msgBegin, "<report type=\"source\"" ) == NULL)
#endif
#if LOG_TRAFFIC_IGNORE_HEARTBEAT
              && (strstr( (char *) pData + msgBegin, "#PONG 0" ) == NULL)
#endif
               )
          NSLog( @"Received: %s", pData + msgBegin );
#endif
          if ([_delegate respondsToSelector: @selector(receivedRaw:data:)] ||
              [_listeners count] > 0 || [_messageQueue count] > 0)
          {
            CFStringEncoding guessEncoding = StringEncodingFor( pData + msgBegin, msgLength );
            CFStringRef string = CFStringCreateWithBytes( kCFAllocatorDefault, pData + msgBegin, msgLength - 1, 
                                                         guessEncoding, FALSE );
            
            // Maybe guessed wrong?
            if (string == NULL && guessEncoding == kCFStringEncodingUTF8)
              string = CFStringCreateWithBytes( kCFAllocatorDefault, pData + msgBegin, msgLength - 1, 
                                               kCFStringEncodingWindowsLatin1, FALSE );
            
            // Still NULL; a memory problem or a corrupt message
            if (string != NULL)
            {
              NSString *nsString = (NSString *) string;
              NSString *idPath = [self idPathFrom: nsString];
              
              //NSLog( @"Received: %@", nsString );
              
              if ([_messageQueue count] > 0 && [nsString rangeOfString: @"MENU_RESP"].length > 0 &&
                  ([idPath isEqualToString: [self idPathFrom: (NSString *) [[_messageQueue objectAtIndex: 0] objectAtIndex: 0]]] ||
                   [idPath isEqualToString: @"menu error"]))
              {
                NSMutableArray *msg = [_messageQueue objectAtIndex: 0];

                // Got a response to a menu request; ask for the next menu request to be sent in
                // 0.2 seconds. This request time is reset each time we receive a MENU_RESP (which
                // generally happens in under 0.2 seconds) so the result is we shouldn't send out
                // the next MENU_LIST until all the responses to the previous one have arrived.
                if (msg != nil)
                {
                  [msg replaceObjectAtIndex: 1 withObject: [NSNumber numberWithDouble: NEXT_MENU_RESP_INTERVAL]];
                  [msg replaceObjectAtIndex: 2 withObject: [NSNumber numberWithUnsignedInteger: 0]];
                }
                [_connectTimer setFireDate: [NSDate dateWithTimeIntervalSinceNow: NEXT_MENU_RESP_INTERVAL]];
              }
              if ([_delegate respondsToSelector: @selector(receivedRaw:data:)])
                [_delegate receivedRaw: self data: nsString];
              if ([_listeners count] > 0)
                [self dispatchMessage: nsString];
              CFRelease( string );
            }
          }
        }
        
        msgBegin = -1;
        cmdBegin = -1;
        msgEnd = -1;
      }
    } // while (i < len)
    
    // Just in case we have a message split over multiple packets where the next message
    // is starting on the last byte of the current packet.
    
    if (msgBegin == -1 && len > 0 && pData[len-1] == '#')
      msgBegin = len - 1;
    
    if (msgBegin == -1)
    {
      // All data dealt with; reset the overflow buffer
      CFDataSetLength( _buffer, 0 );
    }
    else
    {
      // Place any unprocessed data in the buffer, to be prepended to the
      // next packet that is received.
      
      if (CFDataGetLength( _buffer ) == 0)
        CFDataAppendBytes( _buffer, pData + msgBegin, len - msgBegin );
      else
        CFDataReplaceBytes( _buffer, CFRangeMake( 0, CFDataGetLength( _buffer ) ), pData + msgBegin, len - msgBegin );
    }
  }
  [self release];
}

- (void) dispatchMessage: (NSString *) message
{
  // Parse data
  if ([message hasPrefix: @"#@"])
  {
    NSRange restOfString = NSMakeRange( 2, [message length] - 2 );
    NSRange fromAddressStart = [message rangeOfString: @":" options: 0 range: restOfString];
    NSRange messageStart = [message rangeOfString: @"#" options: 0 range: restOfString];

    if (fromAddressStart.length != 0 && messageStart.length != 0 && 
        messageStart.location > fromAddressStart.location)
    {
      NSInteger fromAddressLength = messageStart.location - (fromAddressStart.location + 1);
      NSRange optionsStart = [message rangeOfString: @"%" options: 0 range: 
                              NSMakeRange( fromAddressStart.location, fromAddressLength )];

      if (optionsStart.length > 0)
        fromAddressLength = optionsStart.location - (fromAddressStart.location + 1);
      
      NSString *fromAddress = [message substringWithRange: 
                               NSMakeRange( fromAddressStart.location + 1, fromAddressLength )];
      NSString *toAddress = [message substringWithRange:
                             NSMakeRange( 2, fromAddressStart.location - 2 )];
      NSString *messageType = [message substringWithRange:
                               NSMakeRange( messageStart.location + 1,
                                           [message length] - (messageStart.location + 1) )];
      NSDictionary *resultData = nil;
      NSRange xmlStart = [messageType rangeOfString: @"{{"];
      NSRange xmlEnd = [messageType rangeOfString: @"}}" options: NSBackwardsSearch];
      
      if (xmlStart.length > 0 && xmlEnd.length > 0 && xmlEnd.location > xmlStart.location)
      {
        ResponseXmlParser *responseParser = [ResponseXmlParser new];
        
        resultData = [[responseParser parseResponseXML: 
                       [messageType substringWithRange:
                        NSMakeRange( xmlStart.location + 2, xmlEnd.location - (xmlStart.location + 2) )]] retain];
        if (resultData != nil)
          messageType = [[messageType substringToIndex: xmlStart.location]
                     stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
        [responseParser release];
      }
      
      if (resultData == nil)
      {
        NSRange whiteSpace = [messageType rangeOfCharacterFromSet: [NSCharacterSet whitespaceCharacterSet]];
        
        if (whiteSpace.length > 0)
        {
          NSString *rawText = [messageType substringFromIndex: whiteSpace.location + whiteSpace.length];
          NSString *parseText = rawText;
          NSRange bracketRange = [parseText rangeOfString: @"{{"];
          NSRange commaRange = [parseText rangeOfString: @","];
          NSRange spaceRange = [parseText rangeOfCharacterFromSet: [NSCharacterSet whitespaceCharacterSet]];
          NSMutableArray *parameterList = [NSMutableArray arrayWithCapacity: 4];
          BOOL trailingComma = NO;

          while (bracketRange.length > 0 || commaRange.length > 0 || spaceRange.length > 0)
          {
            // Handle a {{...}} bracketed parameter
            if (bracketRange.location == 0)
            {
              bracketRange = [parseText rangeOfString: @"}}" options: 0 
                                                range: NSMakeRange( bracketRange.location, 
                                                                   [parseText length] - bracketRange.location )];
              if (bracketRange.length > 0)
              {
                // If terminator not found, drop through to simple parameter case below
                // else, store the parameter and then consume any trailing whitespace and comma
                [parameterList addObject: [parseText substringWithRange: NSMakeRange( 2, bracketRange.location - 2 )]];
                parseText = [parseText substringFromIndex: bracketRange.location + 2];
                bracketRange.location = 0;
              }
            }
            
            // Otherwise look for comma or space separator
            if (bracketRange.location != 0)
            {
              NSRange minRange;
              
              if (commaRange.location < spaceRange.location)
                minRange = commaRange;
              else
                minRange = spaceRange;
              
              [parameterList addObject: [parseText substringToIndex: minRange.location]];
              parseText = [parseText substringFromIndex: minRange.location];
            }
            
            // Consume whitespace/comma/whitespace delimiter and check for next parameter
            spaceRange = [parseText rangeOfCharacterFromSet: [NSCharacterSet whitespaceCharacterSet]];
            if (spaceRange.location == 0)
              parseText = [parseText substringFromIndex: spaceRange.length];
            commaRange = [parseText rangeOfString: @","];
            trailingComma = (commaRange.location == 0);
            if (trailingComma)
              parseText = [parseText substringFromIndex: commaRange.length];
            spaceRange = [parseText rangeOfCharacterFromSet: [NSCharacterSet whitespaceCharacterSet]];
            if (spaceRange.location == 0)
              parseText = [parseText substringFromIndex: spaceRange.length];

            bracketRange = [parseText rangeOfString: @"{{"];
            commaRange = [parseText rangeOfString: @","];
            spaceRange = [parseText rangeOfCharacterFromSet: [NSCharacterSet whitespaceCharacterSet]];
          }
          if (trailingComma || [parseText length] > 0)
            [parameterList addObject: parseText];

          resultData = [[NSDictionary dictionaryWithObjectsAndKeys:
                        rawText, @"rawtext", parameterList, @"params", nil] retain];
          messageType = [messageType substringToIndex: whiteSpace.location];
        }
      }

      // Now decide what to do about it on the basis of who it is from and what
      // sort of a message it is
      NSMutableArray *fromAddresses = [NSMutableArray arrayWithObjects: fromAddress, @"*", nil];
      NSMutableArray *toAddresses = [NSMutableArray arrayWithObjects: toAddress, @"*", nil];
      NSRange fromSubAddressStart = [fromAddress rangeOfString: @"~"];
      NSRange toSubAddressStart = [toAddress rangeOfString: @"~"];
      
      if (fromSubAddressStart.length > 0)
        [fromAddresses insertObject: [fromAddress substringToIndex: fromSubAddressStart.location] atIndex: 0];
      if (toSubAddressStart.length > 0)
        [toAddresses insertObject: [toAddress substringToIndex: toSubAddressStart.location] atIndex: 0];

      NSEnumerator *enumFrom = [fromAddresses objectEnumerator];
      NSString *checkFrom;
      
      while ((checkFrom = [enumFrom nextObject]))
      {
        NSEnumerator *enumTo = [toAddresses objectEnumerator];
        NSString *checkTo;
        
        while ((checkTo = [enumTo nextObject]))
        {
          NSString *key = [NSString stringWithFormat: @"%@:%@:%@", checkFrom, checkTo, messageType];        
          NSArray *listeners = [NSArray arrayWithArray: [_listeners objectForKey: key]];
          NSUInteger count = [listeners count];
          NSUInteger i;
      
          for (i = 0; i < count; ++i)
          {
            [((MsgDelegate *) [listeners objectAtIndex: i]).delegate
             received: self messageType: messageType from: fromAddress to: toAddress data: resultData];
          }
        }
      }
      
      [resultData release];
    }
  }
}

// Received a discovery response message.  This is a binary content message with the format:
// struct Msg
// {
//   uint16_t itemCount_;
//   uint16_t magic_;  // 0xcdab
//   Item     item_[itemCount_];  // not strictly an array as item lengths vary
// };
//
// where each item is in the variable length format:
// struct Item
// {
//  uint16_t tag_;
//  uint8_t  length_;
//  uint8_t  dataType_;
//  uint8_t  data_[length_];
// };

- (void) discoveryData: (CFDataRef) data
{
#if LOG_DISCOVERY
  NSLog( @"NetStreamComms: %@: received discovery data: %@", self, data );
#endif

  [self retain];
  if (!_terminated && _delegate != nil &&
      [_delegate respondsToSelector: @selector(discoveredService:address:netmask:type:version:name:permId:room:)])
  {
    const uint8_t *pData = CFDataGetBytePtr( data );
    CFIndex len = CFDataGetLength( data );
    CFIndex i = 0;
    
    // First a basic sanity check on the content of the message
    if (len >= 4 && ntohs( * (uint16_t *) &pData[2] ) == DISCOVERY_MAGIC && 
      len >= ntohs( * (uint16_t *) pData ) * 6)
    {
      CFIndex itemCount = ntohs( * (uint16_t *) pData );
      NSString *deviceAddress = nil;
      NSString *netmask = nil;
      NSString *type = nil;
      NSString *version = nil;
      NSString *name = nil;
      NSString *permId = nil;
      NSString *room = nil;
      
      i += 4;
      while (i + 3 < len && itemCount > 0)
      {
        // Another length sanity check
        if (i + pData[i+2] + 4 <= len)
        {
          switch (ntohs( * (uint16_t *) &pData[i] ))
          {
            case DISCOVERY_DATA_IP_ADDRESS:
              if (pData[i+3] == DISCOVERY_DATA_TYPE_INT && pData[i+2] == 4)
                deviceAddress = [NSString stringWithFormat: @"%u.%u.%u.%u",
                                  (uint32_t) pData[i + 4], (uint32_t) pData[i + 5],
                                  (uint32_t) pData[i + 6], (uint32_t) pData[i + 7]];
              break;
            case DISCOVERY_DATA_PERM_ID:
              if (pData[i+3] == DISCOVERY_DATA_TYPE_STRING)
                permId = [NSString stringWithCString: (char *) (pData + i + 4) encoding: NSUTF8StringEncoding];
              break;
            case DISCOVERY_DATA_NAME:
              if (pData[i+3] == DISCOVERY_DATA_TYPE_STRING)
                name = [NSString stringWithCString: (char *) (pData + i + 4) encoding: NSUTF8StringEncoding];
              break;
            case DISCOVERY_DATA_ROOM:
              if (pData[i+3] == DISCOVERY_DATA_TYPE_STRING)
                room = [NSString stringWithCString: (char *) (pData + i + 4) encoding: NSUTF8StringEncoding];
              break;
            case DISCOVERY_DATA_SERVICETYPE:
              if (pData[i+3] == DISCOVERY_DATA_TYPE_STRING)
                type = [NSString stringWithCString: (char *) (pData + i + 4) encoding: NSUTF8StringEncoding];
              break;
            case DISCOVERY_DATA_VERSION:
              if (pData[i+3] == DISCOVERY_DATA_TYPE_STRING)
                version = [NSString stringWithCString: (char *) (pData + i + 4) encoding: NSUTF8StringEncoding];
              break;
            case DISCOVERY_DATA_NETMASK:
              if (pData[i+3] == DISCOVERY_DATA_TYPE_INT && pData[i+2] == 4)
                netmask = [NSString stringWithFormat: @"%u.%u.%u.%u",
                           (uint32_t) pData[i + 4], (uint32_t) pData[i + 5],
                           (uint32_t) pData[i + 6], (uint32_t) pData[i + 7]];
              break;
            default:
              break;
          }
        }
        
        i = i + pData[i+2] + 4;
        --itemCount;
      } // while (i < len && itemCount > 0)
      
      if (i <= len && deviceAddress != nil && netmask != nil && type != nil &&
        version != nil && name != nil && permId != nil && room != nil)
      {
#if LOG_DISCOVERY
        NSLog( @"NetStreamComms %@: discovered service: %@ (type: %@, version: %@, perm id: %@, room: %@, addr: %@, netmask: %@)",
              self, name, type, version, permId, room, deviceAddress, netmask );
#endif
        [_delegate discoveredService: self address: deviceAddress netmask: netmask type: type 
         version: version name: name permId: permId room: room];
      }
      else
      {
#if LOG_DISCOVERY
        NSLog( @"NetStreamComms %@: failed to parse discovery data "
              "(service: %@, type: %@, version: %@, perm id: %@, room: %@, addr: %@, netmask: %@)", 
              self, name, type, version, permId, room, deviceAddress, netmask );
#endif        
      }

    }
  }
  [self release];
}

- (void) discoveryComplete: (NSError *) error
{
#if LOG_DISCOVERY
  NSLog( @"NetStreamComms %@: discovery complete with error: %@", self, error );
#endif

  if (_broadcastPing != nil)
  {
    [_broadcastPing release];
    _broadcastPing = nil;
  }
  
  if (_findRenderer != nil)
  {
    [_findRenderer release];
    _findRenderer = nil;
  }

  if (_discoverySocket != NULL)
  {
    if (_discoverySource != NULL)
    {
      CFRunLoopRef cfrl = CFRunLoopGetCurrent();
      
      CFRunLoopRemoveSource( cfrl, _discoverySource, 0 );
      CFRelease( _discoverySource );
      _discoverySource = NULL;
    }
    
    CFSocketInvalidate( _discoverySocket );
    CFRelease( _discoverySocket );
    _discoverySocket = NULL;        
  }

  if (_delegate != nil)
  {
    if ([_delegate respondsToSelector: @selector(discoveryComplete:error:)])
      [_delegate discoveryComplete: self error: error];
  }
}

- (void) discoveryTimeoutFired: (NSTimer *) timer
{
#if LOG_DISCOVERY
  NSLog( @"NetStreamsComms %@: discoveryTimeoutFired", self );
#endif
  if ([timer isValid])
    [timer invalidate];
  [_discoveryTimer release];
  _discoveryTimer = nil;
  [self discoveryComplete: nil];
}

- (void) applicationToForeground
{
  if (_deviceAddress != nil)
    [self connect: _deviceAddress];
  if (_discoverOnRestart)
  {
    _discoverOnRestart = NO;
    [_discoveryAddress retain];
    [self discoverWithAddress: _discoveryAddress andPort: _discoveryPort];
    [_discoveryAddress release];
  }
}

- (void) applicationToBackground
{
  _discoverOnRestart = (_discoverySocket != nil);
  if (_discoverOnRestart)
  {
    id oldDelegate = _delegate;
    
    if (_discoveryTimer != nil)
    {
      if ([_discoveryTimer isValid])
        [_discoveryTimer invalidate];
      [_discoveryTimer release];
      _discoveryTimer = nil;
    }
    _delegate = nil;
    [self discoveryComplete: nil];
    _delegate = oldDelegate;
  }

  BOOL terminated = _terminated;

  [self disconnect];
  _terminated = terminated;
}

@end

// Callback called when we connect (or time out trying to connect) to the device, or
// when data has been received.
static void NetStreamsSocketCallBack( CFSocketRef s, CFSocketCallBackType callbackType,
                                        CFDataRef address, const void *data, void *info )
{
  NetStreamsComms *comms = (NetStreamsComms *) info;
  NSError *error = nil;
  
#if LOG_LOW_LEVEL
  NSLog( @"NetStreamsComms socket callback: %08X", (unsigned int) info );
#endif
  if (comms != nil && comms->_magic == COMMS_MAGIC)
  {
    if (callbackType == kCFSocketConnectCallBack)
    {
      comms.ipv4socket = s;
      if (data == NULL)
        [comms initialiseConnection];
      else
      {
        // TODO: pass data as the userInfo
        
        error = [[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                           code: kNetStreamsConnectTimedOut 
                                       userInfo: [NSDictionary dictionaryWithObject: NSLocalizedString( @"Timed out trying to connect",
                                                                                                       @"Error shown if unable to connect to a device" )
                                                                             forKey: NSLocalizedDescriptionKey]];
        [comms handleNoConnection: error];
      }
    }
    else if (callbackType == kCFSocketDataCallBack)
    {
      if (CFDataGetLength( data ) > 0)
        [comms receivedData: (CFDataRef) data];
      else
      {
        error = [[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                           code: kNetStreamsConnectionClosed
                                       userInfo: [NSDictionary dictionaryWithObject: NSLocalizedString( @"Connection to device closed",
                                                                                                       @"Error shown if socket connection closed" )
                                                                             forKey: NSLocalizedDescriptionKey]];
        [comms handleNoConnection: error];
      }
    }
  }
  
  if (error != nil)
    [error release];
}

// Callback called when we receive discovery data
static void DiscoverySocketCallBack( CFSocketRef s, CFSocketCallBackType callbackType,
                                     CFDataRef address, const void *data, void *info )
{
  NetStreamsComms *comms = (NetStreamsComms *) info;
  
#if LOG_DISCOVERY
  NSLog( @"NetStreamsComms %08X: discovery socket callback", (unsigned int) info );
#endif
  if (comms != nil && comms->_magic == COMMS_MAGIC)
  {
    if (callbackType == kCFSocketDataCallBack)
    {
      if (CFDataGetLength( data ) > 0)
        [comms discoveryData: (CFDataRef) data];
    }
  }
}

static u_short inet_cksum( u_short *addr, u_int len )
{
  register int nleft = (int) len;
  register u_short *w = addr;
  u_short answer = 0;
  register int sum = 0;
  
  while (nleft > 1)
  {
    sum += *w++;
    nleft -= 2;
  }
  
  if (nleft == 1)
  {
    * (u_char *) &answer = * (u_char *) w;
    sum += answer;
  }
  
  sum = (sum >> 16) + (sum & 0xFFFF);
  sum += (sum >> 16);
  answer = ~sum;
  
  return answer;
}

// Routine to send an IGMP v2 join message.  From iOS4.3, the iPhone uses IGMP v3
// which is ignored by NetStreams routers (and maybe others?), making discovery
// not work.
#if 0
static void SendIGMPv2Join( struct ip_mreq *pMReq )
{
#if 0
  CFSocketContext socketCtxt = { 0, NULL, NULL, NULL, NULL };
  CFSocketRef igmpSock = CFSocketCreate( kCFAllocatorDefault, PF_INET, SOCK_DGRAM, IPPROTO_UDP, 
                 0, NULL, &socketCtxt );
  
  if (igmpSock == NULL)
#else
  int igmpSock = socket( AF_INET, SOCK_DGRAM, IPPROTO_IGMP );
  
  if (igmpSock < 0)
#endif
  {
    // Log error
#if LOG_DISCOVERY
    NSLog( @"NetStreamComms: Failed to open socket to send IGMP v2 membership report" );
#endif
    int e = errno;
    
    e = e;
  }
  else
  {
    char router_alert[4];
#if 0
    char send_buf[sizeof(struct ip) + sizeof(struct igmp)];
    struct sockaddr_in sdst;
    struct ip *ip;
    struct igmp *igmp;

    ip = (struct ip *) send_buf;
    ip->ip_src.s_addr = INADDR_ANY;
    ip->ip_dst.s_addr = pMReq->imr_multiaddr.s_addr;
    ip->ip_len = sizeof(send_buf);
    
    igmp = (struct igmp *) ( send_buf + sizeof(ip) );
#else
    char send_buf[sizeof(struct igmp)];
    struct sockaddr_in sdst;
    struct igmp *igmp;
    
    igmp = (struct igmp *) send_buf;
#endif    
    igmp->igmp_type = 0x16; // v2 Membership report
    igmp->igmp_code = 0; // Max response time - unused
    igmp->igmp_group.s_addr = pMReq->imr_multiaddr.s_addr;
    igmp->igmp_cksum = 0;
    igmp->igmp_cksum = inet_cksum( (u_short *) igmp, sizeof(igmp) );
    
    //setsockopt( igmp_socket, IPPROTO_IP, IP_OPTIONS, NULL, 0 );
    router_alert[0] = IPOPT_RA;	/* Router Alert */
    router_alert[1] = 4;	/* 4 bytes */
    router_alert[2] = 0;
    router_alert[3] = 0;
    setsockopt( igmpSock, IPPROTO_IP, IP_OPTIONS, router_alert, sizeof(router_alert) );

    bzero( &sdst, sizeof(sdst) );
    sdst.sin_len = sizeof(sdst);
    sdst.sin_family = AF_INET;
    sdst.sin_addr.s_addr = pMReq->imr_multiaddr.s_addr;
    
#if 0
    if (CFSocketSendData( igmpSock, (CFDataRef) [NSData dataWithBytes: &sdst length: sizeof(sdst)],
                         (CFDataRef) [NSData dataWithBytes: send_buf length: sizeof(send_buf)], DEVICE_SEND_TIMEOUT ) != 0)
#else
      if (sendto( igmpSock, send_buf, sizeof(send_buf), 0, (struct sockaddr *) &sdst, sizeof(sdst) ) < 0)
#endif
    {
      // log error
#if LOG_DISCOVERY
      NSLog( @"NetStreamComms: Send IGMP v2 Membership report failed" );
#endif
      int e = errno;
      
      e = e;
    }
    else
    {
      // log success
#if LOG_DISCOVERY
      NSLog( @"NetStreamComms: Send IGMP v2 Membership report succeeded" );
#endif
    }
    
#if 0
    CFSocketInvalidate( igmpSock );
    CFRelease( igmpSock );
#else
    close( igmpSock );
#endif
  }
}
#endif