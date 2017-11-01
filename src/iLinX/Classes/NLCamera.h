//
//  NLCamera.h
//  iLinX
//
//  Created by mcf on 29/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NLCAMERA_CAPABILITY_UP_DOWN    0x0001
#define NLCAMERA_CAPABILITY_LEFT_RIGHT 0x0002
#define NLCAMERA_CAPABILITY_CENTRE     0x0004
#define NLCAMERA_CAPABILITY_ZOOM       0x0008

@class NLCamera;

@protocol NLCameraDelegate <NSObject>
- (void) camera: (NLCamera *) camera hasNewImage: (UIImage *) image;
@end

@interface NLCamera : NSObject
{
@private
  NSString *_displayName;
  NSString *_serviceName;
  UIImage *_image;
  NSURL *_imageURL;
  NSMutableData *_imageData;
  NSURLConnection *_imageConnection;
  NSURL *_up;
  NSURL *_down;
  NSURL *_left;
  NSURL *_right;
  NSURL *_centre;
  NSURL *_zoomIn;
  NSURL *_zoomOut;
  NSMutableArray *_presetNames;
  NSMutableArray *_presetURLs;
  NSTimeInterval _refreshInterval;
  NSTimer *_refreshTimer;
  NSMutableSet *_delegates;
  NSUInteger _random;
}

@property (readonly) NSString *displayName;
@property (readonly) NSString *serviceName;
@property (readonly) UIImage *image;
@property (readonly) NSArray *presetNames;
@property (readonly) NSUInteger capabilities;
@property (assign) NSTimeInterval refreshInterval;

+ (NLCamera *) cameraWithCameraData: (NSDictionary *) data;
+ (void) flushCameraCache;

- (void) addDelegate: (id<NLCameraDelegate>) delegate;
- (void) removeDelegate: (id<NLCameraDelegate>) delegate;

- (void) panUp;
- (void) panDown;
- (void) panLeft;
- (void) panRight;
- (void) recentre;
- (void) zoomIn;
- (void) zoomOut;
- (void) selectPreset: (NSUInteger) presetNumber;

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects;

@end
