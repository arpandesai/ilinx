//
//  GuiXmlParser.h
//  iLinX
//
//  Created by mcf on 09/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XMLNode;
@class GuiXmlParser;
@class NLRoom;
@class NLService;
@class NLSourceList;
@class NLZoneList;
@class NetStreamsComms;

@protocol GuiXmlDelegate

- (void) parser: (GuiXmlParser *) parser addRoom: (NLRoom *) room presorted: (BOOL) presorted;
- (void) parser: (GuiXmlParser *) parser addMacros: (NSDictionary *) macros;

@end

@interface GuiXmlParser : NSObject <NSXMLParserDelegate>
{
  @private
  NetStreamsComms *_comms;
  NSUInteger _parseLevel;
  NSMutableArray *_parseStack;
  NSMutableDictionary *_currentNode;
  id <GuiXmlDelegate> _delegate;
  NSMutableArray *_rooms;
  NSMutableArray *_sources;
  NSMutableArray *_trailingData;
  NSString *_staticMenuRoom;
  NSMutableArray *_staticMenuRooms;
  NSMutableArray *_controls;
  NLRoom *_buildRoom;
  NLZoneList *_buildZones;
  NLService *_buildService;
  NSMutableDictionary *_macros;
  NSMutableDictionary *_iTunesLibraries;
  BOOL _buildSources;
}

@property (assign) id<GuiXmlDelegate> delegate;

+ (NSString *) stripSpecialAffixesFromString: (NSString *) string;

- (BOOL) parseXMLData: (NSData *) data comms: (NetStreamsComms *) comms 
       staticMenuRoom: (NSString *) staticMenuRoom parseError: (NSError **) error;

@end
