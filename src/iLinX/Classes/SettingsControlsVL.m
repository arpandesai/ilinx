//
//  SettingsControlsVL.m
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "SettingsControlsVL.h"

@implementation SettingsControlsVL

// This type of amplifier has no audio controls, so remove the audio section completely.
// TBD: Should this instead be a label saying something like "Use local controls"?
// Video controls are handled by default by the base class.

- (NSUInteger) numberOfSections
{
  return [super numberOfSections] - 1;
}

- (NSString *) titleForSection: (NSUInteger) section
{
  return [super titleForSection: section - 1];
}

- (CGFloat) heightForSection: (NSUInteger) section
{
  return [super heightForSection: section - 1];
}

- (void) addControlsForSection: (NSUInteger) section toView: (UIView *) view
{
  [super addControlsForSection: section - 1 toView: view];
}

@end
