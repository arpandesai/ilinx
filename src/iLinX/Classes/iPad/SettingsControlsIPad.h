//
//  SettingsControlsIPad.h
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServiceViewControllerIPad.h"

@class NLRenderer;

enum
{
  NoControlsLabel = 9,
  SL250ViewTag = 10,
  NNPViewTag = 40,
  SL220ViewTag = 70,
  SN1000ViewTag = 110,
  TH100ViewTag = 140,
};

@interface SettingsControlsIPad : NSObject
{
@protected
  NLRenderer *_renderer;
}

@property (readonly) BOOL rightSettingsForRenderer;

+ (SettingsControlsIPad *) allocSettingsControlsForRenderer: (NLRenderer *) renderer;

- (NSUInteger) numberOfSections;
- (void) addControlsForSection: (NSUInteger) section toView: (UIView *) view  atYOffset: (NSInteger *) yOffset;
- (BOOL) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags;

+ (void) addButton: (UIButton *) button to: (UIView *) view frame: (CGRect) frame;
+ (UIButton *) standardButtonWithStyle: (UIBarStyle) style;

- (void) hideAllAudioViewsFromView: (UIView *) view;

@end
