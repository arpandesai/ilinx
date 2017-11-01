//
//  ITRequest.m
//  iLinX
//
//  Created by mcf on 19/10/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "ITRequest.h"
#import "ITResponse.h"
#import "ITSession.h"
#import "ITURLConnection.h"
#import "ITHTTPURLResponse.h"
#include <zlib.h>

// Timeout for sending iTunes requests, in seconds
#define ITUNES_REQUEST_TIMEOUT 10

static NSString *ITREQUEST_ERROR_DOMAIN = @"iLinXITRequestErrorDomain";

@implementation ITRequest

@synthesize
  requestString = _requestString;

+ (id) allocRequest: (NSString *) requestString connection: (ITURLConnection *) connection
            delegate: (id<ITRequestDelegate>) delegate
{
  NSMutableURLRequest *urlRequest =
    [NSMutableURLRequest requestWithURL: [NSURL URLWithString: requestString] 
                            cachePolicy: NSURLRequestUseProtocolCachePolicy
                        timeoutInterval: ITUNES_REQUEST_TIMEOUT];
  
  [urlRequest setValue: @"1" forHTTPHeaderField: @"Viewer-Only-Client"];
  [urlRequest setValue: @"gzip,deflate" forHTTPHeaderField: @"Accept-Encoding"];
  [urlRequest setValue: @"Remote/1.3.3" forHTTPHeaderField: @"User-Agent"];

  ITRequest *request = [[ITRequest alloc] initWithConnection: connection delegate: delegate requestString: requestString];
  
  [connection submitRequest: urlRequest delegate: request];
  
  return request;
}

+ (id) allocSearchRequest: (NSString *) search from: (NSInteger) start to: (NSInteger) end
                inSession: (ITSession *) session connection: (ITURLConnection *) connection
                 delegate: (id<ITRequestDelegate>) delegate
{
  // doesnt seem to listen to &sort=name
  NSString *encodedSearch = [[search stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
                             stringByReplacingOccurrencesOfString: @"\\+" withString: @"%20"];
  
  return [self allocRequest: [NSString stringWithFormat: 
                         @"%@/databases/%@/containers/%@/items?session-id=%@&meta=dmap.itemname,dmap.itemid,daap.songartist,daap.songalbum&type=music&include-sort-headers=1&query=(('com.apple.itunes.mediakind:1','com.apple.itunes.mediakind:4','com.apple.itunes.mediakind:8')+('dmap.itemname:*%@*','daap.songartist:*%@*','daap.songalbum:*%@*'))&sort=name&index=%d-%d",
                         [session getRequestBase], session.databaseId, session.musicId,
                         session.sessionId, encodedSearch, encodedSearch, encodedSearch, start, end]
                  connection: connection delegate: delegate];
}

+ (id) allocRequestTracksFromAlbum: (NSString *) albumId inSession: (ITSession *) session 
                        connection: (ITURLConnection *) connection delegate: (id<ITRequestDelegate>) delegate
{
  return [self allocRequest: [NSString stringWithFormat:
                         @"%@/databases/%@/containers/%@/items?session-id=%@&meta=dmap.itemname,dmap.itemid,daap.songartist,daap.songalbum,daap.songalbum,daap.songtime,daap.songtracknumber&type=music&sort=album&query='daap.songalbumid:%@'",
                         [session getRequestBase], session.databaseId, session.musicId, session.sessionId, albumId]
                  connection: connection delegate: delegate];
}

+ (id) allocRequestAlbumsFrom: (NSInteger) start to: (NSInteger) end inSession: (ITSession *) session
                   connection: (ITURLConnection *) connection delegate: (id<ITRequestDelegate>) delegate
{
  return [self allocRequest: [NSString stringWithFormat:
                         @"%@/databases/%@/containers/%@/items?session-id=%@&meta=dmap.itemname,dmap.itemid,dmap.persistentid,daap.songartist&type=music&group-type=albums&sort=artist&include-sort-headers=1&index=%d-%d",
                         [session getRequestBase], session.databaseId, session.musicId, session.sessionId, start, end]
               connection: connection delegate: delegate];
}

+ (id) allocRequestPlaylistsInSession: (ITSession *) session connection: (ITURLConnection *) connection 
                             delegate: (id<ITRequestDelegate>) delegate
{
  return [self allocRequest: [NSString stringWithFormat:
                         @"%@/databases/%@/containers?session-id=%@&meta=dmap.itemname,dmap.itemcount,dmap.itemid,dmap.persistentid,daap.baseplaylist,com.apple.itunes.special-playlist,com.apple.itunes.smart-playlist,com.apple.itunes.saved-genius,dmap.parentcontainerid,dmap.editcommandssupported",
                         [session getRequestBase], session.databaseId, session.sessionId]
                  connection: connection delegate: delegate];
}

+ (id) allocRequestThumbnail: (NSInteger) itemId inSession: (ITSession *) session connection: (ITURLConnection *) connection 
                    delegate: (id<ITRequestDelegate>) delegate
{
  return [self allocRequest: [NSString stringWithFormat:
                         @"%@/databases/%@/items/%d/extra_data/artwork?session-id=%@&mw=130&mh=130",
                         [session getRequestBase], session.databaseId, itemId, session.sessionId]
                  connection: connection delegate: delegate];
}

+ (NSString *) requestErrorDomain
{
  return ITREQUEST_ERROR_DOMAIN;
}

- (id) initWithConnection: (ITURLConnection *) connection delegate: (id<ITRequestDelegate>) delegate
            requestString: (NSString *) requestString
{
  if (self = [super init])
  {
    _conn = [connection retain];
    _delegate = delegate; // Don't retain - they retain us
    _requestString = [requestString retain];
  }
  
  return self;
}

- (void) cancel
{
  _delegate = nil;
  [_conn cancelWithDelegate: self];
  [_conn release];
  _conn = nil;
}

- (id) copyWithZone: (NSZone *) zone
{
  return [self retain];
}

- (void) connection: (ITURLConnection *) connection didReceiveResponse: (NSURLResponse *) response
{
  if (![response isKindOfClass: [ITHTTPURLResponse class]] ||
      [(ITHTTPURLResponse *) response statusCode] > 299)
  {
    NSURL *url = [response URL];
    NSString *errorString;
    NSInteger code;
    
    if ([response isKindOfClass: [ITHTTPURLResponse class]])
    {
      code = [(ITHTTPURLResponse *) response statusCode];
      errorString = [NSHTTPURLResponse localizedStringForStatusCode: code];
    }
    else
    {
      code = -1;
      errorString = NSLocalizedString( @"Unexpected response class", 
                                      @"Error string when we don't get an ITHTTPURLResponse from an HTTP request" );
    }

    [self retain];
    [connection cancelWithDelegate: self];
    [self connection: connection 
    didFailWithError: [NSError errorWithDomain: ITREQUEST_ERROR_DOMAIN code: code 
                                      userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
                                                 [url absoluteString], NSURLErrorFailingURLStringErrorKey,
                                                 errorString, NSLocalizedDescriptionKey, nil]]];
    [self release];
  }
  else
  {
#ifdef DEBUG
    //NSURL *url = [response URL];
    //NSInteger code = [(ITHTTPURLResponse *) response statusCode];

    //**/NSLog( @"%@ OK: %d (%@): %@", url, code, [NSHTTPURLResponse localizedStringForStatusCode: code], [response MIMEType] );
    //**/NSLog( @"Headers: %@", [(ITHTTPURLResponse *) response allHeaderFields] );
#endif
    _compressed = ([[(ITHTTPURLResponse *) response allHeaderFields] objectForKey: @"Content-Encoding"] != nil);
  }
}

- (void) connection: (ITURLConnection *) connection didReceiveData: (NSData *) data
{
  if (_data == nil)
    _data = [data mutableCopy];
  else
    [_data appendData: data]; 
}

- (void) connectionDidFinishLoading: (ITURLConnection *) connection
{
  if (_compressed)
  {
    int ret;
    z_stream strm;
    unsigned char buffer[16384];
    
    memset( &strm, 0, sizeof(strm) );
    ret = inflateInit2( &strm, 15+32 );
    if (ret == Z_OK)
    {
      strm.avail_in = [_data length];
      strm.next_in = (Bytef *) [_data bytes];
      NSMutableData *uncompressed = [[NSMutableData alloc] init];

      do
      {
        strm.avail_out = sizeof(buffer);
        strm.next_out = buffer;
        ret = inflate( &strm, Z_NO_FLUSH );
        if (ret == Z_OK || ret == Z_STREAM_END)
          [uncompressed appendBytes: buffer length: sizeof(buffer) - strm.avail_out];
        else
          strm.avail_out = sizeof(buffer);
      }
      while (strm.avail_out == 0);
        
      inflateEnd( &strm );
      if (ret == Z_STREAM_END)
      {
        [_data release];
        _data = [uncompressed retain];
      }
      [uncompressed release];
    }
  }

  [_conn release];
  _conn = nil;
  _response = [[ITResponse alloc] initWithData: _data];
  if (_delegate != nil)
    [_delegate request: self succeededWithResponse: _response];
}

- (void) connection: (ITURLConnection *) connection didFailWithError: (NSError *) error
{
#ifdef DEBUG
  //NSDictionary *userInfo = [error userInfo];
  
  //**/NSLog( @"%@ failed: %d (%@)", [userInfo objectForKey: NSErrorFailingURLStringKey],
  //**/      [error code], [userInfo objectForKey: NSLocalizedDescriptionKey] );
#endif

  [_conn release];
  _conn = nil;
  if (_delegate != nil)
    [_delegate request: self failedWithError: error];
}

- (void) dealloc
{
  [_requestString release];
  if (_conn != nil)
  {
    [_conn cancelWithDelegate: self];
    [_conn release];
    _conn = nil;
  }
  [_data release];
  [_response release];
  [super dealloc];
}

@end
