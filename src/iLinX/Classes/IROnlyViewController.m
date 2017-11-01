//
//  IROnlyViewController.m
//  iLinX
//
//  Created by mcf on 24/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "IROnlyViewController.h"
#import "IROnlyListViewController.h"
#import "IROnlyPageViewController.h"
#import "MainNavigationController.h"
#import "NLBrowseList.h"
#import "NLSourceIROnly.h"
#import "OS4ToolbarFix.h"
#import "StandardPalette.h"

static NSDictionary *VIEW_DATA = nil;
static NSString * const kEnableSkinKey = @"enableSkinKey";

@interface IROnlyViewController ()

- (void) segmentChanged: (UISegmentedControl *) control;

@end

@implementation IROnlyViewController

- initWithRoomList: (NLRoomList *) roomList service: (NLService *) service source: (NLSource *) source
{
  BOOL bSkinsEnabled = [[NSUserDefaults standardUserDefaults] boolForKey: kEnableSkinKey];
  // Should we use simplified views? Yes if skins enabled and ironlyconfig.xml is present.
  BOOL bSimplifed = bSkinsEnabled;
  
  if (bSkinsEnabled)
  {
    // Yes, so check for presence of xml file (Just presence at this point, rather than parsing it)
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString *documentsDirectory = [paths objectAtIndex: 0];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *sCheckFile = [documentsDirectory stringByAppendingFormat: @"/unpacked/ironlyconfig.xml"];

    bSimplifed = [fm fileExistsAtPath: sCheckFile];
  }
  
  //bSimplifed = true; NSLog(@"#### Hard-coded to always use simplified views, due to there currently being no way to get here before ");
  //NSLog(@"#### IROnlyViewController/initWithRoomList: sourceType = %@, skins enabled = %i, simplified = %i", source.sourceType, bSkinsEnabled, bSimplifed);

  if (self = [super initWithRoomList: roomList service: service source: source])
  {
    // Convenience cast
    _irOnlySource = (NLSourceIROnly *) [source retain];
    // Already initialised?
    if (VIEW_DATA == nil)
    {
      // No, so initialiase...
      // Are we using simplified views?
      if (bSimplifed)
      {
        // Yes, simplified
        VIEW_DATA = [[NSDictionary dictionaryWithObjectsAndKeys:
                      [NSArray arrayWithObjects: 
                      NSLocalizedString( @"CD", @"Title of CD view" ),
                      [NSArray arrayWithObjects: 
//                       NSLocalizedString( @"Navigation", @"Name of AppleTV view" ), 
                       nil],
                      [NSArray arrayWithObjects: @"AppleTVView", nil], nil], @"TRNSPRT",
                       [NSArray arrayWithObjects: 
                       NSLocalizedString( @"DVD", @"Title of DVD view" ),
                       [NSArray arrayWithObjects: 
                        NSLocalizedString( @"Navigation", @"Name of DVD navigation view" ), 
                        NSLocalizedString( @"Keypad", @"Name of DVD keypad view" ), 
                        NSLocalizedString( @"Misc", @"Name of DVD Misc view" ), nil],
                       [NSArray arrayWithObjects: @"DVDViewNavigation", @"DVDViewKeypad", @"DVDViewMisc", nil], nil], @"DVD",
                      [NSArray arrayWithObjects: 
                       NSLocalizedString( @"DVR", @"Title of DVR view" ),
                       [NSArray arrayWithObjects: 
                        NSLocalizedString( @"Navigation", @"Name of DVR simple navigation view" ), 
                        NSLocalizedString( @"Keypad", @"Name of DVR simple keypad view" ), 
                        NSLocalizedString( @"DVR", @"Name of DVR simple DVR view" ), nil],
                       [NSArray arrayWithObjects: @"DVRViewSimpleNavigation", @"DVRViewSimpleKeypad", @"DVRViewSimpleDVR", nil], nil], @"PVR",
                      nil] retain];
      }
      else
      {
        // No, not simplified
        VIEW_DATA = [[NSDictionary dictionaryWithObjectsAndKeys:
                      [NSArray arrayWithObjects: 
                       NSLocalizedString( @"CD", @"Title of CD view" ),
                       [NSArray arrayWithObjects: 
                        NSLocalizedString( @"Keypad", @"Name of CD keypad view" ), 
                        NSLocalizedString( @"Misc", @"Name of CD Misc view" ),
                        nil],
                       [NSArray arrayWithObjects: @"CDViewKeypad", @"CDViewMisc", nil], nil], @"TRNSPRT",
                      [NSArray arrayWithObjects: 
                       NSLocalizedString( @"DVD", @"Title of DVD view" ),
                       [NSArray arrayWithObjects: 
                        NSLocalizedString( @"Navigation", @"Name of DVD navigation view" ), 
                        NSLocalizedString( @"Keypad", @"Name of DVD keypad view" ), 
                        NSLocalizedString( @"Misc", @"Name of DVD Misc view" ), nil],
                       [NSArray arrayWithObjects: @"DVDViewNavigation", @"DVDViewKeypad", @"DVDViewMisc", nil], nil], @"DVD",
                      [NSArray arrayWithObjects: 
                       NSLocalizedString( @"DVR", @"Title of DVR view" ),
                       [NSArray arrayWithObjects: 
                        NSLocalizedString( @"Navigation", @"Name of DVR navigation view" ), 
                        NSLocalizedString( @"Keypad", @"Name of DVR keypad view" ), nil],
                       [NSArray arrayWithObjects: @"DVRViewNavigation", @"DVRViewKeypad", nil], nil], @"PVR",
                      nil] retain];
      }
    }
  }
  return self;
}

- (void) loadView
{
  [super loadView];
  
  CGRect contentBounds = self.view.bounds;
  CGFloat toolBarHeight = _toolBar.frame.size.height;
  NSArray *viewData = [VIEW_DATA objectForKey: _irOnlySource.sourceControlType];
  NSArray *viewNames = [viewData objectAtIndex: 1];
  NSArray *viewTypes = [viewData objectAtIndex: 2];
  NSUInteger count = [viewTypes count];
  NSMutableArray *subViews = [NSMutableArray arrayWithCapacity: count];
  NSUInteger i;
  UIImageView *backdrop = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"BackdropDark.png"]];
  
  self.title = _source.displayName;
  [self.view insertSubview: backdrop belowSubview: _toolBar];
  [backdrop release];

  for (i = 0; i < count; ++i)
  {
    IROnlyPageViewController *pageController = [[IROnlyPageViewController alloc] 
                                                initWithNibName: [viewTypes objectAtIndex: i] irOnlySource: _irOnlySource];
    
    pageController.view.frame = CGRectOffset( pageController.view.frame, 0, toolBarHeight - 1 );
    [self.view insertSubview: pageController.view belowSubview: _toolBar];
    if (i != 0)
      pageController.view.hidden = YES;
    [subViews addObject: pageController];
    [pageController release];
  }
  
  _subViews = [[NSArray arrayWithArray: subViews] retain];
  
  if ([viewNames count]) {
    _segmentedSelector = [[UISegmentedControl alloc] initWithItems: viewNames];
    _segmentedSelector.segmentedControlStyle = UISegmentedControlStyleBar;
    _segmentedSelector.tintColor = [UIColor colorWithWhite: 0.25 alpha: 1.0];
    _segmentedSelector.selectedSegmentIndex = 0;
    _currentSegment = 0;
    [_segmentedSelector sizeToFit];
    _segmentedSelector.frame = CGRectMake( 0, 0, contentBounds.size.width - 20, _segmentedSelector.frame.size.height );
    [_segmentedSelector addTarget: self action: @selector(segmentChanged:) forControlEvents: UIControlEventValueChanged];
    
    _controlBar = [[UIToolbar alloc] initWithFrame: CGRectMake( 0, CGRectGetMaxY( contentBounds ) - (toolBarHeight * 3),
                                                               CGRectGetWidth( contentBounds ), toolBarHeight)];
    _controlBar.items = [NSArray arrayWithObjects: 
                         [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target: nil action: nil] autorelease],
                         [[[UIBarButtonItem alloc] initWithCustomView: _segmentedSelector] autorelease],
                         [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target: nil action: nil] autorelease],
                         nil];
    _controlBar.barStyle = UIBarStyleBlackOpaque;
    [self.view addSubview: _controlBar];
  }
}

- (void) viewWillAppear: (BOOL) animated
{
  MainNavigationController *mainController = (MainNavigationController *) self.navigationController;
  
  [super viewWillAppear: animated];
  
  mainController.navigationBar.barStyle = UIBarStyleBlackOpaque;
  mainController.navigationBar.tintColor = nil;
  [mainController setAudioControlsStyle: UIBarStyleBlackOpaque];
  [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque animated: YES];
  [[_subViews objectAtIndex: _currentSegment] viewWillAppear: animated];
  [_irOnlySource addDelegate: self];
  [self irOnlySource: _irOnlySource changed: 0xFFFFFFFF];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  
  if (_location != nil && _service != nil)
  {
    [(MainNavigationController *) self.navigationController showAudioControls: YES];
    [[_subViews objectAtIndex: _currentSegment] viewDidAppear: animated];
  }
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_irOnlySource removeDelegate: self];
  [[_subViews objectAtIndex: _currentSegment] viewWillDisappear: animated];
  [super viewWillDisappear: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
  [[_subViews objectAtIndex: _currentSegment] viewDidDisappear: animated];
  [super viewDidDisappear: animated];
}

- (void) segmentChanged: (UISegmentedControl *) control
{
  UIViewController *disappearing = [_subViews objectAtIndex: _currentSegment];
  UIViewController *appearing = [_subViews objectAtIndex: control.selectedSegmentIndex];
  
  [disappearing viewWillDisappear: NO];
  [appearing viewWillAppear: NO];
  disappearing.view.hidden = YES;
  appearing.view.hidden = NO;
  [disappearing viewDidDisappear: NO];
  [appearing viewDidAppear: NO];
  _currentSegment = control.selectedSegmentIndex;
}

- (void) irOnlySource: (NLSourceIROnly *) irOnlySource changed: (NSUInteger) changed
{
  if ((changed & SOURCE_IRONLY_PRESETS_CHANGED) != 0)
  {
    NLBrowseList *presets = irOnlySource.presets;
    
    if (presets != nil && ![[_subViews lastObject] isKindOfClass: [IROnlyListViewController class]])
    {
      IROnlyListViewController *presetsController = [[IROnlyListViewController alloc] initWithPresets: presets];
      NSMutableArray *subViews = [_subViews mutableCopy];
      
      presetsController.view.hidden = YES;
      presetsController.view.frame = CGRectMake( 0, self.view.bounds.origin.y + _toolBar.frame.size.height - 1, self.view.bounds.size.width,
                                                self.view.bounds.size.height - (3 * _toolBar.frame.size.height) + 1 );
      [self.view insertSubview: presetsController.view belowSubview: _toolBar];
      [subViews addObject: presetsController];
      [presetsController release];
      [_subViews release];
      _subViews = [[NSArray arrayWithArray: subViews] retain]; 
      [subViews release];
      [_segmentedSelector insertSegmentWithTitle: [presets listTitle] 
                                         atIndex: [_segmentedSelector numberOfSegments] animated: YES];
    }
  }
}

- (void) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags
{
  [super renderer: renderer stateChanged: flags];
  
  if ((flags & NLRENDERER_AUDIO_SESSION_CHANGED) != 0)
  {
    if (renderer.audioSessionActive)
    {
      _segmentedSelector.tintColor = [StandardPalette multizoneTintColour];
      [_controlBar fixedSetTint: [StandardPalette multizoneTintColour]];
    }
    else
    {
      _segmentedSelector.tintColor = [UIColor colorWithWhite: 0.25 alpha: 1.0];
      [_controlBar fixedSetTint: nil];
    }
  }
}

- (void) dealloc
{
  [_subViews release];
  [_segmentedSelector release];
  [_controlBar release];
  [super dealloc];
}

@end
