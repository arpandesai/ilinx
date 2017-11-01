//
//  DetailViewController.m
//  NetStreams
//
//  Created by mcf on 31/12/2008.
//  Copyright 2008 Micropraxis Ltd. All rights reserved.
//

#import "DetailViewController.h"
#import "ChangeSelectionHelper.h"
#import "MainNavigationController.h"
#import "NLRoomList.h"
#import "NLRoom.h"
#import "NLService.h"

@interface DetailViewController ()

@property (nonatomic, retain) NSArray *keys;
@property (nonatomic, retain) NSArray *values;
@end

@implementation DetailViewController

@synthesize 
  keys = _keys,
  values = _values;

- (void) loadView
{
  // setup our parent content view and embed it to your view controller
  UIView *contentView = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
  
  contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];
  contentView.autoresizesSubviews = YES;
  contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  self.view = contentView;
  
  UIToolbar *toolBar = [ChangeSelectionHelper
                        addToolbarToView: self.view
                        withTitle: _roomList.currentRoom.name target: self selector: @selector(selectLocation:)
                        title:  nil target: self selector: nil];
  
  CGRect mainViewBounds = self.view.bounds;
  CGFloat topHeight = toolBar.bounds.size.height;
  
  // Fit the label in the remaining space
  _tableView = [[UITableView alloc]
                initWithFrame: CGRectMake( CGRectGetMinX( mainViewBounds ),
                                          CGRectGetMinY( mainViewBounds ) + topHeight,
                                          CGRectGetWidth( mainViewBounds ), 
                                          CGRectGetHeight( mainViewBounds ) - topHeight )
                style: UITableViewStyleGrouped];
  _tableView.delegate = self;
  _tableView.dataSource = self;
  [self.view addSubview: _tableView];
}

- (void) viewWillAppear: (BOOL) animated
{
  MainNavigationController *mainController = (MainNavigationController *) self.navigationController;
  
  // Update the view with current data before it is displayed
  [super viewWillAppear: animated];
  [mainController setAudioControlsStyle: UIBarStyleDefault];
  mainController.navigationBar.barStyle = UIBarStyleDefault;
  [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault animated: YES];
    
  // Scroll the table view to the top before it appears
  [_tableView reloadData];
  [_tableView setContentOffset: CGPointZero animated: NO];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  
  if (_location != nil)
    [(MainNavigationController *) self.navigationController showAudioControls: YES];
}

- (void) cacheData
{
  if (_values == nil)
  {
    // Cache the detail item data for later display
    self.keys = [_service.serviceData allKeys];
    self.values = [_service.serviceData allValues];
  }
}

// Standard table view data source and delegate methods

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
  [self cacheData];
  return [_values count];
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  return 1;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  static NSString *CellIdentifier = @"tvc";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  if (cell == nil)
  {
    cell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: CellIdentifier] autorelease];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  
  [self cacheData];
  
  NSObject *item = [_values objectAtIndex: indexPath.section];
  
  if ([item isMemberOfClass: [NSString class]])
    cell.text = (NSString *) item;
  else
    cell.text = [item description];

  return cell;
}

- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section
{
  [self cacheData];
  return [_keys objectAtIndex: section];
}

- (void) didReceiveMemoryWarning
{
  [_keys release];
  [_values release];
  _keys = nil;
  _values = nil;
  [super didReceiveMemoryWarning];
}

- (void) dealloc
{
  [super dealloc];
  [_tableView release];
  [_keys release];
  [_values release];
}

@end
