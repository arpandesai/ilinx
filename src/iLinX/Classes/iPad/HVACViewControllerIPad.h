//
//  HVACViewControllerIPad.h
//  iLinX
//
//  Created by Tony Short on 15/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServiceViewControllerIPad.h"
#import "NLServiceHVAC.h"
#import "HVACDisplayViewIPad.h"
#import "HVACControlButtonPanelIPad.h"

@interface HVACViewControllerIPad : ServiceViewControllerIPad 
			<NLServiceHVACDelegate>
{
@private
  NLServiceHVAC *_hvacService;
  IBOutlet UISegmentedControl *_segmentedSelector;
  
  IBOutlet HVACDisplayViewIPad *_displayViewController;
  
  IBOutlet UIView *_controlView;
  IBOutlet UILabel *_controlViewLabel;
  IBOutlet HVACControlButtonPanelIPad *_controlButtonPanelView;
}

- (IBAction) segmentChanged: (UISegmentedControl *) control;

@end
