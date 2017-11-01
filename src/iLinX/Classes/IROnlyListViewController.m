//
//  IROnlyListViewController.m
//  iLinX
//
//  Created by mcf on 01/04/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "IROnlyListViewController.h"
#import "DeprecationHelper.h"

@implementation IROnlyListViewController

@synthesize tableView = _tableView;

- initWithPresets: (NLBrowseList *) presets
{
  if (self = [super initWithNibName: nil bundle: nil])
    _presets = [presets retain];
  
  return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void) loadView
{
  CGRect frame = [[UIScreen mainScreen] applicationFrame]; 
  UIView *contentView = [[UIView alloc] initWithFrame: frame];
  UIImageView *imageView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"BackdropDark.png"]];
  
  _tableView = [[UITableView alloc] initWithFrame: contentView.bounds style: UITableViewStylePlain];
  
  contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  contentView.autoresizesSubviews = YES;
  [imageView sizeToFit];
  [contentView addSubview: imageView];
  [imageView release];
  
  _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  _tableView.autoresizesSubviews = YES;
  _tableView.separatorColor = [UIColor clearColor];
  _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  _tableView.backgroundColor = [UIColor clearColor];
  _tableView.delegate = self;
  _tableView.dataSource = self;
  _tableView.sectionIndexMinimumDisplayRowCount = NSIntegerMax;
  [contentView addSubview: _tableView];
  self.view = contentView;
  [contentView release];
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  [_presets addDelegate: self];
  [_tableView reloadData];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_presets removeDelegate: self];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  [super viewWillDisappear: animated];
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
    text.textColor = [UIColor whiteColor];
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

- (void) dealloc
{
  [_presets release];
  _tableView.delegate = nil;
  _tableView.dataSource = nil;
  [_tableView release];
  _tableView = nil;
  [super dealloc];
}

@end

