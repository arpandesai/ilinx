//
//  ITHTTPURLResponse.m
//  iLinX
//
//  Created by mcf on 04/11/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "ITHTTPURLResponse.h"


@implementation ITHTTPURLResponse

@synthesize
  allHeaderFields = _allHeaderFields,
  statusCode = _statusCode;

- (id) initWithURL: (NSURL *) URL MIMEType: (NSString *) MIMEType expectedContentLength: (NSInteger) length
  textEncodingName: (NSString *) name headerFields: (NSDictionary *) headerFields statusCode: (NSInteger) statusCode
{
  if (self = [super initWithURL: URL MIMEType: MIMEType expectedContentLength: length textEncodingName: name])
  {
    _allHeaderFields = [headerFields retain];
    _statusCode = statusCode;
  }
  
  return self;
}

- (void) dealloc
{
  [_allHeaderFields release];
  [super dealloc];
}

@end
