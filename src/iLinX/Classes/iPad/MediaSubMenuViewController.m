//
//  MediaSubMenuViewController.m
//  iLinX
//
//  Created by mcf on 10/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "MediaSubMenuViewController.h"
#import "DeprecationHelper.h"
#import "NLBrowseList.h"
#import "NoItemsView.h"
#import "UncodableObjectArchiver.h"
#ifdef DEBUG
#import "DebugTracing.h"
#define TRACE_RETAIN 0
#endif

#define MINIMUM_ENTRIES_FOR_INDEX_DISPLAY 32

// Flags set in the table template tag

// List data types
#define LIST_DATA_TITLE       0x00
#define LIST_DATA_SECONDARY   0x01
#define LIST_DATA_IMAGE       0x02
#define LIST_DATA_ALL         0x03
#define LIST_DATA_MASK        0x03

// Table row repeat.  Set to true if the visible area should be filled with
// blank table rows when there is not enough data to fill the screen.
#define LIST_DATA_REPEAT_ROWS 0x08


@class TableViewItemIndices;

// Single instance of this object used to ensure that our list has at least
// one delegate remaining while we reset our table type.  Otherwise the list
// data is discarded.
@interface PlaceholderDelegate : NSObject <ListDataDelegate>
{
}
@end
@implementation PlaceholderDelegate
@end

static NSMutableDictionary *g_cachedResponses = nil;
static NSMutableSet *g_unavailableURLs = nil;
static NSUInteger g_currentDisplayOption = 0;
static PlaceholderDelegate *g_placeholderDelegate = nil;

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

@interface MediaSubMenuViewController ()

- (void) handleBrowseListChanged;
- (void) initialiseCellView: (UIView *) cellView withIndices: (TableViewItemIndices *) indices
                   rowIndex: (NSInteger) rowIndex title: (NSString *) title secondaryText: (NSString *) secondaryText
               thumbnailURL: (NSString *) thumbnailURL cellTemplate: (UIView *) cellTemplate;
- (void) calculateRowConstants;
- (void) reportDisplayOptions;
- (void) reloadData;

@end

@interface TableViewItemIndices : NSObject
{
@public
  NSInteger _repeatItemOffset;
  CGFloat _repeatItemWidth;
  CGFloat _repeatItemMargin;
  NSInteger _repeatItemCount;
  NSInteger _imageOffset;
  NSInteger _titleOffset;
  NSInteger _secondaryOffset;
  NSInteger _buttonOffset;
}

@end

@implementation TableViewItemIndices

- (id) init
{
  if ((self = [super init]) != nil)
  {
    _repeatItemOffset = NSNotFound;
    _repeatItemWidth = 0;
    _repeatItemMargin = 0;
    _repeatItemCount = 0;
    _imageOffset = NSNotFound;
    _titleOffset = NSNotFound;
    _secondaryOffset = NSNotFound;
    _buttonOffset = NSNotFound;
  }
  
  return self;
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"%@: {\n  _repeatItemOffset: %d\n  _repeatItemWidth: %f\n"
          "  _repeatItemMargin: %f\n  _repeatItemCount: %d\n  _imageOffset: %d\n  _titleOffset: %d\n"
          "  _secondaryOffset: %d\n  _buttonOffset: %d\n}",
          [super description], self->_repeatItemOffset, self->_repeatItemWidth,
          self->_repeatItemMargin, self->_repeatItemCount, self->_imageOffset, self->_titleOffset,
          self->_secondaryOffset, self->_buttonOffset];
}

@end

@interface TableViewData : NSObject
{
@private
  UIButton *_nameButton;
  UITableView *_tableTemplate;
  NSArray *_rowTemplates;
  NSArray *_rowTemplateData;
  NSArray *_rowOffsets;
  CGFloat _maxRepeatItemWidth;
  CGFloat _maxRepeatItemMargin;
}

@property (readonly) UIButton *nameButton;
@property (readonly) UITableView *tableTemplate;
@property (readonly) NSArray *rowTemplates;
@property (readonly) NSArray *rowTemplateData;
@property (readonly) NSArray *rowOffsets;
@property (readonly) CGFloat maxRepeatItemWidth;
@property (readonly) CGFloat maxRepeatItemMargin;

@end

@implementation TableViewData
@synthesize 
  nameButton = _nameButton,
  tableTemplate = _tableTemplate, 
  rowTemplates = _rowTemplates,
  rowTemplateData = _rowTemplateData,
  rowOffsets = _rowOffsets,
  maxRepeatItemWidth = _maxRepeatItemWidth,
  maxRepeatItemMargin = _maxRepeatItemMargin;

- (id) initWithRootView: (UIView *) view
{
  if ((self = [super init]) != nil)
  {
    _rowTemplates = [[NSArray arrayWithObjects:
                      [NSMutableArray array], [NSMutableArray array], 
                      [NSMutableArray array], [NSMutableArray array], nil] retain];
    _rowTemplateData = [[NSArray arrayWithObjects:
                        [NSMutableArray array], [NSMutableArray array], 
                        [NSMutableArray array], [NSMutableArray array], nil] retain];
    _rowOffsets = [[NSArray arrayWithObjects:
                    [NSMutableArray array], [NSMutableArray array], 
                    [NSMutableArray array], [NSMutableArray array], nil] retain];
    _maxRepeatItemWidth = 0;
    _maxRepeatItemMargin = 0;
	  
    for (UIView *subView in [view subviews])
    {
      if ([subView isKindOfClass: [UITableView class]])
        _tableTemplate = (UITableView *) [subView retain];
      else if ([subView isKindOfClass: [UIButton class]])
        _nameButton = (UIButton *) [subView retain];
      else if (subView.tag >= 256 && subView.tag < 260)
      {
        NSInteger cellType = subView.tag - 256;
        NSMutableArray *rows = [_rowTemplates objectAtIndex: cellType];
        NSMutableArray *rowData = [_rowTemplateData objectAtIndex: cellType];
        NSMutableArray *offsets = [_rowOffsets objectAtIndex: cellType];
  
        for (UIView *cellView in [subView subviews])
        {
          if ([cellView isKindOfClass: [UITableViewCell class]])
          {
            UITableViewCell *tableViewCell = (UITableViewCell *) cellView;
            TableViewItemIndices *indices = [TableViewItemIndices new];
            NSArray *cellSubViews = [tableViewCell.contentView subviews];
            NSInteger count = [cellSubViews count];
            NSInteger i;
            
            [rows addObject: tableViewCell];
            [rowData addObject: [UncodableObjectArchiver dictionaryEncodingWithRootObject: tableViewCell]];
            [offsets addObject: indices];
            [indices release];
            
            for (i = 0; i < count; ++i)
            {
              UIView *cellSubView = [cellSubViews objectAtIndex: i];
              
              switch (cellSubView.tag)
              {
                // Non-repeating item (i.e. one per row)
                case 1:
                  if ([cellSubView isKindOfClass: [UIImageView class]])
                    indices->_imageOffset = i;
                  break;
                case 2:
                  if ([cellSubView isKindOfClass: [UILabel class]])
                    indices->_titleOffset = i;
                  break;
                case 3:
                  if ([cellSubView isKindOfClass: [UILabel class]])
                    indices->_secondaryOffset = i;
                  break;
                case 4:
                  if ([cellSubView isKindOfClass: [UIButton class]])
                    indices->_buttonOffset = i;
                  break;
                  // Repeating item (as many as fit per row)
                case 128:
                case 129:
                case 130:
                case 131:
                  ++indices->_repeatItemCount;
                  if (indices->_repeatItemOffset == NSNotFound)
                  {
                    indices->_imageOffset = NSNotFound;
                    indices->_titleOffset = NSNotFound;
                    indices->_secondaryOffset = NSNotFound;
                    indices->_buttonOffset = NSNotFound;
                    indices->_repeatItemOffset = i;
                    indices->_repeatItemWidth = cellSubView.frame.size.width;
                    indices->_repeatItemMargin = cellSubView.frame.origin.x;
                    if (indices->_repeatItemWidth > _maxRepeatItemWidth)
                      _maxRepeatItemWidth = indices->_repeatItemWidth;
                    if (indices->_repeatItemMargin > _maxRepeatItemMargin)
                      _maxRepeatItemMargin = indices->_repeatItemMargin;
                    cellSubViews = [cellSubView subviews];
                    count = [cellSubViews count];
                    i = -1;
                  }
                  break;
                default:
                  break;
              }
            }
          }
        }
      }
    }
    
    NSInteger firstInitialised = -1;
    NSInteger initialisedCount = 0;
    NSInteger type;
    
    for (type = 0; type < 4; ++type)
    {
      if ([[_rowTemplates objectAtIndex: type] count] > 0)
      {
        ++initialisedCount;
        if (firstInitialised < 0)
          firstInitialised = type;
      }
    }
    
    if (initialisedCount < 4 && firstInitialised >= 0)
    {
      NSMutableArray *initialisedTemplates = [_rowTemplates objectAtIndex: firstInitialised];
      NSMutableArray *initialisedTemplateData = [_rowTemplateData objectAtIndex: firstInitialised];
      NSMutableArray *initialisedOffsets = [_rowOffsets objectAtIndex: firstInitialised];
      
      for (type = firstInitialised + 1; type < 4; ++type)
      {
        NSMutableArray *rows = [_rowTemplates objectAtIndex: type];

        if ([rows count] == 0)
        {
          [rows addObjectsFromArray: initialisedTemplates];
          [[_rowTemplateData objectAtIndex: type] addObjectsFromArray: initialisedTemplateData];
          [[_rowOffsets objectAtIndex: type] addObjectsFromArray: initialisedOffsets];
          if (++initialisedCount == 4)
            break;
        }
      }
    }
  }
  
  return self;
}

- (void) dealloc
{
  [_nameButton release];
  [_tableTemplate release];
  [_rowTemplates release];
  [_rowTemplateData release];
  [_rowOffsets release];
  [super dealloc];
}

@end


@implementation MediaSubMenuViewController

@synthesize
  browseList = _browseList,
  displayOptionsDelegate = _displayOptionsDelegate;

#if TRACE_RETAIN
- (id) init
{
  NSLog( @"%@ init\n%@", self, [self stackTraceToDepth: 10] );
  
  return [super init];
}

- (id) initWithNibName: (NSString *) nibName bundle: (NSBundle *) bundle
{
  NSLog( @"%@ initWithNibName:bundle:\n%@", self, [self stackTraceToDepth: 10] );
  
  return [super initWithNibName: nibName bundle: bundle];
}

- (id) initWithStyle: (UITableViewStyle) style
{
  NSLog( @"%@ initWithStyle\n%@", self, [self stackTraceToDepth: 10] );

  return [super initWithStyle: style];
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
  NSLog( @"%@ initWithCoder\n%@", self, [self stackTraceToDepth: 10] );
  
  return [super initWithCoder: aDecoder];
}

- (id) retain
{
  NSLog( @"%@ retain\n%@", self, [self stackTraceToDepth: 10] );
  return [super retain];
}

- (void) release
{
  NSLog( @"%@ release\n%@", self, [self stackTraceToDepth: 10] );
  [super release];
}
#endif

- (IBAction) selectedRowItem: (UIControl *) control
{
  NLBrowseList *childSource = (NLBrowseList *) [_browseList selectItemAtIndex: control.tag];
  
  if (childSource != _browseList && childSource != nil)
  {
    MediaSubMenuViewController *subController = [[MediaSubMenuViewController alloc]
                                                 initWithNibName: @"MediaSubMenuViewController" bundle: nil];
    subController.browseList = childSource;
    subController.title = [childSource listTitle];
    subController.displayOptionsDelegate = _displayOptionsDelegate;
    [subController setDisplayOption: g_currentDisplayOption];
    
    [self.navigationController pushViewController: subController animated: YES];
    [subController release];
  }
}

- (void) setDisplayOption: (NSUInteger) displayOption
{
  if (displayOption != g_currentDisplayOption)
  {
    NSIndexPath *currentCell = [self.tableView indexPathForRowAtPoint:
                                CGPointMake( self.tableView.bounds.origin.x,
                                            self.tableView.bounds.origin.y + self.tableView.sectionHeaderHeight )];
    NSUInteger currentPosition;

    if (currentCell == nil || g_currentDisplayOption == NSUIntegerMax)
      currentPosition = NSUIntegerMax;
    else
    { 
      currentPosition = [_browseList convertFromOffset: currentCell.row * _itemsPerRow
                                             inSection: currentCell.section];
      if (self.tableView.sectionHeaderHeight == 0 && _itemsPerRow > 1)
        currentPosition = (currentPosition / _itemsPerRow) * _itemsPerRow;
      //**/NSLog( @"Old view, row: %d, section: %d, list pos: %d", currentCell.row, currentCell.section, currentPosition );
      //**/currentCell = [_browseList indexPathFromIndex: currentPosition];
      //**/NSLog( @"Sanity check; list pos: %d = row: %d, section: %d", currentPosition, currentCell.row, currentCell.section );
    }

    g_currentDisplayOption = displayOption;
    
    if ([_viewData count] == 0)
      _currentViewData = nil;
    else
    {
      UIView *superview = [self.view superview];
      BOOL active = _active;
      NSInteger viewIndex;
      CGRect oldFrame = self.view.frame;

      for (NSInteger i = g_currentDisplayOption; i >= 0; --i)
      {
        _currentViewData = [_viewData objectAtIndex: i];
        if ((_currentViewData.tableTemplate.tag & _listProperties) == (_currentViewData.tableTemplate.tag & LIST_DATA_MASK))
          break;
      }
      
      if (superview == nil)
        viewIndex = 0;
      else
      {
        [_browseList addDelegate: g_placeholderDelegate];
        viewIndex = [[[self.view superview] subviews] indexOfObject: self.view];
        if (active)
          [self viewWillDisappear: NO];
        [self.view removeFromSuperview];
        [self.tableView removeFromSuperview];
        if (active)
          [self viewDidDisappear: NO];
      }

      self.tableView.rowHeight = _originalRowHeight;
      self.view = _currentViewData.tableTemplate;
      self.tableView = _currentViewData.tableTemplate;
      _originalRowHeight = self.tableView.rowHeight;
      self.tableView.dataSource = self;
      self.tableView.delegate = self;
      self.view.frame = oldFrame;
      
      if (superview != nil)
      {
        if (active)
          [self viewWillAppear: NO];
        [superview insertSubview: self.view atIndex: viewIndex];
        if (active)
          [self viewDidAppear: NO];
        [_browseList removeDelegate: g_placeholderDelegate];
      }
    }

    [self reloadData];
    if (currentPosition != NSUIntegerMax)
    {
      NSIndexPath *scrollPos = [_browseList indexPathFromIndex: currentPosition / _itemsPerRow * _itemsPerRow];
      
      if (_itemsPerRow > 1)
      {
        NSUInteger sectionCount = [self numberOfSectionsInTableView: self.tableView];
        NSInteger section = scrollPos.section;
        NSUInteger offset = [_browseList convertFromOffset: 0 inSection: section] % _itemsPerRow;

        currentPosition = (scrollPos.row + offset) / _itemsPerRow;
        scrollPos = nil;
        for (; section < sectionCount; ++section)
        {
          NSInteger rows = [self tableView: self.tableView numberOfRowsInSection: section];
          
          if (currentPosition >= rows)
            currentPosition -= rows;
          else
          {
            scrollPos = [NSIndexPath indexPathForRow: currentPosition inSection: section];
            break;
          }
        }
      }

      if (scrollPos != nil)
      {
        //**/NSLog( @"New view, row: %d, section: %d", scrollPos.row, scrollPos.section );
        @try
        {
          [self.tableView scrollToRowAtIndexPath: scrollPos atScrollPosition: UITableViewScrollPositionTop animated: NO];
        }
        @catch (id exception)
        {
        }
      }
    }
    
    [_displayOptionsDelegate subMenu: self didChangeToDisplayOption: g_currentDisplayOption];
  }
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
  // Override to allow orientations other than the default portrait orientation.
  return YES;
}

- (void) viewDidLoad
{
  [super viewDidLoad];

  _pendingConnections = [NSMutableDictionary new];
  if (g_cachedResponses == nil)
    g_cachedResponses = [NSMutableDictionary new];
  if (g_unavailableURLs == nil)
    g_unavailableURLs = [NSMutableSet new];
  if (g_placeholderDelegate == nil)
    g_placeholderDelegate = [PlaceholderDelegate new];
  _hasSections = NO;
  _itemsPerRow = 1;
	
  NSMutableArray *viewData = [NSMutableArray new];
  for (UIView *subView in [_viewTemplates subviews])
  {
    TableViewData *data = [[TableViewData alloc] initWithRootView: subView];
        
    [viewData addObject: data];
    [data release];
  }

  _viewData = viewData;
  
  NSUInteger currentDisplayOption = g_currentDisplayOption;

  g_currentDisplayOption = NSUIntegerMax;
  _originalRowHeight = self.tableView.rowHeight;
  [self setDisplayOption: currentDisplayOption];
}

- (void) viewDidUnload
{
  NSEnumerator *connectionEnum = [_pendingConnections keyEnumerator];
  NSURLConnection *connection;
  
  [_viewData release];
  _viewData = nil;
  _currentViewData = nil;
  
  while ((connection = [connectionEnum nextObject]) != nil)
    [connection cancel];

  [_pendingConnections release];
  _pendingConnections = nil;
  [super viewDidUnload];
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  _active = YES;
  [_browseList addDelegate: self];
  [self.navigationController 
   setNavigationBarHidden: ([self.navigationController.viewControllers objectAtIndex: 0] == self) animated: YES];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_browseList removeDelegate: self];
  _active = NO;
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  [super viewWillDisappear: animated];  
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  [self reloadData];

  NSIndexPath *selected = [self.tableView indexPathForSelectedRow];
  
  if (selected != nil)
    [self.tableView deselectRowAtIndexPath: selected animated: animated];
  [self reportDisplayOptions];
}

- (void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation) fromInterfaceOrientation
{
  [super didRotateFromInterfaceOrientation: fromInterfaceOrientation];
  [self reloadData];
}

// Standard table view data source and delegate methods

- (void) scrollViewDidScroll: (UIScrollView *) scrollView
{
  _lastTopItemIndex = NSUIntegerMax;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
  NSUInteger count = [_browseList countOfList];
  NSUInteger sections = [_browseList countOfSections];
  
  // NSUIntegerMax is a magic number used to indicate an unknown count
  if (!_hasSections && count < NSUIntegerMax && count >= MINIMUM_ENTRIES_FOR_INDEX_DISPLAY)
  {
    _hasSections = [_browseList initAlphaSections];
    if (_hasSections)
      self.tableView.sectionIndexMinimumDisplayRowCount = MINIMUM_ENTRIES_FOR_INDEX_DISPLAY;
    else
      self.tableView.sectionIndexMinimumDisplayRowCount = NSIntegerMax;
  }
  else if (!_hasSections || count == NSUIntegerMax)
  {
    self.tableView.sectionIndexMinimumDisplayRowCount = NSIntegerMax;
  }
  else if (_hasSections && sections <= 2)
  {
    _hasSections = NO;
    self.tableView.sectionIndexMinimumDisplayRowCount = NSIntegerMax;
  }
  else
  {
    self.tableView.sectionIndexMinimumDisplayRowCount = MINIMUM_ENTRIES_FOR_INDEX_DISPLAY;
  }
  
  _hasAllItemsEntries = ([_browseList titleForSection: 0] == nil);

  return sections;
}

- (NSArray *) sectionIndexTitlesForTableView: (UITableView *) tableView
{
  return [_browseList sectionIndices];
}

- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section
{
  if ([_browseList countOfList] < self.tableView.sectionIndexMinimumDisplayRowCount)
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
      (!_hasSections || countOfList < self.tableView.sectionIndexMinimumDisplayRowCount))
    retValue = @" ";
  else
    retValue = nil;
  
  return retValue;
}

- (CGFloat) tableView: (UITableView *) tableView heightForFooterInSection: (NSInteger) section
{
  if (tableView.sectionFooterHeight > 0 &&
      [self tableView: tableView titleForFooterInSection: section] != nil)
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
  NSUInteger count = [_browseList countOfList];
  NSInteger rows;
  
  if (count == 0 && section == 0)
  {
    self.tableView.scrollEnabled = NO;
    self.tableView.bounces = NO;
    self.tableView.rowHeight = self.tableView.bounds.size.height;
    rows = 1;
  }
  else
  {
    NSUInteger numberOfSections = [_browseList countOfSections];
    NSUInteger sectionCount;

    if (!self.tableView.scrollEnabled)
    {
      self.tableView.scrollEnabled = YES;
      self.tableView.bounces = YES;
      self.tableView.rowHeight = _originalRowHeight;
    }
    
    if (_itemsPerRow < 2 || tableView.sectionHeaderHeight > 0)
      sectionCount = [_browseList countOfListInSection: section];
    else
    {
      // Multiple items per row and no section headers indicates that the
      // items from the end of one section should be run together with the
      // items of the next section.  Return a count of the length of the
      // current section that ensures that selecting the next section will
      // position the list for the first items of that section.

      // Absolute offset of start of this section
      sectionCount = [_browseList convertFromOffset: 0 inSection: section];
      if (sectionCount != NSUIntegerMax)
      {
        // Absolute offset of start of the next section
        NSUInteger nextIndex;
        
        if (section == numberOfSections - 1)
          nextIndex = (((count - 1) / _itemsPerRow) + 1) * _itemsPerRow;
        else
           nextIndex = [_browseList convertFromOffset: 0 inSection: section + 1];

        if (nextIndex == NSUIntegerMax)
          sectionCount = NSUIntegerMax;
        else
        {
          // Convert absolute index into a count of items in the section
          if (sectionCount > nextIndex)
            sectionCount = 0;
          else
            sectionCount = ((nextIndex / _itemsPerRow) - (sectionCount / _itemsPerRow)) * _itemsPerRow;
        }
      }
    }

    if (sectionCount == NSUIntegerMax)
      rows = _minimumRows;
    else
    {
      if (sectionCount == 0)
        rows = 0;
      else
        rows = ((NSInteger) sectionCount / _itemsPerRow);
    
      if (section == numberOfSections - 1)
      {
        NSInteger extra;

        if (count == 0 || count == NSUIntegerMax)
          extra = _minimumRows;
        else
          extra = _minimumRows - ((NSInteger) (count - 1) / _itemsPerRow) - 1;
      
        if (extra > 0)
          rows += extra;
      }
    }
  }
  
  //**/ NSLog( @"Number of rows in section %d: %d", section, rows );

  return rows;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  // Configure cell contents
  // Any row with children should show the disclosure indicator
  UITableViewCell *cell;
  
  if (self.tableView.scrollEnabled)
  {
    NSUInteger absoluteIndex = [_browseList convertFromOffset: indexPath.row * _itemsPerRow 
                                                    inSection: indexPath.section];
    
    if (tableView.sectionHeaderHeight == 0 && _itemsPerRow > 1)
      absoluteIndex = (absoluteIndex / _itemsPerRow) * _itemsPerRow;
    
    NSDictionary *item = (NSDictionary *) [_browseList itemAtIndex: absoluteIndex];
    NSString *children = [item objectForKey: @"children"];
    NSString *display2 = [item objectForKey: @"display2"];
    NSString *thumbnailURL = [item objectForKey: @"thumbnail"];
    BOOL selectable = [_browseList itemIsSelectableAtIndex: absoluteIndex];
    NSUInteger rowFeatures = (display2 == nil ? 0 : LIST_DATA_SECONDARY) | (thumbnailURL == nil ? 0 : LIST_DATA_IMAGE);
    NSUInteger oldListProperties = _listProperties;
    
    _listProperties |= rowFeatures;
    if (_listProperties != oldListProperties)
    {
      TableViewData *data = [_viewData objectAtIndex: g_currentDisplayOption];

      [self reportDisplayOptions];
      if (data != _currentViewData && 
          ((_listProperties & data.tableTemplate.tag) == (data.tableTemplate.tag & LIST_DATA_MASK)))
      {
        NSUInteger resetOption = g_currentDisplayOption;
        
        g_currentDisplayOption = NSUIntegerMax;
        [self setDisplayOption: resetOption];
      }
      [self performSelector: @selector(reloadData) withObject: nil afterDelay: 0.1];
    }
    if (indexPath.section > 0 || !_hasAllItemsEntries)
      rowFeatures = _listProperties;

    NSArray *rowTemplates = [_currentViewData.rowTemplates objectAtIndex: rowFeatures];
    NSUInteger rowTemplateCount = [rowTemplates count];
    NSUInteger rowType;

    if (rowTemplateCount == 1)
      rowType = 0;
    else 
      rowType = ((absoluteIndex - 1 / _itemsPerRow) + 1) % rowTemplateCount;
    
    UITableViewCell *rowTemplate = [rowTemplates objectAtIndex: rowType];
    TableViewItemIndices *indices = [[_currentViewData.rowOffsets objectAtIndex: rowFeatures] objectAtIndex: rowType];
    
    cell = [tableView dequeueReusableCellWithIdentifier: rowTemplate.reuseIdentifier];
    if (cell == nil)
      cell = [UncodableObjectUnarchiver unarchiveObjectWithDictionary: 
              [[_currentViewData.rowTemplateData objectAtIndex: rowFeatures] objectAtIndex: rowType]];
    
    cell.frame = CGRectMake( 0, 0, tableView.bounds.size.width, tableView.rowHeight );

    if (indices->_repeatItemOffset == NSNotFound)
    {
      // Single item row
      //**/NSLog( @"Section: %d row: %d", indexPath.section, indexPath.row );
      [self initialiseCellView: cell.contentView withIndices: indices rowIndex: absoluteIndex
                         title: [_browseList titleForItemAtIndex: absoluteIndex] 
                 secondaryText: display2 thumbnailURL: thumbnailURL cellTemplate: rowTemplate.contentView];

      if (selectable)
        cell.selectionStyle = rowTemplate.selectionStyle;
      else
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
      
      if (_hasSections || !selectable || children == nil || [children isEqualToString: @"0"])
      {
        cell.accessoryType = UITableViewCellAccessoryNone;
        if (cell.accessoryView != nil)
          cell.accessoryView.hidden = YES;
      }
      else
      {
        cell.accessoryType = rowTemplate.accessoryType;
        if (cell.accessoryView != nil)
          cell.accessoryView.hidden = NO;
      }
    }
    else
    {
      // Multi-item row
      NSArray *cellSubviews = [cell.contentView subviews];
      UIView *firstView = [[rowTemplate.contentView subviews] objectAtIndex: indices->_repeatItemOffset];
      NSInteger cellSubviewsCount = [cellSubviews count];
      NSInteger subIndex;
      NSInteger initialMargin = firstView.frame.origin.x;
      CGFloat step;
      NSUInteger sectionLimit;
      
      if (tableView.sectionHeaderHeight == 0 || indexPath.section == [_browseList countOfSections] - 1)
        sectionLimit = [_browseList countOfList];
      else
        sectionLimit = [_browseList convertFromOffset: 0 inSection: indexPath.section + 1];
 
      
      if ((firstView.autoresizingMask & UIViewAutoresizingFlexibleWidth) != 0)
      {
        step = (tableView.frame.size.width - (2 * initialMargin) - (_itemsPerRow * indices->_repeatItemWidth)) /
        _itemsPerRow;
        if (step < 0)
          step = 0;
        initialMargin += (NSInteger) (step / 2);
      }
      else if ((firstView.autoresizingMask & (UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin))
               == (UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin))
      {
        step = 0;
        initialMargin = (tableView.frame.size.width - (_itemsPerRow * indices->_repeatItemWidth)) / 2;
      }
      else if ((firstView.autoresizingMask & UIViewAutoresizingFlexibleLeftMargin) != 0)
      {
        step = 0;
        initialMargin = (tableView.frame.size.width - initialMargin - (_itemsPerRow * indices->_repeatItemWidth));
      }
      else if ((firstView.autoresizingMask & UIViewAutoresizingFlexibleRightMargin) != 0)
      {
        step = 0;
      }
      else
      {
        step = (tableView.frame.size.width - (2 * initialMargin) - (_itemsPerRow * indices->_repeatItemWidth)) /
        (_itemsPerRow - 1);
      }
      step += indices->_repeatItemWidth;
      
      //**/NSLog( @"SubMenu section: %d row: %d in table size: %fx%f", indexPath.section, indexPath.row, tableView.frame.size.width, tableView.frame.size.height );


      for (subIndex = 0; subIndex < _itemsPerRow; ++subIndex)
      {
        NSInteger offset = indices->_repeatItemOffset + subIndex;
        UIView *subCellTemplate = [[rowTemplate.contentView subviews] objectAtIndex: 
                                   indices->_repeatItemOffset + (subIndex % indices->_repeatItemCount)];
        UIView *subCell;
        NSInteger subCellTag;

        if (offset < cellSubviewsCount)
        {
          subCell = [cellSubviews objectAtIndex: offset];
          subCellTag = [subCell tag];
        }
        else
        {
          subCell = nil;
          subCellTag = 0;
        }

#if 0
        // We ought to be able to do this but it cocks up the alignment of the left-most cell on each row
        // for some reason.  Commented out until we can figure out why.
        if (subCellTag == subCellTemplate.tag)
        {
          //**/NSLog( @"SubMenu reusing sub-cell" );
        }
        else
#endif
        {
          NSDictionary *encoded = [UncodableObjectArchiver dictionaryEncodingWithRootObject: subCellTemplate];
          
          if (subCellTag >= 128 && subCellTag <= 131)
            [subCell removeFromSuperview];
          subCell = [UncodableObjectUnarchiver unarchiveObjectWithDictionary: encoded];
          [cell.contentView insertSubview: subCell atIndex: offset];
          //**/NSLog( @"SubMenu allocating new sub-cell" );
        }
        
        [self initialiseCellView: subCell withIndices: indices rowIndex: absoluteIndex + subIndex
                           title: [_browseList titleForItemAtIndex: absoluteIndex + subIndex] 
                   secondaryText: display2 thumbnailURL: thumbnailURL cellTemplate: subCellTemplate];
        //subCell.autoresizingMask = (subCell.autoresizingMask & ~UIViewAutoresizingFlexibleWidth);
        subCell.autoresizingMask = 0;
        subCell.frame = CGRectMake( initialMargin + (NSInteger) ((subIndex * step * 10 + 5) / 10),
                                   subCell.frame.origin.y, subCell.frame.size.width, subCell.frame.size.height );
        //**/NSLog( @"SubCell title: %@, x: %f", [_browseList titleForItemAtIndex: absoluteIndex + subIndex], subCell.frame.origin.x );
        
        if (absoluteIndex + subIndex + 1 >= sectionLimit)
        {
          ++subIndex;
          break;
        }
        else 
        {
          item = (NSDictionary *) [_browseList itemAtIndex: absoluteIndex + subIndex + 1];
          //children = [item objectForKey: @"children"];
          display2 = [item objectForKey: @"display2"];
          thumbnailURL = [item objectForKey: @"thumbnail"];
          //selectable = [_browseList itemIsSelectableAtIndex: absoluteIndex + subIndex + 1];
          rowFeatures = (display2 == nil ? 0 : 1) | (thumbnailURL == nil ? 0 : 2);
          rowTemplates = [_currentViewData.rowTemplates objectAtIndex: rowFeatures];
          rowTemplateCount = [rowTemplates count];
          
          if (rowTemplateCount == 1)
            rowType = 0;
          else 
            rowType = ((absoluteIndex + subIndex / _itemsPerRow) + 1) % rowTemplateCount;
          
          rowTemplate = [rowTemplates objectAtIndex: rowType];
          indices = [[_currentViewData.rowOffsets objectAtIndex: rowFeatures] objectAtIndex: rowType];
        }

      }
      
      while (true)
      {
        NSInteger offset = indices->_repeatItemOffset + subIndex;
        UIView *subCell;
        
        cellSubviews = [cell.contentView subviews];
        if (offset < [cellSubviews count])
          subCell = [cellSubviews objectAtIndex: offset];
        else
          break;
        if ([subCell tag] < 128 || [subCell tag] > 131)
          break;
        else
        {
          //**/NSLog( @"SubMenu removing unwanted sub-cell" );
          [subCell removeFromSuperview];
        }
      }

      cell.accessoryType = UITableViewCellAccessoryNone;
      if (cell.accessoryView != nil)
        cell.accessoryView.hidden = YES;
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }    
  }
  else
  {
    NSString *itemType = _browseList.itemType;
    
    cell = [tableView dequeueReusableCellWithIdentifier: @"MyNoItemsIdentifier"];
    if (cell == nil)
      cell = [[[UITableViewCell alloc] initDefaultWithFrame: CGRectZero
                                                  reuseIdentifier: @"MyNoItemsIdentifier"] autorelease];
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
    noItemsView.frame = self.tableView.bounds;
    cell.frame = self.tableView.bounds;
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
  
  if (childSource == _browseList || childSource == nil)
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
  else
  {
    MediaSubMenuViewController *subController = [[MediaSubMenuViewController alloc]
                                                 initWithNibName: @"MediaSubMenuViewController" bundle: nil];
    subController.browseList = childSource;
    subController.title = [childSource listTitle];
    subController.displayOptionsDelegate = _displayOptionsDelegate;
    [subController setDisplayOption: g_currentDisplayOption];

    [self.navigationController pushViewController: subController animated: YES];
    [subController release];
  }
}

- (NSIndexPath *) tableView: (UITableView *) tableView willSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  if (_itemsPerRow < 2 && [_browseList itemIsSelectableAtOffset: indexPath.row inSection: indexPath.section])
    return indexPath;
  else
    return nil;
}

- (void) itemsChangedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [self handleBrowseListChanged];
}

- (void) itemsInsertedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [self handleBrowseListChanged];
}

- (void) itemsRemovedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [self handleBrowseListChanged];
}

- (void) listDataRefreshDidEnd: (id<ListDataSource>) listDataSource
{
  _hasSections = NO;
  [self handleBrowseListChanged];
}

- (void) handleBrowseListChanged
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = _active && [_browseList dataPending];
  
  NSArray *indexPaths = [self.tableView indexPathsForVisibleRows];
  NSIndexPath *index = nil;
  
  if ([indexPaths count] > 0 && !self.tableView.dragging && !self.tableView.decelerating)
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
  
  [self reloadData];
  if (index != nil)
  {
    // Despite our best efforts, the table reload can sometimes invalidate the index, so
    // be prepared to catch an argument exception
    @try
    {
      [self.tableView scrollToRowAtIndexPath: index atScrollPosition: UITableViewScrollPositionTop animated: NO];
    }
    @catch (id exception)
    {
      // Ignore
    }
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
                                                                selector: @selector(thumbnailRefreshTimerFired:)
                                                                userInfo: nil repeats: NO];
      }
    }
  }
  
  if (!ok)
  {
    [connection cancel];
    [_pendingConnections removeObjectForKey: connection];
    if (reload)
      [self reloadData];
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
    [self reloadData];
}

- (void) connectionDidFinishLoading: (NSURLConnection *) connection
{
  NSString *key = [_pendingConnections objectForKey: connection];
  NSData *data = [g_cachedResponses objectForKey: key];
  id thumbnail;
  
  [g_unavailableURLs removeObject: key];
  
  // If no data, keep the empty data object to prevent us re-fetching it.  This will
  // result in the corresponding table item showing whatever the row template has
  // defined as the default image

  if ([data length] == 0)
    thumbnail = data;
  else
    thumbnail = [UIImage imageWithData: data];

  [g_cachedResponses setObject: thumbnail forKey: key];
  [_pendingConnections removeObjectForKey: connection];
  if ([_pendingConnections count] % 16 == 0)
    [self reloadData];
}

- (void) thumbnailRefreshTimerFired: (NSTimer *) timer
{
  _thumbnailRefreshTimer = nil;
  [self reloadData];
}

- (void) initialiseCellView: (UIView *) cellView withIndices: (TableViewItemIndices *) indices
                   rowIndex: (NSInteger) rowIndex title: (NSString *) title secondaryText: (NSString *) secondaryText
               thumbnailURL: (NSString *) thumbnailURL cellTemplate: (UIView *) cellTemplate
{
  //**/NSLog( @"InitialiseCellView, indices: %@, rowIndex: %d, title: %@, 2nd text: %@, URL: %@",
  //**/      nil/*indices*/, rowIndex, title, secondaryText, thumbnailURL );

  if (indices->_imageOffset != NSNotFound)
  {
    UIImageView *imageView = (UIImageView *) [[cellView subviews] objectAtIndex: indices->_imageOffset];
    
    if (thumbnailURL == nil)
      imageView.hidden = YES;
    else
    {
      id cachedResponse = [g_cachedResponses objectForKey: thumbnailURL];
      UIImage *thumbnail;
      
      if ([cachedResponse isKindOfClass: [UIImage class]])
        thumbnail = cachedResponse;
      else
      {
        thumbnail = [(UIImageView *)[[cellTemplate subviews] objectAtIndex: indices->_imageOffset] image];
        if (thumbnail == nil)
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
      
      imageView.hidden = NO;
      imageView.image = thumbnail;
    }
  }
  
  if (indices->_secondaryOffset != NSNotFound)
  {
    UILabel *secondView = (UILabel *) [[cellView subviews] objectAtIndex: indices->_secondaryOffset];
    
    if ([secondaryText length] == 0)
      secondView.hidden = YES;
    else 
    {
      secondView.hidden = NO;
      secondView.text = secondaryText;
    }
  }
  
  if (indices->_titleOffset != NSNotFound)
  {
    UILabel *titleView = (UILabel *) [[cellView subviews] objectAtIndex: indices->_titleOffset];
    
    titleView.text = title;
  }
  
  if (indices->_buttonOffset != NSNotFound)
  {
    UIButton *button = (UIButton *) [[cellView subviews] objectAtIndex: indices->_buttonOffset];

    [button addTarget: self action: @selector(selectedRowItem:) forControlEvents: UIControlEventTouchUpInside];
    button.tag = rowIndex;
  }
}

- (void) calculateRowConstants
{
  if ((_currentViewData.tableTemplate.tag & LIST_DATA_REPEAT_ROWS) == 0)
    _minimumRows = 1;
  else
    _minimumRows = (NSInteger) (self.tableView.frame.size.height / _currentViewData.tableTemplate.rowHeight) + 1;

  if (_currentViewData.maxRepeatItemWidth == 0)
    _itemsPerRow = 1;
  else
  {
    NSInteger itemsPerRow = (NSInteger) ((self.tableView.bounds.size.width  - (2 * _currentViewData.maxRepeatItemMargin)) /
                                         _currentViewData.maxRepeatItemWidth);
    if (itemsPerRow <= 0)
      _itemsPerRow = 1;
    else
      _itemsPerRow = itemsPerRow;
  }
  //**/NSLog( @"SubMenu tableSize: %fx%f, itemWidth: %f, itemMargin: %f, minimumRows: %d, itemsPerRow: %d", self.tableView.frame.size.width, self.tableView.frame.size.height,  _currentViewData.maxRepeatItemWidth, _currentViewData.maxRepeatItemMargin, _minimumRows, _itemsPerRow );
}

- (void) reportDisplayOptions
{
  NSUInteger count = [_viewData count];
  NSMutableArray *options = [NSMutableArray arrayWithCapacity: count];
  
  for (NSUInteger i = 0; i < count; ++i)
  {
    TableViewData *data = [_viewData objectAtIndex: i];

    data.nameButton.enabled = ((_listProperties & data.tableTemplate.tag) == (data.tableTemplate.tag & LIST_DATA_MASK));
    [options addObject: data.nameButton];
  }

  [_displayOptionsDelegate subMenu: self hasDisplayOptions: options];
  [_displayOptionsDelegate subMenu: self didChangeToDisplayOption: g_currentDisplayOption];
}

- (void) reloadData
{
  //**/NSLog( @"SubMenu reloadData" );
  [self calculateRowConstants];
  [self.tableView reloadData];
}

- (void) dealloc
{
#if TRACE_RETAIN
  NSLog( @"%@ dealloc\n%@", self, [self stackTraceToDepth: 10] );
#endif
  NSEnumerator *connectionEnum = [_pendingConnections keyEnumerator];
  NSURLConnection *connection;
  
  [_viewTemplates release];
  self.tableView.delegate = nil;
  self.tableView.dataSource = nil;
  [_thumbnailRefreshTimer invalidate];
  [_browseList release];
  while ((connection = [connectionEnum nextObject]) != nil)
    [connection cancel];
  [_pendingConnections release];
  [super dealloc];
}

@end

