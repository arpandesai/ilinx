//
//  AudioViewControllerIPad.m
//  iLinX
//
//  Created by mcf on 08/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//


#import "AudioViewControllerIPad.h"
#import "MediaViewControllerIPad.h"
#import "IROnlyViewControllerIPad.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLSource.h"
#import "NLSourceList.h"
#import "LocalSourceViewControllerIPad.h"
#import "NoSourceViewControllerIPad.h"
#import "PlaceholderAVViewControllerIPad.h"
#import "RootViewControllerIPad.h"
#import "SourceListViewController.h"
#import "TunerViewControllerIPad.h"

static NSDictionary *AV_VIEW_CLASSES = nil;

@implementation AudioViewControllerIPad

- (id) initWithOwner: (RootViewControllerIPad *) owner service: (NLService *) service
{
  if (self = [super initWithOwner: owner service: service])
  {
    if (AV_VIEW_CLASSES == nil)
    {
      AV_VIEW_CLASSES =
      [[NSDictionary dictionaryWithObjectsAndKeys:
        [NoSourceViewControllerIPad class], @"NOSOURCE",
        [LocalSourceViewControllerIPad class], @"LOCALSOURCE",
        [LocalSourceViewControllerIPad class], @"LOCALSOURCE-STREAM",
        [TunerViewControllerIPad class], @"TUNER",
        [MediaViewControllerIPad class], @"MEDIASERVER",
        [MediaViewControllerIPad class], @"VTUNER",
        [TunerViewControllerIPad class], @"XM TUNER",
        [TunerViewControllerIPad class], @"ZTUNER",
        [IROnlyViewControllerIPad class], @"TRNSPRT",
        [IROnlyViewControllerIPad class], @"DVD",
        [IROnlyViewControllerIPad class], @"PVR",
        nil] retain];
    }
  }
  
  return self;
}

- (BOOL) preparePopoverAnimated: (BOOL) animated
{
  BOOL showPopover = (_sourcesPopover == nil);
  
  if (!showPopover)
    [self dismissSourcesPopoverAnimated: animated];
  else
  {
    SourceListViewController *popoverViewController = 
    [[SourceListViewController alloc] initWithStyle: UITableViewStylePlain];
    
    popoverViewController.delegate = self;
    _sourcesPopover = [[UIPopoverController alloc] 
                       initWithContentViewController: popoverViewController];
    [popoverViewController release];
    _sourcesPopover.delegate = self;
    
    CGFloat maxHeight = [_owner.currentRoom.sources countOfList] * popoverViewController.tableView.rowHeight;
    
    if (maxHeight > self.view.bounds.size.height - 44)
      maxHeight = self.view.bounds.size.height - 44;
    
    _sourcesPopover.popoverContentSize = CGSizeMake( 256, maxHeight );
  }
  
  return showPopover;
}

- (void) presentSourcesPopoverFromButton: (id) popoverButton 
                permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections
                                animated: (BOOL) animated
{
  if ([self preparePopoverAnimated: animated])
  {
    if ([popoverButton isKindOfClass: [UIBarButtonItem class]])
      [_sourcesPopover presentPopoverFromBarButtonItem: popoverButton 
                              permittedArrowDirections: arrowDirections
                                              animated: animated];
    else
      [_sourcesPopover presentPopoverFromRect: [popoverButton frame] inView: _sourceViewController.view
                     permittedArrowDirections: arrowDirections
                                     animated: animated];
    
    _popoverControl = [popoverButton retain];
    _arrowDirections = arrowDirections;
  }
}

- (void) dismissSourcesPopoverAnimated: (BOOL) animated
{
  [_sourcesPopover dismissPopoverAnimated: animated];
  [self popoverControllerDidDismissPopover: _sourcesPopover];
}

- (void) popoverControllerDidDismissPopover: (UIPopoverController *) popoverController
{
  [_sourcesPopover release];
  _sourcesPopover = nil;
  [_popoverControl release];
  _popoverControl = nil;
}

- (void) dataSource: (DataSourceViewController *) dataSource userSelectedItem: (id) item
{
  [self dismissSourcesPopoverAnimated: YES];
}

- (void) currentItemForListData: (id<ListDataSource>) listDataSource
                    changedFrom: (id) old to: (id) new at: (NSUInteger) index
{
  if (new != [_sourceViewController source])
  {
    Class avViewClass = [AV_VIEW_CLASSES objectForKey: [new sourceControlType]];
    
    if (avViewClass == nil)
      avViewClass = [PlaceholderAVViewControllerIPad class];
    
    AudioSubViewControllerIPad *avViewController = 
    [(AudioSubViewControllerIPad *) [avViewClass alloc] initWithOwner: self service: _service source: new];
    UIView *newView = avViewController.view;
    
    //NSLog( @"AudioView: %@", self.view );
    newView.frame = self.view.bounds;
    [_sourceViewController viewWillDisappear: YES];
    [avViewController viewWillAppear: YES];
    [_sourceViewController.view removeFromSuperview];
    [self.view addSubview: newView];
    [_sourceViewController viewDidDisappear: YES];
    [avViewController viewDidAppear: YES];
    [_sourceViewController release];
    _sourceViewController = avViewController;
  }
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  self.view.autoresizesSubviews = YES;
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  [_sourceViewController viewWillAppear: animated];
}

- (void) viewDidAppear: (BOOL) animated
{
  [_sources removeDelegate: self];
  [_sources release];
  _sources = [_owner.roomList.currentRoom.sources retain];
  
  [super viewDidAppear: animated];
  [_sourceViewController viewDidAppear: animated];
  [_sources addDelegate: self];
  [self currentItemForListData: _sources changedFrom: nil 
                            to: [_sources listDataCurrentItem] at: 0];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_sourceViewController viewWillDisappear: animated];
  [_sources removeDelegate: self];
  [_sources release];
  _sources = nil;
  [super viewWillDisappear: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
  [_sourceViewController viewDidDisappear: animated];
  [super viewDidDisappear: animated];
}

- (void) willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation 
                                          duration: (NSTimeInterval) duration
{
  [_sourcesPopover dismissPopoverAnimated: YES];
  [_sourcesPopover release];
  _sourcesPopover = nil;
  [_sourceViewController willAnimateRotationToInterfaceOrientation: interfaceOrientation duration: duration];
}

- (void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation) fromInterfaceOrientation
{
  if (_popoverControl != nil)
  {
    [self presentSourcesPopoverFromButton: _popoverControl permittedArrowDirections: _arrowDirections animated: YES];
    [_popoverControl release];
  }
  
  [_sourceViewController didRotateFromInterfaceOrientation: fromInterfaceOrientation];
}

- (void) dealloc
{
  [_sources removeDelegate: self];
  [_sources release];
  [_sourceViewController release];
  [_sourcesPopover release];
  [_popoverControl release];
  [super dealloc];
}

@end
