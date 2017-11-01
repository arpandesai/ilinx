//
//  HVACViewController.m
//  iLinX
//
//  Created by mcf on 13/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "HVACViewController.h"
#import "HVACButtonsViewController.h"
#import "HVACDisplayViewController.h"
#import "MainNavigationController.h"

@interface HVACViewController ()

- (void) segmentChanged: (UISegmentedControl *) control;
- (void) configureSegments;

@end

@implementation HVACViewController

- initWithRoomList: (NLRoomList *) roomList service: (NLService *) service
{
  if (self = [super initWithRoomList: roomList service: service])
  {
    // Convenience cast here
    _hvacService = (NLServiceHVAC *) service;
  }
  
  return self;
}


- (void) loadView
{
  [super loadView];
  
  CGRect contentBounds = self.view.bounds;
  CGFloat toolBarHeight = _toolBar.frame.size.height;
  
  UIViewController *displayViewController = [[HVACDisplayViewController alloc]
                                             initWithHvacService: _hvacService parentController: self];

  displayViewController.view.frame = CGRectOffset( displayViewController.view.frame, 0, toolBarHeight - 1 );
  [self.view insertSubview: displayViewController.view belowSubview: _toolBar];
    
  _subViews = [[NSArray arrayWithObjects: displayViewController, nil] retain];
  [displayViewController release];

  _segmentedSelector = [[UISegmentedControl alloc] initWithItems: 
                        [NSArray arrayWithObjects: NSLocalizedString( @"Display", @"Title of display segment of HVAC view" ), nil]];
  _segmentedSelector.segmentedControlStyle = UISegmentedControlStyleBar;
  _segmentedSelector.tintColor = [UIColor colorWithWhite: 0.25 alpha: 1.0];
  _segmentedSelector.selectedSegmentIndex = 0;
  _currentSegment = 0;
  [_segmentedSelector sizeToFit];
  _segmentedSelector.frame = CGRectMake( 0, 0, contentBounds.size.width - 20, _segmentedSelector.frame.size.height );
  [_segmentedSelector addTarget: self action: @selector(segmentChanged:) forControlEvents: UIControlEventValueChanged];

  _controlBar = [[UIToolbar alloc] initWithFrame: CGRectMake( 0, CGRectGetMaxY( contentBounds ) - (toolBarHeight * 3),
                                                             CGRectGetWidth( contentBounds ), toolBarHeight)];
  _controlBar.items = [NSArray arrayWithObjects: 
                         [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target: nil action: nil] autorelease],
                         [[[UIBarButtonItem alloc] initWithCustomView: _segmentedSelector] autorelease],
                         [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target: nil action: nil] autorelease],
                         nil];
  _controlBar.barStyle = UIBarStyleBlackOpaque;
  [self.view addSubview: _controlBar];
}

- (void) viewWillAppear: (BOOL) animated
{
  MainNavigationController *mainController = (MainNavigationController *) self.navigationController;

  [super viewWillAppear: animated];
  
  mainController.navigationBar.barStyle = UIBarStyleBlackOpaque;
  mainController.navigationBar.tintColor = nil;
  [mainController setAudioControlsStyle: UIBarStyleBlackOpaque];
  [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque animated: YES];
  [[_subViews objectAtIndex: _currentSegment] viewWillAppear: animated];
  _onScreen = YES;
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  
  if (_location != nil)
  {
    [self service: _hvacService changed: 0xFFFFFFFF];
    [_hvacService addDelegate: self];

    [(MainNavigationController *) self.navigationController showAudioControls: YES];
    [[_subViews objectAtIndex: _currentSegment] viewDidAppear: animated];
  }
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_hvacService removeDelegate: self];
  _onScreen = NO;
  [[_subViews objectAtIndex: _currentSegment] viewWillDisappear: animated];
  [super viewWillDisappear: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
  [[_subViews objectAtIndex: _currentSegment] viewDidDisappear: animated];
  [super viewDidDisappear: animated];
}

- (void) service: (NLServiceHVAC *) service changed: (NSUInteger) changed
{
  if ((changed & SERVICE_HVAC_MODES_CHANGED) != 0)
    [self configureSegments];
}

- (void) segmentChanged: (UISegmentedControl *) control
{
  UIViewController *disappearing = [_subViews objectAtIndex: _currentSegment];
  UIViewController *appearing = [_subViews objectAtIndex: control.selectedSegmentIndex];
  
  [disappearing viewWillDisappear: NO];
  [appearing viewWillAppear: NO];
  disappearing.view.hidden = YES;
  appearing.view.hidden = NO;
  [disappearing viewDidDisappear: NO];
  [appearing viewDidAppear: NO];
  _currentSegment = control.selectedSegmentIndex;
}

- (void) configureSegments
{
  NSUInteger segmentCount = [_hvacService.controlModes count] + 1;
  NSMutableArray *subViews = [NSMutableArray arrayWithCapacity: segmentCount];
  UIViewController *displayViewController = [_subViews objectAtIndex: 0];
  NSUInteger i;
  
  [subViews addObject: displayViewController];
  
  if (_currentSegment != 0 && _onScreen)
  {
    _segmentedSelector.selectedSegmentIndex = 0;
    [self segmentChanged: _segmentedSelector];
  }
  for (i = _segmentedSelector.numberOfSegments - 1; i > 0; --i)
    [_segmentedSelector removeSegmentAtIndex: i animated: YES];

  for (i = 0; i < segmentCount - 1; ++i)
  {
    UIViewController *modeController = [[HVACButtonsViewController alloc] initWithHvacService: _hvacService controlMode: i];
    
    modeController.view.frame = displayViewController.view.frame;
    [subViews addObject: modeController];
    modeController.view.hidden = YES;
    [self.view insertSubview: modeController.view belowSubview: _controlBar];
    [_segmentedSelector insertSegmentWithTitle: [_hvacService.controlModes objectAtIndex: i]
                                       atIndex: i + 1 animated: YES];
    [modeController release];
  }
  
  for (i = 1; i < [_subViews count]; ++i)
    [((UIViewController *) [_subViews objectAtIndex: i]).view removeFromSuperview];
  [_subViews release];
  _subViews = [subViews retain];
}

- (void) dealloc
{
  [_hvacService removeDelegate: self];
  [_subViews release];
  [_segmentedSelector release];
  [_controlBar release];
  [super dealloc];
}

@end
