//
//  FavouritesPageViewController.m
//  iLinX
//
//  Created by mcf on 29/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "FavouritesViewController.h"
#import "ColouredRoundedRect.h"
#import "DeprecationHelper.h"
#import "FavouritesPageViewController.h"
#import "NLServiceFavourites.h"
#import "StandardPalette.h"

@interface FavouritesPageViewController ()

- (void) buttonPushed: (UIButton *) button;

@end

@implementation FavouritesPageViewController

- (id) initWithService: (NLServiceFavourites *) favouritesService offset: (NSUInteger) offset count: (NSUInteger) count
      parentController: (FavouritesViewController *) parentController
{
  if (self = [super initWithNibName: nil bundle: nil])
  {
    _favouritesService = favouritesService;
    _parentController = parentController;
    _offset = offset;
    _count = count;
  }
  
  return self;
}

- (void) loadView
{
  UIView *contentView = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
  UIImageView *imageView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"BackdropLight.png"]];
  
  contentView.backgroundColor = [UIColor clearColor];
  contentView.autoresizesSubviews = YES;
  contentView.frame = CGRectMake( contentView.frame.origin.x, contentView.frame.origin.y,
                                 contentView.frame.size.width, 340 );
  contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  self.view = contentView;
  imageView.frame = contentView.bounds;
  imageView.backgroundColor = [StandardPalette backdropTint];
  [contentView addSubview: imageView];
  [imageView release];
  
  NSUInteger i;
  
  for (i = 0; i < _count; ++i)
  {
    NSString *name = [_favouritesService nameForFavourite: _offset + i];
    
    if (name == nil)
    {
      _count = i;
      break;
    }
    
    UIButton *button = [UIButton buttonWithType: UIButtonTypeCustom];
    UIColor *tint = [StandardPalette buttonColour];
    
    button.frame = CGRectMake( 10 + 155 * (i % 2), 10 + 70 * (i / 2), 145, 60 );
    [button setTitle: name forState: UIControlStateNormal];
    [button setBackgroundImage: [UIImage imageNamed: @"FavouriteButtonReleased.png"] forState: UIControlStateNormal];
    [button setBackgroundImage: [UIImage imageNamed: @"FavouriteButtonPressed.png"] forState: UIControlStateHighlighted];
    [button addTarget: self action: @selector(buttonPushed:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
    [button setTitleColor: [StandardPalette buttonTitleColour] forState: UIControlStateNormal];
    [button setTitleColor: [StandardPalette highlightedButtonTitleColour] forState: UIControlStateHighlighted];
    [button setTitleShadowColor: [StandardPalette buttonTitleShadowColour] forState: UIControlStateNormal];
    [button setTitleLabelFont: [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]]];
    button.tag = _offset + i;

    if (tint != nil)
    {
      ColouredRoundedRect *backdrop = [[ColouredRoundedRect alloc] initWithFrame: button.frame fillColour: tint radius: 12.0];

      [contentView addSubview: backdrop];
      [backdrop release];
    }
    
    [contentView addSubview: button];
  }

  [contentView release];
}

- (void) buttonPushed: (UIButton *) button
{
  NSTimeInterval delay;
  NLService *newUIScreen = [_favouritesService executeFavourite: button.tag returnExecutionDelay: &delay];
  
  [_parentController selectNewService: newUIScreen afterDelay: delay];
}

@end
