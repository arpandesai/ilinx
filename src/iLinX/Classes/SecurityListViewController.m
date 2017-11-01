//
//  SecurityListViewController.m
//  iLinX
//
//  Created by mcf on 27/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "SecurityListViewController.h"
#import "DeprecationHelper.h"

@implementation SecurityListViewController

@synthesize tableView = _tableView;

- initWithSecurityService: (NLServiceSecurity *) securityService controlMode: (NSUInteger) controlMode
{
  if (self = [super initWithNibName: nil bundle: nil])
  {
    _securityService = [securityService retain];
    _controlMode = controlMode;
  }
  
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
  [contentView addSubview: _tableView];
  self.view = contentView;
  [contentView release];
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  [self service: _securityService changed: 0xFFFFFFFF];
  [_securityService addDelegate: self];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_securityService removeDelegate: self];
  [super viewWillDisappear: animated];
}

- (void) service: (NLServiceSecurity *) service changed: (NSUInteger) changed
{
  if ((changed & SERVICE_SECURITY_MODE_TITLES_CHANGED) != 0)
  {
    [self.tableView reloadData];
    if ([_securityService buttonCountInControlMode: _controlMode] > 0)
      [self.tableView scrollToRowAtIndexPath: [NSIndexPath indexPathForRow: 0 inSection: 0]
                            atScrollPosition: UITableViewScrollPositionTop animated: NO];
  }
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  NSUInteger rows = [_securityService buttonCountInControlMode: _controlMode];
 
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

  if (indexPath.row % 2 == 1)
    backgroundView.backgroundColor = [UIColor colorWithWhite: 0.3 alpha: 0.2];
  else
    backgroundView.backgroundColor = [UIColor colorWithWhite: 0.5 alpha: 0.2];
    
  text.text = [_securityService nameForButton: indexPath.row inControlMode: _controlMode];
    
  if ([_securityService isEnabledButton: indexPath.row inControlMode: _controlMode])
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
  else
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

  //if ([_securityService indicatorStateForButton: indexPath.row inControlMode: _controlMode])
  //  cell.accessoryType = UITableViewCellAccessoryCheckmark;

  return cell;
}

- (void) dealloc
{
  [_securityService release];
  _tableView.delegate = nil;
  _tableView.dataSource = nil;
  [_tableView release];
  _tableView = nil;
  [super dealloc];
}

@end
