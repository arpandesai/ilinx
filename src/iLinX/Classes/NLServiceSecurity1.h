//
//  NLServiceSecurity1.h
//  iLinX
//
//  Created by mcf on 18/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLServiceSecurity.h"

@interface NLServiceSecurity1 : NLServiceSecurity
{
@private
  id _registerAllMsgHandle;
  NSTimer *_buttonHoldTimer;
#if LOCAL_CONTROL_OF_DISPLAY
  NSTimer *_displayClearTimer;
#endif
}

@end
