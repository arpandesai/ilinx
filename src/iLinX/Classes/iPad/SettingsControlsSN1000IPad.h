//
//  SettingsControlsSN1000IPad.h
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
	SN1000restoreButtonTag = 111,
	SN1000balanceSliderTag,
	SN1000balanceDownTag,
	SN1000balanceUpTag,
	SN1000balanceLabelTag,
	SN1000band1TitleTag,
	SN1000band2TitleTag,
	SN1000band3TitleTag,
	SN1000band1SliderTag,
	SN1000band2SliderTag,
	SN1000band3SliderTag,
	SN1000band1ValueTag,
	SN1000band2ValueTag,
	SN1000band3ValueTag,
};

@interface SettingsControlsSN1000IPad : SettingsControlsIPad
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
  BOOL _ignoreUpdates;
}

@end

