    //
//  ButtonPageViewController.m
//  iLinX
//
//  Created by mcf on 11/11/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "ButtonPageViewController.h"


@implementation ButtonPageViewController

- (id) initWithNibName: (NSString *) nibName bundle: (NSBundle *) bundle offset: (NSUInteger) offset 
         buttonsPerRow: (NSUInteger) buttonsPerRow buttonsPerPage: (NSUInteger) buttonsPerPage 
           buttonTotal: (NSUInteger) buttonTotal flash: (BOOL) flash
{
  if (self = [super initWithNibName: nibName bundle: bundle])
  {
    _offset = offset;
    _buttonsPerRow = buttonsPerRow;
    if (_buttonsPerRow < 1)
      _buttonsPerRow = 1;
    _buttonsPerPage = buttonsPerPage;
    if (_buttonsPerPage < 1)
      _buttonsPerPage = 1;
    
    if (offset > buttonTotal)
      _count = 0;
    else if (flash)
    {
      if (_offset + 8 >= buttonTotal)
        _count = buttonTotal - _offset;
      else
        _count = 7;
    }
    else if (_offset + buttonsPerPage > buttonTotal)
      _count = buttonTotal - _offset;
    else
      _count = buttonsPerPage;
  }

  return self;
}

- (void) viewDidLoadWithButtonTemplate: (id) buttonTemplate frame: (CGRect) frame 
{
  [super viewDidLoad];
  
  CGFloat marginWidth = frame.origin.x;
  CGFloat marginHeight = frame.origin.y;
  CGFloat availableSpaceWidth = _contentView.frame.size.width - (2 * marginWidth);
  CGFloat availableSpaceHeight = _contentView.frame.size.height - (2 * marginHeight);  
  CGFloat buttonHeight = frame.size.height;
  CGFloat buttonWidth = frame.size.width;
  NSInteger buttonRows = ((_buttonsPerPage + (_buttonsPerRow - 1)) / _buttonsPerRow);
  CGFloat availableSpaceBetweenWidth;
  CGFloat availableSpaceBetweenHeight;
  
  if (_buttonsPerRow < 2)
    availableSpaceBetweenWidth = 0;
  else
    availableSpaceBetweenWidth = (availableSpaceWidth - ( _buttonsPerRow * buttonWidth))/(_buttonsPerRow - 1);
  
  if (buttonRows < 2)
    availableSpaceBetweenHeight = 0;
  else
    availableSpaceBetweenHeight = (availableSpaceHeight - (buttonRows * buttonHeight))/(buttonRows - 1);
  
  _buttonArray = [[NSMutableArray arrayWithCapacity: _count] retain];
  
  for (NSUInteger i = 0; i < _count; ++i)
  {
    [_buttonArray addObject: 
     [self createButtonAtIndex: i 
                buttonTemplate: buttonTemplate
                         frame: CGRectMake( marginWidth + (availableSpaceBetweenWidth + buttonWidth) * (i % _buttonsPerRow),
                                           marginHeight + (availableSpaceBetweenHeight + buttonHeight)  * (i / _buttonsPerRow),
                                           buttonWidth, buttonHeight )]];
  }
}

- (void) viewDidUnload
{
  [_buttonArray release];
  _buttonArray = nil;
  [super viewDidUnload];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
  // Overriden to allow any orientation.
  return YES;
}

- (id) createButtonAtIndex: (NSUInteger) index buttonTemplate: (id) buttonTemplate frame: (CGRect) frame
{
  // For derived classes to implement
  return [NSNull null];
}

- (void) dealloc
{
  [_contentView release];
  [_buttonArray release];
  [super dealloc];
}

@end
