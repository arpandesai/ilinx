//
//  ITResponse.m
//  iLinX
//
//  Created by mcf on 20/10/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "ITResponse.h"
#import "StringEncoding.h"

#if defined(DEBUG)
#define TRACEMSG 0
#define DEBUGLOG(x) NSLog##x
#else
#define DEBUGLOG
#endif

static const NSSet *BRANCHES = nil;
static const NSSet *STRINGS  = nil;
static const NSSet *LONGARRAYS = nil;

@protocol TagListener <NSObject>

- (void) foundTag: (NSString *) tag withData: (ITResponse *) response;
- (void) searchDone;

@end


@interface ITResponse ()

- (NSUInteger) searchForTag: (NSString *) tag mlitHalt: (BOOL) mlitHalt delegate: (id<TagListener>) delegate;
- (NSUInteger) searchForTag: (NSString *) tag mlitHalt: (BOOL) mlitHalt delegate: (id<TagListener>) delegate
  offset: (NSUInteger) offset length: (NSUInteger) length;
- (void) parse;
- (void) parseReportingTag: (NSString *) tag delegate: (id<TagListener>) delegate;
- (void) parseInto: (ITResponse *) response reportingTag: (NSString *) tag delegate: (id<TagListener>) delegate
            offset: (NSUInteger) offset length: (NSUInteger) length;
- (NSString *) readStringAtOffset: (NSUInteger) offset length: (NSUInteger) length;
- (NSUInteger) readUIntAtOffset: (NSUInteger) offset length: (NSUInteger) length;
- (uint64_t) readULongLongAtOffset: (NSUInteger) offset;
- (BOOL) isStringMlitAtOffset: (NSUInteger) offset length: (NSUInteger) length;

@end


@implementation ITResponse

@synthesize
  data = _data;

- (id) initWithData: (NSData *) data
{
  if (self = [super init])
  {
    _data = [data retain];
    if (BRANCHES == nil)
    {
      BRANCHES = [[NSSet setWithObjects: 
                   @"cmst", @"mlog", @"agal", @"mlcl", 
                   @"mshl", @"abro", @"abar", @"mlit",
                   @"apso", @"caci", @"avdb", @"cmgt",
                   @"aply", @"adbs", @"mupd", @"abgn", 
                   @"abcp", @"msrv", @"msml", nil] retain];
      STRINGS  = [[NSSet setWithObjects:
                   @"minm", @"cann", @"cana", @"canl",
                   @"cang", @"asaa", @"asal", @"asar",
                   @"ascn", nil] retain];
      LONGARRAYS = [[NSSet setWithObjects: @"canp", nil] retain];
    }
  }
  
  return self;
}

- (id) initPreParsed
{
  if (self = [super init])
    _parsedData = [NSMutableDictionary new];
  
  return self;
}

- (id) itemForKey: (NSString *) key
{
  if (_parsedData == nil)
    [self parse];

  return [_parsedData objectForKey: key];
}

- (ITResponse *) responseForKey: (NSString *) key
{
  id item = [self itemForKey: key];
  
  if (![item isKindOfClass: [ITResponse class]])
    item = nil;

  return (ITResponse *) item;
}

- (NSString *) stringForKey: (NSString *) key
{
  id item = [self itemForKey: key];
  
  if (![item isKindOfClass: [NSString class]])
    item = @"";
  
  return (NSString *) item;
}

- (NSNumber *) numberForKey: (NSString *) key
{
  id item = [self itemForKey: key];
  
  if (![item isKindOfClass: [NSNumber class]])
    item = [NSNumber numberWithInt: -1];
  
  return (NSNumber *) item;
}

- (NSUInteger) unsignedIntegerForKey: (NSString *) key
{
  return [[self numberForKey: key] unsignedIntegerValue];
}

- (NSArray *) arrayForKey: (NSString *) key
{
  id item = [self itemForKey: key];
  
  if (![item isKindOfClass: [NSArray class]])
    item = nil;
  
  return (NSArray *) item;
}

- (NSString *) numberStringForKey: (NSString *) key
{
  return [[self numberForKey: key] stringValue];
}

- (NSArray *) allItemsWithPrefix: (NSString *) prefix
{
  if (_parsedData == nil)
    [self parse];

  NSMutableArray *array = [NSMutableArray arrayWithCapacity: [_parsedData count]];

  for (NSString *key in [[_parsedData allKeys] sortedArrayUsingSelector: @selector(compare:)])
  {
    if ([key hasPrefix: prefix])
      [array addObject: [_parsedData objectForKey: key]];
  }
    
  return array;
}
  
- (NSUInteger) searchForTag: (NSString *) tag mlitHalt: (BOOL) mlitHalt delegate: (id<TagListener>) delegate
{
  NSUInteger hits = [self searchForTag: tag mlitHalt: mlitHalt delegate: delegate
                            offset: 0 length: [_data length]];

  [delegate searchDone];
  return hits;
}

- (NSUInteger) searchForTag: (NSString *) tag mlitHalt: (BOOL) mlitHalt delegate: (id<TagListener>) delegate
  offset: (NSUInteger) offset length: (NSUInteger) length
{
  NSUInteger hits = 0;
  NSUInteger limit = offset + length;
  
  // loop until done with the section weve been assigned
  while (offset < limit)
  {
    NSString *key = [self readStringAtOffset: offset length: 4];
    NSUInteger blockLength = [self readUIntAtOffset: offset + 4 length: 4];

    offset += 8;

    // check if we need to handle mlit special-case where it doesnt branch
    if (mlitHalt && [key isEqualToString: @"mlit"])
    {
      ITResponse *resp = [[ITResponse alloc] initPreParsed];

      [resp->_parsedData setObject: [self readStringAtOffset: offset length: blockLength] forKey: key];
      [delegate foundTag: key withData: resp];
      ++hits;
      [resp release];
    }
    else if ([BRANCHES containsObject: key])
    {
      if ([key isEqualToString: tag])
      {
        // parse and report if interesting branches
        ITResponse *found = [[ITResponse alloc] initPreParsed];
        
        [self parseInto: found reportingTag: tag delegate: delegate offset: offset length: blockLength];
        [delegate foundTag: key withData: found];
        ++hits;
        [found release];
      }
      else
      {
        // recurse searching for other branches
        hits += [self searchForTag: tag mlitHalt: mlitHalt delegate: delegate offset: offset length: blockLength];
      }
    }

    offset += blockLength;
  }
  
  return hits;
}

- (void) parse
{
  [self parseReportingTag: nil delegate: nil];
}

- (void) parseReportingTag: (NSString *) tag delegate: (id<TagListener>) delegate
{
  if (_parsedData == nil)
  {
    _parsedData = [NSMutableDictionary new];
    [self parseInto: self reportingTag: tag delegate: delegate offset: 0 length: [_data length]];
    [delegate searchDone];
  }
  else
  {
    [self searchForTag: tag mlitHalt: NO delegate: delegate offset: 0 length: [_data length]];
  }
}

#if TRACEMSG
static NSUInteger level = 0;
static NSString *padding = @"                    ";
#endif

- (void) parseInto: (ITResponse *) response reportingTag: (NSString *) tag delegate: (id<TagListener>) delegate
  offset: (NSUInteger) offset length: (NSUInteger) length
{
  NSUInteger limit = offset + length;
#if TRACEMSG
  NSString *debugString;
#endif

  // loop until done with the section weve been assigned
  while (offset + 8 < limit)
  {
    NSString *key = [self readStringAtOffset: offset length: 4];
    NSUInteger blockLength = [self readUIntAtOffset: offset + 4 length: 4];

    offset += 8;

#if TRACEMSG
    debugString = [NSString stringWithFormat: @"%@%@ %u", [padding substringToIndex: level], key, blockLength];
#endif
    // handle key collisions by using index notation
    NSString *niceKey = ([response->_parsedData objectForKey: key] != nil) ? 
       [NSString stringWithFormat: @"%@[%06d]", key, offset] : key;
    
    if (blockLength > length)
      offset = limit;
    else if ([key isEqualToString: @"mlit"] && [self isStringMlitAtOffset: offset length: blockLength])
    {
      [response->_parsedData setObject: [self readStringAtOffset: offset length: blockLength] forKey: niceKey];
#if TRACEMSG
      NSLog( @"%@ \"%@\"", debugString, [response->_parsedData objectForKey: niceKey] );
#endif
    }
    else if ([BRANCHES containsObject: key])
    {
      // recurse off to handle branches
      ITResponse *branch = [[ITResponse alloc] initPreParsed];
      
#if TRACEMSG
      ++level;
      NSLog( @"%@", debugString );
#endif
      [self parseInto: branch reportingTag: tag delegate: delegate 
               offset: offset length: blockLength];
      [response->_parsedData setObject: branch forKey: niceKey];
      
      // pass along to listener if needed
      if ([tag isEqualToString: key])
        [delegate foundTag: key withData: branch];
      [branch release];
#if TRACEMSG
      --level;
#endif
    }
    else if ([STRINGS containsObject: key])
    {
      // force handling as string
      [response->_parsedData setObject: [self readStringAtOffset: offset length: blockLength] forKey: niceKey];
#if TRACEMSG
      NSLog( @"%@ \"%@\"", debugString, [response->_parsedData objectForKey: niceKey] );
#endif
    }
    else if ([LONGARRAYS containsObject: key] && blockLength % 4 == 0)
    {
      // force handling as array of longs
      NSUInteger items = blockLength / 4;
      NSMutableArray *array = [NSMutableArray arrayWithCapacity: items];
      
      for (NSUInteger i = 0; i < items; ++i)
        [array addObject: [NSNumber numberWithUnsignedInteger: [self readUIntAtOffset: offset + (i * 4) length: 4]]];
      [response->_parsedData setObject: array forKey: niceKey];
#if TRACEMSG
      NSLog( @"%@ %@", debugString, array );
#endif
    }
    else if (blockLength == 1 || blockLength == 2 || blockLength == 4)
    {
      // handle parsing unsigned bytes, shorts and ints
      [response->_parsedData setObject: [NSNumber numberWithUnsignedInteger:
                        [self readUIntAtOffset: offset length: blockLength]] forKey: niceKey];
#if TRACEMSG
      unsigned long ul = [(NSNumber *) [response->_parsedData objectForKey: niceKey] unsignedLongValue];
      NSLog( @"%@ 0x%0*X = %u", debugString, blockLength * 2, ul, ul );
#endif
    }
    else if (blockLength == 8)
    {
      // handle parsing unsigned longs
      [response->_parsedData setObject: [NSNumber numberWithUnsignedLongLong:
                        [self readULongLongAtOffset: offset]] forKey: niceKey];
#if TRACEMSG
      unsigned long long ul = [(NSNumber *) [response->_parsedData objectForKey: niceKey] unsignedLongLongValue];
      NSLog( @"%@ 0x%016qX = %qu", debugString, ul, ul );
#endif
    }
    else
    {
      // fallback to just parsing as string
      [response->_parsedData setObject: [self readStringAtOffset: offset length: blockLength] forKey: niceKey];
#if TRACEMSG
      NSLog( @"%@ \"%@\"", debugString, [response->_parsedData objectForKey: niceKey] );
#endif
    }
    
    offset += blockLength;
  }
}

- (NSString *) readStringAtOffset: (NSUInteger) offset length: (NSUInteger) length
{
  const unsigned char *pData = (const unsigned char *) [_data bytes];
  CFStringEncoding guessEncoding = StringEncodingFor( pData + offset, length );
  CFStringRef string = CFStringCreateWithBytes( kCFAllocatorDefault, pData + offset, length, 
                                               guessEncoding, FALSE );
  NSString *retValue;

  // Maybe guessed wrong?
  if (string == NULL && guessEncoding == kCFStringEncodingUTF8)
    string = CFStringCreateWithBytes( kCFAllocatorDefault, pData + offset, length, 
                                     kCFStringEncodingWindowsLatin1, FALSE );

  // Still NULL; a memory problem or a corrupt string
  if (string == NULL)
    retValue = @"";
  else
  {
    retValue = [NSString stringWithString: (NSString *) string];
    CFRelease( string );
  }
  
  return retValue;
}

- (NSUInteger) readUIntAtOffset: (NSUInteger) offset length: (NSUInteger) length
{
  const unsigned char *pData = (const unsigned char *) [_data bytes];
  NSUInteger retValue = 0;
  
  while (length-- > 0)
    retValue = (retValue << 8) | pData[offset++];
  
  return retValue;
}


- (uint64_t) readULongLongAtOffset: (NSUInteger) offset
{
  const unsigned char *pData = (const unsigned char *) [_data bytes];
  uint64_t retValue = 0;
  
  for (NSUInteger length = 8; length > 0; length--)
    retValue = (retValue << 8) | pData[offset++];
  
  return retValue;
}

- (BOOL) isStringMlitAtOffset: (NSUInteger) offset length: (NSUInteger) length
{
  BOOL isString = (length < 8);
  
  if (!isString)
  {
    NSUInteger parsedLength = 0;

    while (parsedLength <= length - 4)
    {
      NSUInteger blockLength = [self readUIntAtOffset: offset + parsedLength + 4 length: 4];
      
      if (blockLength > length)
        break;
      else
        parsedLength += blockLength + 8;
    }
    
    if (parsedLength != length)
      isString = YES;
  }
  
  return isString;
}

- (void) dealloc
{
  [_data release];
  [_parsedData release];
  [super dealloc];
}

@end
