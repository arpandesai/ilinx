//
//  CustomViewController.h
//  iLinX
//
//  Created by mcf on 11/05/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ListDataSource.h"
#import "NLRenderer.h"
#import "DebugTracing.h"

@class NLRoomList;
@class ExecutingMacroAlert;

@interface CustomViewController: NSDebugObject <UIWebViewDelegate, NLRendererDelegate>
{
@private
  UIViewController *_controller;
  NSURL *_initialURL;
  NSString *_initialText;
  UIView *_pageParent;
  UIWebView *_page;
  NSString *_title;
  NSUInteger _statusNeeded;
  ExecutingMacroAlert *_macroHandler;
  BOOL _hidesNavigationBar;
  BOOL _hidesToolBar;
  BOOL _hidesAudioControls;
  SEL _closeMethod;
  id _closeTarget;
  NSMutableDictionary *_renderers;
}

@property (readonly) UIView *view;
@property (readonly) NSString *title;
@property (readonly) BOOL hidesNavigationBar;
@property (readonly) BOOL hidesToolBar;
@property (readonly) BOOL hidesAudioControls;
@property (assign) SEL closeMethod;
@property (assign) id closeTarget;

+ (NSString *) skinChangedNotificationKey;
+ (void) maybeFetchConfig;
+ (void) setCurrentRoomList: (NLRoomList *) roomList;
+ (NSString *) getMacAddress;

- (id) initWithController: (UIViewController *) controller dataSource: (id<ListDataSource>) dataSource;
- (id) initWithController: (UIViewController *) controller customPage: (NSString *) customPage;
- (void) loadViewWithFrame: (CGRect) frame;
- (BOOL) isValid;
- (void) reloadData;
- (void) setMacroHandler: (ExecutingMacroAlert *) macroHandler;
- (void) viewWillAppear: (BOOL) animated;
- (void) viewWillDisappear: (BOOL) animated;

@end
