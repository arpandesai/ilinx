//
//  ITHTTPURLResponse.h
//  iLinX
//
//  What we really want to be able to do is create NSHTTPURLResponse objects, but there is no
//  method available to do that, so we have to have our own class instead.
//
//  Created by mcf on 04/11/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ITHTTPURLResponse : NSURLResponse
{
@private
  NSDictionary *_allHeaderFields;
  NSInteger _statusCode;
}

@property (readonly) NSDictionary *allHeaderFields;
@property (readonly) NSInteger statusCode;

- (id) initWithURL: (NSURL *) URL MIMEType: (NSString *) MIMEType expectedContentLength: (NSInteger) length
  textEncodingName: (NSString *) name headerFields: (NSDictionary *) headerFields statusCode: (NSInteger) statusCode;

@end
