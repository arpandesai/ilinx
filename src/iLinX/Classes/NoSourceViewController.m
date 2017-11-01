//
//  NoSourceViewController.m
//  iLinX
//
//  Created by mcf on 13/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NoSourceViewController.h"
#import "BorderedTableViewCell.h"
#import "ChangeSelectionHelper.h"
#import "CustomViewController.h"
#import "DeprecationHelper.h"
#import "MainNavigationController.h"
#import "NLRoomList.h"
#import "NLRoom.h"
#import "NLSource.h"
#import "NLSourceList.h"
#import "StandardPalette.h"
#import "TintedTableViewDelegate.h"

@interface NoSourceViewController ()

- (void) tableView: (UITableView *) tableView selectFeedbackAtIndexPath: (NSIndexPath *) indexPath;
- (void) forceSourceSelectTimeout: (NSTimer *) timer;
- (void) reloadData;

@end

@implementation NoSourceViewController

- initWithRoomList: (NLRoomList *) roomList service: (NLService *) service source: (NLSource *) source
{
  if ((self = [super initWithRoomList: roomList service: service source: source]) != nil)
  {
    _customPage = [[CustomViewController alloc] initWithController: self customPage: @"avoff.htm"];
    if (![_customPage isValid])
    {
      [_customPage release];
      _customPage = nil;
    }
  }

  return self;
}


- (void) loadView
{
  [super loadView];

  if ([[_customPage title] length] > 0)
    self.title = _customPage.title;
  else
    self.title = NSLocalizedString( @"A/V Off", @"Title of A/V screen when no source selected" );
  _sources = [_roomList.currentRoom.sources retain];

  if (_customPage != nil)
  {
    [_customPage loadViewWithFrame: self.view.bounds];
    [self.view addSubview: _customPage.view];
  }
  else
  {
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"BackdropLight.png"]];
    UITableView *tableView = [[UITableView alloc] initWithFrame: self.view.bounds style: UITableViewStylePlain];
    _tableView = [tableView retain];
    
    imageView.backgroundColor = [StandardPalette backdropTint];
    [self.view addSubview: imageView];
    
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.frame = CGRectMake( tableView.frame.origin.x, tableView.frame.origin.y + _toolBar.frame.size.height - 1,
                                 tableView.frame.size.width, tableView.frame.size.height - ((_toolBar.frame.size.height * 3) - 1) );
    [self.view addSubview: tableView];
    [tableView release];
    
    
    _tintHandler = [[TintedTableViewDelegate alloc] init];
    _tintHandler.tableView = tableView;
    
    imageView.frame = tableView.frame;
    [imageView release];
  }
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  [_tintHandler viewDidLoad];

  if (_customPage == nil)
    _tableView.backgroundColor = [StandardPalette tableCellColour];
  else
  {
    _tableView.hidden = YES;
    [_customPage loadViewWithFrame: self.view.bounds];
    self.view = _customPage.view;
  }
}

- (void) addToolbar
{
  _toolBar = [[ChangeSelectionHelper
               addToolbarToView: self.view
               withTitle: _roomList.currentRoom.displayName target: self selector: @selector(selectLocation:)
               title:  NSLocalizedString( @"Source", @"Title of select source button" ) target: self
               selector: @selector(selectSource:)] retain];
  
  [StandardPalette setTintForToolbar: _toolBar];
}

- (void) viewWillAppear: (BOOL) animated
{
  MainNavigationController *mainController = (MainNavigationController *) self.navigationController;

  [_sources addDelegate: self];
  [self reloadData];
    
  [super viewWillAppear: animated];
  [_tintHandler viewWillAppear: animated];
  [StandardPalette setTintForNavigationBar: mainController.navigationBar];
  [mainController setAudioControlsStyle: UIBarStyleDefault];
  [_customPage viewWillAppear: animated];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];

  if (_location != nil && _service != nil)
  {
    [(MainNavigationController *) self.navigationController 
     showAudioControls: (_customPage == nil || !_customPage.hidesAudioControls)];
    self.navigationController.navigationBarHidden = [_customPage hidesNavigationBar];
  }
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_customPage viewWillDisappear: animated];
  [_sources removeDelegate: self];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

  [super viewWillDisappear: animated];
  [_forceSourceSelectTimer invalidate];
  _forceSourceSelectTimer = nil;
}

- (void) viewDidDisappear: (BOOL) animated
{
  [_tintHandler viewDidDisappear: animated];
  [super viewDidDisappear: animated];
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
  return 1;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  return [_sources countOfListInSection: section];
}

- (void) listDataRefreshDidEnd: (id<ListDataSource>) listDataSource
{
  [self reloadData];
}

- (void) itemsInsertedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [self reloadData];
}

- (void) itemsChangedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [self reloadData];
}

- (void) itemsRemovedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [self reloadData];
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  BorderedTableViewCell *cell = (BorderedTableViewCell *) [tableView dequeueReusableCellWithIdentifier: @"MyIdentifier"];
  
  if (cell == nil)
    cell = [[[BorderedTableViewCell alloc] initDefaultWithFrame: CGRectZero reuseIdentifier: @"MyIdentifier"
                                                          table: tableView] autorelease];

  if (indexPath.row == 0)
  {
    cell.accessoryType = UITableViewCellAccessoryNone;
    [cell setLabelTextColor: [StandardPalette highlightedTableTextColour]];
    [cell setLabelText: NSLocalizedString( @"Select a source...", @"Instructions on what to do on the No Source view" )];
  }
  else
  {
    if ([_sources itemIsSelectedAtOffset: indexPath.row inSection: indexPath.section])
    {
      _selectedIndex = [indexPath retain];
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
      cell.accessoryType = UITableViewCellAccessoryNone;
  
    if ([_sources itemIsSelectableAtOffset: indexPath.row inSection: indexPath.section])
      [cell setLabelTextColor: [StandardPalette tableTextColour]];
    else
      [cell setLabelTextColor: [StandardPalette disabledTableTextColour]];
  
    // Get the object to display and set the value in the cell
    [cell setLabelText: [_sources titleForItemAtOffset: indexPath.row inSection: indexPath.section]];
  }

  return cell;
}

- (NSIndexPath *) tableView: (UITableView *) tableView willSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  if (indexPath.row == 0)
    return nil;
  else if ([_sources refreshIsComplete] && [_sources itemIsSelectableAtOffset: indexPath.row inSection: indexPath.section])
    return indexPath;
  else
    return nil;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  [tableView deselectRowAtIndexPath: indexPath animated: YES];
  [_sources selectItemAtOffset: indexPath.row inSection: indexPath.section];
  [self tableView: tableView selectFeedbackAtIndexPath: indexPath];
}

- (void) tableView: (UITableView *) tableView selectFeedbackAtIndexPath: (NSIndexPath *) indexPath
{
  if (_selectedIndex != nil)
    [tableView cellForRowAtIndexPath: _selectedIndex].accessoryType = UITableViewCellAccessoryNone;
  [tableView cellForRowAtIndexPath: indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
  [_selectedIndex release];
  _selectedIndex = [indexPath retain];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void) forceSourceSelectTimeout: (NSTimer *) timer
{
  [self selectSource: nil];
}

- (void) reloadData
{
  if (_customPage == nil)
    [_tableView reloadData];
  else
    [_customPage reloadData];
}

- (void) dealloc
{
  [_forceSourceSelectTimer invalidate];
  _forceSourceSelectTimer = nil;
  [_sources release];
  [_selectedIndex release];
  [_tintHandler release];
  [_tableView release];
  [_customPage release];
  [super dealloc];
}

@end
