//
//  NLSource.h
//  iLinX
//
//  Created by mcf on 15/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DebugTracing.h"

@class NetStreamsComms;
@class NLBrowseList;

@interface NLSource : NSDebugObject
{
@protected
  NSMutableDictionary *_sourceData;
  NetStreamsComms *_comms;
  BOOL _isCurrentSource;
  BOOL _isSlowSource;
@private
  NSString *_displayName;
}

@property (readonly) NSString *displayName;
@property (readonly) NSString *serviceName;
@property (readonly) NSString *sourceType;
@property (readonly) NSString *controlType;
@property (readonly) NSString *sourceControlType;
@property (readonly) NLBrowseList *browseMenu;
@property (readonly) NSString *browseRootPath;
@property (readonly) NSString *controlState;
@property (assign) BOOL isCurrentSource;
@property (readonly) NSDictionary *sourceData;
@property (assign) BOOL isSlowSource;
@property (readonly) NSTimeInterval retryInterval;

+ (NLSource *) noSourceObject;
+ (id) allocSourceWithSourceData: (NSDictionary *) sourceData comms: (NetStreamsComms *) comms;
+ (NSSet *) sourceControlTypes;

- (id) initWithSourceData: (NSDictionary *) sourceData comms: (NetStreamsComms *) comms;
- (void) parserFoundTrailingDataOfType: (NSString *) type data: (NSDictionary *) data;

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects;


// For child classes to override

// Called when this source has delegates for the first time
- (void) activate;

// Called when there are no more delegates for this source
- (void) deactivate;

// Implement for sources that support metadata
- (NSDictionary *) metadata;
- (NSDictionary *) metadataWithDefault: (NSDictionary *) metadata;
- (void) setMetadata: (NSDictionary *) metadata;

@end
