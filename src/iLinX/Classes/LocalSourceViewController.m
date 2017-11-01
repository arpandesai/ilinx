//
//  LocalSourceViewController.m
//  iLinX
//
//  Created by mcf on 17/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "LocalSourceViewController.h"
#import "CustomLightButtonHelper.h"
#import "DeprecationHelper.h"
#import "ListDataSource.h"
#import "MainNavigationController.h"
#import "XIBViewController.h"

@interface LocalSourceViewController ()

- (void) configurePresets;
- (void) buttonPushed: (UIButton *) button;

@end

@interface ChangeHandler : NSObject <ListDataDelegate>
{
@private
  LocalSourceViewController *_controller;
}

- (id) initWithController: (LocalSourceViewController *) controller;
- (void) registerWithList: (id<ListDataSource>) list;
- (void) deregisterFromList: (id<ListDataSource>) list;

@end

@implementation ChangeHandler
- (id) initWithController: (LocalSourceViewController *) controller
{
  if (self = [super init])
    _controller = controller;
  return self;
}

- (void) registerWithList: (id<ListDataSource>) list
{
  [list addDelegate: self];
}

- (void) deregisterFromList: (id<ListDataSource>) list
{
  [list removeDelegate: self];
}

- (void) itemsInsertedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [_controller configurePresets];
}

- (void) itemsChangedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [_controller configurePresets];
}

- (void) itemsRemovedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [_controller configurePresets];
}

- (void) currentItemForListData: (id<ListDataSource>) listDataSource
                    changedFrom: (id) old to: (id) new at: (NSUInteger) index
{
  [_controller configurePresets];
}

@end

@implementation LocalSourceViewController

- initWithRoomList: (NLRoomList *) roomList service: (NLService *) service source: (NLSource *) source
{
  if ((self = [super initWithRoomList: roomList service: service source: source]) != nil)
  {    
    // Cast here as a convenience to avoid having to cast every time its used
    _localSource = (NLSourceLocal *) source;
    _changeHandler = [[ChangeHandler alloc] initWithController: self];
  }
  
  return self;
}

- (void) loadView
{
  [super loadView];
  
  self.title = NSLocalizedString( @"Local Source", @"Title of local source view" );
  self.view.backgroundColor = [UIColor blackColor];
  _toolBar.barStyle = UIBarStyleBlackOpaque;
  _toolBar.alpha = 0.7;

  UIImageView *imageView = [UIImageView new];
  
  if (_localSource.isNaimAmp)
    imageView.image = [UIImage imageNamed: @"LocalSourceNaim.png"];
  else
    imageView.image = [UIImage imageNamed: @"LocalSource.png"];
  [imageView sizeToFit];
  [self.view insertSubview: imageView belowSubview: _toolBar];
  [imageView release];
  
  if ([_source.sourceControlType isEqualToString: @"LOCALSOURCE-STREAM"])
  {
    UIFont *labelFont = [UIFont italicSystemFontOfSize: 20]; 
    UILabel *streamingLabel = [[UILabel alloc]
                               initWithFrame: CGRectMake( CGRectGetMinX( self.view.frame ) + 10, _toolBar.frame.size.height + 300,
                                                         CGRectGetWidth( self.view.frame ) - 20, 
                                                         [labelFont lineSpacing] + 2 )];
    
    streamingLabel.font = labelFont;
    streamingLabel.text = NSLocalizedString( @"Streaming", @"Label shown when a local source makes its audio available as a stream" );
    streamingLabel.backgroundColor = [UIColor clearColor];
    streamingLabel.textColor = [UIColor lightGrayColor];
    streamingLabel.shadowColor = [UIColor blackColor];
    streamingLabel.shadowOffset = CGSizeMake( 1, 1 );
    streamingLabel.textAlignment = UITextAlignmentRight;
    [self.view addSubview: streamingLabel];
    [streamingLabel release];
  }
  
  NSUInteger i;
  
  _presetButtons = [[NSMutableArray arrayWithCapacity: 8] retain];
  for (i = 0; i < 8; ++i)
  {
    CustomLightButtonHelper *helper = [CustomLightButtonHelper new];
    UIButton *button = helper.button;
    
    button.frame = CGRectMake( 10 + 155 * (i % 2), _toolBar.frame.size.height + 10 + 70 * (i / 2), 145, 60 );
    [button addTarget: self action: @selector(buttonPushed:) forControlEvents: UIControlEventTouchDown];
    [button setTitleLabelFont: [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]]];
    button.tag = i;
    button.hidden = YES;
    [XIBViewController setFontForControl: button];
    [self.view addSubview: button];
    helper.hasIndicator = YES;
    [_presetButtons addObject: helper];
    [helper release];
  }
}

- (void) viewWillAppear: (BOOL) animated
{
  MainNavigationController *mainController = (MainNavigationController *) self.navigationController;
  
  [super viewWillAppear: animated];
  mainController.navigationBar.barStyle = UIBarStyleBlackOpaque;
  mainController.navigationBar.tintColor = nil;
  [mainController setAudioControlsStyle: UIBarStyleBlackTranslucent];
  [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque animated: YES];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  
  if (_location != nil && _service != nil)
  {
    [self configurePresets];
    [_changeHandler registerWithList: _localSource.presets];
    [_localSource addDelegate: self];
    [(MainNavigationController *) self.navigationController showAudioControls: YES];
  }
}

- (void) viewDidDisappear: (BOOL) animated
{
  [_localSource removeDelegate: self];
  [_changeHandler deregisterFromList: _localSource.presets];
  [super viewDidDisappear: animated];
}

- (void) source: (NLSourceLocal *) source stateChanged: (NSUInteger) flags
{
  [self configurePresets];
}

- (void) configurePresets
{
  NSUInteger count = [_localSource.presets countOfList];
  NSUInteger currentItem = _localSource.currentPreset;
  NSUInteger i = 0;
  if (count < NSUIntegerMax)
  {
    if (count > [_presetButtons count])
      count = [_presetButtons count];
    
    for ( ; i < count; ++i)
    {
      CustomLightButtonHelper *helper = (CustomLightButtonHelper *) [_presetButtons objectAtIndex: i];
      UIButton *button = helper.button;
      
      [button setTitle: [_localSource.presets titleForItemAtIndex: i] forState: UIControlStateNormal];
      button.hidden = NO;
      helper.indicatorState = (i == currentItem);
    }
  }
  for ( ; i < [_presetButtons count]; ++i)
    ((CustomLightButtonHelper *) [_presetButtons objectAtIndex: i]).button.hidden = YES;
}

- (void) buttonPushed: (UIButton *) button
{
  [_localSource.presets selectItemAtIndex: button.tag];
}

- (void) dealloc
{
  [_presetButtons release];
  [_changeHandler release];
  [super dealloc];
}

@end
