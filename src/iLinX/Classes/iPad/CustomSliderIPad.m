//
//  CustomSliderIPad.m
//  iLinX
//
//  Created by mcf on 14/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "CustomSliderIPad.h"

@interface CustomSliderIPad ()

- (void) setMatchingThumbImage;

@end

@implementation CustomSliderIPad


- (void) layoutSubviews
{
  if (!_initialisedImages)
  {
    CGRect myFrame = self.frame;
    CGFloat maxHeight = 0;
    
    if ([_leftEnd image] != nil)
    {
      [self setMinimumTrackImage: [_leftEnd.image stretchableImageWithLeftCapWidth: (NSInteger) ((_leftEnd.image.size.width - 1) / 2)
                                                                      topCapHeight: 0]
                        forState: UIControlStateNormal];
      maxHeight = _leftEnd.image.size.height;
    }
    
    if ([_rightEnd image] != nil)
    {
      [self setMaximumTrackImage: [_rightEnd.image stretchableImageWithLeftCapWidth: (NSInteger) ((_rightEnd.image.size.width - 1) / 2)
                                                                       topCapHeight: 0]
                        forState: UIControlStateNormal];
      if (_rightEnd.image.size.height > maxHeight)
        maxHeight = _rightEnd.image.size.height;
    }
    
    if (_progressOnly)
      [self setThumbImage: [UIImage imageNamed: @"Shim.png"] forState: UIControlStateNormal];
    else if ([_thumb image] != nil)
    {
      [self setThumbImage: _thumb.image forState: UIControlStateNormal];
      if (_thumb.image.size.height > maxHeight)
        maxHeight = _thumb.image.size.height;
    }

    if (maxHeight > 0)
      self.frame = CGRectMake( myFrame.origin.x, myFrame.origin.y + (NSInteger) ((myFrame.size.height - maxHeight) / 2),
                              myFrame.size.width, maxHeight );
    _initialisedImages = YES;
  }

  [super layoutSubviews];
}

- (BOOL) progressOnly
{
  return _progressOnly;
}

- (void) setProgressOnly: (BOOL) progressOnly
{
  _progressOnly = progressOnly;
  self.userInteractionEnabled = !progressOnly;
  [self setMatchingThumbImage];
}

- (BOOL) showAlternateThumb
{
  return _showAlternateThumb;
}

- (void) setShowAlternateThumb: (BOOL) showAlternateThumb
{
  _showAlternateThumb = showAlternateThumb;
  [self setMatchingThumbImage];
}

- (void) setMatchingThumbImage
{
  if (_progressOnly)
    [self setThumbImage: [UIImage imageNamed: @"Shim.png"] forState: UIControlStateNormal];
  else
  {
    if (_showAlternateThumb && [_alternateThumb image] != nil)
      [self setThumbImage: _alternateThumb.image forState: UIControlStateNormal];
    else if ([_thumb image] != nil)
      [self setThumbImage: _thumb.image forState: UIControlStateNormal];
  }

  [self setNeedsLayout];
}

- (void) dealloc
{
  [_leftEnd release];
  [_thumb release];
  [_alternateThumb release];
  [_rightEnd release];
  [super dealloc];
}
 
@end
