//
//  SettingsControlsSN1000.h
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SettingsControls.h"

@class CustomSlider;

@interface SettingsControlsSN1000 : SettingsControls
{
@private
  UILabel *_balanceLabel;
  CustomSlider *_balance;
  UILabel *_band1Label;
  CustomSlider *_band1;
  UILabel *_band2Label;
  CustomSlider *_band2;
  UILabel *_band3Label;
  CustomSlider *_band3;
  NSUInteger _ignoreFlags;
}

@end
