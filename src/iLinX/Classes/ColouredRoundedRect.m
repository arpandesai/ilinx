//
//  ColouredRoundedRect.m
//  iLinX
//
//  Created by mcf on 07/05/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "ColouredRoundedRect.h"


@implementation ColouredRoundedRect


- (id) initWithFrame: (CGRect) frame fillColour: (UIColor *) fillColour radius: (CGFloat) radius
{
  if (self = [super initWithFrame: frame])
  {
    _fillColour = [fillColour retain];
    _radius = radius;
    self.backgroundColor = [UIColor clearColor];
  }
  
  return self;
}

- (void) drawRect: (CGRect) rect
{
  // draw a box with rounded corners to fill the view
  
  CGRect boxRect = self.bounds;
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  CGContextBeginPath( context );
  CGContextSetFillColorWithColor( context, [_fillColour CGColor] );
  CGContextMoveToPoint( context, CGRectGetMinX( boxRect ) + _radius, CGRectGetMinY( boxRect ) );
  CGContextAddArc( context, CGRectGetMaxX( boxRect ) - _radius, CGRectGetMinY( boxRect ) + _radius, _radius, 3 * M_PI / 2, 0, 0 );
  CGContextAddArc( context, CGRectGetMaxX( boxRect ) - _radius, CGRectGetMaxY( boxRect ) - _radius, _radius, 0, M_PI / 2, 0 );
  CGContextAddArc( context, CGRectGetMinX( boxRect ) + _radius, CGRectGetMaxY( boxRect ) - _radius, _radius, M_PI / 2, M_PI, 0 );
  CGContextAddArc( context, CGRectGetMinX( boxRect ) + _radius, CGRectGetMinY( boxRect ) + _radius, _radius, M_PI, 3 * M_PI / 2, 0 );
  
  CGContextDrawPath( context, kCGPathFill );
  
}

- (void) dealloc
{
  [_fillColour release];
  [super dealloc];
}

@end
