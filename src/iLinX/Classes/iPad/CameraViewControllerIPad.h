//
//  CameraViewControllerIPad.h
//  iLinX
//
//  Created by mcf on 07/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServiceViewControllerIPad.h"
#import "NLCamera.h"
#import "CameraPresetViewController.h"

#define PlayInterval	2.0

@class NLServiceCameras;

@interface CameraViewControllerIPad : ServiceViewControllerIPad
           <NLCameraDelegate, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, PresetViewDelegate>
{
@private
  NSInteger _templateID;
  
  NLServiceCameras *_cameras;
  NSInteger _currentCameraID;
  NSMutableArray *_visibleCells;
  
  IBOutlet UITableView *_cameraListTableView;
  IBOutlet UIImageView *_currentCameraImageView;
  IBOutlet UILabel *_cameraLabel;
  
  IBOutlet UIButton *_panUp;
  IBOutlet UIButton *_panDown;
  IBOutlet UIButton *_panLeft;
  IBOutlet UIButton *_panRight;
  IBOutlet UIButton *_panCentre;
  IBOutlet UIButton *_zoomIn;
  IBOutlet UIButton *_zoomOut;
  IBOutlet UIButton *_playButton;
  IBOutlet UIButton *_pauseButton;
  IBOutlet UIButton *_presetButton;	
  IBOutlet UIImageView *_cameraControlsBackImage;
  
  CameraPresetViewController *_presetViewController;
  UIPopoverController *_presetPopover;
  
  IBOutlet UIView *_thumbnailCellTemplatesView;
  NSMutableArray *_thumbnailCellTemplates;
}

-(void)panUp:(id)sender;
-(void)panDown:(id)sender;
-(void)panLeft:(id)sender;
-(void)panRight:(id)sender;
-(void)panCentre:(id)sender;
-(void)zoomIn:(id)sender;
-(void)zoomOut:(id)sender;
-(void)playPressed:(id)sender;
-(void)pausePressed:(id)sender;
-(void)presetPressed:(id)sender;

@property (readonly) NLCamera* currentCamera;

@end

@interface CameraThumbnailTableViewCell : UITableViewCell
<NLCameraDelegate>
{
  NLCamera *_camera;
  NSInteger _cameraID;
  UIImageView *_thumbnailImageView;
  UIActivityIndicatorView *_activityView;
  UILabel *_cameraImageUnavailableLabel;
}

-(void)imageLoadTimeout;

@property (nonatomic, retain) NLCamera *camera;
@property (nonatomic, retain) UIImageView *thumbnailImageView;
@property (nonatomic, retain) UIActivityIndicatorView *activityView;
@property (nonatomic, retain) UILabel *cameraImageUnavailableLabel;

@end

@interface ThumbnailCellTemplate : NSObject
{
  NSDictionary *_rowData;
  
  float _cellHeight;
  NSInteger _thumbnailImageViewOffset;
  NSInteger _thumbnailLabelOffset;
  NSInteger _activityViewOffset;
  NSInteger _cameraImageUnavailableLabelOffset;
}

@property (nonatomic, retain) NSDictionary *rowData;
@property float cellHeight;
@property NSInteger thumbnailImageViewOffset;
@property NSInteger thumbnailLabelOffset;
@property NSInteger activityViewOffset;
@property NSInteger cameraImageUnavailableLabelOffset;

@end
