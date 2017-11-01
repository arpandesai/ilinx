//
//  PlaceholderViewController.m
//  iLinX
//
//  Created by mcf on 31/12/2008.
//  Copyright 2008 Micropraxis Ltd. All rights reserved.
//

#import "PlaceholderViewController.h"
#import "ChangeSelectionHelper.h"
#import "MainNavigationController.h"
#import "NLRoomList.h"
#import "RootViewController.h"
#import "NLRoom.h"
#import "NLService.h"
#import "NLSource.h"
#import "NLSourceList.h"

@implementation PlaceholderViewController

- initWithRoomList: (NLRoomList *) roomList service: (NLService *) service source: (NLSource *) source
{
  if (self = [super initWithRoomList: roomList service: service source: source])
  {
    _avPlaceholder = [service.serviceName isEqualToString: @"A/V"];
    if (!_avPlaceholder)
      self.title = service.displayName;
    else
    {
      NSString *sourceControlType = source.sourceControlType;
      
      if ([sourceControlType isEqualToString: @"LOCALSOURCE"] ||
        [sourceControlType isEqualToString: @"LOCALSOURCE-STREAM"])
        self.title = @"Local source";
      else if ([sourceControlType isEqualToString: @"TUNER"])
        self.title = @"Tuner";
      else if ([sourceControlType isEqualToString: @"XM TUNER"])
        self.title = @"XM Tuner";
      else
        self.title = sourceControlType;
    }
  }
  
  return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void) loadView
{
  [super loadView];

  self.view.backgroundColor = [UIColor colorWithWhite: 52.0/255 alpha: 1.0];
  
  if (!_avPlaceholder)
  {
    [_toolBar removeFromSuperview];
    [_toolBar release];
    _toolBar = [[ChangeSelectionHelper 
               addToolbarToView: self.view
               withTitle: _roomList.currentRoom.displayName target: self selector: @selector(selectLocation:)
               title: nil target: nil selector: nil] retain];
    _toolBar.barStyle = UIBarStyleBlackOpaque;
  }
  
  UILabel *tbdLabel = [UILabel new];
  CGRect mainViewBounds = self.view.bounds;
  CGFloat topHeight = _toolBar.bounds.size.height;
  
  // Fit the label in the remaining space
  [tbdLabel setFrame:
   CGRectMake( CGRectGetMinX( mainViewBounds ),
              CGRectGetMinY( mainViewBounds ) + topHeight,
              CGRectGetWidth( mainViewBounds ), 
              CGRectGetHeight( mainViewBounds ) - (topHeight * 2) )];
  tbdLabel.text = NSLocalizedString( @"This service is not yet supported",
                                    @"Message to show for a service or source type that is not supported on the iPhone" );
  tbdLabel.textAlignment = UITextAlignmentCenter;
  tbdLabel.textColor = [UIColor whiteColor];
  tbdLabel.backgroundColor = [UIColor colorWithWhite: 52.0/255 alpha: 1.0];
  tbdLabel.font = [UIFont systemFontOfSize: 20];
  tbdLabel.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  [self.view addSubview: tbdLabel];
  [tbdLabel release];
}

- (void) viewWillAppear: (BOOL) animated
{
  MainNavigationController *mainController = (MainNavigationController *) self.navigationController;
  
  [super viewWillAppear: animated];
  
  mainController.navigationBar.barStyle = UIBarStyleBlackOpaque;
  mainController.navigationBar.tintColor = nil;
  [mainController setAudioControlsStyle: UIBarStyleBlackOpaque];
  [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque animated: YES];
}

- (void) viewDidAppear: (BOOL) animated
{
  if (!_avPlaceholder)
  {
    if (_roomList.currentRoom.sources == nil)
      _source = [NLSource noSourceObject];
    else
      _source = _roomList.currentRoom.sources.currentSource;
  }
  
  [super viewDidAppear: animated];
  
  if (_location != nil && _source != nil)
    [(MainNavigationController *) self.navigationController showAudioControls: YES];
}

- (void) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags
{
  if (_avPlaceholder)
    [super renderer: renderer stateChanged: flags];
}

- (void) selectLocation: (id) button
{
  if (_avPlaceholder)
    [super selectLocation: button];
  else
    [ChangeSelectionHelper showDialogOver: [self navigationController] withListData: _roomList];
}

- (void) currentItemForListData: (id<ListDataSource>) listDataSource
                    changedFrom: (id) old to: (id) new at: (NSUInteger) index
{
  if (_avPlaceholder)
    [super currentItemForListData: listDataSource changedFrom: old to: new at: index];
}

@end
