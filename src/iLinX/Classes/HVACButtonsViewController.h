//
//  HVACButtonsViewController.h
//  iLinX
//
//  Created by mcf on 13/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLServiceHVAC.h"

@interface HVACButtonsViewController : UIViewController <NLServiceHVACDelegate, UIScrollViewDelegate>
{
  NLServiceHVAC *_hvacService;
  NSUInteger _controlMode;
  NSUInteger _buttonCount;
  UIPageControl *_pager;
  UIScrollView *_scroller;
  NSMutableArray *_pageControllers;
  UIViewController *_visiblePage;  
}

- initWithHvacService: (NLServiceHVAC *) hvacService controlMode: (NSUInteger) controlMode;

@end
