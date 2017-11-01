    //
//  NoSourcePageViewControllerIPad.m
//  iLinX
//
//  Created by mcf on 11/11/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "NoSourcePageViewControllerIPad.h"
#import "NoSourceViewControllerIPad.h"
#import "UncodableObjectArchiver.h"

@interface NoSourcePageViewControllerIPad ()

- (void) buttonPushed: (UIButton *) button;

@end


@implementation NoSourcePageViewControllerIPad

- (id) initWithOffset: (NSUInteger) offset buttonsPerRow: (NSUInteger) buttonsPerRow buttonsPerPage: (NSUInteger) buttonsPerPage 
          buttonTotal: (NSUInteger) buttonTotal flash: (BOOL) flash
{
  return [super initWithNibName: @"NoSourcePageIPad" bundle: nil offset: offset buttonsPerRow: buttonsPerRow
                 buttonsPerPage: buttonsPerPage buttonTotal: buttonTotal flash: flash];
}

- (void) refreshButtonStatesWithSources: (NLSourceList *) sources
{
  // No need to retain - our parent does that for us
  _sources = sources;
  if (_sources != nil)
  {
    for (UIButton *button in _buttonArray)
    {
      button.enabled = [_sources itemIsSelectableAtIndex: button.tag];
      [button setTitle: [_sources titleForItemAtIndex: button.tag] forState: UIControlStateNormal];
    }
  }
}

- (void) viewDidLoad
{
  NSDictionary *buttonTemplate = [UncodableObjectArchiver dictionaryEncodingWithRootObject: _buttonTemplate];  

  [super viewDidLoadWithButtonTemplate: buttonTemplate frame: _buttonTemplate.frame];
  [self refreshButtonStatesWithSources: _sources];
}

- (id) createButtonAtIndex: (NSUInteger) index buttonTemplate: (id) buttonTemplate frame: (CGRect) frame
{
  UIButton *button = [UncodableObjectUnarchiver unarchiveObjectWithDictionary: 
                      (NSDictionary *) buttonTemplate];

  button.frame = frame;
  button.tag = _offset + index + 1;
  button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
  UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
  button.hidden = NO;
  [button addTarget: self action: @selector(buttonPushed:) 
   forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
  [_contentView addSubview: button];    
  
  return button;
}

- (void) buttonPushed: (UIButton *) button
{
  if ([_sources refreshIsComplete] && [_sources itemIsSelectableAtIndex: button.tag])
  {
    [_sources selectItemAtIndex: button.tag];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  }
}

- (void) dealloc
{
  [_buttonTemplate release];
  [super dealloc];
}

@end
