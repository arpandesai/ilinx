//
//  FavouritesPageViewController.h
//  iLinX
//
//  Created by mcf on 06/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "XIBViewController.h"

@class NLServiceFavourites;
@class FavouritesViewController;

@interface FavouritesPageViewController : UIViewController
{
@private
  NLServiceFavourites *_favouritesService;
  FavouritesViewController *_parentController;
  NSUInteger _offset;
  NSUInteger _count;
}

- (id) initWithService: (NLServiceFavourites *) favouritesService offset: (NSUInteger) offset count: (NSUInteger) count
      parentController: (FavouritesViewController *) parentController;

@end
