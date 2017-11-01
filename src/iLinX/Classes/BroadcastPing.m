//
//  Ping.m
//  iLinX
//
//  Created by mcf on 28/03/2011.
//  Copyright 2011 Micropraxis Ltd. All rights reserved.
//

#import "BroadcastPing.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>

#pragma mark * ICMP On-The-Wire Format

static uint16_t in_cksum( const void *buffer, size_t bufferLen )
// This is the standard BSD checksum code, modified to use modern types.
{
  size_t bytesLeft;
  int32_t sum;
  const uint16_t *cursor;
  union
  {
    uint16_t us;
    uint8_t uc[2];
  }
  last;
  uint16_t answer;
  
  bytesLeft = bufferLen;
  sum = 0;
  cursor = buffer;
  
  /*
   * Our algorithm is simple, using a 32 bit accumulator (sum), we add
   * sequential 16 bit words to it, and at the end, fold back all the
   * carry bits from the top 16 bits into the lower 16 bits.
   */
  while (bytesLeft > 1)
  {
    sum += *cursor;
    cursor += 1;
    bytesLeft -= 2;
  }
  
  /* mop up an odd byte, if necessary */
  if (bytesLeft == 1)
  {
    last.uc[0] = * (const uint8_t *) cursor;
    last.uc[1] = 0;
    sum += last.us;
  }
  
  /* add back carry outs from top 16 bits to low 16 bits */
  sum = (sum >> 16) + (sum & 0xffff); /* add hi 16 to low 16 */
  sum += (sum >> 16);         /* add carry */
  answer = ~sum;              /* truncate to 16 bits */
  
  return answer;
}

#pragma mark * BroadcastPing

@implementation BroadcastPing

- (BroadcastPing *) initWithLocalAddress: (NSString *) localAddress netMask: (NSString *) netMask
// The initialiser common to both of our construction class methods.
{
  assert( (localAddress != nil) && (netMask != nil) );
  self = [super init];
  if (self != nil)
  {
    NSArray *addrParts = [localAddress componentsSeparatedByString: @"."];
    NSArray *maskParts = [netMask componentsSeparatedByString: @"."];
    
    if ([addrParts count] == 4 && [maskParts count] == 4)
    {
      struct sockaddr_in broadcastAddr;
      
      bzero( &broadcastAddr, sizeof(broadcastAddr) );
      broadcastAddr.sin_len = sizeof(broadcastAddr);
      broadcastAddr.sin_family = AF_INET;

      NSLog( @"local address: %@, netmask: %@, addr parts: %@, mask parts: %@", 
            localAddress, netMask, addrParts, maskParts );
      for (int i = 0; i < 4; ++i)
        broadcastAddr.sin_addr.s_addr |=
        ((([[addrParts objectAtIndex: i] integerValue] | (~[[maskParts objectAtIndex: i] integerValue])) & 0xFF) << ((3 - i) * 8));
      broadcastAddr.sin_addr.s_addr = htonl( broadcastAddr.sin_addr.s_addr );

      _hostAddress = [[NSData dataWithBytes: &broadcastAddr length: sizeof(broadcastAddr)] retain];
      _identifier  = (uint16_t) arc4random();
    }
  }

  return self;
}

+ (BroadcastPing *) broadcastPingWithLocalAddress: (NSString *) localAddress netMask: (NSString *) netMask
{
  return [[[BroadcastPing alloc] initWithLocalAddress: localAddress netMask: netMask] autorelease];
}

- (void) dealloc
{
  // -stop takes care of _host and _socket.
  
  [self stop];
  assert(_host == NULL);
  assert(_socket == NULL);
  
  [_hostAddress release];
  
  [super dealloc];
}

@synthesize delegate           = _delegate;
@synthesize identifier         = _identifier;
@synthesize nextSequenceNumber = _nextSequenceNumber;

- (void) _didFailWithError: (NSError *) error
// Shut down the pinger object and tell the delegate about the error.
{
  assert(error != nil);
  
  // We retain ourselves temporarily because it's common for the delegate method 
  // to release its last reference to use, which causes -dealloc to be called here. 
  // If we then reference self on the return path, things go badly.  I don't think 
  // that happens currently, but I've got into the habit of doing this as a 
  // defensive measure.
  
  [[self retain] autorelease];
  
  [self stop];
  if ( (_delegate != nil) && [_delegate respondsToSelector:@selector(broadcastPing:didFailWithError:)] ) {
    [_delegate broadcastPing: self didFailWithError: error];
  }
}

- (void) _didFailWithHostStreamError: (CFStreamError) streamError
// Convert the CFStreamError to an NSError and then call through to 
// -_didFailWithError: to shut down the pinger object and tell the 
// delegate about the error.
{
  NSDictionary *userInfo;
  NSError *error;
  
  if (streamError.domain == kCFStreamErrorDomainNetDB)
  {
    userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInteger:streamError.error], kCFGetAddrInfoFailureKey,
                nil];
  } 
  else
  {
    userInfo = nil;
  }
  error = [NSError errorWithDomain: (NSString *) kCFErrorDomainCFNetwork code: kCFHostErrorUnknown userInfo: userInfo];
  assert(error != nil);
  
  [self _didFailWithError: error];
}

- (BOOL) sendPingWithData: (NSData *) data
// See comment in header.
{
  int             err;
  NSData *        payload;
  NSMutableData * packet;
  ICMPHeader *    icmpPtr;
  ssize_t         bytesSent;
  
  // Construct the ping packet.
  
  payload = data;
  if (payload == nil)
  {
    payload = [[NSString stringWithFormat: @"%28zd bottles of beer on the wall",
                (ssize_t) 99 - (size_t) (_nextSequenceNumber % 100)]
               dataUsingEncoding: NSASCIIStringEncoding];
    assert(payload != nil);
    assert([payload length] == 56);
  }
  
  packet = [NSMutableData dataWithLength:sizeof(*icmpPtr) + [payload length]];
  assert(packet != nil);
  
  icmpPtr = [packet mutableBytes];
  icmpPtr->type = kICMPTypeEchoRequest;
  icmpPtr->code = 0;
  icmpPtr->checksum = 0;
  icmpPtr->identifier = OSSwapHostToBigInt16( self.identifier );
  icmpPtr->sequenceNumber = OSSwapHostToBigInt16( self.nextSequenceNumber );
  memcpy( &icmpPtr[1], [payload bytes], [payload length] );
  
  // The IP checksum returns a 16-bit number that's already in correct byte order 
  // (due to wacky 1's complement maths), so we just put it into the packet as a 
  // 16-bit unit.
  
  icmpPtr->checksum = in_cksum( [packet bytes], [packet length] );
  
  // Send the packet.
  
  if (_socket == NULL)
  {
    bytesSent = -1;
    err = EBADF;
  } 
  else
  {
    bytesSent = sendto( CFSocketGetNative( _socket ), [packet bytes], [packet length], 
                       0, (struct sockaddr *) [_hostAddress bytes], 
                       (socklen_t) [_hostAddress length] );
    err = 0;
    if (bytesSent < 0)
      err = errno;
  }
  
  // Handle the results of the send.
  
  if ((bytesSent > 0) && (((NSUInteger) bytesSent) == [packet length]))
  {
    // Complete success.  Tell the client.
    
    if ((_delegate != nil) && [_delegate respondsToSelector: @selector(broadcastPing:didSendPacket:)])
      [_delegate broadcastPing: self didSendPacket: packet];
  }
  else
  {
    NSError *error;
    
    // Some sort of failure.  Tell the client.
    
    if (err == 0)
      err = ENOBUFS;          // This is not a hugely descriptive error, alas.
    error = [NSError errorWithDomain: NSPOSIXErrorDomain code: err userInfo: nil];
    if ((_delegate != nil) && [_delegate respondsToSelector: @selector(broadcastPing:didFailToSendPacket:error:)])
      [_delegate broadcastPing: self didFailToSendPacket: packet error: error];
  }
  
  _nextSequenceNumber += 1;
  
  return (err == 0);
}

+ (NSUInteger) _icmpHeaderOffsetInPacket: (NSData *) packet
// Returns the offset of the ICMPHeader within an IP packet.
{
  NSUInteger result;
  const struct IPHeader * ipPtr;
  size_t ipHeaderLength;
  
  result = NSNotFound;
  if ([packet length] >= (sizeof(IPHeader) + sizeof(ICMPHeader)))
  {
    ipPtr = (const IPHeader *) [packet bytes];
    assert((ipPtr->versionAndHeaderLength & 0xF0) == 0x40);     // IPv4
    assert(ipPtr->protocol == 1);                               // ICMP
    ipHeaderLength = (ipPtr->versionAndHeaderLength & 0x0F) * sizeof(uint32_t);

    if ([packet length] >= (ipHeaderLength + sizeof(ICMPHeader)))
      result = ipHeaderLength;
  }
  
  return result;
}

+ (const struct ICMPHeader *) icmpInPacket: (NSData *) packet
// See comment in header.
{
  const struct ICMPHeader *result;
  NSUInteger icmpHeaderOffset;
  
  result = nil;
  icmpHeaderOffset = [self _icmpHeaderOffsetInPacket: packet];
  if (icmpHeaderOffset != NSNotFound)
    result = (const struct ICMPHeader *) (((const uint8_t *)[packet bytes]) + icmpHeaderOffset);
  
  return result;
}

- (BOOL) _isValidPingResponsePacket: (NSMutableData *) packet
// Returns true if the packet looks like a valid ping response packet destined 
// for us.
{
  BOOL result;
  NSUInteger icmpHeaderOffset;
  ICMPHeader *icmpPtr;
  uint16_t receivedChecksum;
  uint16_t calculatedChecksum;
  
  result = NO;
  
  icmpHeaderOffset = [[self class] _icmpHeaderOffsetInPacket: packet];
  if (icmpHeaderOffset != NSNotFound)
  {
    icmpPtr = (struct ICMPHeader *) (((uint8_t *)[packet mutableBytes]) + icmpHeaderOffset);
    
    receivedChecksum   = icmpPtr->checksum;
    icmpPtr->checksum  = 0;
    calculatedChecksum = in_cksum(icmpPtr, [packet length] - icmpHeaderOffset);
    icmpPtr->checksum  = receivedChecksum;
    
    if (receivedChecksum == calculatedChecksum)
    {
      if ((icmpPtr->type == kICMPTypeEchoReply) && (icmpPtr->code == 0))
      {
        if (OSSwapBigToHostInt16( icmpPtr->identifier ) == self.identifier)
        {
          if (OSSwapBigToHostInt16( icmpPtr->sequenceNumber ) < self.nextSequenceNumber)
            result = YES;
        }
      }
    }
  }
  
  return result;
}

- (void) _readData
// Called by the socket handling code (SocketReadCallback) to process an ICMP 
// messages waiting on the socket.
{
  int err;
  struct sockaddr_storage addr;
  socklen_t addrLen;
  ssize_t bytesRead;
  void *buffer;
  enum { kBufferSize = 65535 };
  
  // 65535 is the maximum IP packet size, which seems like a reasonable bound 
  // here (plus it's what <x-man-page://8/ping> uses).
  
  buffer = malloc( kBufferSize );
  assert(buffer != NULL);
  
  // Actually read the data.
  
  addrLen = sizeof(addr);
  bytesRead = recvfrom( CFSocketGetNative( _socket ), buffer, kBufferSize, 0, (struct sockaddr *) &addr, &addrLen );
  err = 0;
  if (bytesRead < 0)
    err = errno;
  
  // Process the data we read.
  
  if (bytesRead > 0)
  {
    NSMutableData *packet;
    
    packet = [NSMutableData dataWithBytes: buffer length: bytesRead];
    assert(packet != nil);
    
    // We got some data, pass it up to our client.
    
    if ([self _isValidPingResponsePacket: packet])
    {
      if ((_delegate != nil) && [_delegate respondsToSelector: @selector(broadcastPing:didReceivePingResponsePacket:)])
        [_delegate broadcastPing: self didReceivePingResponsePacket: packet];
    } 
    else 
    {
      if ((_delegate != nil) && [_delegate respondsToSelector: @selector(broadcastPing:didReceiveUnexpectedPacket:)])
        [_delegate broadcastPing: self didReceiveUnexpectedPacket: packet];
    }
  }
  else
  {
    // We failed to read the data, so shut everything down.
    
    if (err == 0)
      err = EPIPE;
    [self _didFailWithError: [NSError errorWithDomain:NSPOSIXErrorDomain code: err userInfo: nil]];
  }
  
  free( buffer );

  // Note that we don't loop back trying to read more data.  Rather, we just 
  // let CFSocket call us again.
}

static void SocketReadCallback( CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info )
// This C routine is called by CFSocket when there's data waiting on our 
// ICMP socket.  It just redirects the call to Objective-C code.
{
  BroadcastPing *obj;
  
  obj = (BroadcastPing *) info;
  assert([obj isKindOfClass: [BroadcastPing class]]);
  
#pragma unused(s)
  assert(s == obj->_socket);
#pragma unused(type)
  assert(type == kCFSocketReadCallBack);
#pragma unused(address)
  assert(address == nil);
#pragma unused(data)
  assert(data == nil);
  
  [obj _readData];
}

- (void) start
// We have a host address, so let's actually start pinging it.
{
  int err;
  int fd;
  const struct sockaddr *addrPtr;
  
  assert(_hostAddress != nil);
  
  // Open the socket.
  
  addrPtr = (const struct sockaddr *) [_hostAddress bytes];
  
  fd = -1;
  err = 0;
  switch (addrPtr->sa_family)
  {
    case AF_INET:
    {
      fd = socket( AF_INET, SOCK_DGRAM, IPPROTO_ICMP );
      if (fd < 0)
        err = errno;
      break;
    } 
    case AF_INET6:
      assert(NO);
      // fall through

    default:
      err = EPROTONOSUPPORT;
      break;
  }
  
  if (err != 0)
    [self _didFailWithError: [NSError errorWithDomain: NSPOSIXErrorDomain code: err userInfo: nil]];
  else
  {
    CFSocketContext context = { 0, self, NULL, NULL, NULL };
    CFRunLoopSourceRef rls;
    
    // Wrap it in a CFSocket and schedule it on the runloop.
    
    _socket = CFSocketCreateWithNative( NULL, fd, kCFSocketReadCallBack, SocketReadCallback, &context );
    assert(_socket != NULL);
    
    // The socket will now take care of clean up our file descriptor.
    
    assert( CFSocketGetSocketFlags(_socket) & kCFSocketCloseOnInvalidate );
    fd = -1;
    
    rls = CFSocketCreateRunLoopSource( NULL, _socket, 0 );
    assert(rls != NULL);
    
    CFRunLoopAddSource( CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode );
    
    CFRelease( rls );
    
    if ((_delegate != nil) && [_delegate respondsToSelector: @selector(broadcastPing:didStartWithAddress:)])
      [_delegate broadcastPing: self didStartWithAddress: _hostAddress];
  }
  assert(fd == -1);
}

- (void) stop   
// Shut down anything to do with sending and receiving pings.
{
  if (_socket != NULL)
  {
    CFSocketInvalidate( _socket );
    CFRelease( _socket );
    _socket = NULL;
  }
}

@end