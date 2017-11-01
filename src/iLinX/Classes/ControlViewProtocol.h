//
//  ControlViewProtocol.h
//  iLinX
//
//  Created by mcf on 13/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NLRoomList;
@class NLService;

@protocol ControlViewProtocol <NSCoding, NSObject>

- (id) initWithRoomList: (NLRoomList *) roomList service: (NLService *) service;
- (UIView *) view;
- (NLService *) service;

@end
