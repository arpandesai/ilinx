//
//  CameraViewController.h
//  iLinX
//
//  Created by mcf on 29/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ListDataSource.h"
#import "ServiceViewController.h"
#import "NLCamera.h"

@class ButtonBar;
@class CameraControlsViewController;
@class NLServiceCameras;

@interface CameraViewController : ServiceViewController <NLCameraDelegate, ListDataSource>
{
@private
  NLServiceCameras *_cameras;
  NSUInteger _previousCamera;
  NSUInteger _currentCamera;
  UIBarButtonItem *_cameraSelectButton;
  UIView *_portraitView;
  UIView *_imageArea;
  UIToolbar *_topBar;
  UIImageView *_currentFullImage;
  UILabel *_currentFullTitle;
  UIView *_fourImagesView;
  NSArray *_fourImages;
  NSArray *_fourTitles;
  UIButton *_tappedImage;
  ButtonBar *_slideshowBar;
  UIButton *_cameraViewButton;
  NSTimer *_slideshowTimer;
  IBOutlet CameraControlsViewController *_controlsOverlay;
}

@end
