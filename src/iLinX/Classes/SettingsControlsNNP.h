//
//  SettingsControlsNNP.h
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SettingsControls.h"

@class CustomSlider;

@interface SettingsControlsNNP : SettingsControls
{
@private
  UILabel *_balanceLabel;
  CustomSlider *_balance;
}

@end
