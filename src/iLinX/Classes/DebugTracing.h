//
//  DebugTracing.h
//  iLinX
//
//  Created by mcf on 21/02/2011.
//  Copyright 2011 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIView (DebugTracing)

- (NSString *) dumpViewToDepth: (NSUInteger) depth;

@end

@interface NSObject (DebugTracing)

- (NSString *) stackTraceToDepth: (NSUInteger) depth;
- (NSString *) stackTraceToDepth: (NSUInteger) depth ignoringFirst: (NSUInteger) ignored;

@end

#if !defined(DEBUG)
#define NSDebugObject NSObject
#else
@interface NSDebugObject : NSObject
{
  NSUInteger _debugMagic;
}

+ (NSSet *) liveObjects;
- (NSString *) displayName;

@end
#endif
