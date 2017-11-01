//
//  LicenceString.m
//  iLinX
//
//  Created by mcf on 24/11/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "LicenceString.h"
#include "mtwist.h"

const unsigned char TOP_MASK[]    = { 0xFE, 0x7E, 0x3E, 0x1E, 0x0E, 0x06, 0x02 };
const unsigned char BOTTOM_MASK[] = { 0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE };
const unsigned char BASE64_DECODE[] =
{
//                  +     ,     -     .     /
0x09, 0xFF, 0xFF, 0xFF, 0x2C,
//0     1     2     3     4     5     6     7
0x03, 0x37, 0x12, 0x3A, 0x21, 0x2B, 0x18, 0x3C,
//8     9     :     ;     <     =     >     ?
0x33, 0x07, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//@     A     B     C     D     E     F     G
0xFF, 0x3D, 0x30, 0x38, 0x2E, 0x34, 0x26, 0x27,
//H     I     J     K     L     M     N     O
0x24, 0x1F, 0x3B, 0x1E, 0x14, 0x2D, 0x25, 0x3E,
//P     Q     R     S     T     U     V     W
0x0E, 0x00, 0x0F, 0x01, 0x17, 0x05, 0x32, 0x0D,
//X     Y     Z     [     \     ]     ^     _
0x13, 0x0A, 0x1B, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//`     a     b     c     d     e     f     g
0xFF, 0x1C, 0x31, 0x3F, 0x39, 0x16, 0x28, 0x29,
//h     i     j     k     l     m     n     o
0x0C, 0x2F, 0x22, 0x02, 0x10, 0x06, 0x0B, 0x20,
//p     q     r     s     t     u     v     w
0x15, 0x08, 0x04, 0x1A, 0x1D, 0x11, 0x2A, 0x35,
//x     y     z
0x36, 0x23, 0x19
};


@implementation NSString (iLinXLicenceString)

- (NSString *) decodeAsiLinXLicenceString
{
  // Decode licence.  If valid, return as a string
  NSInteger len = [self length];
  NSString *decoded;
  
  // Base64 decode
  if (len < 44 || len % 4 != 0)
    decoded = nil;
  else
  {
    unsigned char *decodeBuffer = malloc( len * 3 / 4 );
    unsigned long randomSeed = 0;
    BOOL isValidASCIIString = YES;
    mt_state state;
    unsigned char *pRandomData = (unsigned char *) &state.statevec[0];
    int i;
    
    if (decodeBuffer == NULL)
      decoded = nil;
    else
    {
      NSUInteger outLen = 0;
      
      for (i = 0; i < len; i += 4)
      {
        unsigned char in[4];
        
        for (int j = 0; j < 4; ++j)
        {
          unichar c = [self characterAtIndex: i + j];
          
          if (c >= '+' && c <= 'z')
            in[j] = BASE64_DECODE[c-'+'];
          else
            in[j] = 0xFF;
        }
        
        decodeBuffer[outLen++] = (unsigned char) (in[0] << 2 | in[1] >> 4);
        if (in[2] != 0xFF)
          decodeBuffer[outLen++] = (unsigned char) (in[1] << 4 | in[2] >> 2);
        if (in[3] != 0xFF)
          decodeBuffer[outLen++] = (unsigned char) (((in[2] << 6) & 0xc0) | in[3]);
      }
      
      // Extract the random seed bits and pack the rest up
      for (i = 1; i < 29; ++i)
      {
        unsigned int p7 = (i - 1) % 7;
        unsigned int d7 = (i - 1) / 7;
        
        if ((decodeBuffer[i] & 0x01) != 0)
          randomSeed |= (1<<(i-1)); 
        decodeBuffer[i] = ((decodeBuffer[i + d7] & TOP_MASK[p7]) << p7) |
        ((decodeBuffer[i + d7 + 1] & BOTTOM_MASK[p7]) >> (7 - p7));
      }
      for ( ; i < 33; ++i)
      {
        if ((decodeBuffer[i] & 0x01) != 0)
          randomSeed |= (1<<(i-1)); 
      }
      if (outLen > 33)
        memmove( &decodeBuffer[29], &decodeBuffer[33], outLen - 33 );
      
      // Initialise the random number system
      mts_seed32new( &state, randomSeed );
      
      // Remove the random bits
      unsigned int value = 0x01000000;
      BOOL bigEndian = ((* (char *) &value) == 1);
      
      if (bigEndian)
        decodeBuffer[1] ^= pRandomData[3];
      else
        decodeBuffer[1] ^= pRandomData[0];
      
      unsigned int nameLen = decodeBuffer[1];
      
      for (i = 2; i < outLen - 4; ++i)
      {
        if (bigEndian)
          decodeBuffer[i] ^= pRandomData[(((i-1)/4) * 4) + (3 - ((i-1) % 4))];
        else
          decodeBuffer[i] ^= pRandomData[i-1];
        if (i - 2 < nameLen)
          isValidASCIIString = (isValidASCIIString && 
                                decodeBuffer[i] > 0x1F && decodeBuffer[i] != 0x7F);
        else
          isValidASCIIString = (isValidASCIIString && decodeBuffer[i] == 0);
      }
      
      if (decodeBuffer[0] != 0 || nameLen > outLen - 1 || !isValidASCIIString)
        decoded = nil;
      else
      {
        char *pUnscrambled = malloc( nameLen + 1 );
        
        if (pUnscrambled == NULL)
          decoded = nil;
        else
        {
          memset( pUnscrambled, 0, nameLen + 1 );
          for (i = nameLen; i > 0; --i)
          {
            unsigned int pos = mts_lrand( &state ) % i;
            
            for (int j = 0; j < nameLen; ++j)
            {
              if (pUnscrambled[j] == 0)
              {
                if (pos > 0)
                  --pos;
                else
                {
                  pUnscrambled[j] = decodeBuffer[i + 1];
                  break;
                }
              }
            } 
          }
          
          decoded = [[[NSString stringWithCString: pUnscrambled
                                         encoding: NSUTF8StringEncoding] retain] autorelease];
          free( pUnscrambled );
        }
      }
      
      free( decodeBuffer );
    }
  }
  
  return decoded;
}

@end
