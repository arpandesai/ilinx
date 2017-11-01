//
//  HVACControlButtonPanelIPad.h
//  iLinX
//
//  Created by Tony Short on 15/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLServiceHVAC.h"

#define MaxCols	3

@interface HVACControlButtonPanelIPad : UIScrollView 
<UIScrollViewDelegate>
{
  IBOutlet UIPageControl *_pageControl;
  IBOutlet UIButton *_onTemplate;
  IBOutlet UIButton *_offTemplate;
  IBOutlet UIButton *_noIndicatorTemplate;
  
  NLServiceHVAC *_hvacService;
  NSInteger _controlMode;
  NSMutableArray *_buttonArray;
  NSDictionary *_archivedOnTemplate;
  NSDictionary *_archivedOffTemplate;
  NSDictionary *_archivedNoIndicatorTemplate;
  CGRect _buttonRect;
}

- (void) updateButtonStates;
- (void) updateWithControlModeID: (NSInteger) controlMode;

- (IBAction) pageControlChanged;

@property (nonatomic, retain) NLServiceHVAC *hvacService;

@end
