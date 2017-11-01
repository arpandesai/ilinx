//
//  TunerViewControllerIPad.h
//  iLinX
//
//  Created by Tony Short on 01/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioSubViewControllerIPad.h"
#import "NLSourceTuner.h"
#import "ListDataSource.h"
#import "TunerPresetView.h"
#import "TunerKeypadViewControllerIPad.h"
#import "TunerAddPresetViewControllerIPad.h"

enum
{
  TUNE_TYPE_CHANNEL,
  TUNE_TYPE_TUNE,
  TUNE_TYPE_SEEK,
  TUNE_TYPE_SCAN,
  TUNE_TYPE_PRESET,
  NUM_TUNE_TYPES,
};

@class TunerCurrentStation;

@interface TunerViewControllerIPad : AudioSubViewControllerIPad <NLSourceTunerDelegate, UIActionSheetDelegate>
{
@private
  NLSourceTuner *_tuner;
  
  IBOutlet UIView *_mainView;
  IBOutlet UILabel *_titleLabel;
  IBOutlet UILabel *_bandLabel;
  IBOutlet UILabel *_stereoLabel;
  IBOutlet UIImageView *_tunerTypeLogo;
  IBOutlet UILabel *_tuningIndicatorLabel;
  IBOutlet UIView *_stationLogoView;
  
  IBOutlet TunerCurrentStation *_currentStationView;
  
  NSUInteger _tuneType;
  IBOutlet UIButton *_tuneTypeButton;
  UIActionSheet *_tuneTypeActionSheet;
  
  IBOutlet UIButton *_keypadButton;
  IBOutlet UIButton *_storePresetButton;
  BOOL _isStereo;
  
  IBOutlet TunerPresetView *_presetView;
  UIPopoverController *_keypadPopover;
  TunerKeypadViewControllerIPad *_keypadViewController;
  
  UIPopoverController *_addPresetPopover;
  TunerAddPresetViewControllerIPad *_addPresetViewController;
}

- (BOOL) isIRTuner;
- (BOOL) isSatellite;
- (BOOL) isDAB;
- (BOOL) isAnalog;

- (IBAction) pressedStorePreset: (id) control;
- (IBAction) pressedBand: (id) control;
- (IBAction) pressedMode: (id) control;
- (IBAction) pressedTuneDown: (id) control;
- (IBAction) pressedTuneUp: (id) control;
- (IBAction) pressedStereo: (id) control;
- (IBAction) pressedKeypad: (id) control;

- (void) dismissKeyboard;
- (void) dismissAddPresetView;

@end
