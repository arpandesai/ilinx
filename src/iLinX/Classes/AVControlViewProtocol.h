//
//  AVControlViewProtocol.h
//  iLinX
//
//  Created by mcf on 19/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ControlViewProtocol.h"

@class NLSource;

@protocol AVControlViewProtocol <ControlViewProtocol>

@property (readonly) BOOL isBrowseable;

- (id) initWithRoomList: (NLRoomList *) roomList service: (NLService *) service source: (NLSource *) source;
- (id<ControlViewProtocol>) allocBrowseViewController;

@end
