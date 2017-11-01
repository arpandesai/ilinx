//
//  BrowseViewController.m
//  iLinX
//
//  Created by mcf on 16/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//
#import "BrowseViewController.h"
#import "BrowseSubViewController.h"
#import "BorderedTableViewCell.h"
#import "ChangeSelectionHelper.h"
#import "DeprecationHelper.h"
#import "Icons.h"
#import "MainNavigationController.h"
#import "NLBrowseList.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLService.h"
#import "NLSource.h"
#import "NLSourceList.h"
#import "RootViewController.h"
#import "StandardPalette.h"

static NSString *kIconOrderPrefsKey = @"BrowseViewIconOrderPrefs";

@interface BrowseViewController ()

- (void) pushedNowPlaying: (id) button;
- (void) addText: (NSString *) text to: (UIView *) view at: (CGRect) location
     shadowColor: (UIColor *) shadowColor;
- (void) setDefaultCustomizedItems;
- (void) beginCustomizingItems;
- (void) endCustomizingItems;
- (void) redetermineTabBarItems;
- (void) redoTabBarItemsWithCount: (NSUInteger) count;
- (void) addMoreEditButton;
- (void) removeMoreEditButton;
- (UIBarButtonItem *) getNowPlayingButton;
- (void) layoutSubviews;
- (NSString *) localisedTitleForTitle: (NSString *) title abbreviated: (BOOL) abbreviated;
- (void) setDisappearingController: (UIViewController *) disappearingController;

@end

@implementation BrowseViewController

- initWithRoomList: (NLRoomList *) roomList service: (NLService *) service
            source: (NLSource *) source nowPlaying: (id<AVControlViewProtocol>) nowPlaying
{
  if ((self = [super initWithRoomList: roomList service: service source: source]) != nil)
  {
    _nowPlaying = [nowPlaying retain];
    _browseList = [source.browseMenu retain];
    _moreViewController = [UITableViewController new];
    _moreViewController.tableView.dataSource = self;
    _moreViewController.tableView.delegate = self;
    _moreViewController.tableView.backgroundColor = [StandardPalette tableCellColour];
    _moreViewController.tableView.separatorColor = [StandardPalette tableSeparatorColour];
    if (![_source isKindOfClass: [NLSourceMediaServer class]])
      _moreViewController.navigationItem.rightBarButtonItem = [self getNowPlayingButton];
    _moreViewController.title = NSLocalizedString( @"More", @"The title of the more tab in the browse view" );
    _subViewControllers = [NSMutableArray new];
    _subNavController = [[UINavigationController alloc] initWithRootViewController: _moreViewController];
    //NSLog( @"Sub nav hidden 1" );
    [_subNavController setNavigationBarHidden: YES animated: NO];
    _subNavController.delegate = self;
    _allTabBarItems = nil;
    _unusedTabBarItems = nil;
    _animatePop = YES;
    [self setDefaultCustomizedItems];
  }

  return self;
}

- (void) navigateToBrowseList: (NLBrowseList *) browseList
{
  BrowseSubViewController *newController = [[BrowseSubViewController alloc]
                                            initWithSource: _source browseList: browseList owner: self];
  
  newController.title = [browseList listTitle];
  if (![_source isKindOfClass: [NLSourceMediaServer class]] ||
    !((NLSourceMediaServer *) _source).playNotPossible)
    newController.navigationItem.rightBarButtonItem = [self getNowPlayingButton];
  self.title = newController.title;
  //**SUBNAV**/[_subNavController.visibleViewController viewWillDisappear: YES];
  [self setDisappearingController: _subNavController.visibleViewController];
  [_subNavController pushViewController: newController animated: YES];
  [_navBar pushNavigationItem: newController.navigationItem animated: YES];
  [newController release];
}

- (void) navigateToNowPlaying
{
  // Should only ever display A/V view if A/V is enabled, so ensure it is!
  [_roomList.currentRoom.renderer ensureAmpOn];

  // Push the A/V view controller
  [[self navigationController] pushViewController: (UIViewController *) _nowPlaying animated: YES];
}

- (void) refreshBrowseList
{
  if ([_browseList canBeRefreshed])
    [_browseList refresh];
}

- (void) loadView
{
  [super loadView];

  self.view.backgroundColor = [StandardPalette tableCellColour];
  [self.view sizeToFit];
  [StandardPalette setTintForToolbar: _toolBar];

  NSMutableArray *newItems = [[_toolBar items] mutableCopy];
  UIBarButtonItem *newButton = [[UIBarButtonItem alloc]
                                initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                target: nil action: nil];
  [newItems addObject: newButton];
  _toolBar.items = newItems;
  [newItems release];
  [newButton release];

  // Add a navigation bar to handle our own sub-view navigation
  _navBar = [UINavigationBar new];
  [_navBar sizeToFit];
  _navBar.delegate = self;
  [StandardPalette setTintForNavigationBar: _navBar];
  
  // Add a now playing button
  if (![_source isKindOfClass: [NLSourceMediaServer class]])
    self.navigationItem.rightBarButtonItem = [self getNowPlayingButton];
  
  // Make sure that back button always says "Browse"
  self.navigationItem.backBarButtonItem =
  [[[UIBarButtonItem alloc]
   initWithTitle: NSLocalizedString( @"Browse", @"Title of back button when returning to the browse view" )
   style: UIBarButtonItemStyleBordered target: nil action: nil] autorelease];

  // Create a tab bar
  _tabBar = [UITabBar new];
  _tabBar.delegate = self;
  
  // Add the navigable table view
  [self.view addSubview: _subNavController.view];
  _subNavController.view.backgroundColor = [StandardPalette standardTintColour];
  
  // Finally add the created tab bar last so that its configuration popup
  // displays over all the other items
  [self.view addSubview: _tabBar];
}

- (void) viewWillAppear: (BOOL) animated
{
  MainNavigationController *mainController = (MainNavigationController *) self.navigationController;
  
  //**/NSLog( @"BrowseViewController viewWillAppear: %@ [%08X]", _source.name, (NSUInteger) self );
  [super viewWillAppear: animated];
    
  // Populate our navigation bar with data to make it look like the real one
  NSArray *viewControllers = mainController.viewControllers;
  NSUInteger viewControllerCount = [viewControllers count];
  while (viewControllerCount > 0 && [viewControllers objectAtIndex: viewControllerCount - 1] != self)
    --viewControllerCount;
  
  if (viewControllerCount < 2)
    _minNavItemCount = 1;
  else
    _minNavItemCount = 2;
  
  if ([_navBar.items count] == 0)
  {
    if (_minNavItemCount == 2)
    {
      UINavigationItem *oldItem = ((UIViewController *) [mainController.viewControllers
                                                         objectAtIndex: viewControllerCount - 2]).navigationItem;
      UINavigationItem *item = [[UINavigationItem alloc] initWithTitle: oldItem.title];
      
      if (oldItem.backBarButtonItem != nil)
      {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                       initWithTitle: oldItem.backBarButtonItem.title
                                       style: oldItem.backBarButtonItem.style target: nil action: nil];
        
        backButton.image = oldItem.backBarButtonItem.image;
        backButton.imageInsets = oldItem.backBarButtonItem.imageInsets;
        item.backBarButtonItem = backButton;
        [backButton release];
      }
      [_navBar pushNavigationItem: item animated: NO];
      [item release];
    }
    [_navBar pushNavigationItem: _subNavController.topViewController.navigationItem animated: NO];
  }

  [StandardPalette setTintForNavigationBar: mainController.navigationBar];
#if defined(DEMO_BUILD)
  [mainController setAudioControlsStyle: UIBarStyleDefault];
#else
  [mainController setAudioControlsStyle: UIBarStyleBlackOpaque];
#endif
  
  [_browseList addDelegate: self];
  
  NSUInteger count = [_browseList countOfList];
  BOOL changed = (count != [_allTabBarItems count]);
  NSUInteger i;
  
  if (!changed)
  {
    for (i = 0; i < count; ++i)
    {
      if (![((UITabBarItem *) [_allTabBarItems objectAtIndex: i]).title isEqualToString: 
          [self localisedTitleForTitle: [_browseList titleForItemAtIndex: i] abbreviated: YES]])
      {
        changed = YES;
        break;
      }
    }
  }
  
  if (changed)
    [self redetermineTabBarItems];
  
  [_roomList.currentRoom.sources addSourceOnlyDelegate: self];
  [_subNavController.visibleViewController viewWillAppear: animated];
  [self layoutSubviews];
}

- (void) viewWillDisappear: (BOOL) animated
{
  //**/NSLog( @"BrowseViewController viewWillDisappear: %@ [%08X]", _source.name, (NSUInteger) self );
  [self setDisappearingController: _subNavController.visibleViewController];
  [_disappearingController viewWillDisappear: animated];
  if ([_source isKindOfClass: [NLSourceMediaServer class]])
   [(NLSourceMediaServer *) _source removeDelegate: self];  
  [_browseList removeDelegate: self];
  [_roomList.currentRoom.sources removeSourceOnlyDelegate: self];
  [_navBar removeFromSuperview];
  //NSLog( @"Main nav revealed 2" );
  [self.navigationController setNavigationBarHidden: NO animated: NO];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  [self layoutSubviews];
  [super viewWillDisappear: animated];
}

- (void) viewDidAppear: (BOOL) animated
{
  //**/NSLog( @"BrowseViewController viewDidAppear: %@ [%08X]", _source.name, (NSUInteger) self );
  [super viewDidAppear: animated];
  
  if (_location != nil && _source != nil)
  {
    MainNavigationController *mainController = (MainNavigationController *) self.navigationController;
    
    if ([_source isKindOfClass: [NLSourceMediaServer class]])
    {
      [(NLSourceMediaServer *) _source addDelegate: self];
      [self source: (NLSourceMediaServer *) _source stateChanged: 0xFFFFFFFF];
    }
    
    [mainController showAudioControls: NO];
    //NSLog( @"Main nav hidden 3" );
    [mainController setNavigationBarHidden: YES animated: NO];
    [self.view addSubview: _navBar];
    [self layoutSubviews];
    [_subNavController.visibleViewController viewDidAppear: animated];
    [_moreViewController.tableView deselectRowAtIndexPath:
     [_moreViewController.tableView indexPathForSelectedRow] animated: animated];
  }
}

- (void) viewDidDisappear: (BOOL) animated
{
  //**/NSLog( @"BrowseViewController viewDidDisappear: %@ [%08X]", _source.name, (NSUInteger) self );
  [_disappearingController viewDidDisappear: animated];
  [_disappearingController release];
  _disappearingController = nil;
  [super viewDidDisappear: animated];
}

- (void) tabBar: (UITabBar *) tabBar didSelectItem: (UITabBarItem *) item
{
  NSUInteger itemCount = [_allTabBarItems count];
  NSUInteger itemIndex = [_tabBar.items indexOfObject: item];
  NSUInteger navCount = [_navBar.items count];

  _animatePop = (item == _currentTabBarItem);
  if (navCount <= _minNavItemCount)
  {
    if (!_animatePop)
    {
      //**SUBNAV**/[_subNavController.visibleViewController viewWillDisappear: _animatePop];
      [self setDisappearingController: _subNavController.visibleViewController];
    }
  }
  else
  {
    // [_navBar popNavigationItemAnimated:] doesn't always immediately decrease the
    // item count and doesn't seem to be able to pop more than one thing at once i.e.
    // no matter how many times you pop, we only go back one level.  This was tested
    // and working at one point, so maybe a bug introduced in 2.2.1?  Whatever, we
    // get round this by brute force.
    
    NSUInteger limit = (navCount - _minNavItemCount);

    [self setDisappearingController: _subNavController.visibleViewController];
    if (limit > 1)
    {
      NSMutableArray *newItems = [_navBar.items mutableCopy];
      NSMutableArray *newControllers = [_subNavController.viewControllers mutableCopy];
    
      [newItems removeObjectsInRange: NSMakeRange( _minNavItemCount + 1, limit - 1 )];
      [newControllers removeObjectsInRange: NSMakeRange( _minNavItemCount, limit - 1 )];
      
      _navBar.items = newItems;
      [newItems release];
      _subNavController.viewControllers = newControllers;
      [newControllers release];
    }
    
    _programmaticPop = YES;
    [_navBar popNavigationItemAnimated: _animatePop];
    _programmaticPop = NO;
  }

  if (!_animatePop)
  {
    NSMutableArray *newItems = [_navBar.items mutableCopy];

    _subNavController.viewControllers =
     [NSArray arrayWithObject: [_subViewControllers objectAtIndex: itemIndex]];
    [newItems replaceObjectAtIndex: _minNavItemCount - 1 withObject: _subNavController.topViewController.navigationItem];
    _navBar.items = newItems;
    [newItems release];
    
    id tableController = _subNavController.topViewController;
    
    if ([tableController respondsToSelector: @selector(tableView)])
    {
      UITableView *tableView = [tableController tableView];
      
      if ([tableView numberOfSections] > 0 && [tableView numberOfRowsInSection: 0] > 0)
        [[tableController tableView] scrollToRowAtIndexPath: [NSIndexPath indexPathForRow: 0 inSection: 0]
                                           atScrollPosition: UITableViewScrollPositionTop animated: NO];
    }
  }
  _animatePop = YES;
  
  _currentTabBarItem = item;
  if (item.tag == itemCount)
    self.title = _moreViewController.title;
  else
    self.title = item.title;
  
  [self setBarButtonsForItem: itemIndex of: itemCount];
}

- (BOOL) navigationBar: (UINavigationBar *) navigationBar shouldPopItem: (UINavigationItem *) item
{
  NSUInteger viewControllerCount = [_subNavController.viewControllers count];
  BOOL shouldPop = (viewControllerCount > 1);

  if (shouldPop)
  {
    if (viewControllerCount == 2 && _currentTabBarItem.tag == [_allTabBarItems count])
      [self addMoreEditButton];
    self.title = ((UIViewController *) [_subNavController.viewControllers objectAtIndex: viewControllerCount - 2]).title;
    if (!_programmaticPop)
    {
      //**SUBNAV**/[_subNavController.visibleViewController viewWillDisappear: _animatePop];
      [self setDisappearingController: _subNavController.visibleViewController];
    }
    [_subNavController popViewControllerAnimated: _animatePop];
  }
  else
    [self.navigationController popViewControllerAnimated: YES];
  
  return shouldPop;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
  return 1;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  return [_unusedTabBarItems count];
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"MoreTableViewCell"];
  UITabBarItem *item = (UITabBarItem *) [_unusedTabBarItems objectAtIndex: indexPath.row];
  NSDictionary *itemDict = (NSDictionary *) [_browseList itemAtIndex: item.tag];
  NSString *children = [itemDict objectForKey: @"children"];
  NSString *originalName = [_browseList titleForItemAtIndex: item.tag];
  NSString *listType = [itemDict objectForKey: @"listType"];

  if (listType == nil)
    listType = originalName;

  if (cell == nil)
    cell = [[[BorderedTableViewCell alloc] initDefaultWithFrame: CGRectZero 
                                                reuseIdentifier: @"MoreTableViewCell"
                                                          table: tableView] autorelease];
  
  // Configure cell contents
  // Any row with children should show the disclosure indicator
  if (children == nil || [children isEqualToString: @"0"])
    cell.accessoryType = UITableViewCellAccessoryNone;
  else
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  [cell setLabelText: [self localisedTitleForTitle: originalName abbreviated: NO]];
  [cell setLabelImage: [Icons browseIconForItemName: listType]];
  [cell setLabelSelectedImage: [Icons selectedBrowseIconForItemName: listType]];

  //NSLog( [NSString stringWithFormat: @"\"%@\" -> \"%@\"", originalName, cell.text] );
  if ([_browseList itemIsSelectableAtIndex: item.tag])
    [cell setLabelTextColor: [StandardPalette tableTextColour]];
  else
    [cell setLabelTextColor: [StandardPalette disabledTableTextColour]];

  return cell;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  UITabBarItem *item = [_unusedTabBarItems objectAtIndex: indexPath.row];
  NLBrowseList *subList = (NLBrowseList *) [_browseList selectItemAtIndex: item.tag];
  
  if (subList != nil && subList != _browseList)
    [self navigateToBrowseList: subList];
  else
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
    
  [self removeMoreEditButton];
}

- (void) itemsChangedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  if (listDataSource == (id<ListDataSource>) _browseList)
  {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self redetermineTabBarItems];
  }
}

- (void) itemsInsertedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  if (listDataSource == (id<ListDataSource>) _browseList)
  {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self redetermineTabBarItems];
  }
}

- (void) itemsRemovedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  if (listDataSource == (id<ListDataSource>) _browseList)
  {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self redetermineTabBarItems];
  }
}

- (void) listDataRefreshDidEnd: (id<ListDataSource>) listDataSource
{
  if (listDataSource == (id<ListDataSource>) _browseList)
  {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self redetermineTabBarItems];
  }
}

- (void) didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  [_browseList didReceiveMemoryWarning];
}

- (void) dealloc
{
  [_nowPlaying release];
  [_browseList release];
  [_previousBrowseList release];
  [_tabBar release];
  [_allTabBarItems release];
  [_unusedTabBarItems release];
  _moreViewController.tableView.delegate = nil;
  _moreViewController.tableView.dataSource = nil;
  [_moreViewController release];
  [_subViewControllers release];
  [_subNavController release];
  [_navBar release];
  [_disappearingController release];
  [super dealloc];
}

// Local methods

- (void) pushedNowPlaying: (id) button
{
  [self navigateToNowPlaying];
}

- (void) addText: (NSString *) text to: (UIView *) view at: (CGRect) location shadowColor: (UIColor *) shadowColor
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

- (void) setDefaultCustomizedItems
{
  NSString *prefsKey = [NSString stringWithFormat: @"%@:%@", kIconOrderPrefsKey, [_source sourceControlType]];
  NSArray *iconOrderPrefs = [[NSUserDefaults standardUserDefaults] objectForKey: prefsKey];
  
  if (iconOrderPrefs == nil)
  {
    if ([[_source sourceControlType] caseInsensitiveCompare: @"MEDIASERVER"] == NSOrderedSame) 
      iconOrderPrefs = [NSArray arrayWithObjects: @"Albums", @"Artists", @"Genres", @"All Songs", nil];
    else
      iconOrderPrefs = [NSArray arrayWithObjects: nil];
    [[NSUserDefaults standardUserDefaults] setObject: iconOrderPrefs forKey: prefsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
}

- (void) beginCustomizingItems
{
  [_navBar.topItem setRightBarButtonItem:
    [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                   target: self action: @selector(endCustomizingItems)] autorelease]
   animated: YES];
  [_tabBar beginCustomizingItems: _allTabBarItems];
}

- (void) endCustomizingItems
{  
  [_tabBar endCustomizingAnimated: YES];

  NSString *prefsKey = [NSString stringWithFormat: @"%@:%@", kIconOrderPrefsKey, [_source sourceControlType]];
  NSArray *iconOrderPrefs = [[NSUserDefaults standardUserDefaults] objectForKey: prefsKey];
  NSMutableArray *newPrefs = [NSMutableArray arrayWithCapacity: [iconOrderPrefs count]];
  NSUInteger tabBarCount = [_tabBar.items count];
  NSUInteger browseListCount = [_browseList countOfList];
  NSUInteger i;
  NSUInteger j;
  
  for (i = 0; i < tabBarCount; ++i)
  {
    NSUInteger tag = ((UITabBarItem *) [_tabBar.items objectAtIndex: i]).tag;
    if (tag == browseListCount)
      break;
    else
      [newPrefs addObject: [_browseList titleForItemAtIndex: tag]];
  }
  
  [newPrefs addObjectsFromArray: iconOrderPrefs];
  tabBarCount = i;
  
  while (i < [newPrefs count])
  {
    for (j = 0; j < tabBarCount; ++j)
    {
      if ([[newPrefs objectAtIndex: i] isEqualToString: [newPrefs objectAtIndex: j]])
      {
        [newPrefs removeObjectAtIndex: i];
        --i;
        break;
      }
    }
    ++i;
  }

  [[NSUserDefaults standardUserDefaults] setObject: newPrefs forKey: prefsKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  if ([_source isKindOfClass: [NLSourceMediaServer class]] &&
    ((NLSourceMediaServer *) _source).playNotPossible)
    [_navBar.topItem setRightBarButtonItem: nil animated: YES];
  else
    [_navBar.topItem setRightBarButtonItem: [self getNowPlayingButton] animated: YES];
  
  // Force redetermination, even though there are no new items
  [_previousBrowseList release];
  _previousBrowseList = nil;
  [self redetermineTabBarItems];
}

- (void) redetermineTabBarItems
{
  NSUInteger count = [_browseList countOfList];
  BOOL changed = (_previousBrowseList == nil);
  NSUInteger i;
  
#if defined(DEBUG)
  //**/NSLog( @"Redetermining tab bar items with count: %u and item 0 title: %@",
  //**/        count, [_browseList titleForItemAtIndex: 0] );
#endif

  if (count == NSUIntegerMax)
    count = 1;
  
  if (!changed)
    changed = (count != [_previousBrowseList count]);
  if (!changed)
  {
    for (i = 0; i < count; ++i)
    {
      if (![[_browseList titleForItemAtIndex: i] isEqualToString: [_previousBrowseList objectAtIndex: i]])
      {
        changed = YES;
        break;
      }
    }
  }
  
  if (changed)
  {
    NSMutableArray *newBrowseList = [NSMutableArray arrayWithCapacity: count];

    for (i = 0; i < count; ++i)
    {
      NSString *title = [_browseList titleForItemAtIndex: i];
      
      if (title != nil)
        [newBrowseList addObject: title];
      else
        break;
    }

    if (i == count)
    {
      [_previousBrowseList release];
      _previousBrowseList = [newBrowseList retain];
      [self redoTabBarItemsWithCount: count];
    }
  }

  [_moreViewController.tableView reloadData];
}

- (void) redoTabBarItemsWithCount: (NSUInteger) count
{
  NSString *prefsKey = [NSString stringWithFormat: @"%@:%@", kIconOrderPrefsKey, [_source sourceControlType]];
  NSMutableArray *iconOrderPrefs = [[[NSUserDefaults standardUserDefaults] objectForKey: prefsKey] mutableCopy];
  NSUInteger i;

  [_allTabBarItems release];
  _allTabBarItems = [[NSMutableArray arrayWithCapacity: count] retain];
  
  for (i = 0; i < count; ++i)
  {
    NSString *title = [_browseList titleForItemAtIndex: i];
    UIImage *image = [Icons tabBarBrowseIconForItemName: title];
    UITabBarItem *tabBarItem = [[UITabBarItem alloc]
                                initWithTitle: [self localisedTitleForTitle: title abbreviated: YES]
                                image: image tag: i];
    
    if (title == nil)
    {
      tabBarItem.title = NSLocalizedString( @"Loading...", @"Tab bar string to show when loading tab bar contents" );
      tabBarItem.enabled = NO;
    }
    [_allTabBarItems addObject: tabBarItem];
    [tabBarItem release];
  }
  
  NSMutableArray *newBarItems;
  NSMutableArray *newBarControllers;
  NSUInteger oldCount;
  NSUInteger limit;
  NSUInteger j;
  
  // Special hack for undocked iPod dock to force Media list to show (so that we can see the
  // "No iPod is docked" caption)
  if (count > 0 && [[_browseList titleForItemAtIndex: 0] isEqualToString: @"Media"])
  {
    [iconOrderPrefs release];
    iconOrderPrefs = [[NSMutableArray arrayWithObject: @"Media"] retain];
  }
  else if (iconOrderPrefs == nil)
  {
    oldCount = _tabBar.items.count;
    iconOrderPrefs = [[NSMutableArray arrayWithCapacity: oldCount] retain];
    for (i = 0; i < oldCount; ++i)
    {
      NSUInteger tag = ((UITabBarItem *) [_tabBar.items objectAtIndex: i]).tag;
      
      if (tag < count)
        [iconOrderPrefs addObject: [_browseList titleForItemAtIndex: tag]];
    }
  }
  oldCount = [iconOrderPrefs count];
  
  [_unusedTabBarItems release];
  _unusedTabBarItems = [_allTabBarItems mutableCopy];
  _currentTabBarItem = nil;
  
  if (count > 5)
    limit = 4;
  else
    limit = 5;
  
  if (oldCount > limit)
    oldCount = limit;

  NSString *selTitle = _tabBar.selectedItem.title;
  
  newBarItems = [NSMutableArray arrayWithCapacity: 5];
  newBarControllers = [NSMutableArray arrayWithCapacity: 5];
  
  for (i = 0; i < oldCount; ++i)
  {
    NSString *oldTitle = [iconOrderPrefs objectAtIndex: i];

    for (j = 0; j < count; ++j)
    {
      UITabBarItem *item = [_allTabBarItems objectAtIndex: j];
      NSString *itemTitle = [_browseList titleForItemAtIndex: item.tag];
      
      if ([oldTitle isEqualToString: itemTitle])
      {
        if ([selTitle isEqualToString: itemTitle])
          _currentTabBarItem = item;
        [newBarItems addObject: item];
        [_unusedTabBarItems removeObject: item];
        break;
      }
    }
  }

  for (i = 0; i < [_unusedTabBarItems count]; ++i)
  {
    NSString *itemTitle = [_browseList titleForItemAtIndex: ((UITabBarItem *) [_unusedTabBarItems objectAtIndex: i]).tag];
    
    for (j = 0; j < oldCount; ++j)
    {
      if ([[iconOrderPrefs objectAtIndex: j] isEqualToString: itemTitle])
        break;
    }
    
    if (j == oldCount && itemTitle != nil)
      [iconOrderPrefs addObject: itemTitle];
  }
  
  if (oldCount != [iconOrderPrefs count])
  {
    [[NSUserDefaults standardUserDefaults] setObject: iconOrderPrefs forKey: prefsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
  [iconOrderPrefs release];
  
  while ([newBarItems count] < limit && [_unusedTabBarItems count] > 0)
  {
    [newBarItems addObject: [_unusedTabBarItems objectAtIndex: 0]];
    [_unusedTabBarItems removeObjectAtIndex: 0];
  }
  
  for (i = 0; i < [newBarItems count]; ++i)
  {
    UITabBarItem *item = [newBarItems objectAtIndex: i];
    NLBrowseList *subList = [_browseList browseListForItemAtIndex: item.tag];
    UIViewController *newController;
    
    if (subList == nil || subList == _browseList)
    {
      // We're loading.  Put in a make-shift temporary table view controller to
      // keep things looking right
      
      newController = [UITableViewController new];
    }
    else
    {
      newController = [[BrowseSubViewController alloc] initWithSource: _source browseList: subList owner: self];
    }
    
    newController.title = item.title;
    if (![_source isKindOfClass: [NLSourceMediaServer class]] ||
        !((NLSourceMediaServer *) _source).playNotPossible)
      newController.navigationItem.rightBarButtonItem = [self getNowPlayingButton];    
    [newBarControllers addObject: newController];
    [newController release];
  }
  
  if (count > 5)
  {
    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem: UITabBarSystemItemMore tag: count];
    
    [newBarItems addObject: tabBarItem];
    [newBarControllers addObject: _moreViewController];
    [tabBarItem release];
    if (_tabBar.selectedItem != nil && selTitle == nil)
    {
      _currentTabBarItem = tabBarItem;
      selTitle = _moreViewController.title;
    }
  }
  
  _tabBar.items = newBarItems;
  _tabBar.selectedItem = _currentTabBarItem;
  [_subViewControllers release];
  _subViewControllers = [newBarControllers retain];
  if (_currentTabBarItem == nil && [_tabBar.items count] > 0)
  {
    UITabBarItem *firstItem = [_tabBar.items objectAtIndex: 0];

    _tabBar.selectedItem = firstItem;
    [self tabBar: _tabBar didSelectItem: firstItem];
    selTitle = firstItem.title;
  }
  self.title = selTitle;
  [UIApplication sharedApplication].networkActivityIndicatorVisible = !_currentTabBarItem.enabled;
  if (count > 0)
    [self setBarButtonsForItem: [_tabBar.items indexOfObject: _currentTabBarItem] of: count];
}

- (void) setBarButtonsForItem: (NSUInteger) itemIndex of: (NSUInteger) itemCount
{
  if (itemCount < 2)
    [self removeMoreEditButton];
  else if (itemCount >= 5)
  {
    if (itemIndex == 4)
      [self addMoreEditButton];
    else
      [self removeMoreEditButton];
  }
  else if (itemIndex < itemCount - 1)
    [self removeMoreEditButton];
  else
    [self addMoreEditButton];
}

- (void) addMoreEditButton
{
  UIBarButtonItem *lastButton = [_toolBar.items lastObject];
  
  if (lastButton.action != @selector(beginCustomizingItems))
  {
    NSMutableArray *newItems = [_toolBar.items mutableCopy];
    UIBarButtonItem *newButton = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                  target: self action: @selector(beginCustomizingItems)];
    [newItems addObject: newButton];
    [newButton release];
    _toolBar.items = newItems;
    [newItems release];
  }
}

- (void) removeMoreEditButton
{
  UIBarButtonItem *lastButton = [_toolBar.items lastObject];
  
  if (lastButton.action == @selector(beginCustomizingItems))
  {
    NSMutableArray *newItems = [_toolBar.items mutableCopy];
    
    [newItems removeLastObject];
    _toolBar.items = newItems;
    [newItems release];
  }  
}

- (UIBarButtonItem *) getNowPlayingButton
{
  UIBarButtonItem *nowPlayingButton;
  UIView *customButton = [UIView new];
  UIButton *nowPlaying = [UIButton buttonWithType: UIButtonTypeCustom];
  NSString *line1 = NSLocalizedString( @"Now", @"First line of Now Playing label" );
  NSString *line2 = NSLocalizedString( @"Playing", @"Second line of Now Playing label" );
  UIColor *shadowColor = [UIColor colorWithRed: 0.3549 green: 0.3549 blue: 0.3549 alpha: 1.0];
  
  [nowPlaying setBackgroundImage: [UIImage imageNamed: @"Now_Playing_image.png"] forState: UIControlStateNormal];
  [nowPlaying addTarget: self action: @selector(pushedNowPlaying:) forControlEvents: UIControlEventTouchUpInside];
  [nowPlaying sizeToFit];
  customButton.frame = nowPlaying.frame;
  [customButton addSubview: nowPlaying];
  
  if ([line2 length] == 0)
    [self addText: line1 to: customButton
               at: CGRectMake( 2, 2, customButton.frame.size.width - 12, customButton.frame.size.height - 4 )
      shadowColor: shadowColor];
  else
  {
    [self addText: line1 to: customButton
               at: CGRectMake( 2, 2, customButton.frame.size.width - 12, (customButton.frame.size.height / 2) - 2 )
      shadowColor: shadowColor];
    [self addText: line2 to: customButton
               at: CGRectMake( 2, (customButton.frame.size.height / 2) - 1,
                              customButton.frame.size.width - 12, (customButton.frame.size.height / 2) - 1 )
      shadowColor: nil];
  }
  
  [customButton setBackgroundColor: [UIColor clearColor]];
  customButton.opaque = NO;
  nowPlayingButton = [[[UIBarButtonItem alloc] initWithCustomView: customButton] autorelease];
  [customButton release];
  
  return nowPlayingButton;
}

- (void) layoutSubviews
{
  CGFloat navBarHeight;
  
  if ([_navBar superview] == self.view)
    navBarHeight = _navBar.frame.size.height - 1;
  else
    navBarHeight = -1;
  
  CGRect oldFrame = _toolBar.frame;
  
  _toolBar.frame = CGRectMake( oldFrame.origin.x, navBarHeight, oldFrame.size.width, oldFrame.size.height );    
  
  [_tabBar sizeToFit];
  
  CGRect mainViewBounds = self.view.bounds;
  CGFloat topHeight = _toolBar.bounds.size.height + navBarHeight;
  CGFloat bottomHeight = _tabBar.bounds.size.height;
  
  [_tabBar setFrame:
   CGRectMake( CGRectGetMinX( mainViewBounds ),
              CGRectGetMaxY( mainViewBounds ) - bottomHeight,
              CGRectGetWidth( mainViewBounds ), bottomHeight )];
  
  // Fit the table view in the remaining space
  [_subNavController.view setFrame:
   CGRectMake( CGRectGetMinX( mainViewBounds ),
              CGRectGetMinY( mainViewBounds ) + topHeight,
              CGRectGetWidth( mainViewBounds ), 
              CGRectGetHeight( mainViewBounds ) - topHeight - bottomHeight )];
}

- (NSString *) localisedTitleForTitle: (NSString *) title abbreviated: (BOOL) abbreviated
{
  NSString *localisedTitle;
  
  if (title == nil)
    localisedTitle = nil;
  else
  {
    NSString *titleResource;
    
    if (abbreviated)
    {
      titleResource = [NSString stringWithFormat: @"1000%@", title];    
      localisedTitle = NSLocalizedString( titleResource, @"Short localised version of top level menu item" );
    }
    else
    {
      titleResource = [NSString stringWithFormat: @"1001%@", title];    
      localisedTitle = NSLocalizedString( titleResource, @"Long localised version of top level menu item" );
    }

    if (localisedTitle == nil || [localisedTitle isEqualToString: titleResource])
      localisedTitle = title;
  }
  
  return localisedTitle;
}

- (void) setDisappearingController: (UIViewController *) disappearingController
{
  if (_disappearingController != nil)
  {
    [_disappearingController viewWillDisappear: NO];
    [_disappearingController viewDidDisappear: NO];
    [_disappearingController release];
    _disappearingController = nil;
  }

  _disappearingController = [disappearingController retain];
}

- (void) navigationController: (UINavigationController *) navigationController 
        didShowViewController: (UIViewController *) viewController animated: (BOOL) animated
{
  [viewController viewDidAppear: animated];
  [_disappearingController viewDidDisappear: animated];
  [_disappearingController release];
  _disappearingController = nil;
}

- (void) navigationController: (UINavigationController *) navigationController
       willShowViewController: (UIViewController *) viewController animated: (BOOL) animated
{
  [viewController viewWillAppear: animated];
  [_disappearingController viewWillDisappear: animated];
}

- (void) source: (NLSourceMediaServer *) source stateChanged: (NSUInteger) flags
{
  if ((flags & SOURCE_MEDIA_SERVER_TRANSPORT_STATE_CHANGED) != 0)
  {
    if (source.playNotPossible)
    {
      self.navigationItem.rightBarButtonItem = nil;
      _moreViewController.navigationItem.rightBarButtonItem = nil;
      
      for (UIViewController *controller in _subNavController.viewControllers)
        controller.navigationItem.rightBarButtonItem = nil;
      for (UIViewController *controller in _subViewControllers)
        controller.navigationItem.rightBarButtonItem = nil;
    }
    else
    {
      if (self.navigationItem.rightBarButtonItem == nil)
        self.navigationItem.rightBarButtonItem = [self getNowPlayingButton];
      if (_moreViewController.navigationItem.rightBarButtonItem == nil)
        _moreViewController.navigationItem.rightBarButtonItem = [self getNowPlayingButton];
      
      for (UIViewController *controller in _subNavController.viewControllers)
      {
        if (controller.navigationItem.rightBarButtonItem == nil)
          controller.navigationItem.rightBarButtonItem = [self getNowPlayingButton];
      }
      
      for (UIViewController *controller in _subViewControllers)
      {
        if (controller.navigationItem.rightBarButtonItem == nil)
          controller.navigationItem.rightBarButtonItem = [self getNowPlayingButton];
      }
    }
  }
}

@end
