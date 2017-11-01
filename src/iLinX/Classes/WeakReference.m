//
//  WeakReference.m
//  iLinX
//
//  Created by mcf on 18/02/2011.
//  Copyright 2011 Micropraxis Ltd. All rights reserved.
//

#import "WeakReference.h"

@implementation WeakReference

+ (WeakReference *) weakReferenceForObject: (id) object
{
  return [[[WeakReference alloc] initWithObject: object] autorelease];
}

- (id) initWithObject: (id) object
{
  if (self = [super init])
  {
#if UINT_MAX == UINT32_MAX
    _ref = [[NSNumber numberWithUnsignedLong: (unsigned long) object] retain];
#else
    _ref = [[NSNumber numberWithUnsignedLongLong: (unsigned long long) object] retain];
#endif
  }
  
  return self;
}

- (id) referencedObject
{
#if UINT_MAX == UINT32_MAX
  return (id) [_ref unsignedLongValue];
#else
  return (id) [_ref unsignedLongLongValue];
#endif
}

- (BOOL) isEqual: (id) object
{
  BOOL equal;

  if ([object isKindOfClass: [WeakReference class]])
    object = [object referencedObject];

  equal = (object == [self referencedObject]);
  
  return equal; 
}

- (NSUInteger) hash
{
  return [[self referencedObject] hash];
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"%@ -> %@", [super description], [[self referencedObject] description]];
}

- (id) copyWithZone: (NSZone *) zone
{
  return [self retain];
}

- (void) dealloc
{
  [_ref release];
  [super dealloc];
}

@end
