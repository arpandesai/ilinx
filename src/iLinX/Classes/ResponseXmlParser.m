//
//  ResponseXmlParser.m
//  iLinX
//
//  Created by mcf on 14/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "ResponseXmlParser.h"

@interface NSMutableDictionary (ResponseXmlParser)

- (NSMutableDictionary *) setResponseValue: (NSString *) value forKey: (NSString *) key;

@end

@implementation NSMutableDictionary (ResponseXmlParser)

- (NSMutableDictionary *) setResponseValue: (NSString *) value forKey: (NSString *) key
{
  if (value != nil && [value length] > 0 && [value characterAtIndex: [value length] - 1] == '"')
  {
    value = [value stringByReplacingOccurrencesOfString: @"&quot;" withString: @"\""];
    value = [value stringByReplacingOccurrencesOfString: @"&lt;" withString: @"<"];
    value = [value stringByReplacingOccurrencesOfString: @"&gt;" withString: @">"];
    value = [value stringByReplacingOccurrencesOfString: @"&amp;" withString: @"&"];
    value = [value stringByReplacingOccurrencesOfString: @"&apos;" withString: @"'"];
    
    [self setObject: [value substringToIndex: [value length] - 1] forKey: key];
  }
  
  return self;
}

@end

@implementation ResponseXmlParser

- (NSDictionary *) parseResponseXML: (NSString *) xmlString
{
  // Actually, the string isn't proper XML - it allows the special characters <, > and &
  // within the data items.  So, we parse it ourselves longhand rather than relying on
  // the built-in XML parser.

  NSMutableDictionary *result;
  
  xmlString = [xmlString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  
  if (!([xmlString hasPrefix: @"<"] && [xmlString hasSuffix: @"/>"]))
    result = nil;
  else
  {
    result = [NSMutableDictionary dictionaryWithCapacity: 10];

    if ([xmlString hasSuffix: @" />"])
      xmlString = [xmlString substringToIndex: [xmlString length] - 3];
    else
      xmlString = [xmlString substringToIndex: [xmlString length] - 2];

    NSArray *parts = [xmlString componentsSeparatedByString: @" "];
    NSUInteger count = [parts count];
    NSString *tag = nil;
    NSString *value = nil;
    NSUInteger i;
    
    [result setObject: [[parts objectAtIndex: 0] substringFromIndex: 1] forKey: @"responseType"];
    
    for (i = 1; i < count; ++i)
    {
      NSString *part = [parts objectAtIndex: i];
      NSRange equalQuote = [part rangeOfString: @"=\""];
      
      if (equalQuote.length == 0)
        value = [NSString stringWithFormat: @"%@ %@", value, part];
      else
      {
        if (equalQuote.location == 0)
        {
          NSRange previousTag;
          
          if (value == nil)
            previousTag = NSMakeRange( 0, 0 );
          else
            previousTag = [value rangeOfString: @" " options: NSBackwardsSearch];

          if (previousTag.length > 0)
          {
            part = [NSString stringWithFormat: @"%@%@", [value substringFromIndex: previousTag.location + 1], part];
            value = [value substringToIndex: previousTag.location];
            equalQuote = [part rangeOfString: @"=\""];
          }
        }
        
        [result setResponseValue: value forKey: tag];

        tag = [part substringToIndex: equalQuote.location];
        value = [part substringFromIndex: equalQuote.location + equalQuote.length];
      }
    }
    
    [result setResponseValue: value forKey: tag];    
  }
  
  return result;
}

@end
