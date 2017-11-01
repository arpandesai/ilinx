//
//  ArtworkRequest.h
//  iLinX
//
//  Created by mcf on 19/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ArtworkCache;
@class NLSource;

@interface ArtworkRequest : NSObject
{
@private
  NLSource *_source;
  NSDictionary *_item;
  id _target;
  SEL _action;
  NSArray *_imagesData;
  NSUInteger _currentImage;
  NSURL *_artworkURL;
  NSString *_currentImageHref;
  NSURLConnection *_connection;
  NSMutableData *_data;
}

+ (ArtworkRequest *) allocRequestImageForSource: (NLSource *) source item: (NSDictionary *) item 
                                    target: (id) target action: (SEL) action;
+ (void) flushCache;

- (void) invalidate;

@end

// Private interface used by the ArtworkCache class
@interface ArtworkRequest (ArtworkCache)

- (void) startSearch: (ArtworkCache *) cache;

@end
