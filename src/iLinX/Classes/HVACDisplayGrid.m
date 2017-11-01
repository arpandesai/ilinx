//
//  HVACDisplayGrid.m
//  iLinX
//
//  Created by mcf on 13/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "HVACDisplayGrid.h"


@implementation HVACDisplayGrid

- (void) drawRect: (CGRect) rect
{
  CGRect boxRect = CGRectInset( self.bounds, 9.0f, 9.0f );
  CGContextRef context = UIGraphicsGetCurrentContext();
  float radius = 5.0;
  
  CGContextBeginPath( context );
  CGContextSetGrayStrokeColor( context, 1.0, 0.8 );
  CGContextSetLineWidth ( context, 2.0 );
  CGContextMoveToPoint( context, CGRectGetMinX( boxRect ) + radius, CGRectGetMinY( boxRect ) );
  CGContextAddArc( context, CGRectGetMaxX( boxRect ) - radius, CGRectGetMinY( boxRect ) + radius, radius, 3 * M_PI / 2, 0, 0 );
  CGContextAddArc( context, CGRectGetMaxX( boxRect ) - radius, CGRectGetMaxY( boxRect ) - radius, radius, 0, M_PI / 2, 0 );
  CGContextAddArc( context, CGRectGetMinX( boxRect ) + radius, CGRectGetMaxY( boxRect ) - radius, radius, M_PI / 2, M_PI, 0 );
  CGContextAddArc( context, CGRectGetMinX( boxRect ) + radius, CGRectGetMinY( boxRect ) + radius, radius, M_PI, 3 * M_PI / 2, 0 );
  CGContextMoveToPoint( context, CGRectGetMinX( boxRect ), 0.4 * CGRectGetHeight( boxRect ) );
  CGContextAddLineToPoint( context, CGRectGetMaxX( boxRect ), 0.4 * CGRectGetHeight( boxRect ) );
  CGContextMoveToPoint( context,  CGRectGetMinX( boxRect ), 0.6 * CGRectGetHeight( boxRect ) );
  CGContextAddLineToPoint( context, CGRectGetMaxX( boxRect ), 0.6 * CGRectGetHeight( boxRect ) );
  CGContextMoveToPoint( context, CGRectGetWidth( boxRect ) / 2 + CGRectGetMinX( boxRect ), 0.6 * CGRectGetHeight( boxRect ) );
  CGContextAddLineToPoint( context, CGRectGetWidth( boxRect ) / 2 + CGRectGetMinX( boxRect ), CGRectGetMaxY( boxRect ) );
  CGContextClosePath( context );
  CGContextDrawPath( context, kCGPathStroke );
}


@end
