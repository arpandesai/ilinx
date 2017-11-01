//
//  NSSourceList.h
//  iLinX
//
//  Created by mcf on 15/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetStreamsComms.h"
#import "NLRenderer.h"
#import "NLListDataSource.h"

@class NetStreamsComms;
@class NLRoom;
@class NLSource;

@interface NLSourceList : NLListDataSource <NetStreamsMsgDelegate, NLRendererDelegate>
{
  @private
  NSMutableArray *_sources;
  BOOL _possibleNoSource;
  NSSet *_availableSources;
  NSMutableSet *_buildSources;
  NLSource *_currentSource;
  BOOL _addedSourceNotInStaticMenu;
  NSUInteger _listContentDelegateCount;
  NLRoom *_room;
  NetStreamsComms *_netStreamsComms;
  id _queryRspHandle;
  id _menuRspHandle;
  id _queryMsgHandle;
  id _menuMsgHandle;
  NSTimer *_refreshListTimer;
}

@property (nonatomic, retain) NSMutableArray *sources;
@property (readonly) NLSource *currentSource;

+ (NSArray *) masterSources;
+ (void) setMasterSources: (NSArray *) masterSources;

- (id) initWithRoom: (NLRoom *) room comms: (NetStreamsComms *) comms;
- (void) addSource: (NLSource *) source;
- (void) addSourceOnlyDelegate: (id<ListDataDelegate>) delegate;
- (void) removeSourceOnlyDelegate: (id<ListDataDelegate>) delegate;

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects;

@end
