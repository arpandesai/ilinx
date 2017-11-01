//
//  IROnlyViewControllerIPad.m
//  iLinX
//
//  Created by mcf on 24/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//


#import "IROnlyViewControllerIPad.h"
#import "AudioViewControllerIPad.h"
#import "MainNavigationController.h"
#import "NLBrowseList.h"
#import "NLSourceIROnly.h"
#import "StandardPalette.h"
#import "DeprecationHelper.h"

static NSDictionary *VIEW_DATA = nil;


@implementation IROnlyViewControllerIPad

@synthesize
tableView  = _tableView;

- initWithPresets: (NLBrowseList *) presets
{
 if (self = [super initWithNibName: nil bundle: nil])
    _presets = [presets retain];
  
  return self;
}

- (id) initWithOwner: (AudioViewControllerIPad *) owner service: (NLService *) service source: (NLSource *) source
{
  if (VIEW_DATA == nil)
  {
    VIEW_DATA = [[NSDictionary dictionaryWithObjectsAndKeys:
		   @"CDIPad", @"TRNSPRT",
		   @"DVDIPad", @"DVD",
		   @"DVRIPad", @"PVR",
		  nil] 
		 retain];
  }    
  
  NSString *viewName = [VIEW_DATA objectForKey: ((NLSourceIROnly *) source).sourceControlType];

  if (self = [super initWithOwner: owner service: service source: source nibName: viewName bundle: nil])
  {
    _irOnlySource = (NLSourceIROnly *) [source retain]; 
  }

  return self;
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  
  NSString *redText = _irOnlySource.redText;
  NSString *yellowText = _irOnlySource.yellowText;
  NSString *blueText = _irOnlySource.blueText;
  NSString *greenText = _irOnlySource.greenText;
  
  if (_redButton != nil && redText != nil)
  {
    _redButton.text = redText;
  }
  
  if (_yellowButton != nil && yellowText != nil)
  {
    _yellowButton.text = yellowText; 
  }
  
  if (_blueButton != nil && blueText != nil)
  {
    _blueButton.text = blueText; 
  }
  
  if (_greenButton != nil && greenText != nil)
  {
    _greenButton.text = greenText; 
  }
  
  _sourceTitle.text = _source.displayName;
}

 - (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  
  [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque animated: YES];
  [_irOnlySource addDelegate: self];
  [self irOnlySource: _irOnlySource changed: 0xFFFFFFFF];
  [_presets addDelegate: self];
  [_tableView reloadData];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_irOnlySource removeDelegate: self];
  [_presets removeDelegate: self];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  [super viewWillDisappear: animated];
}

- (void) irOnlySource: (NLSourceIROnly *) irOnlySource changed: (NSUInteger) changed
{
  if ((changed & SOURCE_IRONLY_PRESETS_CHANGED) != 0)
  {
    NLBrowseList *presets = irOnlySource.presets;
    
    if (presets != nil)
    {
      [_presets release];
      _presets = [presets retain];
      [_tableView reloadData];
    }
  }
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
  return [_presets countOfSections];
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  NSUInteger rows = [_presets countOfListInSection: section];
  return rows;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"MyIdentifier"];
  UIView *backgroundView;
  UILabel *text;
  if (cell == nil)
  {
    cell = [[[UITableViewCell alloc] initDefaultWithFrame: CGRectMake( 0, 0, self.tableView.bounds.size.width, self.tableView.rowHeight )
					  reuseIdentifier: @"MyIdentifier"] autorelease];
    
    backgroundView = [[UIView alloc] initWithFrame: cell.bounds];
    [cell.contentView addSubview: backgroundView];
    [backgroundView release];
    
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
    text = [[UILabel alloc] initWithFrame: CGRectInset( cell.bounds, 10, 0 )];
    text.backgroundColor = [UIColor clearColor];
    text.font = [UIFont boldSystemFontOfSize: [UIFont buttonFontSize]];
     [cell.contentView addSubview: text];
    [text release];
  }
  else
  {
    NSArray *subviews = [cell.contentView subviews];
    
    backgroundView = [subviews objectAtIndex: 0];
    text = [subviews objectAtIndex: 1];
  }
  
  NSString *title = [_presets titleForItemAtOffset: indexPath.row inSection: indexPath.section];
  
  if (indexPath.row % 2 == 1)
    backgroundView.backgroundColor = [UIColor colorWithWhite: 0.3 alpha: 0.2];
  else
    backgroundView.backgroundColor = [UIColor colorWithWhite: 0.5 alpha: 0.2];
  
  text.text = title;
  
  if (title != nil)
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
  else
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
  [UIApplication sharedApplication].networkActivityIndicatorVisible = [_presets dataPending];
  
  return cell;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  [_presets selectItemAtOffset: indexPath.row inSection: indexPath.section];
  [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

- (NSIndexPath *) tableView: (UITableView *) tableView willSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  if ([_presets itemIsSelectableAtOffset: indexPath.row inSection: indexPath.section])
    return indexPath;
  else
    return nil;
}

- (void) itemsChangedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = [_presets dataPending];
  
  NSArray *indexPaths = [_tableView indexPathsForVisibleRows];
  NSIndexPath *index = nil;
  
  if ([indexPaths count] > 0 && !_tableView.dragging && !_tableView.decelerating)
  {
    index = [indexPaths objectAtIndex: 0];
    
    NSUInteger count = [_presets countOfListInSection: index.section];
    
    if (count == 0)
      index = nil;
    else if (count <= index.row)
      index = [NSIndexPath indexPathForRow: count - 1 inSection: index.section];
    else
      index = [NSIndexPath indexPathForRow: index.row inSection: index.section];
  }
  
  [_tableView reloadData];
  if (index != nil)
    [_tableView scrollToRowAtIndexPath: index atScrollPosition: UITableViewScrollPositionTop animated: NO];
}

- (void) didReceiveMemoryWarning
{
  // Releases the view if it doesn't have a superview
  [super didReceiveMemoryWarning];
  
  // Release anything that's not essential, such as cached data
  [_presets didReceiveMemoryWarning];
}

- (IBAction) pressedButton: (UIButton *) button
{
  [_irOnlySource sendKey: button.tag];
}

- (IBAction) releasedButton: (UIButton *) button
{
}

- (void) dealloc
{
  [_redButton release];
  [_yellowButton release];
  [_blueButton release];
  [_greenButton release];
  [_sourceTitle release];
  _tableView.delegate = nil;
  _tableView.dataSource = nil;
  [_tableView release];
  [_presets release];
  [super dealloc];
}
@end
