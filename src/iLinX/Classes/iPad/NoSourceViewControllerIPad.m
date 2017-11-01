

//  NoSourceViewControllerIPad.m
//  iLinX
//
//  Created by mcf on 13/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.

#import "NoSourceViewControllerIPad.h"
#import "BorderedTableViewCell.h"
#import "DeprecationHelper.h"
#import "NLRoomList.h"
#import "NLRoom.h"
#import "NLSource.h"
#import "NLSourceList.h"
#import "StandardPalette.h"
#import "AudioViewControllerIPad.h"
#import "ConfigManager.h"
#import "ConfigProfile.h"
#import "NoSourcePageViewControllerIPad.h"

@interface NoSourceViewControllerIPad ()

- (void) refreshSubviews;
- (void) tableView: (UITableView *) tableView selectFeedbackAtIndexPath: (NSIndexPath *) indexPath;

@end


@implementation NoSourceViewControllerIPad

- (id) initWithOwner: (AudioViewControllerIPad *) owner service: (NLService *) service source: (NLSource *) source
{
  if (self = [super initWithOwner: owner service: service source: source
		      nibName: @"NoSourceViewIPad" bundle: nil])
  {
    _numberOfColumns = [ConfigManager currentProfileData].buttonsPerRow;
    if (_numberOfColumns == 0)
    {
      _numberOfColumns = 2;
      _buttonsOnPage = 7;
      _flash = YES;
    }
    else
    {
      _buttonsOnPage = _numberOfColumns * [ConfigManager currentProfileData].buttonRows;
      _flash = NO;
    }
  }

  return self;
}

- (void) viewDidLoad
{
  NSUInteger pageCount;

  [super viewDidLoad];
  
  _tableView.backgroundColor = [StandardPalette tableCellColour];
  _sources = _owner.roomList.currentRoom.sources;
  
  // Exclude "No Source" - that's the reason we're on this page in the first place!
  _buttonCount = [_sources countOfList] - 1;
  if (_buttonCount == 0)
  {  
    pageCount = 1;
  }
  else if (_flash)
  { 
    NSUInteger pageCounter = _buttonCount;
    pageCount = 1;
    while (pageCounter > 8) 
    {
      ++pageCount;
      pageCounter -= 7;
    }
  }
  else
  {  
    pageCount = ((_buttonCount - 1) / _buttonsOnPage) + 1;
  }
  
  _pageController.numberOfPages = pageCount;
}

- (void) viewDidUnload
{
  _sources = nil;
  [super viewDidUnload];
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  [self refreshSubviews];
  [_sources addDelegate: self];
  [_pageController viewWillAppear: animated];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  [_pageController viewDidAppear: animated];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_pageController viewWillDisappear: animated];
  [_sources removeDelegate: self];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  [super viewWillDisappear: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
  [_pageController viewDidDisappear: animated];
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
  [self refreshSubviews];
}

- (void) itemsInsertedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [self refreshSubviews];
}

- (void) itemsChangedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [self refreshSubviews];
}

- (void) itemsRemovedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [self refreshSubviews];
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

- (UIViewController *) pagedScrollView: (PagedScrollView *) pagedScrollView viewControllerForPage: (NSInteger) page;
{
  NoSourcePageViewControllerIPad *controller =
  [[[NoSourcePageViewControllerIPad alloc]
    initWithOffset: page * _buttonsOnPage buttonsPerRow: _numberOfColumns 
    buttonsPerPage: _buttonsOnPage buttonTotal: _buttonCount flash: _flash] autorelease];
  
  [controller refreshButtonStatesWithSources: _sources];

  return controller;
}

- (void) refreshSubviews
{
  for (NoSourcePageViewControllerIPad *page in _pageController.pageControllers)
  {
    if ([page isKindOfClass: [NoSourcePageViewControllerIPad class]])
      [page refreshButtonStatesWithSources: _sources];
  }
  
  [_tableView reloadData];
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

- (void) dealloc
{
  [_pageController release];
  [_tableView release];
  [_titleLabel release];
  [_selectedIndex release];
  [super dealloc];
}

@end
