//
//  FindRenderer.h
//  iLinX
//
//  Created by mcf on 31/03/2011.
//  Copyright 2011 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DebugTracing.h"
#import "NetStreamsComms.h"

@interface FindRenderer : NSDebugObject <NetStreamsCommsDelegate,NetStreamsMsgDelegate>
{
@private
  NetStreamsComms *_comms;
  NetStreamsComms *_parent;
  NSString *_defaultNetMask;
  id<NetStreamsCommsDelegate> _delegate;
  id _responseHandle;
  NSString *_rendererService;
  NSMutableSet *_rendererQueue;
}

- (id) initWithParent: (NetStreamsComms *) parent address: (NSString *) address 
       defaultNetMask: (NSString *) defaultNetMask delegate: (id<NetStreamsCommsDelegate>) delegate;

@end
