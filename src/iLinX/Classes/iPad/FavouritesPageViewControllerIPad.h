//
//  FavouritesPageViewControllerIPad.h
//  iLinX
//
//  Created by James Stamp on 06/09/2010.
//  Copyright 2010 Janus Technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ButtonPageViewController.h"

@class NLServiceFavourites;
@class FavouritesViewControllerIPad;

@interface FavouritesPageViewControllerIPad : ButtonPageViewController
{
@private
  IBOutlet UIButton    	*_buttonTemplateNa;
  NLServiceFavourites *_favouritesService;
  FavouritesViewControllerIPad *_parentController;
}

- (id) initWithService: (NLServiceFavourites *) favouritesService offset: (NSUInteger) offset
         buttonsPerRow: (NSUInteger) buttonsPerRow buttonsPerPage: (NSUInteger) buttonsPerPage 
           buttonTotal: (NSUInteger) buttonTotal flash: (BOOL) flash 
      parentController: (FavouritesViewControllerIPad *) parentController;

@end
