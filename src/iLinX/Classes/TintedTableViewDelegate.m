//
//  TintedTableViewDelegate.m
//  iLinX
//
//  Created by mcf on 10/05/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "TintedTableViewDelegate.h"
#import "DeprecationHelper.h"
#import "StandardPalette.h"

@implementation TintedTableViewDelegate

@synthesize
  tableView = _tableView,
  backdropTint = _backdropTint,
  headerTextColour = _headerTextColour,
  headerShadowColour = _headerShadowColour,
  headerTint = _headerTint;

- (void) setTableView: (UITableView *) tableView
{
  _tableView = tableView;
  if (tableView.style == UITableViewStylePlain)
  {
    self.backdropTint = [StandardPalette tableCellColour];
    self.headerTextColour = [StandardPalette tablePlainHeaderTextColour];
    self.headerShadowColour = [StandardPalette tablePlainHeaderShadowColour];
    self.headerTint = [StandardPalette tablePlainHeaderTintColour];
  }
  else
  {
    self.backdropTint = [StandardPalette standardTintColour];
    self.headerTextColour = [StandardPalette tableGroupedHeaderTextColour];
    self.headerShadowColour = [StandardPalette tableGroupedHeaderShadowColour];
    self.headerTint = nil;
  }
}

- (void) viewDidLoad
{
  if (_backdrop != nil)
  {
    [_backdrop removeFromSuperview];
    [_backdrop release];
    _backdrop = nil;
  }

  self.tableView.separatorColor = [StandardPalette tableSeparatorColour];
  if (_backdropTint == nil)
  {
    if (self.tableView.style == UITableViewStylePlain)
      self.tableView.backgroundColor = [UIColor whiteColor];
    else
      self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
  }
  else
  {
    if (self.tableView.style == UITableViewStylePlain)
      self.tableView.backgroundColor = _backdropTint;
    else
    {
      self.tableView.backgroundColor = [UIColor clearColor];
      _backdrop = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"GroupTableBackground.png"]];
      _backdrop.backgroundColor = _backdropTint;
    }
  }
}

- (void) viewWillAppear: (BOOL) animated
{
  if (_backdrop != nil)
  {
    _backdrop.frame = self.tableView.frame;
    [self.tableView.superview insertSubview: _backdrop belowSubview: self.tableView];
  }
}

- (void) viewDidDisappear: (BOOL) animated
{
  if (_backdrop != nil)
    [_backdrop removeFromSuperview];
}

- (UIView *) tableView: (UITableView *) tableView viewForSection: (NSInteger) section isHeader: (BOOL) isHeader
{
  UIView *view;
  
  if (_headerTint == nil && _headerTextColour == nil && _headerShadowColour == nil)
    view = nil;
  else
  {
    NSString *title;
    CGFloat height;
    
    if (isHeader)
    {
      if ([tableView.dataSource respondsToSelector: @selector(tableView:titleForHeaderInSection:)])
        title = [tableView.dataSource tableView: tableView titleForHeaderInSection: section];
      else
        title = nil;
      
      if ([tableView.delegate respondsToSelector: @selector(tableView:heightForHeaderInSection:)])
        height = [tableView.delegate tableView: tableView heightForHeaderInSection: section];
      else if ([title length] > 0)
        height = tableView.sectionHeaderHeight;
      else
        height = 0;
    }
    else
    {
      if ([tableView.dataSource respondsToSelector: @selector(tableView:titleForFooterInSection:)])
        title = [tableView.dataSource tableView: tableView titleForFooterInSection: section];
      else
        title = nil;
      
      if ([tableView.delegate respondsToSelector: @selector(tableView:heightForFooterInSection:)])
        height = [tableView.delegate tableView: tableView heightForFooterInSection: section];
      else if ([title length] > 0)
        height = tableView.sectionFooterHeight;
      else
        height = 0;
    }
  
    if (height == 0)
      view = nil;
    else if (tableView.style == UITableViewStylePlain)
    {
      UIImageView *background = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"PlainTableSectionBar.png"]];
      UILabel *viewLabel = [[UILabel alloc] initWithFrame: CGRectZero];
      
      view = [[[UIView alloc] initWithFrame: CGRectMake( 0, 0, tableView.bounds.size.width, height )] autorelease];
      
      background.frame = view.frame;
      background.backgroundColor = _headerTint;
      [view addSubview: background];
      [background release];
      
      viewLabel.text = title;
      viewLabel.font = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]];
      viewLabel.backgroundColor = [UIColor clearColor];
      viewLabel.textColor = _headerTextColour;
      viewLabel.shadowColor = _headerShadowColour;
      viewLabel.shadowOffset = CGSizeMake( 0, 1 );
      [viewLabel sizeToFit];
      viewLabel.frame = CGRectOffset( viewLabel.frame, 10, (NSInteger) ((height - [viewLabel.font lineSpacing]) / 2) );
      [view addSubview: viewLabel];
      [viewLabel release];
    }
    else
    {
      UILabel *viewLabel = [[UILabel alloc] initWithFrame: CGRectZero];
      
      view = [[[UIView alloc] initWithFrame: CGRectMake( 0, 0, tableView.bounds.size.width, 20 )] autorelease];
      
      viewLabel.text = title;
      viewLabel.font = [UIFont boldSystemFontOfSize: [UIFont labelFontSize]];
      viewLabel.backgroundColor = [UIColor clearColor];
      viewLabel.textColor = _headerTextColour;
      viewLabel.shadowColor = _headerShadowColour;
      viewLabel.shadowOffset = CGSizeMake( 0, 1 );
      [viewLabel sizeToFit];
      
      if (section == 0 && isHeader)
        viewLabel.frame = CGRectOffset( viewLabel.frame, 20, 15 );
      else
        viewLabel.frame = CGRectOffset( viewLabel.frame, 20, 5 );
      
      view.frame = CGRectMake( 0, 0, viewLabel.frame.size.width, height );
      [view addSubview: viewLabel];
      [viewLabel release];
    }
  }
  
  return view;
}

- (UIView *) tableView: (UITableView *) tableView viewForHeaderInSection: (NSInteger) section
{
  return [self tableView: tableView viewForSection: section isHeader: YES];
}

- (UIView *) tableView: (UITableView *) tableView viewForFooterInSection: (NSInteger) section
{
  return [self tableView: tableView viewForSection: section isHeader: NO];
}

- (CGFloat) tableView: (UITableView *) tableView heightForSection: (NSInteger) section isHeader: (BOOL) isHeader
{
  NSString *title;
  
  if (isHeader)
  {
    if ([tableView.dataSource respondsToSelector: @selector(tableView:titleForHeaderInSection:)])
      title = [tableView.dataSource tableView: tableView titleForHeaderInSection: section];
    else
      title = nil;
  }
  else
  {
    if ([tableView.dataSource respondsToSelector: @selector(tableView:titleForFooterInSection:)])
      title = [tableView.dataSource tableView: tableView titleForFooterInSection: section];
    else
      title = nil;
  }
  
  if ([title length] == 0)
    return 0;
  else if (tableView.style != UITableViewStyleGrouped)
    return 23;
  else if (section > 0 || !isHeader ||
           (_headerTint == nil && _headerTextColour == nil && _headerShadowColour == nil))
    return 35;
  else
    return 45;
}

- (CGFloat) tableView: (UITableView *) tableView heightForHeaderInSection: (NSInteger) section
{
  return [self tableView: tableView heightForSection: section isHeader: YES];
}

- (CGFloat) tableView: (UITableView *) tableView heightForFooterInSection: (NSInteger) section
{
  return [self tableView: tableView heightForSection: section isHeader: NO];
}

- (void) dealloc
{
  [_backdrop release];
  [_backdropTint release];
  [_headerTextColour release];
  [_headerShadowColour release];
  [_headerTint release];
  [super dealloc];
}

@end
