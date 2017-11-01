//
//  ExecutingMacroAlert.h
//  iLinX
//
//  Created by mcf on 28/08/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NLService;

@interface ExecutingMacroAlert : NSObject
{
@private
  UINavigationController *_navigationController;
  UIButton *_disableInput;
  UIButton *_executingMacroBanner;
  UILabel *_executingMacroTitle;
  UIActivityIndicatorView *_executingMacroActivity;
  NSTimer *_executingMacroTimer;
  BOOL _animated;
}

- (void) loadViewUnderView: (UIView *) view atIndex: (NSInteger) index inBounds: (CGRect) mainViewBounds
  withNavigationController: (UINavigationController *) navigationController;
- (void) selectNewService: (NLService *) service afterDelay: (NSTimeInterval) delay animated: (BOOL) animated;
- (void) cancelExecutingMacroTimer;
- (void) showExecutingMacroBanner: (BOOL) show;

@end
