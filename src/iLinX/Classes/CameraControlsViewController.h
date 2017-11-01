//
//  CameraControlsViewController.h
//  iLinX
//
//  Created by mcf on 30/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NLCamera;
@class GreyRoundedRect;

@interface CameraControlsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
  NLCamera *_camera;
  IBOutlet UIButton *_panUp;
  IBOutlet UIButton *_panDown;
  IBOutlet UIButton *_panLeft;
  IBOutlet UIButton *_panRight;
  IBOutlet UIButton *_panCentre;
  IBOutlet UIButton *_zoomIn;
  IBOutlet UIButton *_zoomOut;
  IBOutlet GreyRoundedRect *_zoomInBackdrop;
  IBOutlet GreyRoundedRect *_zoomOutBackdrop;
  IBOutlet GreyRoundedRect *_centreBackdrop;
  IBOutlet GreyRoundedRect *_hideBackdrop;
  IBOutlet UILabel *_presetsTitle;
  IBOutlet UITableView *_presets;
  IBOutlet UILabel *_unavailable;
}

- (id) initWithCamera: (NLCamera *) camera;
- (void) setCamera: (NLCamera *) camera;
- (void) enableHideBackdrop: (BOOL) enable;
- (void) ensureArrowsCorrect;

- (IBAction) pressedPanUp: (id) sender;
- (IBAction) pressedPanDown: (id) sender;
- (IBAction) pressedPanLeft: (id) sender;
- (IBAction) pressedPanRight: (id) sender;
- (IBAction) pressedPanCentre: (id) sender;
- (IBAction) pressedZoomIn: (id) sender;
- (IBAction) pressedZoomOut: (id) sender;
- (IBAction) pressedHide: (id) sender;

@end
