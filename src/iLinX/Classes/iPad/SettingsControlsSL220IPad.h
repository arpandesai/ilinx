//
//  SettingsControlsSL220IPad.h
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
	SL220BassSliderTag = 71,
	SL220BassDownTag,
	SL220BassLabelTag,
	SL220BassUpTag,
	SL220TrebleSliderTag,
	SL220TrebleDownTag,
	SL220TrebleLabelTag,
	SL220TrebleUpTag,
	SL220BalanceSliderTag,
	SL220BalanceDownTag,
	SL220BalanceLabelTag,
	SL220BalanceUpTag,
};

@interface SettingsControlsSL220IPad : SettingsControlsIPad
{
@private
  UILabel *_bassLabel;
  CustomSlider *_bass;
  UILabel *_trebleLabel;
  CustomSlider *_treble;
  UILabel *_balanceLabel;
  CustomSlider *_balance;
  BOOL _ignoreUpdates;
}

@end
