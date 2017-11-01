//
//  SecurityButtonsPageViewController.m
//  iLinX
//
//  Created by mcf on 26/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "SecurityButtonsPageViewController.h"
#import "CustomLightButtonHelper.h"

@interface SecurityButtonsPageViewController ()

- (void) buttonPushed: (UIButton *) button;
- (void) buttonReleased: (UIButton *) button;

@end

@implementation SecurityButtonsPageViewController

- (id) initWithService: (NLServiceSecurity *) securityService controlMode: (NSUInteger) controlMode
                offset: (NSUInteger) offset count: (NSUInteger) count
{
  if (self = [super initWithNibName: nil bundle: nil])
  {
    _securityService = securityService;
    _controlMode = controlMode;
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
  
  NSArray *titles = [_securityService.controlModeTitles objectAtIndex: _controlMode];
  NSUInteger i;
  
  if (_offset + _count > [titles count])
    _count = [titles count] - _offset;
  
  _buttonHelpers = [[NSMutableArray arrayWithCapacity: _count] retain];
  
  for (i = 0; i < _count; ++i)
  {
    NSString *name = [titles objectAtIndex: _offset + i];
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
    [self service: _securityService controlMode: _controlMode button: i + _offset changed: 0xFFFFFFFF];
  [_securityService addDelegate: self];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_securityService removeDelegate: self];
  [super viewWillDisappear: animated];
}

- (void) service: (NLServiceSecurity *) service controlMode: (NSUInteger) controlMode
          button: (NSUInteger) buttonIndex changed: (NSUInteger) changed
{
  if (controlMode == _controlMode && buttonIndex >= _offset && buttonIndex < _offset + _count)
  {
    CustomLightButtonHelper *helper = [_buttonHelpers objectAtIndex: buttonIndex - _offset];
    UIButton *button = helper.button;
    
    if ((changed & SERVICE_SECURITY_MODE_TITLES_CHANGED) != 0)
      [button setTitle: [service nameForButton: buttonIndex inControlMode: controlMode] forState: UIControlStateNormal];
    
    if ((changed & SERVICE_SECURITY_MODE_STATES_CHANGED) != 0)
    {
      helper.hasIndicator = [service indicatorPresentOnButton: buttonIndex inControlMode: controlMode];
      helper.indicatorState = [service indicatorStateForButton: buttonIndex inControlMode: controlMode];
      button.hidden = ![service isVisibleButton: buttonIndex inControlMode: controlMode];
      button.enabled = [service isEnabledButton: buttonIndex inControlMode: controlMode];
    }
  }
}

- (void) buttonPushed: (UIButton *) button
{
  [_securityService pushButton: button.tag inControlMode: _controlMode];
}

- (void) buttonReleased: (UIButton *) button
{
  [_securityService releaseButton: button.tag inControlMode: _controlMode];
}

@end
