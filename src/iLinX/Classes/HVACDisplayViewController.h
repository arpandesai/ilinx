//
//  HVACDisplayViewController.h
//  iLinX
//
//  Created by mcf on 13/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLServiceHVAC.h"

@interface HVACDisplayViewController : UIViewController <NLServiceHVACDelegate>
{
@private
  NLServiceHVAC *_hvacService;
  UIViewController *_parentController;
  IBOutlet UILabel *_zoneLabel;
  IBOutlet UILabel *_zoneTemp;
  IBOutlet UILabel *_zoneTempType;
  IBOutlet UILabel *_zoneHumidityLabel;
  IBOutlet UILabel *_zoneHumidity;
  IBOutlet UILabel *_zoneSetPointLabel;
  IBOutlet UILabel *_zoneSetPointTemp;
  IBOutlet UILabel *_zoneSetPointTempType;
  IBOutlet UIButton *_setSetPointButton;
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

- (id) initWithHvacService: (NLServiceHVAC *) hvacService parentController: (UIViewController *) parentController;

- (IBAction) pressedSetSetPointButton: (UIButton *) button;
- (IBAction) nothing;

@end
