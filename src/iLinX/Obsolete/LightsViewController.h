//
//  LightsViewController.h
//  iLinX
//
//  Created by mcf on 29/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServiceViewController.h"
#import "NLServiceGeneric.h"

@interface LightsViewController : ServiceViewController <UIScrollViewDelegate, NLServiceGenericDelegate>
{
@private
  NLServiceGeneric *_lightsService;
  NSUInteger _buttonCount;
  UIPageControl *_pager;
  UIScrollView *_scroller;
  NSMutableArray *_pageControllers;
  UIViewController *_visiblePage;
}

@end
