//
//  ExecutingMacroAlertIPad.h
//  iLinX
//
//  Created by mcf on 28/08/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RootViewControllerIPad.h"

@class NLService;

@interface ExecutingMacroAlertIPad : NSObject
{
@private
  RootViewControllerIPad *_owner;
  NSTimer *_executingMacroTimer;
  BOOL _animated;
}

- (id) initWithOwner: (RootViewControllerIPad *) owner;
//- (void) loadViewUnderView: (UIView *) view atIndex: (NSInteger) index inBounds: (CGRect) mainViewBounds;
- (void) loadViewUnderView: (RootViewControllerIPad *) owner service: (NLService *) service;

- (void) selectNewService: (NLService *) service afterDelay: (NSTimeInterval) delay animated: (BOOL) animated;
- (void) cancelExecutingMacroTimer;


@end
