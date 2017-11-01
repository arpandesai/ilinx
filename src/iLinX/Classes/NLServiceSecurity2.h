//
//  NLServiceSecurity2.h
//  iLinX
//
//  Created by mcf on 18/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLServiceSecurity.h"

@interface NLServiceSecurity2 : NLServiceSecurity
{
@private
  NSTimer *_displayClearTimer;
  NSString *_password;
  NSString *_armingState;
  NSString *_openZones;
  NSString *_bypassedZones;
}

@end
