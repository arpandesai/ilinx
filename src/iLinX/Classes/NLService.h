//
//  NLService.h
//  iLinX
//
//  Created by mcf on 15/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DebugTracing.h"
#import "NLRenderer.h"

@class NetStreamsComms;
@class NLRoom;

@interface NLService : NSDebugObject
{
@protected
  NSDictionary *_serviceData;
  NLRoom *_room;
  NetStreamsComms *_comms;
}

@property (readonly) NSString *displayName;
@property (readonly) NSString *identifier;
@property (readonly) NSString *serviceType;
@property (readonly) NSString *serviceName;
@property (readonly) BOOL isDefaultScreen;
@property (readonly) NLRenderer *renderer;

+ (id) allocServiceWithServiceData: (NSDictionary *) serviceData room: (NLRoom *) room comms: (NetStreamsComms *) comms;
- (id) initWithServiceData: (NSDictionary *) serviceData room: (NLRoom *) room comms: (NetStreamsComms *) comms;

// Used when parsing gui.xml to build up service details
- (void) parserDidStartElement: (NSString *) elementName attributes: (NSDictionary *) attributeDict;
- (void) parserDidEndElement: (NSString *) elementName;
- (void) parserFoundCharacters: (NSString *) string;
- (void) parserFoundTrailingDataOfType: (NSString *) type data: (NSDictionary *) data;

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects;

@end
