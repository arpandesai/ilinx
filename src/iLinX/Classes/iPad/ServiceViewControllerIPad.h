//
//  ServiceViewControllerIPad.h
//  iLinX
//
//  Created by mcf on 09/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewControllerIPad;
@class NLRoomList;
@class NLService;

@protocol ServiceViewControllerIPad <NSObject>

- (id) initWithOwner: (RootViewControllerIPad *) owner service: (NLService *) service;
- (id) initWithOwner: (RootViewControllerIPad *) owner service: (NLService *) service
             nibName: (NSString *) nibName bundle: (NSBundle *) bundle;
- (NLRoomList *) roomList;
- (NLService *) service;

@end


@interface ServiceViewControllerIPad : UIViewController <ServiceViewControllerIPad>
{
@protected
  RootViewControllerIPad *_owner;
  NLService *_service;
}

- (NLRoomList *) roomList;

@end
