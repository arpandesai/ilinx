//
//  TintedTableViewController.m
//  iLinX
//
//  Created by mcf on 07/05/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "TintedTableViewController.h"
#import "TintedTableViewDelegate.h"

@implementation TintedTableViewController

#if DOES_NOT_INHERIT_FROM_UITABLEVIEWCONTROLLER
@synthesize
  style = _tableStyle,
  tableView = _tableView;
#endif

- (UIColor *) backdropTint
{
  return _tintHandler.backdropTint;
}

- (void) setBackdropTint: (UIColor *) backdropTint
{
  _tintHandler.backdropTint = backdropTint;
}

- (UIColor *) headerTextColour
{
  return _tintHandler.headerTextColour;
}

- (void) setHeaderTextColour: (UIColor *) headerTextColour
{
  _tintHandler.headerTextColour = headerTextColour;
}

- (UIColor *) headerShadowColour
{
  return _tintHandler.headerShadowColour;
}

- (void) setHeaderShadowColour: (UIColor *) headerShadowColour
{
  _tintHandler.headerShadowColour = headerShadowColour;
}

- (UIColor *) headerTint
{
  return _tintHandler.headerTint;
}

- (void) setHeaderTint: (UIColor *) headerTint
{
  _tintHandler.headerTint = headerTint;
}

#if DOES_NOT_INHERIT_FROM_UITABLEVIEWCONTROLLER
- (id) initWithStyle: (UITableViewStyle) style
{
  if (self = [super initWithNibName: nil bundle: nil])
  {
    _tableStyle = style;
    _tintHandler = [[TintedTableViewDelegate alloc] init];
  }

  return self;
}
#else
- (id) initWithStyle: (UITableViewStyle) style
{
  if (self = [super initWithStyle: style])
    _tintHandler = [[TintedTableViewDelegate alloc] init];
  
  return self;
}
#endif

- (void) refreshPalette
{
  ++_paletteVersion;
  _tintHandler.tableView = self.tableView;
  [_tintHandler viewDidLoad];
  [_tintHandler viewWillAppear: YES];
  [self.tableView reloadData];
}

#if DOES_NOT_INHERIT_FROM_UITABLEVIEWCONTROLLER
- (void) loadView
{
  [super loadView];
  
  CGRect bounds = self.view.bounds;
  
  if ([[self navigationController] navigationBar] != nil &&
      !self.navigationController.navigationBar.hidden)
    bounds.size.height -= self.navigationController.navigationBar.frame.size.height;
  _tableView = [[UITableView alloc] initWithFrame: bounds style: _tableStyle];
  _tableView.delegate = self;
  _tableView.dataSource = self;
  [self.view addSubview: _tableView];
}
#endif

- (void) viewDidLoad
{
  [super viewDidLoad];
  
  _tintHandler.tableView = self.tableView;
  [_tintHandler viewDidLoad];
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];  
  [_tintHandler viewWillAppear: animated];
}

- (void) viewDidAppear: (BOOL) animated
{  
  [super viewDidAppear: animated];
   self.navigationController.navigationBarHidden = NO;
}

- (void) viewDidDisappear: (BOOL) animated
{
  [_tintHandler viewDidDisappear: animated];

  [super viewDidDisappear: animated];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
#if defined(IPAD_BUILD)
  // Overriden to allow any orientation.
  return YES;
#else
  return UIInterfaceOrientationIsPortrait(interfaceOrientation);
#endif
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  return 0;
}

- (UIView *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  return nil;
}

- (UIView *) tableView: (UITableView *) tableView viewForHeaderInSection: (NSInteger) section
{
  return [_tintHandler tableView: tableView viewForHeaderInSection: section];
}

- (UIView *) tableView: (UITableView *) tableView viewForFooterInSection: (NSInteger) section
{
  return [_tintHandler tableView: tableView viewForFooterInSection: section];
}

- (CGFloat) tableView: (UITableView *) tableView heightForHeaderInSection: (NSInteger) section
{
  //if ([self methodForSelector: _cmd] == [TintedTableViewController instanceMethodForSelector: _cmd])
  //  return 0;
  //else
    return [_tintHandler tableView: tableView heightForHeaderInSection: section];
}

- (CGFloat) tableView: (UITableView *) tableView heightForFooterInSection: (NSInteger) section
{
  //if ([self methodForSelector: _cmd] == [TintedTableViewController instanceMethodForSelector: _cmd])
  //  return 0;
  //else
    return [_tintHandler tableView: tableView heightForFooterInSection: section];
}

- (void) dealloc
{
#if DOES_NOT_INHERIT_FROM_UITABLEVIEWCONTROLLER
  [_tableView release];
#endif
  [_tintHandler release];
  [super dealloc];
}

@end

