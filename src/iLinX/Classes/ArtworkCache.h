//
//  ArtworkCache.h
//  iLinX
//
//  Created by mcf on 18/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ArtworkCacheItem;
@class ArtworkRequest;
@class NLSource;

@interface ArtworkCache : NSObject <NSXMLParserDelegate>
{
@private
  NSURL *_artworkURL;
  NSURLConnection *_connection;
  NSMutableData *_data;
  NSMutableDictionary *_gallery;
  ArtworkCacheItem *_matchTree;
  ArtworkCacheItem *_currentMatch;
  NSMutableArray *_buildStack;
  NSDictionary *_currentImage;
  NSString *_text;
  NSMutableArray *_pendingRequests;
}

@property (readonly) NSURL *artworkURL;

- (id) initWithArtworkURL: (NSURL *) artworkURL;
- (void) addRequest: (ArtworkRequest *) request;
- (NSArray *) findMatchesForSource: (NLSource *) source item: (NSDictionary *) item;

@end
