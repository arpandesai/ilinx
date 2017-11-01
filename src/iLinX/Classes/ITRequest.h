//
//  ITRequest.h
//  iLinX
//
//  Created by mcf on 19/10/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ITURLConnection.h"
#import "DebugTracing.h"

@class ITRequest;
@class ITResponse;
@class ITSession;

@protocol ITRequestDelegate <NSObject>

- (void) request: (ITRequest *) request failedWithError: (NSError *) error;
- (void) request: (ITRequest *) request succeededWithResponse: (ITResponse *) response;

@end

@interface ITRequest : NSDebugObject <NSCopying, ITURLResponseHandler>
{
@private
  id<ITRequestDelegate> _delegate;
  NSString *_requestString;
  ITURLConnection *_conn;
  NSMutableData *_data;
  ITResponse *_response;
  BOOL _compressed;
}

@property (readonly) NSString *requestString;

+ (id) allocRequest: (NSString *) requestString connection: (ITURLConnection *) connection 
            delegate: (id<ITRequestDelegate>) delegate;
+ (id) allocSearchRequest: (NSString *) search from: (NSInteger) start to: (NSInteger) end
                 inSession: (ITSession *) session connection: (ITURLConnection *) connection 
                  delegate: (id<ITRequestDelegate>) delegate;
+ (id) allocRequestTracksFromAlbum: (NSString *) albumId inSession: (ITSession *) session 
                        connection: (ITURLConnection *) connection delegate: (id<ITRequestDelegate>) delegate;
+ (id) allocRequestAlbumsFrom: (NSInteger) start to: (NSInteger) end inSession: (ITSession *) session 
                   connection: (ITURLConnection *) connection delegate: (id<ITRequestDelegate>) delegate;
+ (id) allocRequestPlaylistsInSession: (ITSession *) session connection: (ITURLConnection *) connection 
                             delegate: (id<ITRequestDelegate>) delegate;
+ (id) allocRequestThumbnail: (NSInteger) itemId inSession: (ITSession *) session connection: (ITURLConnection *) connection 
                    delegate: (id<ITRequestDelegate>) delegate;
+ (NSString *) requestErrorDomain;

- (id) initWithConnection: (ITURLConnection *) connection delegate: (id<ITRequestDelegate>) delegate
            requestString: (NSString *) requestString;
- (void) cancel;

@end
