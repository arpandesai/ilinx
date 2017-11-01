//
//  ButtonBar.m
//  iLinX
//
//  Created by mcf on 06/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "ButtonBar.h"

#define EDGE_INSET 0

static CGFloat LINE_SHADES[] =
{
  0.0/255, 148.0/255, 116.0/255, 111.0/255, 107.0/255, 103.0/255, 100.0/255, 94.0/255, 92.0/255, 88.0/255, 84.0/255,
  79.0/255, 76.0/255, 73.0/255, 69.0/255, 64.0/255, 62.0/255, 55.0/255, 54.0/255, 50.0/255, 45.0/255, 43.0/255,
  0.0/255
};

@implementation ButtonBar

@synthesize items = _items;

- (id) initWithFrame: (CGRect) frame
{
  if (self = [super initWithFrame:frame])
  {
    // Initialization code
  }
  
  return self;
}

- (void) setItems: (NSArray *) items
{
  NSUInteger count = [_items count];
  NSUInteger i;
  
  for (i = 0; i < count; ++i)
    [(UIView *) [_items objectAtIndex: i] removeFromSuperview];
  [_items release];
  
  _items = [items retain];
  count = [items count];
  for (i = 0; i < count; ++i)
    [self addSubview: (UIView *) [items objectAtIndex: i]];
  
  [self layoutSubviews];
}

- (void) layoutSubviews
{
  NSUInteger count = [_items count];
  CGSize size = self.bounds.size;
  BOOL horizontal = (size.width >= size.height);
  CGFloat totalSize;
  CGFloat buttonSize;
  NSUInteger i;
  
  if (horizontal)
    totalSize = size.width;
  else
    totalSize = size.height;
  totalSize -= (2 * EDGE_INSET);
  buttonSize = totalSize;
  
  if (count > 1)
    buttonSize /= count;
  
  for (i = 0; i < count; ++i)
  {
    UIButton *item = [_items objectAtIndex: i];
    
    if (horizontal)
      item.frame = CGRectMake( EDGE_INSET + (i * buttonSize), 0, buttonSize, size.height );
    else
      item.frame = CGRectMake( 0, EDGE_INSET + (i * buttonSize), size.width, buttonSize );
  }
}

- (void) drawRect: (CGRect) rect
{
  CGRect boxRect = self.bounds;
  CGContextRef context = UIGraphicsGetCurrentContext();
  NSUInteger count = (sizeof(LINE_SHADES)/sizeof(LINE_SHADES[0]));
  NSUInteger i;
  
  CGContextClipToRect( context, rect );
  
  if (boxRect.size.width > boxRect.size.height)
  {
    if (count > boxRect.size.height)
      count = boxRect.size.height;
    for (i = 0; i < count; ++i)
    {
      CGContextBeginPath( context );
      CGContextSetGrayFillColor( context, LINE_SHADES[i], 1.0 );
      CGContextAddRect( context, CGRectMake( CGRectGetMinX( boxRect ), CGRectGetMinY( boxRect ) + i,
                                          CGRectGetWidth( boxRect ), 1 ) );
      CGContextClosePath( context );
      CGContextFillPath( context );
    }
    if (i < boxRect.size.height)
    {      
      CGContextBeginPath( context );
      CGContextSetGrayFillColor( context, LINE_SHADES[count - 1], 1.0 );
      CGContextAddRect( context, CGRectMake( CGRectGetMinX( boxRect ), CGRectGetMinY( boxRect ) + i,
                                            CGRectGetWidth( boxRect ), CGRectGetHeight( boxRect ) - i ) );
      CGContextClosePath( context );
      CGContextFillPath( context );
    }
  }
  else
  {
    if (count > boxRect.size.width)
      count = boxRect.size.width;
    
    for (i = 0; i < count; ++i)
    {
      CGContextBeginPath( context );
      CGContextSetGrayFillColor( context, LINE_SHADES[i], 1.0 );
      CGContextAddRect( context, CGRectMake( CGRectGetMaxX( boxRect ) - 1 - i, CGRectGetMinY( boxRect ),
                                            1, CGRectGetHeight( boxRect ) ) );
      //CGContextMoveToPoint( context, CGRectGetMaxX( boxRect ) - i, CGRectGetMinY( boxRect ) );
      //CGContextAddLineToPoint( context, CGRectGetMaxX( boxRect ) - i, CGRectGetMaxY( boxRect ) );
      CGContextClosePath( context );
      CGContextFillPath( context );
    }
    if (i < boxRect.size.height)
    {      
      CGContextBeginPath( context );
      CGContextSetGrayFillColor( context, LINE_SHADES[count - 1], 1.0 );
      CGContextAddRect( context, CGRectMake( CGRectGetMinX( boxRect ), CGRectGetMinY( boxRect ),
                                            CGRectGetWidth( boxRect ) - i, CGRectGetHeight( boxRect ) ) );
      CGContextClosePath( context );
      CGContextFillPath( context );
    }
  }
}

- (void) dealloc
{
  [_items release];
  [super dealloc];
}


@end
