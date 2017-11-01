//
//  DebugTracing.m
//  iLinX
//
//  Created by mcf on 21/02/2011.
//  Copyright 2011 Micropraxis Ltd. All rights reserved.
//

#import "DebugTracing.h"
#import "WeakReference.h"
#include "execinfo.h"

@implementation UIView (DebugTracing)


- (NSString *) _dumpViewToDepth: (NSUInteger) depth atLevel: (NSUInteger) level
{
  NSString *dump = [NSString stringWithFormat: @"%*.*s%@", level - 1, level - 1, "", self];
  
  if (level < depth)
  {
    for (UIView *subView in [self subviews])
      dump = [dump stringByAppendingFormat: @"\n%@", [subView _dumpViewToDepth: depth atLevel: level + 1]];
  }
  
  return dump;
}

- (NSString *) dumpViewToDepth: (NSUInteger) depth
{
  return [self _dumpViewToDepth: depth atLevel: 1];
}

@end


@implementation NSObject (DebugTracing)

- (NSString *) stackTraceToDepth: (NSUInteger) depth
{
  return [self stackTraceToDepth: depth ignoringFirst: 2];
}

- (NSString *) stackTraceToDepth: (NSUInteger) depth ignoringFirst: (NSUInteger) ignored
{
  void * callstack[128];
  NSString *callPath = @"";
  
  depth += ignored;
  if (depth > 128)
    depth = 128;
  
  int frames = backtrace( callstack, depth );
  char** strs = backtrace_symbols( callstack, frames );
  
  for (int i = ignored; i < frames; ++i)
  {
    NSString *trace = [NSString stringWithFormat: @"%s", strs[i]];
    NSRange r = [trace rangeOfString: @"0x"];
    
    if (r.length > 0)
      trace = [trace substringFromIndex: r.location];
    callPath = [callPath stringByAppendingFormat: @"  %@\n", trace];
  }
  
  free( strs );
  if (frames < depth)
    callPath = [callPath substringToIndex: [callPath length] - 2];
  else
    callPath = [callPath stringByAppendingString: @"..."];
  
  return callPath;
}

@end

#if defined(DEBUG)
static NSSet *TRACE_CLASSES = nil;
static NSMutableSet *g_liveObjects = nil;

@implementation NSDebugObject

+ (NSSet *) liveObjects
{
  return g_liveObjects;
}

- (NSString *) displayName
{
  return @"";
}

- (void) _conditionalStackTraceToLog: (NSString *) type
{
  if (TRACE_CLASSES == nil)
  {
    TRACE_CLASSES = [[NSSet setWithObjects:
                      //@"CustomViewController",
                      //@"ITSession", 
                      //@"ITRequest",
                      //@"ITStatus",
                      //@"ITURLConnection",
                      //@"NLSourceMediaServerITunes",
                      //@"NLSourceMediaServerNetStreams",
                      //@"NLBrowseListITunesRoot",
                      //@"NLBrowseListITunes",
                      //@"NLBrowseListITunesWaiting",
                      //@"NLBrowseListNetStreams",
                      //@"NLRoomList",
                      //@"NLServiceList",
                      //@"NLServiceTimers",
                      //@"NLServiceTimersCheckService",
                      //@"NLServiceTimersCheckServiceProxy",
                      nil] retain];
  }
  
  if ([TRACE_CLASSES containsObject: NSStringFromClass( [self class] )])
  {
    NSString *name;
    
    if ([type isEqualToString: @"alloc"])
      name = @"";
    else
      name = [self displayName];
    NSLog( @"%@ %@ %@\n%@", self, name, type, [self stackTraceToDepth: 10 ignoringFirst: 3] );
  }
}

+ (id) allocWithZone: (NSZone *) zone
{
  id newItem = [super allocWithZone: zone];
  ((NSDebugObject *) newItem)->_debugMagic = (((NSUInteger) newItem) ^ 0x10203040);
  
  [newItem _conditionalStackTraceToLog: @"alloc"];
  
  if (g_liveObjects == nil)
    g_liveObjects = [NSMutableSet new];
  
  [g_liveObjects addObject: [WeakReference weakReferenceForObject: newItem]];

  return newItem;
}

- (id) retain
{
  if (_debugMagic != (((NSUInteger) self) ^ 0x10203040))
    NSLog( @"Bogus object!" );
  [self _conditionalStackTraceToLog: @"retain"];
  return [super retain];
}

- (oneway void) release
{
  if (_debugMagic != (((NSUInteger) self) ^ 0x10203040))
    NSLog( @"Bogus object!" );
  [self _conditionalStackTraceToLog: @"release"];
  [super release];
}

- (void) dealloc
{
  if (_debugMagic != (((NSUInteger) self) ^ 0x10203040))
    NSLog( @"Bogus object!" );
  _debugMagic = 0;
  [self _conditionalStackTraceToLog: @"dealloc"];
  [g_liveObjects removeObject: [WeakReference weakReferenceForObject: self]];
  [super dealloc];
}

@end
#endif
