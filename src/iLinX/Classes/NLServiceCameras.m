//
//  NLServiceCameras.m
//  iLinX
//
//  Created by mcf on 29/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLServiceCameras.h"
#import "NLCamera.h"

@implementation NLServiceCameras

@synthesize
  cameras = _cameras;

- (id) initWithServiceData: (NSDictionary *) serviceData room: (NLRoom *) room comms: (NetStreamsComms *) comms
{
  if (self = [super initWithServiceData: serviceData room: room comms: comms])
    _cameras = [NSMutableArray new];
  
  return self;
}

- (NSUInteger) cameraCount
{
  return [_cameras count];
}

- (NLCamera *) cameraAtIndex: (NSUInteger) index
{
  if (index < [_cameras count])
    return [_cameras objectAtIndex: index];
  else
    return nil;
}

- (void) parserDidStartElement: (NSString *) elementName attributes: (NSDictionary *) attributeDict
{
  if ([elementName isEqualToString: @"camera"])
    [_cameras addObject: attributeDict];
}

- (void) parserFoundTrailingDataOfType: (NSString *) type data: (NSDictionary *) data
{
  if ([type isEqualToString: @"cameras"])
  {
    NSArray *children = [data objectForKey: @"#children"];
    NSUInteger childCount = [children count];
    NSUInteger i = 0;
    NSUInteger j;
    
    while (i < [_cameras count])
    {
      NSString *name = [[_cameras objectAtIndex: i] objectForKey: @"id"];
      
      for (j = 0; j < childCount; ++j)
      {
        NSDictionary *child = [children objectAtIndex: j];
        
        if ([[child objectForKey: @"#elementName"] isEqualToString: @"camera"] &&
            [[child objectForKey: @"id"] isEqualToString: name])
        {
          [_cameras replaceObjectAtIndex: i withObject: [NLCamera cameraWithCameraData: child]];
          break;
        }
      }
      
      if (j < childCount)
        ++i;
      else
        [_cameras removeObjectAtIndex: i];
    }
  }
}

@end
