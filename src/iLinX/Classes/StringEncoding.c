/*
 *  StringEncoding.c
 *  iLinX
 *
 *  Created by mcf on 28/01/2009.
 *  Copyright 2009 Micropraxis Ltd. All rights reserved.
 *
 */
#include "StringEncoding.h"

// A rough-and-ready attempt at spotting UTF8 strings
#define UTF8_LEAD_FLAG 0xC0
#define UTF8_LAST_FLAG 0x80
#define UTF8_MASK 0xC0

CFStringEncoding StringEncodingFor( const uint8_t *bytes, uint32_t length )
{
  CFStringEncoding encoding = kCFStringEncodingWindowsLatin1;
  char leadFound = 0;
  uint8_t byte = 0;
  uint32_t offset;
  
  for (offset = 0; offset < length && ((byte = bytes[offset]) != 0); ++offset)
  {
    if ((byte & UTF8_MASK) == UTF8_LAST_FLAG)
    {
      if (leadFound)
        encoding = kCFStringEncodingUTF8;
      break;
    }
    else if ((byte & UTF8_MASK) == UTF8_LEAD_FLAG)
    {
      leadFound = 1;
    }
    else if (leadFound)
      break;
  }

  if (offset < length - 1 && byte == 0 && encoding == kCFStringEncodingWindowsLatin1)
  {
    if (offset % 2 == 0)
      encoding = kCFStringEncodingUTF16LE;
    else
      encoding = kCFStringEncodingUTF16BE;
  }

  return encoding;
}

