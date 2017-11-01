//
//  ITResponse.h
//  iLinX
//
//  Created by mcf on 20/10/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DebugTracing.h"

@interface ITResponse : NSDebugObject
{
@private
  NSData *_data;
  NSMutableDictionary *_parsedData;
}

@property (readonly) NSData *data;

- (id) initWithData: (NSData *) data;
- (id) itemForKey: (NSString *) key;
- (ITResponse *) responseForKey: (NSString *) key;
- (NSString *) stringForKey: (NSString *) key;
- (NSNumber *) numberForKey: (NSString *) key;
- (NSUInteger) unsignedIntegerForKey: (NSString *) key;
- (NSArray *) arrayForKey: (NSString *) key;
- (NSString *) numberStringForKey: (NSString *) key;
- (NSArray *) allItemsWithPrefix: (NSString *) prefix;

@end
