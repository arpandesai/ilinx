//
//  ResponseXmlParser.h
//  iLinX
//
//  Created by mcf on 14/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ResponseXmlParser : NSObject
{
}

- (NSDictionary *) parseResponseXML: (NSString *) xmlString;

@end
