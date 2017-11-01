//
//  HVACDisplayViewControllerIPad.h
//  iLinX
//
//  Created by Tony Short on 15/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLServiceHVAC.h"

@interface HVACDisplayViewIPad : UIView 
<NLServiceHVACDelegate>
{
  NLServiceHVAC *_hvacService;
  
  IBOutlet UIView *_currentTempView;
  IBOutlet UIView *_outsideTempView;
  IBOutlet UIView *_setPointView;
  IBOutlet UIView *_setPointView1;
  IBOutlet UIView *_setPointView2;
  IBOutlet UIView *_feedbackView;
  IBOutlet UIView *_controlView;
  
  IBOutlet UILabel *_zoneTemp;
  IBOutlet UILabel *_zoneTempType;
  IBOutlet UILabel *_zoneHumidityLabel;
  IBOutlet UILabel *_zoneHumidity;
  IBOutlet UILabel *_setPointTemp;
  IBOutlet UILabel *_setPointTempType;
  IBOutlet UILabel *_coolSetPointTemp;
  IBOutlet UILabel *_coolSetPointTempType;
  IBOutlet UILabel *_warmSetPointTemp;
  IBOutlet UILabel *_warmSetPointTempType;
  IBOutlet UISlider *_setPointSlider;
  IBOutlet UISlider *_coolSetPointSlider;
  IBOutlet UISlider *_warmSetPointSlider;
  IBOutlet UILabel *_outsideLabel;
  IBOutlet UILabel *_outsideTemp;
  IBOutlet UILabel *_outsideTempType;
  IBOutlet UILabel *_outsideHumidityLabel;
  IBOutlet UILabel *_outsideHumidity;
  IBOutlet UILabel *_modeTitle;
  IBOutlet UILabel *_modeLine1;
  IBOutlet UILabel *_modeLine2;
  IBOutlet UIImageView *_modeIcon;
  IBOutlet UILabel *_modeLine2WithIcon;
}

- (IBAction) setPointChanged;
- (IBAction) coolSetPointChanged;
- (IBAction) warmSetPointChanged;
- (IBAction) setPointUpdateService;
- (IBAction) coolSetPointUpdateService;
- (IBAction) warmSetPointUpdateService;

- (void) setViewBorders;

@property (nonatomic, retain) NLServiceHVAC *hvacService;

@end
