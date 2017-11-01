//
//  BorderedCellBackgroundView.m
//  iLinX
//
//  Created by mcf on 05/05/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "BorderedCellBackgroundView.h"

@implementation BorderedCellBackgroundView

@synthesize
  fillColour = _fillColour,
  borderColour = _borderColour;

- (id) initWithFrame: (CGRect) frame
{
  if (self = [super initWithFrame: frame])
    self.backgroundColor = [UIColor clearColor];
  
  return self;
}

- (NSInteger) borderType
{
  return _borderType;
}

- (void) setBorderType: (NSInteger) borderType
{
  if (borderType != _borderType)
  {
    _borderType = borderType;
    [self setNeedsDisplay];
  }
}

- (void) drawRect: (CGRect) rect
{
  // draw a box with rounded corners to fill the view
  
  CGRect boxRect = CGRectMake( self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height );
  CGContextRef context = UIGraphicsGetCurrentContext();
  float radius = 12.0;
  
  CGContextBeginPath( context );
  CGContextSetFillColorWithColor( context, [_fillColour CGColor] );
  CGContextSetStrokeColorWithColor( context, [_borderColour CGColor] );
  CGContextSetLineWidth( context, 1.2 );
  switch (_borderType)
  {
    case BORDER_TYPE_TOP:
    case BORDER_TYPE_TOP_NO_SEP:
      CGContextMoveToPoint( context, CGRectGetMinX( boxRect ), CGRectGetMaxY( boxRect ) );
      CGContextAddArc( context, CGRectGetMinX( boxRect ) + radius, CGRectGetMinY( boxRect ) + radius, radius, M_PI, 3 * M_PI / 2, 0 );
      CGContextAddArc( context, CGRectGetMaxX( boxRect ) - radius, CGRectGetMinY( boxRect ) + radius, radius, 3 * M_PI / 2, 0, 0 );
      CGContextAddArc( context, CGRectGetMaxX( boxRect ), CGRectGetMaxY( boxRect ), 0, 0, 0, 0 );
      break;
    case BORDER_TYPE_BOTTOM:
    case BORDER_TYPE_BOTTOM_NO_SEP:
      if (_borderType == BORDER_TYPE_BOTTOM_NO_SEP)
        CGContextMoveToPoint( context, CGRectGetMaxX( boxRect ), CGRectGetMinY( boxRect ) );
      else
      {
        CGContextMoveToPoint( context, CGRectGetMinX( boxRect ), CGRectGetMinY( boxRect ) );
        CGContextAddArc( context, CGRectGetMaxX( boxRect ), CGRectGetMinY( boxRect ), 0, 0, 0, 0 );
      }
      CGContextAddArc( context, CGRectGetMaxX( boxRect ) - radius, CGRectGetMaxY( boxRect ) - radius, radius, 0, M_PI / 2, 0 );
      CGContextAddArc( context, CGRectGetMinX( boxRect ) + radius, CGRectGetMaxY( boxRect ) - radius, radius, M_PI / 2, M_PI, 0 );
      CGContextAddArc( context, CGRectGetMinX( boxRect ), CGRectGetMinY( boxRect ), 0, 0, 0, 0 );
      break;
    case BORDER_TYPE_SINGLE:
    case BORDER_TYPE_SINGLE_NO_SEP:
      CGContextMoveToPoint( context, CGRectGetMinX( boxRect ) + radius, CGRectGetMinY( boxRect ) );
      CGContextAddArc( context, CGRectGetMaxX( boxRect ) - radius, CGRectGetMinY( boxRect ) + radius, radius, 3 * M_PI / 2, 0, 0 );
      CGContextAddArc( context, CGRectGetMaxX( boxRect ) - radius, CGRectGetMaxY( boxRect ) - radius, radius, 0, M_PI / 2, 0 );
      CGContextAddArc( context, CGRectGetMinX( boxRect ) + radius, CGRectGetMaxY( boxRect ) - radius, radius, M_PI / 2, M_PI, 0 );
      CGContextAddArc( context, CGRectGetMinX( boxRect ) + radius, CGRectGetMinY( boxRect ) + radius, radius, M_PI, 3 * M_PI / 2, 0 );
      break;
    case BORDER_TYPE_NONE:
    case BORDER_TYPE_MIDDLE:
    case BORDER_TYPE_MIDDLE_NO_SEP:
    case BORDER_TYPE_SEPARATOR_ONLY:
    default:
      if (_borderType == BORDER_TYPE_MIDDLE)
        CGContextSetLineWidth( context, 2.0 );
      else
        CGContextSetLineWidth( context, 0 );
      CGContextMoveToPoint( context, CGRectGetMinX( boxRect ), CGRectGetMaxY( boxRect ) );
      CGContextAddArc( context, CGRectGetMinX( boxRect ), CGRectGetMinY( boxRect ), 0, 0, 0, 0 );
      CGContextAddArc( context, CGRectGetMaxX( boxRect ), CGRectGetMinY( boxRect ), 0, 0, 0, 0 );
      CGContextAddArc( context, CGRectGetMaxX( boxRect ), CGRectGetMaxY( boxRect ), 0, 0, 0, 0 );
      break;
  }

  CGContextDrawPath( context, kCGPathFillStroke );

  CGContextSetLineWidth( context, 2.0 );
  switch (_borderType)
  {
    case BORDER_TYPE_TOP:
    case BORDER_TYPE_TOP_NO_SEP:
      CGContextBeginPath( context );
      CGContextMoveToPoint( context, CGRectGetMinX( boxRect ), CGRectGetMaxY( boxRect ) );
      CGContextAddLineToPoint( context, CGRectGetMinX( boxRect ), CGRectGetMinY( boxRect ) + radius - 2 );
      CGContextDrawPath( context, kCGPathStroke );
      CGContextBeginPath( context );
      CGContextMoveToPoint( context, CGRectGetMinX( boxRect ) + radius - 2, CGRectGetMinY( boxRect ) );
      CGContextAddLineToPoint( context, CGRectGetMaxX( boxRect ) - radius + 2, CGRectGetMinY( boxRect ) );
      CGContextDrawPath( context, kCGPathStroke );
      CGContextBeginPath( context );
      CGContextMoveToPoint( context, CGRectGetMaxX( boxRect ), CGRectGetMinY( boxRect ) + radius - 2 );
      CGContextAddLineToPoint( context, CGRectGetMaxX( boxRect ), CGRectGetMaxY( boxRect ) );
      CGContextDrawPath( context, kCGPathStroke );
      break;
    case BORDER_TYPE_BOTTOM:
    case BORDER_TYPE_BOTTOM_NO_SEP:
      CGContextBeginPath( context );
      CGContextMoveToPoint( context, CGRectGetMinX( boxRect ), CGRectGetMaxY( boxRect ) - radius + 2 );
      CGContextAddLineToPoint( context, CGRectGetMinX( boxRect ), CGRectGetMinY( boxRect ) );
      CGContextDrawPath( context, kCGPathStroke );
      if (_borderType == BORDER_TYPE_BOTTOM)
      {
        CGContextBeginPath( context );
        CGContextMoveToPoint( context, CGRectGetMinX( boxRect ), CGRectGetMinY( boxRect ) );
        CGContextAddLineToPoint( context, CGRectGetMaxX( boxRect ), CGRectGetMinY( boxRect ) );
        CGContextDrawPath( context, kCGPathStroke );
        CGContextBeginPath( context );
      }
      CGContextMoveToPoint( context, CGRectGetMaxX( boxRect ), CGRectGetMinY( boxRect ) );
      CGContextAddLineToPoint( context, CGRectGetMaxX( boxRect ), CGRectGetMaxY( boxRect ) - radius + 2 );
      CGContextDrawPath( context, kCGPathStroke );
      CGContextBeginPath( context );
      CGContextMoveToPoint( context, CGRectGetMaxX( boxRect ) - radius + 2, CGRectGetMaxY( boxRect ) );
      CGContextAddLineToPoint( context, CGRectGetMinX( boxRect ) + radius - 2, CGRectGetMaxY( boxRect ) );
      CGContextDrawPath( context, kCGPathStroke );
      break;
    case BORDER_TYPE_SINGLE:
    case BORDER_TYPE_SINGLE_NO_SEP:
      CGContextBeginPath( context );
      CGContextMoveToPoint( context, CGRectGetMinX( boxRect ), CGRectGetMaxY( boxRect ) - radius + 2 );
      CGContextAddLineToPoint( context, CGRectGetMinX( boxRect ), CGRectGetMinY( boxRect ) + radius - 2 );
      CGContextDrawPath( context, kCGPathStroke );
      CGContextBeginPath( context );
      CGContextMoveToPoint( context, CGRectGetMinX( boxRect ) + radius - 2, CGRectGetMinY( boxRect ) );
      CGContextAddLineToPoint( context, CGRectGetMaxX( boxRect ) - radius + 2, CGRectGetMinY( boxRect ) );
      CGContextDrawPath( context, kCGPathStroke );
      CGContextBeginPath( context );
      CGContextMoveToPoint( context, CGRectGetMaxX( boxRect ), CGRectGetMinY( boxRect ) + radius - 2 );
      CGContextAddLineToPoint( context, CGRectGetMaxX( boxRect ), CGRectGetMaxY( boxRect ) - radius + 2 );
      CGContextDrawPath( context, kCGPathStroke );
      CGContextBeginPath( context );
      CGContextMoveToPoint( context, CGRectGetMaxX( boxRect ) - radius + 2, CGRectGetMaxY( boxRect ) );
      CGContextAddLineToPoint( context, CGRectGetMinX( boxRect ) + radius - 2, CGRectGetMaxY( boxRect ) );
      CGContextDrawPath( context, kCGPathStroke );
      break;
    case BORDER_TYPE_MIDDLE_NO_SEP:
      CGContextBeginPath( context );
      CGContextMoveToPoint( context, CGRectGetMinX( boxRect ), CGRectGetMaxY( boxRect ) );
      CGContextAddLineToPoint( context, CGRectGetMinX( boxRect ), CGRectGetMinY( boxRect ) );
      CGContextDrawPath( context, kCGPathStroke );
      CGContextBeginPath( context );
      CGContextMoveToPoint( context, CGRectGetMaxX( boxRect ), CGRectGetMinY( boxRect ) );
      CGContextAddLineToPoint( context, CGRectGetMaxX( boxRect ), CGRectGetMaxY( boxRect ) );
      CGContextDrawPath( context, kCGPathStroke );
      break;
    case BORDER_TYPE_SEPARATOR_ONLY:
      CGContextBeginPath( context );
      CGContextMoveToPoint( context, CGRectGetMinX( boxRect ), CGRectGetMaxY( boxRect ) );
      CGContextAddLineToPoint( context, CGRectGetMaxX( boxRect ), CGRectGetMaxY( boxRect ) );
      CGContextDrawPath( context, kCGPathStroke );
      break;
    case BORDER_TYPE_NONE:
    case BORDER_TYPE_MIDDLE:
    default:
      break;
  }
}

@end
