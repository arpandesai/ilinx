//
//  LightsPageViewController.m
//  iLinX
//
//  Created by mcf on 29/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "LightsPageViewController.h"

@interface LightsPageViewController ()

- (void) buttonPushed: (UIButton *) button;
- (void) buttonReleased: (UIButton *) button;

@end

@implementation LightsPageViewController

- (id) initWithService: (NLServiceGeneric *) lightsService offset: (NSUInteger) offset count: (NSUInteger) count
{
  if (self = [super initWithNibName: nil bundle: nil])
  {
    _lightsService = lightsService;
    _offset = offset;
    _count = count;
  }
  
  return self;
}

- (void) loadView
{
  UIView *contentView = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
  
  contentView.backgroundColor = [UIColor blackColor];
  contentView.autoresizesSubviews = YES;
  contentView.frame = CGRectMake( contentView.frame.origin.x, contentView.frame.origin.y,
                                 contentView.frame.size.width, 340 );
  contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  self.view = contentView;
  
  NSUInteger i;
  
  for (i = 0; i < _count; ++i)
  {
    NSString *name = [_lightsService nameForButton: _offset + i];
    
    if (name == nil)
    {
      _count = i;
      break;
    }
    
    UIButton *button = [UIButton buttonWithType: UIButtonTypeCustom];
    
    button.frame = CGRectMake( 10 + 155 * (i % 2), 10 + 70 * (i / 2), 145, 60 );
    [button setTitle: name forState: UIControlStateNormal];
    [button setBackgroundImage: [UIImage imageNamed: @"LightIndicatorNone.png"] forState: UIControlStateNormal];
    [button addTarget: self action: @selector(buttonPushed:) forControlEvents: UIControlEventTouchDown];
    [button addTarget: self action: @selector(buttonReleased:) 
     forControlEvents: UIControlEventTouchUpOutside|UIControlEventTouchUpInside];
    [button setTitleColor: [UIColor colorWithRed: 41.0/255.0 green: 74.0/255.0 blue: 112.0/255.0 alpha: 1.0] forState: UIControlStateNormal];
    [button setTitleColor: [UIColor whiteColor] forState: UIControlStateHighlighted];
    [button setTitleShadowColor: [UIColor darkGrayColor] forState: UIControlStateHighlighted];
    button.font = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]];
    [contentView addSubview: button];
  }
}

- (void) viewWillAppear: (BOOL) animated
{
  NSUInteger i;
  
  [super viewWillAppear: animated];
  for (i = 0; i < _count; ++i)
    [self service: _lightsService button: _offset + i changed: 0xFFFFFFFF];
  [_lightsService addDelegate: self];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_lightsService removeDelegate: self];
  [super viewWillDisappear: animated];
}

- (void) service: (NLServiceGeneric *) service button: (NSUInteger) buttonIndex changed: (NSUInteger) changed
{
  UIButton *button = [[self.view subviews] objectAtIndex: buttonIndex - _offset];

  if ((changed & SERVICE_GENERIC_NAME_CHANGED) != 0)
    [button setTitle: [service nameForButton: buttonIndex] forState: UIControlStateNormal];
  
  if ((changed & SERVICE_GENERIC_INDICATOR_CHANGED) != 0)
  {
    if (![service indicatorPresentOnButton: buttonIndex])
      [button setBackgroundImage: [UIImage imageNamed: @"LightIndicatorNone.png"] forState: UIControlStateNormal];
    else if ([service indicatorStateForButton: buttonIndex])
      [button setBackgroundImage: [UIImage imageNamed: @"LightIndicatorOn.png"] forState: UIControlStateNormal];
    else
      [button setBackgroundImage: [UIImage imageNamed: @"LightIndicatorOff.png"] forState: UIControlStateNormal];
  }
}

- (void) buttonPushed: (UIButton *) button
{
  NSUInteger index = [[self.view subviews] indexOfObject: button];
  
  [_lightsService pushButton: _offset + index];
}

- (void) buttonReleased: (UIButton *) button
{
  NSUInteger index = [[self.view subviews] indexOfObject: button];
  
  [_lightsService releaseButton: _offset + index];
}

@end
