//
//  GenericPageViewController.m
//  iLinX

//  Creted by mcf on 29/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "GenericPageViewControllerIPad.h"
#import "UncodableObjectArchiver.h"

@interface GenericPageViewControllerIPad ()

- (void) buttonPushed: (UIButton *) button;
- (void) buttonReleased: (UIButton *) button;

@end

#define BUTTON_STATE_OFF  0
#define BUTTON_STATE_ON   1
#define BUTTON_STATE_NA   2
#define NUM_BUTTON_STATES 3

@implementation GenericPageViewControllerIPad

- (id) initWithService: (NLServiceGeneric *) genericService offset: (NSUInteger) offset
         buttonsPerRow: (NSUInteger) buttonsPerRow buttonsPerPage: (NSUInteger) buttonsPerPage 
           buttonTotal: (NSUInteger) buttonTotal flash: (BOOL) flash
{
  if (self = [super initWithNibName: @"GenericPageIPad" bundle: nil offset: offset
                      buttonsPerRow: buttonsPerRow buttonsPerPage: buttonsPerPage
                        buttonTotal: buttonTotal flash: flash])
    _genericService = genericService;

  return self;
}

- (void) viewDidLoad
{
  NSArray *buttonTemplate = [NSArray arrayWithObjects:
                             [UncodableObjectArchiver dictionaryEncodingWithRootObject: _buttonTemplateOff],
                             [UncodableObjectArchiver dictionaryEncodingWithRootObject: _buttonTemplateOn],
                             [UncodableObjectArchiver dictionaryEncodingWithRootObject: _buttonTemplateNa], nil];
  
  [super viewDidLoadWithButtonTemplate: buttonTemplate frame: _buttonTemplateOff.frame];
  
  // Hide the templates once they're no longer needed
  _buttonTemplateOff.hidden = YES;
  _buttonTemplateOn.hidden = YES;
  _buttonTemplateNa.hidden = YES;
}

- (id) createButtonAtIndex: (NSUInteger) index buttonTemplate: (id) buttonTemplate frame: (CGRect) frame
{
  NSMutableArray *buttonArrayType = [NSMutableArray arrayWithCapacity: NUM_BUTTON_STATES];
  NSString *name = [_genericService nameForButton: _offset + index];
  
  for (NSInteger i = 0; i < NUM_BUTTON_STATES; ++i)
  {
    UIButton *button = [UncodableObjectUnarchiver unarchiveObjectWithDictionary: [(NSArray *) buttonTemplate objectAtIndex: i]];
    
    button.frame = frame;
    button.tag = _offset + index;
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    button.hidden = YES;
    [button setTitle: name forState: UIControlStateNormal];
    [button addTarget: self action: @selector(buttonPushed:) forControlEvents: UIControlEventTouchDown];
    [button addTarget: self action: @selector(buttonReleased:) 
     forControlEvents: UIControlEventTouchUpOutside|UIControlEventTouchUpInside];
    [_contentView addSubview: button];
    [buttonArrayType addObject: button];
  }

  return buttonArrayType;
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
    NSArray *buttonSet = [_buttonArray objectAtIndex: (buttonIndex - _offset)];
    BOOL hasIndicator = [service indicatorPresentOnButton: buttonIndex];
    BOOL indicatorState = [service indicatorStateForButton: buttonIndex];

    for (NSInteger i = 0; i < NUM_BUTTON_STATES; ++i)  
    {
      UIButton *button = [buttonSet objectAtIndex: i];
      
      if (i == BUTTON_STATE_OFF)
        button.hidden = (!hasIndicator || indicatorState);
      else if (i == BUTTON_STATE_ON)
        button.hidden = (!hasIndicator || !indicatorState);
      else
        button.hidden = hasIndicator;
    }
  }
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
  // Overriden to allow any orientation.
  return YES;
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
  [_buttonTemplateOff release];
  [_buttonTemplateOn release];
  [_buttonTemplateNa release];
  [super dealloc];
}

@end 
