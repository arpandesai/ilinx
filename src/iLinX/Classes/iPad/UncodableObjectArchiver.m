//
//  UncodableObjectArchiver.m
//  iLinX
//
//  Created by mcf on 16/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "UncodableObjectArchiver.h"

@interface UncodableObjectProxy : NSObject <NSCoding>
{
@private
  NSString *_key;
}

@property (readonly) NSString * key;

- (id) initWithKey: (NSString *) key;

@end

@implementation UncodableObjectProxy

@synthesize key = _key;

- (id) initWithKey: (NSString *) key
{
  if (self = [super init])
    _key = [key retain];
  
  return self;
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
  if (self = [super init])
    _key = [[aDecoder decodeObjectForKey: @"key"] retain];
  
  return self;
}

- (void) encodeWithCoder: (NSCoder *) aCoder
{
  [aCoder encodeObject: _key forKey: @"key"];
}

- (void) dealloc
{
  [_key release];
  [super dealloc];
}

@end

@implementation UncodableObjectArchiver

@synthesize
  dictionary = _dictionary;

- (id) initForWritingWithDictionary
{
  NSMutableData *codedData = [NSMutableData new];

  if (self = [super initForWritingWithMutableData: codedData])
  {
    _dictionary = [NSMutableDictionary new];
    [_dictionary setObject: codedData forKey: @"data"];
  }

  [codedData release];
  
  return self;
}

+ (NSDictionary *) dictionaryEncodingWithRootObject: (id) rootObject
{
  UncodableObjectArchiver *archiver = [[UncodableObjectArchiver alloc] initForWritingWithDictionary];
  NSDictionary *result;

  [archiver encodeRootObject: rootObject];
  [archiver finishEncoding];
  
  result = [[archiver.dictionary retain] autorelease];
  [archiver release];
  
  return result;
}

- (void) encodeObject: (id) object forKey: (NSString *) key
{
  if (object == nil || [object respondsToSelector: @selector(encodeWithCoder:)])
    [super encodeObject: object forKey: key];
  else
  {
    NSString *proxyKey = [NSString stringWithFormat: @"%x", (NSUInteger) object];
    UncodableObjectProxy *proxy = [[UncodableObjectProxy alloc] initWithKey: proxyKey];
    
    [super encodeObject: proxy forKey: key];
    [_dictionary setObject: object forKey: proxyKey];
    [proxy release];
  }
}

@end
     
@implementation UncodableObjectUnarchiver

- (id) initWithDictionary: (NSDictionary *) dictionary
{
  if (self = [super initForReadingWithData: [dictionary objectForKey: @"data"]])
    _dictionary = [dictionary retain];
  
  return self;
}

+ (id) unarchiveObjectWithDictionary: (NSDictionary *) dictionary
{
  UncodableObjectUnarchiver *unarchiver = [[UncodableObjectUnarchiver alloc] initWithDictionary: dictionary];
  id result = [[[unarchiver decodeObject] retain] autorelease];
  
  [unarchiver finishDecoding];
  [unarchiver release];
  
  return result;
}

- (id) decodeObjectForKey: (NSString *) key
{
  id result = [super decodeObjectForKey: key];
  
  if ([result isKindOfClass: [UncodableObjectProxy class]])
    result = [_dictionary objectForKey: [result key]];
  
  return result;
}

@end
