//
//  FavouritesPageViewControllerIPad.m
//  iLinX
//
//  Created by James Stamp on 06/09/2010.
//  Copyright 2010 Janus Technology. All rights reserved.
//

#import "FavouritesViewControllerIPad.h"
#import "ColouredRoundedRect.h"
#import "DeprecationHelper.h"
#import "FavouritesPageViewControllerIPad.h"
#import "NLServiceFavourites.h"
#import "StandardPalette.h"
#import "UncodableObjectArchiver.h"
#import <QuartzCore/QuartzCore.h>

@interface FavouritesPageViewControllerIPad ()

- (void) buttonPushed: (UIButton *) button;

@end

@implementation FavouritesPageViewControllerIPad


- (id) initWithService: (NLServiceFavourites *) favouritesService offset: (NSUInteger) offset
         buttonsPerRow: (NSUInteger) buttonsPerRow buttonsPerPage: (NSUInteger) buttonsPerPage 
           buttonTotal: (NSUInteger) buttonTotal flash: (BOOL) flash 
      parentController: (FavouritesViewControllerIPad *) parentController
{
  if (self = [super initWithNibName: @"FavouritesPageIPad" bundle: nil offset: offset
                      buttonsPerRow: buttonsPerRow buttonsPerPage: buttonsPerPage
                        buttonTotal: buttonTotal flash: flash])
  {
    _favouritesService = favouritesService;
    _parentController = parentController;
  }

  return self;
}

- (void) viewDidLoad
{
  NSDictionary *buttonTemplate = [UncodableObjectArchiver dictionaryEncodingWithRootObject: _buttonTemplateNa];
  
  [super viewDidLoadWithButtonTemplate: buttonTemplate frame: _buttonTemplateNa.frame];
}

- (id) createButtonAtIndex: (NSUInteger) index buttonTemplate: (id) buttonTemplate frame: (CGRect) frame
{
  UIButton *button = [UncodableObjectUnarchiver unarchiveObjectWithDictionary: (NSDictionary *) buttonTemplate];
  NSString *name = [_favouritesService nameForFavourite: _offset + index];
  
  button.frame = frame;
  button.tag = _offset + index;
  button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
  UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
  button.hidden = NO;
  [button setTitle: name forState: UIControlStateNormal];
  [button addTarget: self action: @selector(buttonPushed:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
  [_contentView addSubview: button];
  
  return button;
}

- (void) buttonPushed: (UIButton *) button
{
  NSTimeInterval delay;

  NLService *newUIScreen = [_favouritesService executeFavourite: button.tag returnExecutionDelay: &delay];
  
  [_parentController selectNewService: newUIScreen afterDelay: delay];
}

- (void) dealloc
{
  [_buttonTemplateNa release];
  [super dealloc];
}

@end

