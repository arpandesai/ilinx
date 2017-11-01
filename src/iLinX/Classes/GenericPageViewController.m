//
//  GenericPageViewController.m
//  iLinX
//
//  Created by mcf on 29/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "GenericPageViewController.h"
#import "CustomLightButtonHelper.h"

@interface GenericPageViewController ()

- (void) buttonPushed: (UIButton *) button;
- (void) buttonReleased: (UIButton *) button;

@end

@implementation GenericPageViewController

- (id) initWithService: (NLServiceGeneric *) genericService offset: (NSUInteger) offset count: (NSUInteger) count
{
  if (self = [super initWithNibName: nil bundle: nil])
  {
    _genericService = genericService;
    _offset = offset;
    _count = count;
  }
  
  return self;
}

- (void) loadView
{
  UIView *contentView = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
  UIImageView *imageView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"BackdropDark.png"]];
  
  contentView.backgroundColor = [UIColor clearColor];
  contentView.autoresizesSubviews = YES;
  contentView.frame = CGRectMake( contentView.frame.origin.x, contentView.frame.origin.y,
                                 contentView.frame.size.width, 340 );
  contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  self.view = contentView;
  imageView.frame = contentView.bounds;
  [contentView addSubview: imageView];
  [imageView release];
  
  
  _buttonHelpers = [[NSMutableArray arrayWithCapacity: _count] retain];

  NSUInteger i;
  
  for (i = 0; i < _count; ++i)
  {
    NSString *name = [_genericService nameForButton: _offset + i];
    
    if (name == nil)
    {
      _count = i;
      break;
    }
    
    CustomLightButtonHelper *helper = [CustomLightButtonHelper new];
    UIButton *button = helper.button;
    
    button.frame = CGRectMake( 10 + 155 * (i % 2), 10 + 70 * (i / 2), 145, 60 );
    button.tag = _offset + i;
    [button setTitle: name forState: UIControlStateNormal];
    [button addTarget: self action: @selector(buttonPushed:) forControlEvents: UIControlEventTouchDown];
    [button addTarget: self action: @selector(buttonReleased:) 
     forControlEvents: UIControlEventTouchUpOutside|UIControlEventTouchUpInside];
    [contentView addSubview: button];
    [_buttonHelpers addObject: helper];
    [helper release];
  }
  
  [contentView release];
}

- (void) viewWillAppear: (BOOL) animated
{
  NSUInteger i;
  
  [super viewWillAppear: animated];
  for (i = 0; i < _count; ++i)
    [self service: _genericService button: _offset + i changed: 0xFFFFFFFF];
  [_genericService addDelegate: self];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_genericService removeDelegate: self];
  [super viewWillDisappear: animated];
}

- (void) service: (NLServiceGeneric *) service button: (NSUInteger) buttonIndex changed: (NSUInteger) changed
{
  if (buttonIndex >= _offset && buttonIndex < _offset + _count)
  {
    CustomLightButtonHelper *helper = [_buttonHelpers objectAtIndex: buttonIndex - _offset];
    UIButton *button = helper.button;

    if ((changed & SERVICE_GENERIC_NAME_CHANGED) != 0)
      [button setTitle: [service nameForButton: buttonIndex] forState: UIControlStateNormal];
  
    if ((changed & SERVICE_GENERIC_INDICATOR_CHANGED) != 0)
    {
      helper.hasIndicator = [service indicatorPresentOnButton: buttonIndex];
      helper.indicatorState = [service indicatorStateForButton: buttonIndex];
    }
  }
}

- (void) buttonPushed: (UIButton *) button
{
  [_genericService pushButton: button.tag];
}

- (void) buttonReleased: (UIButton *) button
{
  [_genericService releaseButton: button.tag];
}

- (void) dealloc
{
  [_buttonHelpers release];
  [super dealloc];
}

@end
