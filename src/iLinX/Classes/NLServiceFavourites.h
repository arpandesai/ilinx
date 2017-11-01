//
//  NLServiceFavourites.h
//  iLinX
//
//  Created by mcf on 06/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLService.h"

@interface NLServiceFavourites : NLService
{
@private
  NSMutableArray *_favourites;
  NSMutableDictionary *_macros;
}

- (NSUInteger) favouriteCount;
- (NLService *) executeFavourite: (NSUInteger) index returnExecutionDelay: (NSTimeInterval *) pDelay;
- (NSString *) nameForFavourite: (NSUInteger) index;

@end
