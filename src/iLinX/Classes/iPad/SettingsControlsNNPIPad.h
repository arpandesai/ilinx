//
//  SettingsControlsNNP.h
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SettingsControlsIPad.h"

@class CustomSlider;

enum
{
	NNPBalanceSliderTag = 41,
	NNPBalanceDownTag,
	NNPBalanceUpTag,
	NNPBalanceLabelTag,
};

@interface SettingsControlsNNPIPad : SettingsControlsIPad
{
@private
  UILabel *_balanceLabel;
  CustomSlider *_balance;
}

@end
