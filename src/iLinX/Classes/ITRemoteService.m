//
//  ITRemoteService.m
//  iLinX
//
//  Created by mcf on 21/10/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "ITRemoteService.h"
#import "mtwist.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <CFNetwork/CFSocketStream.h>

#import "AppStateNotification.h"

//#define ID_IS_ADMINISTRATORS_IPOD 1

static NSString *kITunesLibraryDataKey = @"iTunesLibraryData";

static void TCPServerAcceptCallBack( CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info );
static void EncodeLength( NSUInteger length, unsigned char *pBuffer );

static unsigned char PAIRING_PREFIX[] =
{ 
  0x63, 0x6d, 0x70, 0x61,
  0x00, 0x00, 0x00, 0x2e,

  0x63, 0x6d, 0x70, 0x67,
  0x00, 0x00, 0x00, 0x08,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
 
  0x63, 0x6d, 0x6e, 0x6d,
  0x00, 0x00, 0x00, 0x00,
  0x69, 0x4c, 0x69, 0x6e,
  0x58, 0x3a, 0x20
};
#define PAIRING_PREFIX_LENGTH sizeof(PAIRING_PREFIX)
#define PAIRING_TOTAL_LENGTH_OFFSET 4
#define PAIRING_ID_OFFSET 16
#define PAIRING_NAME_LENGTH_OFFSET 28
#define PAIRING_FIXED_NAME_LENGTH 7

static unsigned char PAIRING_SUFFIX[] =
{
  0x63, 0x6d, 0x74, 0x79,
  0x00, 0x00, 0x00, 0x00
};
#define PAIRING_SUFFIX_LENGTH sizeof(PAIRING_SUFFIX)
#define PAIRING_MODEL_NAME_LENGTH_OFFSET 4

// Magic value to cross-check that we're really being called by a valid remote service
#define REMOTE_SERVICE_MAGIC 0x45E1F90D

@interface ITRemoteService ()

- (void) publishNetService;
- (int) startNetService;
- (void) handleNewConnectionFromAddress: (NSData *) peer inputStream: (NSInputStream *) readStream
                           outputStream: (NSOutputStream *) writeStream;
- (void) pairingRequestCompleted: (id) pairingRequest;
- (void) cleanUp;
- (void) applicationToForeground;
- (void) applicationToBackground;

@end


// Simple class to handle and respond to a request to pair with this service
@interface ITRemotePairingRequest : NSObject <NSStreamDelegate>
{
@private
  ITRemoteService *_owner;
  NSInputStream *_in;
  NSOutputStream *_out;
  NSMutableData *_inData;
  NSMutableData *_outData;
}

- (id) initWithOwner: (ITRemoteService *) owner inputStream: (NSInputStream *) inputStream 
        outputStream: (NSOutputStream *) outputStream;
- (void) openComms;
- (void) writeData;
- (void) readData;
- (void) handlePairingRequest;
- (void) close;

@end

@implementation ITRemotePairingRequest

- (id) initWithOwner: (ITRemoteService *) owner inputStream: (NSInputStream *) inputStream outputStream: (NSOutputStream *) outputStream
{
  //**/NSLog( @"ITRPR %@: init", self );
  if ((self = [super init]) != nil)
  {
    _owner = owner;
    _in = [inputStream retain];
    [_in setDelegate: self];    
    _out = [outputStream retain];
    [_out setDelegate: self];
  }

  return self;
}

- (void) openComms
{
  [_in scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
  [_in open];
  [_out scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
  [_out open];
}

- (void) stream: (NSStream *) aStream handleEvent: (NSStreamEvent) eventCode
{
  //**/NSLog( @"ITRPR %@: handleEvent: %d", self, eventCode );
  switch (eventCode) 
  {
    case NSStreamEventHasBytesAvailable:
      [self readData];
      break;
    case NSStreamEventHasSpaceAvailable:
      [self writeData];
      break;
    case NSStreamEventErrorOccurred:
    case NSStreamEventEndEncountered:
      // Don't waste time trying to recover a pairing request - we can always
      // do another!
      [self close];
      break;
    default:
      break;
  }
}

- (void) writeData 
{
  //**/NSLog( @"ITRPR %@: writeData", self );
  while ([_out hasSpaceAvailable] && [_outData length] > 0)
  {
    NSInteger bytesWritten = [_out write:[_outData bytes] maxLength: [_outData length]];

    //**/NSLog( @"ITRPR %@: wrote %d bytes", self, bytesWritten );
    if (bytesWritten > 0)
      [_outData replaceBytesInRange: NSMakeRange( 0, bytesWritten ) withBytes: NULL length: 0];
    else if (bytesWritten == -1)
    {
      //**/NSLog( @"ITRPR %@: write error", self );
      break;
    }
  }
}

#define INPUT_BUFFER_SIZE 1024

- (void) readData
{
  uint8_t buf[INPUT_BUFFER_SIZE];

  //**/NSLog( @"ITRPR %@: readData", self );
  while ([_in hasBytesAvailable])
  {
    NSInteger bytesRead = [_in read: buf maxLength: sizeof(buf)];
    
    //**/NSLog( @"ITRPR %@: read %d bytes", self, bytesRead );
    if (bytesRead > 0)
    {
      if (_inData == nil)
        _inData = [[NSMutableData alloc] initWithBytes: (void *) buf length: bytesRead];
      else
        [_inData appendBytes: (void *) buf length: bytesRead];
    }
  }
  
  if ([_inData length] > 0)
    [self handlePairingRequest];
}

- (void) handlePairingRequest
{
  // A request to pair...  Say we're happy to do so, no matter what they send us
  
  //**/NSLog( @"ITRPR %@: handlePairingRequest", self );
  mt_state state;
  const uint8_t *pCode = (const uint8_t *) &state.statevec[0];
  uint8_t requestBuffer[INPUT_BUFFER_SIZE];
  NSUInteger bytesRead = [_inData length];
  NSString *request;
  NSRange serviceNameRange;
  NSRange endServiceNameRange;
  NSString *libraryId;
  NSString *codeAsHex;

  if (bytesRead >= INPUT_BUFFER_SIZE - 1)
    bytesRead = INPUT_BUFFER_SIZE - 1;
  memcpy( requestBuffer, [_inData bytes], bytesRead );
  requestBuffer[bytesRead] = 0;
  request = [NSString stringWithUTF8String: (const char *) requestBuffer];
  serviceNameRange = [request rangeOfString: @"servicename="];
  if (serviceNameRange.length > 0)
  {
    endServiceNameRange =
    [request rangeOfCharacterFromSet: 
     [NSCharacterSet characterSetWithCharactersInString: @" \t\r\n&#"] options: 0
                               range: NSMakeRange( NSMaxRange( serviceNameRange ), 
                                                  [request length] - NSMaxRange( serviceNameRange ) )];
    if (endServiceNameRange.length > 0)
    {
      NSData *nameData = [[[UIDevice currentDevice] name] dataUsingEncoding: NSUTF8StringEncoding];
      NSUInteger nameLength = [nameData length];
      NSData *modelData = [[[UIDevice currentDevice] model] dataUsingEncoding: NSUTF8StringEncoding];
      NSUInteger modelLength = [modelData length];
      NSUInteger length = PAIRING_PREFIX_LENGTH + PAIRING_SUFFIX_LENGTH + nameLength + modelLength;
      
      libraryId = [request substringWithRange:
                   NSMakeRange( NSMaxRange( serviceNameRange ),
                               endServiceNameRange.location - NSMaxRange( serviceNameRange ) )];
      
      //**/NSLog( @"ITRPR %@: valid pairing request from %@", self, libraryId );

      EncodeLength( length - 8, &PAIRING_PREFIX[PAIRING_TOTAL_LENGTH_OFFSET] );
      
      // Generate random pairing id for the response
      
      NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];
      unsigned long long lseed = t * 1000;
      unsigned long seed = (unsigned long) (lseed % ULONG_MAX);
      
      mts_seed32new( &state, seed );
      memcpy( &PAIRING_PREFIX[PAIRING_ID_OFFSET], pCode, 8 );
      EncodeLength( nameLength + PAIRING_FIXED_NAME_LENGTH, &PAIRING_PREFIX[PAIRING_NAME_LENGTH_OFFSET] );
      EncodeLength( modelLength, &PAIRING_SUFFIX[PAIRING_MODEL_NAME_LENGTH_OFFSET] );
      
      codeAsHex = [NSString stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X",
                   pCode[0], pCode[1], pCode[2], pCode[3],
                   pCode[4], pCode[5], pCode[6], pCode[7]];
      
      _outData = [[[NSString stringWithFormat: @"HTTP/1.1 200 OK\r\nContent-Length: %u\r\n\r\n", length] 
                   dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
      
      [_outData appendBytes: PAIRING_PREFIX length: PAIRING_PREFIX_LENGTH];
      [_outData appendData: nameData];
      [_outData appendBytes: PAIRING_SUFFIX length: PAIRING_SUFFIX_LENGTH];
      [_outData appendData: modelData];
      [_inData setLength: 0];
      [self writeData];

      // Record the random id that we issued for this library
      NSDictionary *libraryData = [[NSUserDefaults standardUserDefaults] objectForKey: kITunesLibraryDataKey];
      NSMutableDictionary *newLibraryData;
      
      if (libraryData == nil)
        newLibraryData = [[NSMutableDictionary dictionaryWithCapacity: 1] retain];
      else
        newLibraryData = [libraryData mutableCopy];
      
      [newLibraryData setObject: codeAsHex forKey: libraryId];
      [[NSUserDefaults standardUserDefaults] setObject: newLibraryData forKey: kITunesLibraryDataKey];
      [[NSUserDefaults standardUserDefaults] synchronize];
      [newLibraryData release];
    }
  }
}

- (void) close
{
  //**/NSLog( @"ITRPR %@: close", self );
  [_in close];
  [_in removeFromRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
  [_in setDelegate: nil];
  [_in release];
  _in = nil;
  [_out close];
  [_out removeFromRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
  [_out setDelegate: nil];
  [_out release];
  _out = nil;
  
  [_inData release];
  _inData = nil;
  [_outData release];
  _outData = nil;

  [_owner pairingRequestCompleted: self];
}

- (void) dealloc
{
  //**/NSLog( @"ITRPR %@: dealloc", self );
  [self close];
  [super dealloc];
}

@end


@implementation ITRemoteService

- (id) init
{
  //**/NSLog( @"ITRS %@: init", self );
  if ((self = [super init]) != nil)
  {
    _serviceMagic = REMOTE_SERVICE_MAGIC;
    _pairingRequests = [NSMutableSet new];

    [self publishNetService];
    
    [AppStateNotification addWillEnterForegroundObserver: self selector: @selector(applicationToForeground)];
    [AppStateNotification addDidEnterBackgroundObserver: self selector: @selector(applicationToBackground)];
  }

  return self;
}

/* Sent to the NSNetService instance's delegate prior to advertising the service on the network.
 * If for some reason the service cannot be published, the delegate will not receive this message,
 * and an error will be delivered to the delegate via the delegate's -netService:didNotPublish: method.
 */
- (void) netServiceWillPublish: (NSNetService *) sender
{
}

/* Sent to the NSNetService instance's delegate when the publication of the instance is complete and successful.
 */
- (void) netServiceDidPublish: (NSNetService *) sender
{
  //**/NSLog( @"ITRS %@: netServiceDidPublish", self );
}

/* Sent to the NSNetService instance's delegate when an error in publishing the instance occurs.
 * The error dictionary will contain two key/value pairs representing the error domain and code
 * (see the NSNetServicesError enumeration above for error code constants). It is possible for an
 * error to occur after a successful publication.
 */
- (void) netService: (NSNetService *) sender didNotPublish: (NSDictionary *) errorDict
{
  //**/NSLog( @"ITRS %@: Failed to publish ITRemoteService", self );
}

/* Sent to the NSNetService instance's delegate when the instance's previously running
 * publication or resolution request has stopped.
 */
- (void) netServiceDidStop: (NSNetService *) sender
{
  //**/NSLog( @"ITRS %@: netServiceDidStop", self );
}

- (void) publishNetService
{
  //**/NSLog( @"ITRS %@: publishNetService", self );
  int port = [self startNetService];

  if (port != 0 &&
      (self = [super initWithDomain: @"" type: @"_touch-remote._tcp."
                               name: 
               [@"iLinX " stringByAppendingString: [[NSProcessInfo processInfo] globallyUniqueString]] port: port]) != nil)
  {
    // Generate random pairing id for the service offer
    mt_state state;
    const uint8_t *pCode = (const uint8_t *) &state.statevec[0];
    NSString *codeAsHex;
    NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];
    unsigned long long lseed = t * 1000;
    unsigned long seed = (unsigned long) (lseed % ULONG_MAX);
    
    mts_seed32new( &state, seed );
    codeAsHex = [NSString stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X",
                 pCode[0], pCode[1], pCode[2], pCode[3],
                 pCode[4], pCode[5], pCode[6], pCode[7]];
    
    NSDictionary *props = [NSDictionary dictionaryWithObjectsAndKeys:
                           [[NSString stringWithFormat: @"iLinX: %@", [[UIDevice currentDevice] name]]
                            dataUsingEncoding: NSUTF8StringEncoding], @"DvNm",
                           [@"10000" dataUsingEncoding: NSUTF8StringEncoding], @"RemV",
                           [[[UIDevice currentDevice] model] dataUsingEncoding: NSUTF8StringEncoding], @"DvTy",
                           [@"Remote" dataUsingEncoding: NSUTF8StringEncoding], @"RemN",
                           [@"1" dataUsingEncoding: NSUTF8StringEncoding], @"txtvers",
                           [codeAsHex dataUsingEncoding: NSUTF8StringEncoding], @"Pair", nil];
    NSData *txtData = [NSNetService dataFromTXTRecordDictionary: props];
    
    [self setTXTRecordData: txtData];
    [self setDelegate: self];
    [self publish];
  }
}

- (int) startNetService
{
  CFSocketContext socketCtxt = { 0, self, NULL, NULL, NULL };
  int port;
  
  //**/NSLog( @"ITRS %@: startNetService", self );

  _ipv4socket = CFSocketCreate( kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP,
                               kCFSocketAcceptCallBack, (CFSocketCallBack)&TCPServerAcceptCallBack, &socketCtxt );
  
  if (NULL == _ipv4socket)
  {
    //if (error) *error = [[NSError alloc] initWithDomain:TCPServerErrorDomain code:kTCPServerNoSocketsAvailable userInfo:nil];
    port = 0;
  }
  else
  {
    int yes = 1;
    setsockopt( CFSocketGetNative( _ipv4socket ), SOL_SOCKET, SO_REUSEADDR, (void *) &yes, sizeof(yes) );
    setsockopt( CFSocketGetNative( _ipv4socket ), SOL_SOCKET, SO_NOSIGPIPE, (void *) &yes, sizeof(yes) );
    
    // set up the IPv4 endpoint; use port 0, so the kernel will choose an arbitrary port for us, which will be advertised using Bonjour
    struct sockaddr_in addr4;
    
    memset( &addr4, 0, sizeof(addr4) );
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = 0;
    addr4.sin_addr.s_addr = htonl( INADDR_ANY );
    NSData *address4 = [NSData dataWithBytes: &addr4 length: sizeof(addr4)];
    
    if (kCFSocketSuccess != CFSocketSetAddress( _ipv4socket, (CFDataRef) address4 ))
    {
      //if (error) *error = [[NSError alloc] initWithDomain:TCPServerErrorDomain code:kTCPServerCouldNotBindToIPv4Address userInfo:nil];
      CFRelease( _ipv4socket );
      _ipv4socket = NULL;
      port = 0;
    }
    else
    {
      // now that the binding was successful, we get the port number 
      // -- we will need it for the NSNetService
      NSData *addr = [(NSData *) CFSocketCopyAddress( _ipv4socket ) autorelease];
      memcpy( &addr4, [addr bytes], [addr length] );
      
      port = ntohs( addr4.sin_port );
      
      // set up the run loop sources for the sockets
      CFRunLoopRef cfrl = CFRunLoopGetCurrent();
      CFRunLoopSourceRef source4 = CFSocketCreateRunLoopSource( kCFAllocatorDefault, _ipv4socket, 0 );
      
      CFRunLoopAddSource( cfrl, source4, kCFRunLoopCommonModes );
      CFRelease( source4 );
    }
  }
  
  return port;
}

- (void) handleNewConnectionFromAddress: (NSData *) peer inputStream: (NSInputStream *) readStream
                           outputStream: (NSOutputStream *) writeStream
{
  //**/NSLog( @"ITRS %@: handleNewConnectionFromAddress", self );

  id request = [[ITRemotePairingRequest alloc] initWithOwner: self inputStream: readStream outputStream: writeStream];
  
  //**/NSLog( @"ITRS %@: adding object %@ to pairing requests", self, request );
  [_pairingRequests addObject: request];
  [request openComms];
  [request release];
}

- (void) pairingRequestCompleted: (id) pairingRequest
{
  //**/NSLog( @"ITRS %@: pairing request %@ completed", self, pairingRequest );
  [_pairingRequests removeObject: pairingRequest];
}

- (void) cleanUp
{
  //**/NSLog( @"ITRS %@: cleanup", self );
  [_pairingRequests removeAllObjects];
  if (_ipv4socket != NULL)
  {
    CFRelease( _ipv4socket );
    _ipv4socket = NULL;
  }
}

- (void) applicationToForeground
{
  //**/NSLog( @"ITRS %@: applicationToForeground", self );
  [self publishNetService];
}

- (void) applicationToBackground
{
  //**/NSLog( @"ITRS %@: applicationToBackground", self );
  [self cleanUp];
}

- (void) dealloc
{
  //**/NSLog( @"ITRS %@: dealloc", self );
  [AppStateNotification removeObserver: self];

  [self cleanUp];
  [_pairingRequests release];
  _serviceMagic = 0;
  [super dealloc];
}

@end

// This function is called by CFSocket when a new connection comes in.
// We gather some data here, and convert the function call to a method
// invocation on TCPServer.
static void TCPServerAcceptCallBack( CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info )
{
  ITRemoteService *server = (ITRemoteService *) info;
  
  //**/NSLog( @"ITRS %@: TCPServerAcceptCallBack", server );

  if (kCFSocketAcceptCallBack == type && server->_serviceMagic == REMOTE_SERVICE_MAGIC)
  { 
    // for an AcceptCallBack, the data parameter is a pointer to a CFSocketNativeHandle
    CFSocketNativeHandle nativeSocketHandle = * (CFSocketNativeHandle *) data;
    uint8_t name[SOCK_MAXADDRLEN];
    socklen_t namelen = sizeof(name);
    NSData *peer = nil;
    
    if (0 == getpeername( nativeSocketHandle, (struct sockaddr *) name, &namelen ))
      peer = [NSData dataWithBytes: name length: namelen];
    
    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    
    CFStreamCreatePairWithSocket( kCFAllocatorDefault, nativeSocketHandle, &readStream, &writeStream );
    if (readStream != NULL && writeStream != NULL)
    {
      CFReadStreamSetProperty( readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue );
      CFWriteStreamSetProperty( writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue );
      [server handleNewConnectionFromAddress: peer inputStream: (NSInputStream *) readStream outputStream: (NSOutputStream *) writeStream];
    }
    else
    {
      // on any failure, need to destroy the CFSocketNativeHandle 
      // since we are not going to use it any more
      close( nativeSocketHandle );
    }
    if (readStream != NULL)
      CFRelease( readStream );
    if (writeStream != NULL)
      CFRelease( writeStream );
  }
}

static void EncodeLength( NSUInteger length, unsigned char *pBuffer )
{
  pBuffer[3] = (unsigned char) length;
  pBuffer[2] = (unsigned char) (length >> 8);
  pBuffer[1] = (unsigned char) (length >> 8);
  pBuffer[0] = (unsigned char) (length >> 8);
}
