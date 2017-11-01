//
//  SecurityViewController.m
//  iLinX
//
//  Created by mcf on 18/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "SecurityViewController.h"
#import "SecurityButtonsViewController.h"
#import "SecurityKeypadViewController.h"
#import "SecurityListViewController.h"
#import "MainNavigationController.h"

@interface SecurityViewController ()

- (void) segmentChanged: (UISegmentedControl *) control;
- (void) configureSegments;

@end

@implementation SecurityViewController

- initWithRoomList: (NLRoomList *) roomList service: (NLService *) service
{
  if (self = [super initWithRoomList: roomList service: service])
  {
    // Convenience cast here
    _securityService = (NLServiceSecurity *) service;
  }
  
  return self;
}


- (void) loadView
{
  [super loadView];
  
  CGRect contentBounds = self.view.bounds;
  CGFloat toolBarHeight = _toolBar.frame.size.height;
  UIViewController *keypadViewController = [[SecurityKeypadViewController alloc]
                                             initWithSecurityService: _securityService parentController: self];
  
  keypadViewController.view.frame = CGRectOffset( keypadViewController.view.frame, 0, toolBarHeight - 1 );
  [self.view insertSubview: keypadViewController.view belowSubview: _toolBar];
  
  _subViews = [[NSArray arrayWithObjects: keypadViewController, nil] retain];
  [keypadViewController release];
  
  if ((_securityService.capabilities & SERVICE_SECURITY_HAS_CUSTOM_MODES) == 0)
    keypadViewController.view.frame = CGRectOffset( keypadViewController.view.frame, 0, toolBarHeight / 2 );
  else
  {
    _segmentedSelector = [[UISegmentedControl alloc] initWithItems: 
                          [NSArray arrayWithObjects: NSLocalizedString( @"Keypad", @"Title of keypad segment of Security view" ), nil]];
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
    [_securityService addDelegate: self];
    [self service: _securityService changed: 0xFFFFFFFF];
    [(MainNavigationController *) self.navigationController showAudioControls: YES];
    [[_subViews objectAtIndex: _currentSegment] viewDidAppear: animated];
  }
}

- (void) viewWillDisappear: (BOOL) animated
{
  _onScreen = NO;
  [_securityService removeDelegate: self];
  [[_subViews objectAtIndex: _currentSegment] viewWillDisappear: animated];
  [super viewWillDisappear: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
  [[_subViews objectAtIndex: _currentSegment] viewDidDisappear: animated];
  [super viewDidDisappear: animated];
}

- (void) service: (NLServiceSecurity *) service changed: (NSUInteger) changed
{
  if ((changed & SERVICE_SECURITY_ERROR_MESSAGE_CHANGED) != 0)
  {
    NSString *message = service.errorMessage;
    
    if (message != nil && [message length] > 0)
    {
      UIAlertView *alert = [[UIAlertView alloc] 
                            initWithTitle: NSLocalizedString( @"Security System Warning", @"Title for the security warning dialog" )
                            message: NSLocalizedString( service.errorMessage,
                                                       @"Localised version of the error message" ) 
                            delegate: nil
                            cancelButtonTitle: NSLocalizedString( @"OK", @"Title of button dismissing the security warning dialog" )
                            otherButtonTitles: nil];
    
      [alert show];
      [alert release];
    }
  }
  if ((changed & SERVICE_SECURITY_MODES_CHANGED) != 0)
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
  NSUInteger segmentCount = [_securityService.controlModes count] + 1;
  NSMutableArray *subViews = [NSMutableArray arrayWithCapacity: segmentCount];
  UIViewController *keypadViewController = [_subViews objectAtIndex: 0];
  CGRect subViewFrame = keypadViewController.view.frame;
  NSUInteger i;
  
  [subViews addObject: keypadViewController];
  subViewFrame = CGRectMake( subViewFrame.origin.x, subViewFrame.origin.y, 
                            subViewFrame.size.width, subViewFrame.size.height - _toolBar.frame.size.height );
  
  if (_currentSegment != 0 && _onScreen)
  {
    _segmentedSelector.selectedSegmentIndex = 0;
    [self segmentChanged: _segmentedSelector];
  }
  for (i = _segmentedSelector.numberOfSegments - 1; i > 0; --i)
    [_segmentedSelector removeSegmentAtIndex: i animated: YES];
 
  for (i = 0; i < segmentCount - 1; ++i)
  {
    UIViewController *modeController;

    if ([_securityService styleForControlMode: i] == SERVICE_SECURITY_MODE_TYPE_LIST)
      modeController = [[SecurityListViewController alloc] initWithSecurityService: _securityService controlMode: i];
    else
      modeController = [[SecurityButtonsViewController alloc] initWithSecurityService: _securityService controlMode: i];

    modeController.view.frame = subViewFrame;
    modeController.view.hidden = YES;
    [self.view insertSubview: modeController.view belowSubview: _toolBar];
    [subViews addObject: modeController];
    [_segmentedSelector insertSegmentWithTitle: [_securityService.controlModes objectAtIndex: i]
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
  [_securityService removeDelegate: self];
  [_subViews release];
  [_segmentedSelector release];
  [_controlBar release];
  [super dealloc];
}

@end
