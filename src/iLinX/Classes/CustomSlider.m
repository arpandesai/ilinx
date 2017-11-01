//
//  CustomSlider.m
//  iLinX
//
//  Created by mcf on 23/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "CustomSlider.h"


@implementation CustomSlider

@synthesize
  tint = _tint;

- (id) initWithFrame: (CGRect) frame tint: (UIColor *) tint progressOnly: (BOOL) progressOnly
{
  if (self = [super initWithFrame: frame])
  {
    _progressOnly = progressOnly;
    if (progressOnly)
      self.userInteractionEnabled = NO;
    self.tint = tint;
  }
  
  return self;
}
- (void) setTint: (UIColor *) tint
{
  [_tint release];
  _tint = [tint retain];

  if (tint == nil || tint == [UIColor blackColor])
  {
    self.minimumValueImage = [UIImage imageNamed: @"SliderLeftEnd.png"];
    self.maximumValueImage = [UIImage imageNamed: @"SliderRightEnd.png"];
    [self setMinimumTrackImage: [[UIImage imageNamed: @"SliderOn.png"] stretchableImageWithLeftCapWidth: 3 topCapHeight: 0]
                      forState: UIControlStateNormal];
    [self setMaximumTrackImage: [[UIImage imageNamed: @"SliderOff.png"] stretchableImageWithLeftCapWidth: 3 topCapHeight: 0]
                      forState: UIControlStateNormal];
    if (_progressOnly)
      [self setThumbImage: [UIImage imageNamed: @"Shim.png"] forState: UIControlStateNormal];
    else
      [self setThumbImage: [UIImage imageNamed: @"SliderButton.png"] forState: UIControlStateNormal];
  }
  else
  {
    self.minimumValueImage = [UIImage imageNamed: @"SliderLeftEndWhite.png"];
    self.maximumValueImage = [UIImage imageNamed: @"SliderRightEndWhite.png"];
    [self setMinimumTrackImage: [[UIImage imageNamed: @"SliderOnWhite.png"] stretchableImageWithLeftCapWidth: 3 topCapHeight: 0]
                      forState: UIControlStateNormal];
    [self setMaximumTrackImage: [[UIImage imageNamed: @"SliderOffWhite.png"] stretchableImageWithLeftCapWidth: 3 topCapHeight: 0]
                      forState: UIControlStateNormal];
    if (_progressOnly)
      [self setThumbImage: [UIImage imageNamed: @"Shim.png"] forState: UIControlStateNormal];
    else
      [self setThumbImage: [UIImage imageNamed: @"SliderButtonWhite.png"] forState: UIControlStateNormal];
  }
}

- (CGRect) minimumValueImageRectForBounds: (CGRect) bounds
{
  UIImage *leftEnd = self.minimumValueImage;
  CGFloat height = leftEnd.size.height;

  return CGRectMake( bounds.origin.x, (CGRectGetHeight( bounds ) - bounds.origin.y - height) / 2 + bounds.origin.y,
                    leftEnd.size.width, height );
}

- (CGRect) maximumValueImageRectForBounds: (CGRect) bounds
{
  UIImage *rightEnd = self.maximumValueImage;
  CGFloat width = rightEnd.size.width;
  CGFloat height = rightEnd.size.height;
  
  return CGRectMake( CGRectGetMaxX( bounds ) - width, (CGRectGetHeight( bounds ) - bounds.origin.y - height) / 2 + bounds.origin.y,
                    width, height );
}

- (CGRect) thumbRectForBounds: (CGRect) bounds trackRect: (CGRect) rect value: (float) value
{
  CGRect suggestion;// = [super thumbRectForBounds: bounds trackRect: rect value: value];
  UIImage *thumb = [self thumbImageForState: UIControlStateNormal];
  CGFloat width = thumb.size.width;
  CGFloat height = thumb.size.height;
  CGFloat scaledValue = (value - self.minimumValue) / (self.maximumValue - self.minimumValue);

  suggestion = CGRectMake( ((CGRectGetMaxX( bounds ) - bounds.origin.x - width) * scaledValue) + bounds.origin.x,
                    (CGRectGetHeight( bounds ) - bounds.origin.y - height) / 2 + bounds.origin.y, width, height );
  
  return suggestion;
}

- (CGRect) trackRectForBounds: (CGRect) bounds
{
  CGFloat leftWidth = self.minimumValueImage.size.width;
  CGFloat rightWidth = self.maximumValueImage.size.width;
  UIImage *track = [self minimumTrackImageForState: UIControlStateNormal];
  CGFloat height = track.size.height;
  
  return CGRectMake( leftWidth, (CGRectGetHeight( bounds ) - height) / 2, CGRectGetWidth( bounds ) - (leftWidth + rightWidth), height );
}

- (void) dealloc
{
  [_tint release];
  [super dealloc];
}

@end
