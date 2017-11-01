//
//  JavaScriptSupport.h
//  iLinX
//
//  Created by mcf on 12/05/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

// Constants for mask of which information to pass to JavaScript
#define JSON_CURRENT_LOCATION 0x00000001
#define JSON_ALL_LOCATIONS    0x00000003
#define JSON_MACROS           0x00000004
#define JSON_CURRENT_PROFILE  0x00000008
#define JSON_ALL_PROFILES     0x00000018
#define JSON_RENDERER         0x00000020
#define JSON_CURRENT_SOURCE   0x00000040
#define JSON_ALL_SOURCES      0x000000C0
#define JSON_CURRENT_SERVICE  0x00000100
#define JSON_ALL_SERVICES     0x00000300
#define JSON_CURRENT_ZONE     0x00000400
#define JSON_ALL_ZONES        0x00000C00
#define JSON_FAVOURITES       0x00001000

@interface NSString (JavaScriptSupport)

- (NSString *) javaScriptEscapedString;

@end
