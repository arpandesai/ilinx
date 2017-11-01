//
//  GreyRoundedRect.m
//  iLinX
//
//  Created by mcf on 30/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "GreyRoundedRect.h"


@implementation GreyRoundedRect

- (void) drawRect: (CGRect) rect
{
  // draw a box with rounded corners to fill the view
  
  CGRect boxRect = self.bounds;
  CGContextRef context = UIGraphicsGetCurrentContext();
  float radius = 5.0;
  
  CGContextBeginPath( context );
  CGContextSetGrayFillColor( context, 0.2, 0.8 );
  CGContextMoveToPoint( context, CGRectGetMinX( boxRect ) + radius, CGRectGetMinY( boxRect ) );
  CGContextAddArc( context, CGRectGetMaxX( boxRect ) - radius, CGRectGetMinY( boxRect ) + radius, radius, 3 * M_PI / 2, 0, 0 );
  CGContextAddArc( context, CGRectGetMaxX( boxRect ) - radius, CGRectGetMaxY( boxRect ) - radius, radius, 0, M_PI / 2, 0 );
  CGContextAddArc( context, CGRectGetMinX( boxRect ) + radius, CGRectGetMaxY( boxRect ) - radius, radius, M_PI / 2, M_PI, 0 );
  CGContextAddArc( context, CGRectGetMinX( boxRect ) + radius, CGRectGetMinY( boxRect ) + radius, radius, M_PI, 3 * M_PI / 2, 0 );
  
  CGContextDrawPath( context, kCGPathFill );
}

@end
