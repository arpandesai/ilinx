//
//  ServiceViewController.m
//  iLinX
//
//  Created by mcf on 23/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "ServiceViewController.h"
#import "ChangeSelectionHelper.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLService.h"
#import "NLSourceList.h"
#import "MainNavigationController.h"
#import "OS4ToolbarFix.h"
#import "RootViewController.h"

#import "AVViewController.h"
#ifdef DEBUG
#import "DebugTracing.h"
#define LOG_RETAIN 0
#endif

@implementation ServiceViewController

- initWithRoomList: (NLRoomList *) roomList service: (NLService *) service
{
  if (self = [super initWithNibName: nil bundle: nil])
  {
    _roomList = [roomList retain];
    //NSLog( @"NLRoomList %08X retained by ServiceViewController (%@) %08X", roomList, [self class], self );
    _service = [service retain];
    self.title = service.displayName;
    _location = [_roomList.currentRoom.serviceName retain];
  }
  
#if LOG_RETAIN
  NSLog( @"%@ init (%@)\n%@", self, _service, [self stackTraceToDepth: 10] );
#endif
  return self;
}

#if LOG_RETAIN
- (id) retain
{
  NSLog( @"%@ retain (%@)\n%@", self, _service, [self stackTraceToDepth: 10] );
  return [super retain];
}

- (void) release
{
  NSLog( @"%@ release (%@)\n%@", self, _service, [self stackTraceToDepth: 10] );
  [super release];
}
#endif

- (NLService *) service
{
  return _service;
}

- (void) loadView
{
  // setup our parent content view and embed it to your view controller
  UIView *contentView = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
  
  contentView.backgroundColor = [UIColor blackColor];
  contentView.autoresizesSubviews = YES;
  contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  self.view = contentView;
  [contentView release];

  [self addToolbar];  
}

- (void) addToolbar
{
  _toolBar = [[ChangeSelectionHelper 
              addToolbarToView: self.view
              withTitle: _roomList.currentRoom.displayName target: self selector: @selector(selectLocation:)
              title: nil target: nil selector: nil] retain];
  
  [_toolBar fixedSetStyle: UIBarStyleBlackOpaque tint: nil];
}

- (void) viewWillAppear: (BOOL) animated
{
  //**/if (![self isKindOfClass: [AVViewController class]])
  //**/  NSLog( @"ServiceViewController viewWillAppear: %@ [%08X]", _service.name, (NSUInteger) self );
  [super viewWillAppear: animated];
  self.navigationController.navigationBarHidden = NO;
}

- (void) viewWillDisappear: (BOOL) animated
{
  //**/if (![self isKindOfClass: [AVViewController class]])
  //**/  NSLog( @"ServiceViewController viewWillDisappear: %@ [%08X]", _service.name, (NSUInteger) self );
  _isCurrentView = NO;
  [super viewWillDisappear: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
  //**/if (![self isKindOfClass: [AVViewController class]])
  //**/  NSLog( @"ServiceViewController viewDidDisappear: %@ [%08X]", _service.name, (NSUInteger) self );
  [super viewDidDisappear: animated];
}

- (void) viewDidAppear: (BOOL) animated
{
  //**/if (![self isKindOfClass: [AVViewController class]])
  //**/  NSLog( @"ServiceViewController viewDidAppear: %@ [%08X]", _service.name, (NSUInteger) self );
  [super viewDidAppear: animated];
 
  if ([_location compare: _roomList.currentRoom.serviceName options: NSCaseInsensitiveSearch] != NSOrderedSame ||
    _roomList.listDataCurrentItem != _roomList.currentRoom)
  {    
    // If source now selected or location changed, return to the root view, which will refresh
    // with the services available for the new location
    
    [(RootViewController *) [[self.navigationController viewControllers] objectAtIndex: 0] selectHomeScreen: YES];
    [_location release];
    _location = nil;
  }
  else
  {
    //NSLog( @"Main nav revealed 4" );
    [self.navigationController setNavigationBarHidden: NO animated: NO];
    _isCurrentView = YES;
  }
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) toInterfaceOrientation
{
  return UIInterfaceOrientationIsPortrait( toInterfaceOrientation );
}

- (void) selectLocation: (id) button
{
  [ChangeSelectionHelper showDialogOver: [self navigationController]
                           withListData: _roomList];
}

- (void) dealloc
{
#if LOG_RETAIN
  NSLog( @"%@ dealloc (%@)\n%@", self, _service, [self stackTraceToDepth: 10] );
#endif
  //NSLog( @"NLRoomList %08X about to be released by ServiceViewController (%@) %08X", _roomList, [self class], self );
  [_roomList release];
  [_service release];
  [_location release];
  [_toolBar release];
  [super dealloc];
}

@end
