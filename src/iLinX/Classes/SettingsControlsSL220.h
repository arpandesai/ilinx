//
//  SettingsControlsSL220.h
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SettingsControls.h"

@class CustomSlider;

@interface SettingsControlsSL220 : SettingsControls
{
@private
  UILabel *_bassLabel;
  CustomSlider *_bass;
  UILabel *_trebleLabel;
  CustomSlider *_treble;
  UILabel *_balanceLabel;
  CustomSlider *_balance;
  NSUInteger _ignoreFlags;
}

@end
