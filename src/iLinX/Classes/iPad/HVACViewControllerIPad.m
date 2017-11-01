//
//  HVACViewControllerIPad.h
//  iLinX
//
//  Created by Tony Short on 15/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <QuartzCore/CALayer.h>
#import "HVACViewControllerIPad.h"

@interface HVACViewControllerIPad ()

- (void) segmentChanged: (UISegmentedControl *) control;
- (void) configureSegments;

@end

@implementation HVACViewControllerIPad

- (id) initWithOwner: (RootViewControllerIPad *) owner service: (NLService *) service
{
  if (self = [super initWithOwner: owner service: service
                         nibName: @"HVACViewIPad" bundle: nil])
    _hvacService = [(NLServiceHVAC *) service retain];
  
  return self;
}

- (void) dealloc
{
  [_hvacService release];
  [_segmentedSelector release];
  [_displayViewController release];
  [_controlView release];
  [_controlViewLabel release];
  [_controlButtonPanelView release];
  [super dealloc];
}

- (void) setViewBorder: (UIView *) suppliedView
{
  suppliedView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
  suppliedView.layer.borderWidth = 1.0;
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  
  [_displayViewController setViewBorders];
  [self setViewBorder: _controlView];
  
  [_segmentedSelector removeAllSegments];
  
  _displayViewController.hvacService = _hvacService;
  _controlButtonPanelView.hvacService = _hvacService;
}

- (void) viewDidUnload
{
  _displayViewController.hvacService = nil;
  _controlButtonPanelView.hvacService = nil;
  
  [super viewDidUnload];
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  
  [self service: _hvacService changed: 0xFFFFFFFF];
  [_hvacService addDelegate: self];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_hvacService removeDelegate: self];

  [super viewWillDisappear: animated];
}

- (void) service: (NLServiceHVAC *) service changed: (NSUInteger) changed
{
  if (((changed & SERVICE_HVAC_MODES_CHANGED) != 0) || (changed & SERVICE_HVAC_MODE_TITLES_CHANGED) != 0)
    [self configureSegments];
  
  if ((changed & SERVICE_HVAC_MODE_STATES_CHANGED) != 0)
    [_controlButtonPanelView updateButtonStates];
  
  [_displayViewController service: service changed: changed];
}

- (void) segmentChanged: (UISegmentedControl *) control
{
  _controlViewLabel.text = [_hvacService.controlModes objectAtIndex:_segmentedSelector.selectedSegmentIndex];
  
  [_controlButtonPanelView updateWithControlModeID:_segmentedSelector.selectedSegmentIndex];
}

- (void) configureSegments
{
  NSUInteger segmentCount = [_hvacService.controlModes count];
  
  [_segmentedSelector removeAllSegments];
  for (int i = 0; i < segmentCount; ++i)
  {
    [_segmentedSelector insertSegmentWithTitle: [_hvacService.controlModes objectAtIndex: i]
                                       atIndex: i animated: NO];
  }
  
  if (_segmentedSelector.selectedSegmentIndex == -1)
    _segmentedSelector.selectedSegmentIndex = 0;
  
  _controlViewLabel.text = [_hvacService.controlModes objectAtIndex: _segmentedSelector.selectedSegmentIndex];
  
  [_controlButtonPanelView updateWithControlModeID: _segmentedSelector.selectedSegmentIndex];
}

@end
