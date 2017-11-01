/*
 *  StringEncoding.h
 *  iLinX
 *
 *  Created by mcf on 28/01/2009.
 *  Copyright 2009 Micropraxis Ltd. All rights reserved.
 *
 */
#import <CoreFoundation/CFString.h>

extern CFStringEncoding StringEncodingFor( const uint8_t *bytes, uint32_t length );
