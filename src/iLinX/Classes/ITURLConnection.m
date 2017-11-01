//
//  ITURLConnection.m
//  iLinX
//
//  Created by mcf on 04/11/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include <CFNetwork/CFSocketStream.h>
#import "AppStateNotification.h"
#import "ITURLConnection.h"
#import "ITHTTPURLResponse.h"

#if defined(DEBUG)
#define TRACEMSG 0
#endif

// Time in seconds to try to connect to the remote host before timing out
#define ITURL_CONNECT_TIMEOUT 10

#define DEFAULT_HTTP_PORT 80

static NSMutableSet *g_openConnections = nil;

static void TargetSocketCallBack( CFSocketRef s, CFSocketCallBackType callbackType,
                                 CFDataRef address, const void *data, void *info );

@interface ITURLConnection ()

- (void) processNextRequest;
- (void) processQueue;
- (void) connectToHost: (NSString *) host port: (NSUInteger) port;
- (void) initialiseConnectionWithSocket: (CFSocketRef) socket;
- (void) handleError: (NSError *) error;
- (void) sendRequest;
- (void) receivedData: (CFDataRef) data;
- (void) handleDataComplete: (CFDataRef) optionalData;
- (void) disconnect;
- (NSError *) allocError: (NSUInteger) code message: (NSString *) message;
- (void) applicationToForeground;
- (void) applicationToBackground;
- (void) cleanUp;

@end

@implementation ITURLConnection

- (id) init
{
  if ((self = [super init]) != nil)
  {
    _requests = [[NSMutableArray alloc] init];
    _delegates = [[NSMutableArray alloc] init];
    _expectedLength = NSURLResponseUnknownLength;
    if (g_openConnections == nil)
      g_openConnections = [NSMutableSet new];
    [g_openConnections addObject: [NSNumber numberWithLongLong: (long long) (long) self]];
    
    [AppStateNotification addWillEnterForegroundObserver: self selector: @selector(applicationToForeground)];
    [AppStateNotification addDidEnterBackgroundObserver: self selector: @selector(applicationToBackground)];
  }

  return self;
}

- (void) submitRequest: (NSURLRequest *) request delegate: (id<ITURLResponseHandler>) delegate
{
  NSUInteger itemCount = [_requests count];

  // Place on queue
  if (!_closed && request != nil)
  {
#if TRACEMSG
    NSLog( @"%@: submitRequest: %@", self, request );
#endif
    [_requests addObject: request];
  
    if (delegate == nil)
      [_delegates addObject: [NSNull null]];
    else
      [_delegates addObject: delegate];

    // If original queue length was zero, process queue
    if (itemCount == 0)
      [self processQueue];
  }
}

- (void) cancelWithDelegate: (id<ITURLResponseHandler>) delegate
{
  if (delegate == _currentDelegate)
  {
    [self disconnect];
    if (!_closed)
      [self processNextRequest];
  }
  else
  {
    NSUInteger count = [_delegates count];
    
    for (NSUInteger i = 0; i < count; ++i)
    {
      if ([_delegates objectAtIndex: i] == delegate)
      {
        [_delegates removeObjectAtIndex: i];
        [_requests removeObjectAtIndex: i];
        break;
      }
    }
  }
}

- (void) close
{
  [self retain];
  [self disconnect];
  _closed = YES;
  
  NSMutableArray *requests = _requests;
  NSMutableArray *delegates = _delegates;
  NSURLRequest *currentRequest = _currentRequest;
  id<ITURLResponseHandler> currentDelegate = _currentDelegate;
  
  _requests = nil;
  _delegates = nil;
  _currentRequest = nil;
  _currentDelegate = nil;
  
  [currentRequest release];
  [currentDelegate release];
  [requests release];
  [delegates release];
  [g_openConnections removeObject: [NSNumber numberWithLongLong: (long long) (long) self]];
  [self release];
}

- (void) processNextRequest
{
  if (!_closed && _currentRequest != nil)
  {
    [_requests removeObjectAtIndex: 0];
    [_delegates removeObjectAtIndex: 0];
    [self cleanUp];
  }

  [self processQueue];
}

- (void) processQueue
{
  if (!_closed && !_connectionPending && [_requests count] > 0)
  {
    [_currentRequest release];
    [_currentDelegate release];

    _currentRequest = [[_requests objectAtIndex: 0] retain];
    _currentDelegate = [[_delegates objectAtIndex: 0] retain];

    if ([_currentDelegate isKindOfClass: [NSNull class]])
    {
      [_currentDelegate release];
      _currentDelegate = nil;
    }
    
    // Extract target host and port
    NSURL *targetURL = [_currentRequest URL];
    NSNumber *targetPort = [targetURL port];
    NSString *target = [targetURL host];
    NSUInteger port;

    if (targetPort == nil)
      port = DEFAULT_HTTP_PORT;
    else
      port = [targetPort unsignedIntegerValue];

    // Compare with that of our existing connection
    if (port == _port && [target isEqualToString: _target])
      [self sendRequest];
    else
      [self connectToHost: target port: port];
  }
}

- (void) connectToHost: (NSString *) host port: (NSUInteger) port
{
  CFSocketContext socketCtxt = { 0, self, NULL, NULL, NULL };
  NSError *pError = nil;
  CFSocketRef socket;
  
#if TRACEMSG
  NSLog( @"%@ connectToHost: %@:%u", self, host, port );
  if (host == nil)
    host = @"Invalid host!";
#endif

  [self disconnect];
  _connectionPending = YES;
  [_target release];
  _target = [host retain];
  _port = port;  

  socket = CFSocketCreate( kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, 
                          kCFSocketConnectCallBack|kCFSocketDataCallBack,
                          (CFSocketCallBack) &TargetSocketCallBack, &socketCtxt );
  
  if (socket == NULL)
  {
    pError = [self allocError: NSURLErrorCannotLoadFromNetwork
                       message: NSLocalizedString( @"No resources to connect to network",
                                                  @"Error shown if unable to create a socket" )];
#if TRACEMSG
    NSLog( @"%@ connectToHost failed to create socket", self );
#endif
  }
  else
  {
    int yes = 1;
    struct sockaddr_in addr4;
    const char *pDevice = [_target UTF8String];
    
    setsockopt( CFSocketGetNative( socket ), SOL_SOCKET, SO_REUSEADDR, (void *) &yes, sizeof(yes) );
    setsockopt( CFSocketGetNative( socket ), SOL_SOCKET, SO_KEEPALIVE, (void *) &yes, sizeof(yes) );
    setsockopt( CFSocketGetNative( socket ), SOL_SOCKET, SO_NOSIGPIPE, (void *) &yes, sizeof(yes) );
    setsockopt( CFSocketGetNative( socket ), IPPROTO_TCP, TCP_NODELAY, (void *) &yes, sizeof(yes) );
    
    memset( &addr4, 0, sizeof(addr4) );
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons( _port );
    addr4.sin_addr.s_addr = inet_addr( pDevice );
    
    if (addr4.sin_addr.s_addr == INADDR_NONE)
    {
      struct hostent *pHost = gethostbyname( pDevice );
      
      if (pHost == NULL)
      {
        pError = [self allocError: NSURLErrorCannotFindHost 
                           message: NSLocalizedString( @"Cannot resolve host name",
                                                      @"Error shown if unable to resolve a host name" )];
#if TRACEMSG
        NSLog( @"%@ connectToHost cannot resolve host name: %@", self, host );
#endif
      }
      else
        memcpy( &addr4.sin_addr, pHost->h_addr_list[0], pHost->h_length );
    }
    
    if (pError == NULL)
    {
      NSData *address4 = [NSData dataWithBytes: &addr4 length: sizeof(addr4)];
      
      // TODO: Pass the error code as user info.
      if (CFSocketConnectToAddress( socket, (CFDataRef) address4, -ITURL_CONNECT_TIMEOUT ) != kCFSocketSuccess)
      {
        pError = [self allocError: NSURLErrorCannotConnectToHost
                           message: [NSString stringWithFormat:
                                     NSLocalizedString( @"Unable to connect to %s",
                                                       @"Error shown if unable to connect to chosen remote host" ), pDevice]];
#if TRACEMSG
        NSLog( @"%@ connectToHost unable to connect to %@:%u", self, host, port );
#endif
      }
      else
      {
        // All OK, set up the run loop sources for the socket
        CFRunLoopRef cfrl = CFRunLoopGetCurrent();
        CFRunLoopSourceRef source = CFSocketCreateRunLoopSource( kCFAllocatorDefault, socket, 0 );

        CFRunLoopAddSource( cfrl, source, kCFRunLoopCommonModes );
        CFRelease( source );
#if TRACEMSG
        NSLog( @"%@ connectToHost connected to %@:%u", self, host, port );
#endif
      }
    }
  }

  if (pError != nil)
  {
    if (socket != NULL)
    {
      CFSocketDisableCallBacks( socket, kCFSocketDataCallBack|kCFSocketConnectCallBack );
      CFSocketInvalidate( socket );
      CFRelease( socket );
    }
    
    [_target release];
    _target = nil;
    _port = 0;
    _connectionPending = NO;

    [self handleError: pError];
    [pError release];
  }
}

- (void) initialiseConnectionWithSocket: (CFSocketRef) socket
{
#if TRACEMSG
  NSLog( @"%@ socket connection received", self );
#endif
  _targetSocket = socket;
  _connectionPending = NO;
  [self sendRequest];
}

- (void) handleError: (NSError *) error
{
  BOOL closed;

#if TRACEMSG
  NSLog( @"%@ error:", self, error );
#endif
  [self retain];
  [_currentDelegate connection: self didFailWithError: error];
  closed = _closed;
  [self release];
  
  if (!closed)
    [self processNextRequest];
}

- (void) handleRemoteClosed
{
#if TRACEMSG
  NSLog( @"%@ remote connection closed", self );
#endif
  [self disconnect];
  if (_expectedLength == NSURLResponseUnknownLength && _currentResponse != nil)
    [self handleDataComplete: NULL];
  else
  {
    NSError *error = [self allocError: NSURLErrorNetworkConnectionLost
                              message: NSLocalizedString( @"Connection to device closed",
                                                         @"Error shown if socket connection closed" )];
    [self handleError: error];
    [error release];
  }
}

- (void) sendRequest
{
  if (_currentRequest != nil)
  {
    CFHTTPMessageRef request =
    CFHTTPMessageCreateRequest( NULL, (CFStringRef) [_currentRequest HTTPMethod],
                               (CFURLRef) [_currentRequest URL], kCFHTTPVersion1_1 );
    NSDictionary *headers = [_currentRequest allHTTPHeaderFields];
    NSData *body = [_currentRequest HTTPBody];
    CFTimeInterval timeout = (CFTimeInterval) [_currentRequest timeoutInterval];
    NSError *pError = nil;
    BOOL succeeded = NO;
    
#if TRACEMSG
    NSLog( @"%@ sendRequest: %@", self, [_currentRequest URL] );
#endif
    
    if (request != NULL)
    {
      if (body != nil)
        CFHTTPMessageSetBody( request, (CFDataRef) body );
      
      for (NSString *header in [headers allKeys])
        CFHTTPMessageSetHeaderFieldValue( request, (CFStringRef) header, (CFStringRef) [headers objectForKey: header] );
      
      CFDataRef serialisedMessage = CFHTTPMessageCopySerializedMessage( request );
      
      if (serialisedMessage != NULL)
      {
        CFSocketError err = CFSocketSendData( _targetSocket, NULL, serialisedMessage, timeout );
        
        if (err == kCFSocketSuccess)
          succeeded = YES;
        else if (err == kCFSocketTimeout)
          pError = [self allocError: NSURLErrorTimedOut 
                            message: NSLocalizedString( @"Timed out trying to send request",
                                                       @"Error shown if unable to send to a remote host due to timeout" )];
        
        CFRelease( serialisedMessage );
      }
      
      CFRelease( request );
    }
    
    if (!succeeded)
    {
      if (pError == nil)
        pError = [self allocError: NSURLErrorUnknown
                          message: NSLocalizedString( @"Unable to create request due to lack of resources",
                                                     @"Error shown if unable to create a URL request" )];
#if TRACEMSG
    NSLog( @"%@ sendRequest failed: %@", self, pError );
#endif
      [self handleError: pError];
      [pError release];
    }
  }
}

- (void) receivedData: (CFDataRef) data
{
  CFIndex receivedLength = CFDataGetLength( data );

  if (_currentRawResponse == NULL)
    _currentRawResponse = CFHTTPMessageCreateEmpty( NULL, NO );
  
  CFHTTPMessageAppendBytes( _currentRawResponse, CFDataGetBytePtr( data ), receivedLength );
  if (_currentResponse != nil)
  {
    _bytesReceived += receivedLength;
    if (_bytesReceived == _expectedLength)
      [self handleDataComplete: NULL];
  }
  else if (CFHTTPMessageIsHeaderComplete( _currentRawResponse ))
  {
    NSURLRequest *currentRequest = [_currentRequest retain];
    CFIndex statusCode = CFHTTPMessageGetResponseStatusCode( _currentRawResponse );
    CFDictionaryRef headerFields = CFHTTPMessageCopyAllHeaderFields( _currentRawResponse );
    CFDataRef body = CFHTTPMessageCopyBody( _currentRawResponse );
    NSString *MIMEType = nil;
    NSString *textEncodingName = nil;
    
    for (NSString *key in [(NSDictionary *) headerFields allKeys])
    {
      if ([key compare: @"Content-Length" options: NSCaseInsensitiveSearch] == NSOrderedSame)
        _expectedLength = [[(NSDictionary *) headerFields objectForKey: key] integerValue];
      else if ([key compare: @"Content-Type" options: NSCaseInsensitiveSearch] == NSOrderedSame)
      {
        MIMEType = [(NSDictionary *) headerFields objectForKey: key];
        
        NSRange trailer = [MIMEType rangeOfString: @";"];
        
        if (trailer.length > 0)
        {
          NSString *trailing = [MIMEType substringFromIndex: NSMaxRange( trailer )];
          NSRange charsetPos = [trailing rangeOfString: @"charset=" options: NSCaseInsensitiveSearch];
          
          MIMEType = [MIMEType substringToIndex: trailer.location];
          if (charsetPos.length > 0)
          {
            textEncodingName = [trailing substringFromIndex: NSMaxRange( charsetPos )];
            trailer = [textEncodingName rangeOfString: @";"];
            if (trailer.length > 0)
              textEncodingName = [textEncodingName substringToIndex: trailer.location];
            textEncodingName = [textEncodingName stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
          }
        }
      }
      
      if (MIMEType != nil && _expectedLength != NSURLResponseUnknownLength)
        break;
    }

    _currentResponse = [[ITHTTPURLResponse alloc]
                        initWithURL: [_currentRequest URL] MIMEType: MIMEType
                        expectedContentLength: _expectedLength textEncodingName: textEncodingName
                        headerFields: (NSDictionary *) headerFields statusCode: (NSInteger) statusCode];
    CFRelease( headerFields );

    if (body == NULL)
      _bytesReceived = 0;
    else
      _bytesReceived = CFDataGetLength( body );
    [_currentDelegate connection: self didReceiveResponse: _currentResponse];

    if (_bytesReceived == _expectedLength && currentRequest == _currentRequest)
      [self handleDataComplete: body];

    if (body != NULL)
      CFRelease( body );    
    [currentRequest release];
  }
}

- (void) handleDataComplete: (CFDataRef) optionalData
{
  BOOL closed;

  if (_currentDelegate == nil)
    closed = _closed;
  else
  {
    NSURLRequest *currentRequest = [_currentRequest retain];
    CFDataRef data;
    
    if (optionalData != NULL)
      data = optionalData;
    else
      data = CFHTTPMessageCopyBody( _currentRawResponse );
    
    [self retain];

    if (data != NULL)
    {
      [_currentDelegate connection: self didReceiveData: (NSData *) data];
      if (optionalData == NULL)
        CFRelease( data );
    }
    
    if (!_closed && currentRequest == _currentRequest)
      [_currentDelegate connectionDidFinishLoading: self];
    [currentRequest release];
    closed = _closed;
    [self release];
  }

  if (!closed)
    [self processNextRequest];
}

- (void) disconnect
{
  //NSLog( @"%@: disconnect: %@", [self stackTraceToDepth: 10] );
  if (_targetSocket != NULL)
  {
    CFSocketDisableCallBacks( _targetSocket, kCFSocketDataCallBack|kCFSocketConnectCallBack );
    CFSocketInvalidate( _targetSocket );
    CFRelease( _targetSocket );
    _targetSocket = NULL;
  }
  [_target release];
  _target = nil;
  _port = 0;
}

- (NSError *) allocError: (NSUInteger) code message: (NSString *) message
{
  return [[NSError alloc] initWithDomain: NSURLErrorDomain code: code 
                                userInfo:
  [NSDictionary dictionaryWithObjectsAndKeys:
   message, NSLocalizedDescriptionKey,
   [[_currentRequest URL] absoluteString], NSURLErrorFailingURLStringErrorKey, nil]];
}

- (void) applicationToForeground
{
  [self processNextRequest];
}

- (void) applicationToBackground
{
  if (!_closed && _currentRequest != nil)
  {
    // Abandon the current request and report an error
    NSError *error = [self allocError: NSURLErrorNetworkConnectionLost
                              message: NSLocalizedString( @"Connection to device closed",
                                                         @"Error shown if socket connection closed" )];
    [self handleError: error];
    [error release];
  }

  [self disconnect];
  [self cleanUp];
}

- (void) cleanUp
{
  [self retain];
  [_currentRequest release];
  _currentRequest = nil;
  [_currentDelegate release];
  _currentDelegate = nil;
  if (_currentRawResponse != NULL)
  {
    CFRelease( _currentRawResponse );
    _currentRawResponse = NULL;
  }
  [_currentResponse release];
  _currentResponse = nil;
  _expectedLength = NSURLResponseUnknownLength;
  _bytesReceived = 0;
  [self release];
}

- (void) dealloc
{
  [AppStateNotification removeObserver: self];

  [self close];
  [self cleanUp];
  [_requests release];
  [_delegates release];
  [super dealloc];
}

@end


// Callback called when we connect (or time out trying to connect) to the remote host, or
// when data has been received.
static void TargetSocketCallBack( CFSocketRef s, CFSocketCallBackType callbackType,
                                     CFDataRef address, const void *data, void *info )
{
  if ([g_openConnections containsObject: [NSNumber numberWithLongLong: (long long) (long) info]])
  {
    ITURLConnection *conn = (ITURLConnection *) info;
  
    if (callbackType == kCFSocketConnectCallBack)
    {
      if (data == NULL)
        [conn initialiseConnectionWithSocket: s];
      else
      {
        NSError *error = [[NSError alloc] initWithDomain: NSPOSIXErrorDomain code: * (NSInteger *) data userInfo: nil];

        [conn disconnect];
        [conn handleError: error];
        [error release];
      }
    }
    else if (callbackType == kCFSocketDataCallBack)
    {
      if (CFDataGetLength( data ) == 0)
        [conn handleRemoteClosed];
      else
        [conn receivedData: (CFDataRef) data];
    }
  }
}
