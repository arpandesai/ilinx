//
//  NLSourceLocal.h
//  iLinX
//
//  Created by mcf on 25/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ListDataSource.h"
#import "NetStreamsComms.h"
#import "NLSource.h"


// Flags indicating which source values have changed
#define SOURCE_LOCAL_PRESET_CHANGED          0x0001

@class NLSourceLocal;
@class NLBrowseList;

@protocol NLSourceLocalDelegate <NSObject>
- (void) source: (NLSourceLocal *) source stateChanged: (NSUInteger) flags;
@end

@interface NLSourceLocal : NLSource <NetStreamsMsgDelegate>
{
@private
  NSMutableSet *_sourceDelegates;
  NLBrowseList *_presets;
  id _statusRspHandle;
  id _registerMsgHandle;
  NSUInteger _currentPreset;
}

@property (readonly) BOOL isNaimAmp;
@property (readonly) id<ListDataSource> presets;
@property (readonly) NSUInteger currentPreset;

- (void) addDelegate: (id<NLSourceLocalDelegate>) delegate;
- (void) removeDelegate: (id<NLSourceLocalDelegate>) delegate;

@end
