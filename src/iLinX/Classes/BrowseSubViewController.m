//
//  BrowseSubViewController.m
//  iLinX
//
//  Created by mcf on 19/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "BrowseSubViewController.h"
#import "BrowseViewController.h"
#import "BorderedTableViewCell.h"
#import "DeprecationHelper.h"
#import "NLBrowseList.h"
#import "NLSource.h"
#import "NLSourceMediaServer.h"
#import "NoItemsView.h"
#import "StandardPalette.h"
#import "TintedTableViewDelegate.h"
#ifdef DEBUG
#import "DebugTracing.h"
#define LOG_RETAIN 0
#define LOG_VIEW_CALLBACKS 0
#endif


#define MINIMUM_ENTRIES_FOR_INDEX_DISPLAY 32

static NSMutableDictionary *g_cachedResponses = nil;
static NSMutableSet *g_unavailableURLs = nil;

// Need to support copyWithZone on NSURLConnection so that it can be used
// as a dictionary key

@interface NSURLConnection (NSCopying)

- (id) copyWithZone: (NSZone *) zone;

@end

@implementation NSURLConnection (NSCopying)

- (id) copyWithZone: (NSZone *) zone
{
  return [self retain];
}

@end

@interface BrowseSubViewController ()

- (void) _handleBrowseListChanged;
- (void) _setNowPlayingButton: (BOOL) animated;
- (void) _addText: (NSString *) text to: (UIView *) view at: (CGRect) location shadowColor: (UIColor *) shadowColor;
- (void) _thumbnailRefreshTimerFired: (NSTimer *) timer;

@end

@implementation BrowseSubViewController

@synthesize
  tableView = _tableView;

- (void) _reloadData
{
    NSLog(@"Reload data in %@", [_browseList listTitle]);
    [_tableView reloadData];
}

- (id) initWithSource: (NLSource *) source browseList: (NLBrowseList *) browseList
                owner: (BrowseViewController *) owner
{
  if ((self = [super init]) != nil)
  {
    if ([source isKindOfClass: [NLSourceMediaServer class]])
      _source = (NLSourceMediaServer *) [source retain];
    _browseList = [browseList retain];
    _owner = owner;
    _pendingConnections = [NSMutableDictionary new];
    if (g_cachedResponses == nil)
      g_cachedResponses = [NSMutableDictionary new];
    if (g_unavailableURLs == nil)
      g_unavailableURLs = [NSMutableSet new];
    _hasSections = NO;
  }
  
#if LOG_RETAIN
  NSLog( @"%@ init (%@)\n%@", self, browseList, [self stackTraceToDepth: 10] );
#endif
  return self;
}

#if LOG_RETAIN
- (id) retain
{
  NSLog( @"%@ retain (%@)\n%@", self, _browseList, [self stackTraceToDepth: 10] );
  return [super retain];
}

- (void) release
{
  NSLog( @"%@ release (%@)\n%@", self, _browseList, [self stackTraceToDepth: 10] );
  [super release];
}
#endif

- (void) loadView
{
  // Create a new table using the full application frame
  _tableView = [[UITableView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame] 
                                            style: UITableViewStylePlain];
  
  // Set the autoresizing mask so that the table will always fill the view
  _tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
  
  // Set the cell separator to a single straight line.
  _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
  _tableView.separatorColor = [StandardPalette tableSeparatorColour];
  _tableView.sectionIndexMinimumDisplayRowCount = NSIntegerMax;
  _tableView.delegate = self;
  _tableView.dataSource = self;
  _tableView.backgroundColor = [StandardPalette tableCellColour];
  
  // Set the tableview as the controller view
  self.view = _tableView;
  
  _tintHandler = [[TintedTableViewDelegate alloc] init];
  _tintHandler.tableView = _tableView;
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  [_tintHandler viewDidLoad];
}

- (void) viewWillAppear: (BOOL) animated
{
#if LOG_VIEW_CALLBACKS
  NSLog( @"%@ viewWillAppear (%@)\n%@", self, _browseList, [self stackTraceToDepth: 10] );
#endif
  [super viewWillAppear: animated];
  _active = YES;
  [_browseList setServerToThisContext];
  [_browseList addDelegate: self];
  [_source addDelegate: self];
  [_tintHandler viewWillAppear: animated];
  [self _reloadData];
  
  [self _setNowPlayingButton: NO];
}

- (void) viewWillDisappear: (BOOL) animated
{
#if LOG_VIEW_CALLBACKS
  NSLog( @"%@ viewWillDisappear (%@)\n%@", self, _browseList, [self stackTraceToDepth: 10] );
#endif
  [_browseList removeDelegate: self];
  [_source removeDelegate: self];
  _active = NO;
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  [super viewWillDisappear: animated];  
}

- (void) viewDidAppear: (BOOL) animated
{
#if LOG_VIEW_CALLBACKS
  NSLog( @"%@ viewDidAppear (%@)\n%@", self, _browseList, [self stackTraceToDepth: 10] );
#endif
  [super viewDidAppear: animated];
  [_tableView deselectRowAtIndexPath: [_tableView indexPathForSelectedRow] animated: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
#if LOG_VIEW_CALLBACKS
  NSLog( @"%@ viewDidDisappear (%@)\n%@", self, _browseList, [self stackTraceToDepth: 10] );
#endif
  [_tintHandler viewDidDisappear: animated];
  [super viewDidDisappear: animated];
}

// Standard table view data source and delegate methods

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
  NSUInteger count = [_browseList countOfList];
  NSUInteger sections = [_browseList countOfSections];
  
  // NSUIntegerMax is a magic number used to indicate an unknown count
  if (!_hasSections && count < NSUIntegerMax && count >= MINIMUM_ENTRIES_FOR_INDEX_DISPLAY && sections > 2)
  {
    _hasSections = [_browseList initAlphaSections];
    if (_hasSections)
      _tableView.sectionIndexMinimumDisplayRowCount = MINIMUM_ENTRIES_FOR_INDEX_DISPLAY;
    else
      _tableView.sectionIndexMinimumDisplayRowCount = NSIntegerMax;
  }
  else if (!_hasSections || count == NSUIntegerMax)
  {
    _tableView.sectionIndexMinimumDisplayRowCount = NSIntegerMax;
  }
  else if (_hasSections && sections <= 2)
  {
    _hasSections = NO;
    _tableView.sectionIndexMinimumDisplayRowCount = NSIntegerMax;
  }
  else
  {
    _tableView.sectionIndexMinimumDisplayRowCount = MINIMUM_ENTRIES_FOR_INDEX_DISPLAY;
  }

  return sections;
}

- (NSArray *) sectionIndexTitlesForTableView: (UITableView *) tableView
{
  return [_browseList sectionIndices];
}

- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section
{
  if ([_browseList countOfList] < _tableView.sectionIndexMinimumDisplayRowCount)
    return nil;
  else
    return [_browseList titleForSection: section];
}

- (NSString *) tableView: (UITableView *) tableView titleForFooterInSection: (NSInteger) section
{
  NSUInteger countOfList = [_browseList countOfList];
  NSString *retValue;
  
  // Footer needed if:
  //  Section is zero and count of list is more than count of section zero and
  //    We have sections, but too few entries for the alpha bar yet or
  //    We don't have sections
  if (section == 0 && [_browseList countOfListInSection: 0] < countOfList &&
    (!_hasSections || countOfList < _tableView.sectionIndexMinimumDisplayRowCount))
      retValue = @" ";
    else
      retValue = nil;
  
  return retValue;
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
  return [_tintHandler tableView: tableView heightForHeaderInSection: section];
}

- (CGFloat) tableView: (UITableView *) tableView heightForFooterInSection: (NSInteger) section
{
  if ([self tableView: tableView titleForFooterInSection: section] != nil)
    return 1;
  else
    return 0;
}

- (NSInteger) tableView: (UITableView *) tableView
  sectionForSectionIndexTitle: (NSString *) title atIndex: (NSInteger) index
{
  return [_browseList sectionForPrefix: title];
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  NSInteger rows;

  if ([_browseList countOfList] == 0 && section == 0)
  {
    _tableView.scrollEnabled = NO;
    _tableView.bounces = NO;
    _tableView.rowHeight = 323;
    rows = 1;
    [self _setNowPlayingButton: NO];
  }
  else
  {
    if (!_tableView.scrollEnabled)
    {
      _tableView.scrollEnabled = YES;
      _tableView.bounces = YES;
      _tableView.rowHeight = 44;
      [self _setNowPlayingButton: YES];
    }
    
    rows = [_browseList countOfListInSection: section];
  }
  
  return rows;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  // Configure cell contents
  // Any row with children should show the disclosure indicator
  UITableViewCell *cell;
  
  NSLog(@"cellForRow: %d:%d", indexPath.row, indexPath.section );
  if (_tableView.scrollEnabled)
  {
    NSDictionary *item = (NSDictionary *) [_browseList itemAtOffset: indexPath.row inSection: indexPath.section];
    NSString *children = [item objectForKey: @"children"];
    NSString *display2 = [item objectForKey: @"display2"];
    NSString *thumbnailURL = [item objectForKey: @"thumbnail"];
    BOOL selectable = [_browseList itemIsSelectableAtOffset: indexPath.row inSection: indexPath.section];
    UITableViewCellAccessoryType accessoryType;

    if (children == nil || [children isEqualToString: @"0"] || _hasSections)
      accessoryType = UITableViewCellAccessoryNone;
    else
      accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if (display2 == nil && thumbnailURL == nil)
    {
      cell = [tableView dequeueReusableCellWithIdentifier: @"MyIdentifier"];
      if (cell == nil)
        cell = [[[BorderedTableViewCell alloc] initDefaultWithFrame: CGRectZero reuseIdentifier: @"MyIdentifier"
                                                              table: tableView] autorelease];

      [cell setLabelText: [_browseList titleForItemAtOffset: indexPath.row inSection: indexPath.section]];
      
      if (selectable)
        [cell setLabelTextColor: [StandardPalette tableTextColour]];
      else
        [cell setLabelTextColor: [StandardPalette disabledTableTextColour]];
    }
    else
    {
      cell = [tableView dequeueReusableCellWithIdentifier: @"MyComplexIdentifier"];
      if (cell == nil)
        cell = [[[BorderedTableViewCell alloc] initDefaultWithFrame: CGRectZero
                                              reuseIdentifier: @"MyComplexIdentifier"
                                                              table: tableView] autorelease];
      else
      {
        while ([[cell.contentView subviews] count] > 0)
          [[[cell.contentView subviews] lastObject] removeFromSuperview];
      }
      
      CGFloat rightMargin;
      CGFloat thumbnailWidth;
      CGFloat mainTextHeight;
      
      if (accessoryType == UITableViewCellAccessoryNone && !_hasSections)
        rightMargin = 0;
      else
        rightMargin = 20;

      if (thumbnailURL == nil)
        thumbnailWidth = 0;
      else
      {
        id cachedResponse = [g_cachedResponses objectForKey: thumbnailURL];
        UIImage *thumbnail;
        
        thumbnailWidth = 43;

        if ([cachedResponse isKindOfClass: [UIImage class]])
          thumbnail = cachedResponse;
        else
        {
          thumbnail = [UIImage imageNamed: @"UnknownThumbnail.png"];
          if (![cachedResponse isKindOfClass: [NSData class]] && ![g_unavailableURLs containsObject: thumbnailURL])
          {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: thumbnailURL]];
        
            [request setValue: @"1" forHTTPHeaderField: @"Viewer-Only-Client"];

            NSURLConnection *conn = [NSURLConnection connectionWithRequest: request delegate: self];
            
            [g_unavailableURLs addObject: thumbnailURL];
            [_pendingConnections setObject: thumbnailURL forKey: (id<NSCopying>) conn];
          }
        }
        
        UIImageView *thumbnailView = [[UIImageView alloc] initWithImage: thumbnail];
        
        thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
        thumbnailView.frame = CGRectMake( 0, (NSInteger) ((tableView.rowHeight - thumbnailWidth) / 2), thumbnailWidth, thumbnailWidth );
        [cell.contentView addSubview: thumbnailView];
        [thumbnailView release];
      }
      
      if (display2 == nil)
        mainTextHeight = tableView.rowHeight;
      else
      {
        mainTextHeight = (NSUInteger) (tableView.rowHeight / 2) + 6;
        UILabel *secondLabel = [[UILabel alloc] initWithFrame: CGRectMake( 10 + thumbnailWidth, mainTextHeight - 6,
                                                             tableView.frame.size.width - thumbnailWidth - 10 - rightMargin,
                                                             tableView.rowHeight - mainTextHeight + 6 )];

        secondLabel.text = display2;
        if (selectable)
          secondLabel.textColor = [StandardPalette smallTableTextColour];
        else
          secondLabel.textColor = [StandardPalette disabledTableTextColour];
        secondLabel.backgroundColor = [UIColor clearColor];
        secondLabel.font = [UIFont systemFontOfSize: [UIFont smallSystemFontSize]];
        [cell.contentView addSubview: secondLabel];
        [secondLabel release];
      }

      UILabel *mainLabel = [[UILabel alloc] initWithFrame: CGRectMake( 10 + thumbnailWidth, 0,
                                                                      tableView.frame.size.width - thumbnailWidth - 10 - rightMargin,
                                                                  mainTextHeight )];

      mainLabel.text = [_browseList titleForItemAtOffset: indexPath.row inSection: indexPath.section];
      
      if (selectable)
        mainLabel.textColor = [StandardPalette tableTextColour];
      else
        mainLabel.textColor = [StandardPalette disabledTableTextColour];
      mainLabel.backgroundColor = [UIColor clearColor];
      if (mainTextHeight == tableView.rowHeight)
        mainLabel.font = [cell labelFont];
      else
        mainLabel.font = [UIFont boldSystemFontOfSize: [UIFont systemFontSize]];
      [cell.contentView addSubview: mainLabel];
      [mainLabel release];
    }
    
    if (selectable)
      cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    else
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.accessoryType = accessoryType;
  }
  else
  {
    NSString *itemType = _browseList.itemType;
    
    cell = [tableView dequeueReusableCellWithIdentifier: @"MyNoItemsIdentifier"];
    if (cell == nil)
      cell = [[[BorderedTableViewCell alloc] initDefaultWithFrame: CGRectZero
                                            reuseIdentifier: @"MyNoItemsIdentifier"
                                                            table: tableView] autorelease];
    else
    {
      while ([[cell.contentView subviews] count] > 0)
        [[[cell.contentView subviews] lastObject] removeFromSuperview];
    }

    if (itemType == nil)
      itemType = [_browseList listTitle];

    NoItemsView *noItemsView = [[NoItemsView alloc] initWithItemType: itemType isLoading: [_browseList dataPending]
                                                      pendingMessage: [_browseList pendingMessage]];
    
    [cell setLabelText: @""];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    CGRect rect = tableView.bounds;

    rect.size.height -= 40;
    noItemsView.frame = rect;
    cell.frame = rect;
    [cell.contentView addSubview: noItemsView];
    [noItemsView release];
  }

  [UIApplication sharedApplication].networkActivityIndicatorVisible = _active && [_browseList dataPending];

  return cell;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  NLBrowseList *childSource = (NLBrowseList *)
  [_browseList selectItemAtOffset: indexPath.row inSection: indexPath.section];
  
  if (childSource == _browseList)
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
  else if (childSource != nil)
    [_owner navigateToBrowseList: childSource];
  else
  {
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
    [_owner navigateToNowPlaying];
  }
}

- (NSIndexPath *) tableView: (UITableView *) tableView willSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  if ([_browseList itemIsSelectableAtOffset: indexPath.row inSection: indexPath.section])
    return indexPath;
  else
    return nil;
}

- (void) itemsChangedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  NSLog(@"itemsChanged in %@", [listDataSource listTitle]);
  [self _handleBrowseListChanged];
}

- (void) itemsInsertedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
    NSLog(@"itemsInserted in %@", [listDataSource listTitle]);
  [self _handleBrowseListChanged];
}

- (void) itemsRemovedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
    NSLog(@"itemsRemoved in %@", [listDataSource listTitle]);
  [self _handleBrowseListChanged];
}

- (void) listDataRefreshDidEnd: (id<ListDataSource>) listDataSource
{
    NSLog(@"refreshEnded in %@", [listDataSource listTitle]);
  _hasSections = NO;
  [self _handleBrowseListChanged];
}

- (void) source: (NLSourceMediaServer *) source stateChanged: (NSUInteger) flags
{
  if ((flags & SOURCE_MEDIA_SERVER_PLAY_POSSIBLE_CHANGED) != 0)
    [self _setNowPlayingButton: YES];
  if ((flags & SOURCE_MEDIA_SERVER_CONNECTED_CHANGED) != 0)
  {
      NSLog(@"stateChanged in %@", [_browseList listTitle]);
    if (source.connected)
      [g_unavailableURLs removeAllObjects];
    [self _reloadData];
  }
}

- (void) didReceiveMemoryWarning
{
  NSEnumerator *connectionEnum = [_pendingConnections keyEnumerator];
  NSURLConnection *connection;
  
  // Releases the view if it doesn't have a superview
  [super didReceiveMemoryWarning];
  
  // Release anything that's not essential, such as cached data
  [_browseList didReceiveMemoryWarning];
  
  // Dump any image data we're waiting for
  while ((connection = [connectionEnum nextObject]) != nil)
    [connection cancel];
  [_pendingConnections removeAllObjects];
  [g_unavailableURLs removeAllObjects];
  [g_cachedResponses removeAllObjects];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = _active && [_browseList dataPending];
}

- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response
{
  BOOL ok = NO;
  BOOL reload = NO;

  if ([response isKindOfClass: [NSHTTPURLResponse class]])
  {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    NSUInteger statusCode = [httpResponse statusCode];
    
    if (statusCode == 200 && [[httpResponse MIMEType] rangeOfString: @"image"].length > 0)
      ok = YES;
    else if (statusCode != 204)
      reload = YES;
    else
    {
      // Server can return "no content" for thumbnails if it is in the process of generating
      // them.  Retry a bit later by removing our cached response and forcing a reload in
      // a little while

      NSString *key = [_pendingConnections objectForKey: connection];
      id cacheValue = [g_cachedResponses objectForKey: key];
      NSTimeInterval timeout;
      
      if (![cacheValue isKindOfClass: [NSNumber class]])
        timeout = 1;
      else
        timeout = [cacheValue unsignedIntegerValue] + 1;

      [g_unavailableURLs removeObject: key];
      [g_cachedResponses setObject: [NSNumber numberWithInteger: (NSUInteger) timeout] forKey: key];
      
      if (_thumbnailRefreshTimer == nil || [[_thumbnailRefreshTimer fireDate] timeIntervalSinceNow] > timeout)
      {
        [_thumbnailRefreshTimer invalidate];
        _thumbnailRefreshTimer = [NSTimer scheduledTimerWithTimeInterval: timeout target: self
                                                                selector: @selector(_thumbnailRefreshTimerFired:)
                                                                userInfo: nil repeats: NO];
      }
    }
  }
  
  if (!ok)
  {
    [connection cancel];
    [_pendingConnections removeObjectForKey: connection];
    if (reload)
      [self _reloadData];
    else
      [UIApplication sharedApplication].networkActivityIndicatorVisible = _active && [_browseList dataPending];
  }
}

- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) data
{
  NSString *key = [_pendingConnections objectForKey: connection];
  id cachedResponse = [g_cachedResponses objectForKey: key];
  NSMutableData *imageData;
  
  if (![cachedResponse isKindOfClass: [NSMutableData class]])
    imageData = [data mutableCopy];
  else
  {
    imageData = [cachedResponse retain];
    [imageData appendData: data];
  }

  [g_cachedResponses setObject: imageData forKey: key];
  [imageData release];
}

- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error
{
  NSString *key = [_pendingConnections objectForKey: connection];
  
  [g_unavailableURLs removeObject: key];
  [g_cachedResponses removeObjectForKey: key];
  [_pendingConnections removeObjectForKey: connection];
  if ([_pendingConnections count] % 16 == 0)
    [self _reloadData];
}

- (void) connectionDidFinishLoading: (NSURLConnection *) connection
{
  NSString *key = [_pendingConnections objectForKey: connection];
  NSData *data = [g_cachedResponses objectForKey: key];
  UIImage *thumbnail;

  [g_unavailableURLs removeObject: key];
  if ([data length] == 0)
    thumbnail = [UIImage imageNamed: @"UnknownThumbnail.png"];
  else
    thumbnail = [UIImage imageWithData: data];
  [g_cachedResponses setObject: thumbnail forKey: key];
  [_pendingConnections removeObjectForKey: connection];
  if ([_pendingConnections count] % 16 == 0)
    [self _reloadData];
}

- (void) _handleBrowseListChanged
{
    NSLog( @"browseListChanged in %@", [_browseList listTitle]);
  [UIApplication sharedApplication].networkActivityIndicatorVisible = _active && [_browseList dataPending];
  
  NSArray *indexPaths = [_tableView indexPathsForVisibleRows];
  NSIndexPath *index = nil;
  
  if ([indexPaths count] > 0 && !_tableView.dragging && !_tableView.decelerating)
  {
    index = [indexPaths objectAtIndex: 0];
    
    NSUInteger count;
    
    if ((index.section == 0 && index.row == 0) || index.section >= [_browseList countOfSections])
      count = 0;
    else
      count = [_browseList countOfListInSection: index.section];
    
    if (count == 0)
      index = nil;
    else if (count <= index.row)
      index = [NSIndexPath indexPathForRow: count - 1 inSection: index.section];
    else
      index = [NSIndexPath indexPathForRow: index.row inSection: index.section];
  }
  
  [self _reloadData];
  if (index != nil)
  {
    // Despite our best efforts, the table reload can sometimes invalidate the index, so
    // be prepared to catch an argument exception
    @try
    {
      [_tableView scrollToRowAtIndexPath: index atScrollPosition: UITableViewScrollPositionTop animated: NO];
    }
    @catch (id exception)
    {
      // Ignore
    }
  }
}

- (void) _setNowPlayingButton: (BOOL) animated
{
  if ((_source != nil && _source.playNotPossible) || [_browseList pendingMessage] != nil)
    [self.navigationItem setRightBarButtonItem: nil animated: animated];
  else if (self.navigationItem.rightBarButtonItem == nil)
  {
    UIBarButtonItem *nowPlayingButton;
    UIView *customButton = [UIView new];
    UIButton *nowPlaying = [UIButton buttonWithType: UIButtonTypeCustom];
    NSString *line1 = NSLocalizedString( @"Now", @"First line of Now Playing label" );
    NSString *line2 = NSLocalizedString( @"Playing", @"Second line of Now Playing label" );
    UIColor *shadowColor = [UIColor colorWithRed: 0.3549 green: 0.3549 blue: 0.3549 alpha: 1.0];
    
    [nowPlaying setBackgroundImage: [UIImage imageNamed: @"Now_Playing_image.png"] forState: UIControlStateNormal];
    [nowPlaying addTarget: _owner action: @selector(navigateToNowPlaying) forControlEvents: UIControlEventTouchUpInside];
    [nowPlaying sizeToFit];
    customButton.frame = nowPlaying.frame;
    [customButton addSubview: nowPlaying];
    
    if ([line2 length] == 0)
      [self _addText: line1 to: customButton
                  at: CGRectMake( 2, 2, customButton.frame.size.width - 12, customButton.frame.size.height - 4 )
         shadowColor: shadowColor];
    else
    {
      [self _addText: line1 to: customButton
                  at: CGRectMake( 2, 2, customButton.frame.size.width - 12, (customButton.frame.size.height / 2) - 2 )
         shadowColor: shadowColor];
      [self _addText: line2 to: customButton
                  at: CGRectMake( 2, (customButton.frame.size.height / 2) - 1,
                                customButton.frame.size.width - 12, (customButton.frame.size.height / 2) - 1 )
         shadowColor: nil];
    }

    [customButton setBackgroundColor: [UIColor clearColor]];
    customButton.opaque = NO;
    nowPlayingButton = [[UIBarButtonItem alloc] initWithCustomView: customButton];
    [customButton release];
    [self.navigationItem setRightBarButtonItem: nowPlayingButton animated: animated];
    [nowPlayingButton release];
  }
}

- (void) _addText: (NSString *) text to: (UIView *) view at: (CGRect) location shadowColor: (UIColor *) shadowColor
{
  UILabel *label = [UILabel new];
  
  label.text = text;
  label.frame = location;
  label.font = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]];
  label.textColor = [UIColor whiteColor];
  label.shadowColor = shadowColor;
  label.shadowOffset = CGSizeMake( 0, -1 );
  label.lineBreakMode = UILineBreakModeTailTruncation;
  label.textAlignment = UITextAlignmentCenter;
  label.numberOfLines = 1;
  [label setBackgroundColor: [UIColor clearColor]];
  label.opaque = NO;
  [view addSubview: label];
  [label release];
}

- (void) _thumbnailRefreshTimerFired: (NSTimer *) timer
{
  _thumbnailRefreshTimer = nil;
  [self _reloadData];
}

- (void) dealloc
{
  NSEnumerator *connectionEnum = [_pendingConnections keyEnumerator];
  NSURLConnection *connection;

#if LOG_RETAIN
  NSLog( @"%@ dealloc (%@)\n%@", self, _browseList, [self stackTraceToDepth: 10] );
#endif
  _tableView.delegate = nil;
  _tableView.dataSource = nil;
  [_thumbnailRefreshTimer invalidate];
  [_tableView release];
  [_tintHandler release];
  [_browseList release];
  while ((connection = [connectionEnum nextObject]) != nil)
    [connection cancel];
  [_pendingConnections release];
  [super dealloc];
}

@end
