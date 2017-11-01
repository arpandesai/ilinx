//
//  NLServiceHVAC1.h
//  iLinX
//
//  Created by mcf on 16/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLServiceHVAC.h"

@interface NLServiceHVAC1 : NLServiceHVAC
{
@private
  NSString *_outdoorTempService;
  NSString *_outdoorTempField;
  NSString *_outdoorHumidityService;
  NSString *_outdoorHumidityField;
  id _outdoorTempStatusRspHandle;
  id _outdoorTempRegisterMsgHandle;
  id _outdoorTempQueryMsgHandle;
  id _outdoorHumidityStatusRspHandle;
  id _outdoorHumidityRegisterMsgHandle;
  id _outdoorHumidityQueryMsgHandle;
  BOOL _setHeatEnabled;
  BOOL _setCoolEnabled;
  BOOL _fanOn;
  NSUInteger _fanMode;
  NSUInteger _hvacMode;
}

@end
