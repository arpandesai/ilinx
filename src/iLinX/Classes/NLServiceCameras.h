//
//  NLServiceCameras.h
//  iLinX
//
//  Created by mcf on 29/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLService.h"

@class NLCamera;

@interface NLServiceCameras : NLService
{
@private
  NSMutableArray *_cameras;
}

@property (readonly) NSArray *cameras;
@property (readonly) NSUInteger cameraCount;

- (NLCamera *) cameraAtIndex: (NSUInteger) index;

@end
