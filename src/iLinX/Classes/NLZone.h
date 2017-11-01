//
//  NLZone.h
//  iLinX
//
//  Created by mcf on 12/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NLZone : NSObject
{
@private
  NSString *_serviceName;
  NSString *_displayName;
}

@property (readonly) NSString *displayName;
@property (readonly) NSString *serviceName;
@property (readonly) NSString *audioSessionName;

- (id) initWithServiceName: (NSString *) serviceName;

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects;

@end
