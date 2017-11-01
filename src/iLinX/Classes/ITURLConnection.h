//
//  ITURLConnection.h
//  iLinX
//
//  Created by mcf on 04/11/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CFNetwork/CFHTTPMessage.h>
#import "DebugTracing.h"

@class ITHTTPURLResponse;
@class ITURLConnection;

@protocol ITURLResponseHandler <NSObject>

- (void) connection: (ITURLConnection *) connection didReceiveResponse: (NSURLResponse *) response;
- (void) connection: (ITURLConnection *) connection didReceiveData: (NSData *) data;
- (void) connectionDidFinishLoading: (ITURLConnection *) connection;
- (void) connection: (ITURLConnection *) connection didFailWithError: (NSError *) error;

@end

@interface ITURLConnection : NSDebugObject
{
@private
  NSString *_target;
  NSUInteger _port;
  CFSocketRef _targetSocket;
  NSMutableArray *_requests;
  NSMutableArray *_delegates;
  NSURLRequest *_currentRequest;
  id<ITURLResponseHandler> _currentDelegate;
  CFHTTPMessageRef _currentRawResponse;
  ITHTTPURLResponse *_currentResponse;
  NSInteger _expectedLength;
  NSInteger _bytesReceived;
  BOOL _closed;
  BOOL _connectionPending;
}

- (void) submitRequest: (NSURLRequest *) request delegate: (id<ITURLResponseHandler>) delegate;
- (void) cancelWithDelegate: (id<ITURLResponseHandler>) delegate;
- (void) close;

@end
