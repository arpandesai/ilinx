//
//  NLRoom.h
//  iLinX
//
//  Created by mcf on 09/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DebugTracing.h"

@class NetStreamsComms;
@class NLRenderer;
@class NLRoom;
@class NLSourceList;
@class NLService;
@class NLServiceList;
@class NLZoneList;

@interface NLRoom : NSDebugObject
{
@private
  NSString *_serviceName;
  NSString *_displayName;
  NetStreamsComms *_comms;
  NLServiceList *_services;
  NLSourceList *_sources;
  NLZoneList *_zones;
  NSDictionary *_macros;
  NLRenderer *_renderer;
  NSString *_videoServiceName;
}

@property (nonatomic, retain) NSString *serviceName;
@property (nonatomic, retain) NSString *displayName;
@property (nonatomic, retain) NLServiceList *services;
@property (nonatomic, retain) NLSourceList *sources;
@property (nonatomic, retain) NLZoneList *zones;
@property (nonatomic, retain) NSDictionary *macros;
@property (nonatomic, retain) NLRenderer *renderer;
@property (nonatomic, retain) NSString *videoServiceName;

- (id) initWithName: (NSString *) name comms: (NetStreamsComms *) comms;

// Execute a macro in the context of the current room
- (NLService *) executeMacro: (NSString *) macro;
- (NLService *) executeMacro: (NSString *) macro returnExecutionDelay: (NSTimeInterval *) pDelay;
- (NLService *) executeMacroString: (NSString *) macroString;
- (NLService *) executeMacroString: (NSString *) macroString returnExecutionDelay: (NSTimeInterval *) pDelay;

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects;

@end

