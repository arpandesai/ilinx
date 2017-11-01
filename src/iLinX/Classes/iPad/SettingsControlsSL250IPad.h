//
//  SettingsControlsSL250IPad.h
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SettingsControlsIPad.h"

@class CustomSlider;

#define BUTTONS_PER_ROW	5

enum
{
	restoreButtonTag = 11,
	balanceSliderTag,
	balanceDownTag,
	balanceUpTag,
	balanceLabelTag,
	band1TitleTag,
	band2TitleTag,
	band3TitleTag,
	band4TitleTag,
	band1SliderTag,
	band2SliderTag,
	band3SliderTag,
	band4SliderTag,
	band1ValueTag,
	band2ValueTag,
	band3ValueTag,
	band4ValueTag,
	presetButtonTemplateTag,
	presetViewTag,
};

@interface SettingsControlsSL250IPad : SettingsControlsIPad
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
  UILabel *_band4Label;
  CustomSlider *_band4;
  BOOL _ignoreUpdates;
}

@end
