//
//  JavaScriptSupport.m
//  iLinX
//
//  Created by mcf on 12/05/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "JavaScriptSupport.h"


@implementation NSString (JavaScriptSupport)

- (NSString *) javaScriptEscapedString
{
  NSString *escaped = [self stringByReplacingOccurrencesOfString: @"\\" withString: @"\\\\"];
  
  return [escaped stringByReplacingOccurrencesOfString: @"\"" withString: @"\\\""];
}

@end
