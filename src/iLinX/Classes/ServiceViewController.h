//
//  ServiceViewController.h
//  iLinX
//
//  Created by mcf on 23/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ControlViewProtocol.h"

@interface ServiceViewController : UIViewController <ControlViewProtocol>
{
@protected
  UIToolbar *_toolBar;
  NLRoomList *_roomList;
  NLService *_service;
  NSString *_location;
  BOOL _isCurrentView;
}

- (void) addToolbar;
- (void) selectLocation: (id) button;

@end
