//
//  CustomLightButtonHelper.m
//  iLinX
//
//  Created by mcf on 23/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "CustomLightButtonHelper.h"
#import "DeprecationHelper.h"

@interface CustomLightButtonHelper ()

- (void) setImages;

@end

@implementation CustomLightButtonHelper

@synthesize
  button = _button;

- (id) init
{
  if (self = [super init])
  {
    _button = [[UIButton buttonWithType: UIButtonTypeCustom] retain];
    [_button setTitleColor: [UIColor colorWithWhite: 1.0 alpha: 1.0] forState: UIControlStateNormal];
    [_button setTitleColor: [UIColor colorWithWhite: 0.8 alpha: 1.0] forState: UIControlStateHighlighted];
    [_button setTitleShadowColor: [UIColor darkGrayColor] forState: UIControlStateNormal];
    [_button setTitleLabelFont: [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]]];
    _hasIndicator = NO;
    _indicatorState = NO;
    [self setImages];
  }
  
  return self;
}

- (BOOL) hasIndicator
{
  return _hasIndicator;
}

- (void) setHasIndicator: (BOOL) hasIndicator
{
  if (hasIndicator != _hasIndicator)
  {
    _hasIndicator = hasIndicator;
    [self setImages];
  }
}

- (BOOL) indicatorState
{
  return _indicatorState;
}

- (void) setIndicatorState: (BOOL) indicatorState
{
  if (indicatorState != _indicatorState)
  {
    _indicatorState = indicatorState;
    [self setImages];
  }
}

- (void) setImages
{
  if (!_hasIndicator)
  {
    [_button setBackgroundImage: [UIImage imageNamed: @"ButtonLightNoneReleased.png"] forState: UIControlStateNormal];
    [_button setBackgroundImage: [UIImage imageNamed: @"ButtonLightNonePressed.png"] forState: UIControlStateHighlighted];
  }
  else if (_indicatorState)
  {
    [_button setBackgroundImage: [UIImage imageNamed: @"ButtonLightOnReleased.png"] forState: UIControlStateNormal];
    [_button setBackgroundImage: [UIImage imageNamed: @"ButtonLightOnPressed.png"] forState: UIControlStateHighlighted];
  }
  else
  {
    [_button setBackgroundImage: [UIImage imageNamed: @"ButtonLightOffReleased.png"] forState: UIControlStateNormal];
    [_button setBackgroundImage: [UIImage imageNamed: @"ButtonLightOffPressed.png"] forState: UIControlStateHighlighted];
  }
}

- (void) dealloc
{
  [_button release];
  [super dealloc];
}

@end
