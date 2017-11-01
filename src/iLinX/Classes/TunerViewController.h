//
//  TunerViewController.h
//  iLinX
//
//  Created by mcf on 18/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVViewController.h"
#import "NLSourceTuner.h"

@class TunerKeypadViewController;
@class BrowseViewController;

@interface TunerViewController : AVViewController <NLSourceTunerDelegate>
{
@private
  NLSourceTuner *_tuner;
  UILabel *_titleLine1;
  UILabel *_titleLine2;
  UILabel *_titleLine3;
  UILabel *_titleLines12;
  UILabel *_titleLines123;
  UIButton *_flipButton;
  UIView *_flipBase;
  UIView *_flippingView;
  UIImageView *_backdrop;
  UIImageView *_reflection;
  UIImageView *_logo;
  UILabel *_noLogoCaption;
  UIButton *_overlayView;
  TunerKeypadViewController *_keypadViewController;
  UIToolbar *_controlBar;
  UIBarButtonItem *_tuneTypeButton;
  NSUInteger _tuneType;
  UIBarButtonItem *_stereoButton;
  UILabel *_bandIndicator;
  UILabel *_tuningIndicator;
  UILabel *_stereoIndicator;
  UILabel *_songLabel;
  UILabel *_song;
  UILabel *_artistLabel;
  UILabel *_artist;
  UILabel *_genreLabel;
  UILabel *_genre;
  UILabel *_stationLabel;
  UILabel *_station;
  UILabel *_radioTextLabel;
  UILabel *_radioText;
  NSUInteger _radioTextVisibleOffset;
  BrowseViewController *_browseViewController;
  
}

- (void) flipCurrentView: (UIButton *) button;

@end
