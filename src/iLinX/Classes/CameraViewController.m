//
//  CameraViewController.m
//  iLinX
//
//  Created by mcf on 29/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "ButtonBar.h"
#import "CameraViewController.h"
#import "CameraControlsViewController.h"
#import "ChangeSelectionHelper.h"
#import "MainNavigationController.h"
#import "NLCamera.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLServiceCameras.h"
#import "OS4ToolbarFix.h"
#import "RotatableViewControllerProtocol.h"

// Number of seconds between image transitions in the slideshow
#define SLIDESHOW_INTERVAL 3

// Preferences key for last used camera view (1 or 4)
static NSString *kShowFourCamerasPrefKey = @"CameraViewShowFourCamerasPref";

@interface CameraViewController ()

- (void) selectCamera: (id) button;
- (void) pressedControls: (id) button;
- (void) pressedNext: (id) button;
- (void) pressedPrevious: (id) button;
- (void) pressedPlay: (UIButton *) button;
- (void) tappedImage: (UIButton *) button withEvent: (UIEvent *) event;
- (void) slideshowTimerFired: (NSTimer *) timer;
- (void) deregisterCamerasFromIndex: (NSUInteger) index;
- (void) setCurrentCamera;
- (void) setSlideshowControlsEnabled: (BOOL) enabled;
- (void) toggleCameraView: (id) button;
- (void) setFourCameraView: (BOOL) on;
- (void) prepareForOrientation: (UIInterfaceOrientation) orientation;

@end

@implementation CameraViewController

- initWithRoomList: (NLRoomList *) roomList service: (NLService *) service
{
  if (self = [super initWithRoomList: roomList service: service])
  {
    // Convenience cast here
    _cameras = (NLServiceCameras *) service;
  }
  
  return self;
}

- (void) loadView
{
  [super loadView];
  _portraitView = [self.view retain];
  
  CGRect contentBounds = _portraitView.bounds;
  
  NSString *button2Title;
  id button2Target;
  SEL button2Selector;

  if (_cameras.cameraCount == 0)
  {
    button2Title = nil;
    button2Target = nil;
    button2Selector = nil;
  }
  else
  {
    button2Title = [_cameras cameraAtIndex: 0].displayName;
    button2Target = self;
    button2Selector = @selector(selectCamera:);
  }
  
  _topBar = [[ChangeSelectionHelper
             addToolbarToView: self.view
             withTitle: _roomList.currentRoom.displayName target: self selector: @selector(selectLocation:)
             title: button2Title target: button2Target selector: button2Selector] retain];

  CGFloat toolBarHeight = _topBar.frame.size.height;
  CGFloat fontSize = [UIFont smallSystemFontSize] + 4;
  NSUInteger i;
    
  [_topBar fixedSetStyle: UIBarStyleBlackOpaque tint: nil];
  _topBar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;

  if (button2Title != nil)
    _cameraSelectButton = [_topBar.items objectAtIndex: 1];
 
  _imageArea = [[UIView alloc] initWithFrame: 
                     CGRectMake( contentBounds.origin.x,
                                contentBounds.origin.y + toolBarHeight - 1, 
                                contentBounds.size.width, contentBounds.size.height - (toolBarHeight * 2) + 1 )];
  _imageArea.backgroundColor = [UIColor blackColor];
  _imageArea.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  [_portraitView insertSubview: _imageArea belowSubview: _topBar];

  _currentFullImage = [[UIImageView alloc] initWithFrame: CGRectMake( 0, 0, 320, 240 )];
  _currentFullImage.backgroundColor = [UIColor blackColor];
  [_imageArea addSubview: _currentFullImage];

  _currentFullTitle = [UILabel new];
  _currentFullTitle.font = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]];
  _currentFullTitle.textColor = [UIColor whiteColor];
  _currentFullTitle.shadowColor = [UIColor darkGrayColor];
  _currentFullTitle.backgroundColor = [UIColor clearColor];
  _currentFullTitle.textAlignment = UITextAlignmentCenter;
  _currentFullTitle.frame = CGRectMake( 0, 240, _imageArea.bounds.size.width, fontSize );
  [_imageArea addSubview: _currentFullTitle];

  _fourImagesView = [[UIView alloc] initWithFrame: 
                     CGRectMake( 0, 0, 320, 240 + (2 * fontSize) )];
  _fourImagesView.backgroundColor = [UIColor blackColor];
  _fourImagesView.hidden = YES;
  [_imageArea addSubview: _fourImagesView];

  _fourImages = [[NSArray arrayWithObjects:
                 [[[UIImageView alloc] initWithFrame: CGRectMake( 0, 0, 160, 120 )] autorelease],
                 [[[UIImageView alloc] initWithFrame: CGRectMake( 160, 0, 160, 120 )] autorelease],
                 [[[UIImageView alloc] initWithFrame: CGRectMake( 0, 120 + fontSize, 160, 120 )] autorelease],
                 [[[UIImageView alloc] initWithFrame: CGRectMake( 160, 120 + fontSize, 160, 120 )] autorelease],
                  nil] retain];
  _fourTitles = [[NSArray arrayWithObjects:
                 [[[UILabel alloc] initWithFrame: CGRectMake( 2, 120, 156, fontSize )] autorelease],
                 [[[UILabel alloc] initWithFrame: CGRectMake( 162, 120, 156, fontSize )] autorelease],
                 [[[UILabel alloc] initWithFrame: CGRectMake( 2, 240 + fontSize, 156, fontSize )] autorelease],
                 [[[UILabel alloc] initWithFrame: CGRectMake( 162, 240 + fontSize, 156, fontSize )] autorelease],
                  nil] retain];
  
  for (i = 0; i < 4; ++i)
  {
    UIImageView *imageView = [_fourImages objectAtIndex: i];
    UILabel *label = [_fourTitles objectAtIndex: i];

    [_fourImagesView insertSubview: imageView atIndex: 0];
    [_fourImagesView addSubview: label];
    label.font = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]];
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor darkGrayColor];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = UITextAlignmentCenter;
  }

  if (_cameras.cameraCount != 0)
  {
    _tappedImage = [[UIButton buttonWithType: UIButtonTypeCustom] retain];
    
    _tappedImage.frame = _fourImagesView.frame;
    _tappedImage.backgroundColor = [UIColor clearColor];
    [_tappedImage addTarget: self action: @selector(tappedImage:withEvent:) forControlEvents: UIControlEventTouchDown];
    [_imageArea addSubview: _tappedImage];
    _controlsOverlay = [[CameraControlsViewController alloc] initWithCamera: [_cameras cameraAtIndex: 0]];
  }
  
  UIButton *controls = [UIButton buttonWithType: UIButtonTypeCustom];
  UIButton *back = [UIButton buttonWithType: UIButtonTypeCustom];
  UIButton *play = [UIButton buttonWithType: UIButtonTypeCustom];
  UIButton *next = [UIButton buttonWithType: UIButtonTypeCustom];
  
  _cameraViewButton = [[UIButton buttonWithType: UIButtonTypeCustom] retain];
  
  [controls addTarget: self action: @selector(pressedControls:) forControlEvents: UIControlEventTouchDown];
  [controls setImage: [UIImage imageNamed: @"SmallControls.png"] forState: UIControlStateNormal];
  controls.showsTouchWhenHighlighted = YES;

  [back addTarget: self action: @selector(pressedPrevious:) forControlEvents: UIControlEventTouchDown];
  [back setImage: [UIImage imageNamed: @"LeftArrow.png"] forState: UIControlStateNormal];
  back.showsTouchWhenHighlighted = YES;

  [play addTarget: self action: @selector(pressedPlay:) forControlEvents: UIControlEventTouchDown];
  [play setImage: [UIImage imageNamed: @"SmallPlay.png"] forState: UIControlStateNormal];
  play.showsTouchWhenHighlighted = YES;

  [next addTarget: self action: @selector(pressedNext:) forControlEvents: UIControlEventTouchDown];
  [next setImage: [UIImage imageNamed: @"RightArrow.png"] forState: UIControlStateNormal];
  next.showsTouchWhenHighlighted = YES;

  [_cameraViewButton addTarget: self action: @selector(toggleCameraView:) forControlEvents: UIControlEventTouchDown];
  [_cameraViewButton setImage: [UIImage imageNamed: @"CameraViewMultiple.png"] forState: UIControlStateNormal];
  _cameraViewButton.showsTouchWhenHighlighted = YES;

  _slideshowBar = [ButtonBar new];
  _slideshowBar.items = [NSArray arrayWithObjects: controls, back, play, next, _cameraViewButton, nil];

  if (_cameras.cameraCount < 2)
    [self setSlideshowControlsEnabled: NO];
  
  [_slideshowBar setFrame:
   CGRectMake( 0, CGRectGetMaxY( _imageArea.bounds ) - (toolBarHeight * 2),
              CGRectGetWidth( _imageArea.bounds ), toolBarHeight)];
  [_imageArea addSubview: _slideshowBar];
  _previousCamera = _cameras.cameraCount;
  _currentCamera = 0;
}

- (void) viewWillAppear: (BOOL) animated
{
  MainNavigationController *mainController = (MainNavigationController *) self.navigationController;
  BOOL showFourCameras = [[NSUserDefaults standardUserDefaults] boolForKey: kShowFourCamerasPrefKey];
  
  [super viewWillAppear: animated];
  
  mainController.navigationBar.barStyle = UIBarStyleBlackOpaque;
  mainController.navigationBar.tintColor = nil;
  [mainController setAudioControlsStyle: UIBarStyleBlackOpaque];
  [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque animated: YES];
  [self setCurrentCamera];
  [self setFourCameraView: showFourCameras];
  [self prepareForOrientation: [[UIApplication sharedApplication] statusBarOrientation]];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  
  if (_location != nil)
    [(MainNavigationController *) self.navigationController showAudioControls: YES];
}

- (void) viewWillDisappear: (BOOL) animated
{
  if (_cameraSelectButton != nil)
  {
    [self deregisterCamerasFromIndex: _currentCamera];
    _previousCamera = _cameras.cameraCount;
    [[NSUserDefaults standardUserDefaults] setBool: !_fourImagesView.hidden
                                            forKey: kShowFourCamerasPrefKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }

  [super viewWillDisappear: animated];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
  return YES;
}

- (NSUInteger) implementedRotationOrientations
{
  return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void) willRotateToInterfaceOrientation: (UIInterfaceOrientation) toInterfaceOrientation
                                 duration: (NSTimeInterval) duration
{
  [self prepareForOrientation: toInterfaceOrientation];
}

- (void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation) fromInterfaceOrientation
{
  MainNavigationController *navControl = (MainNavigationController *) self.navigationController;
  CGFloat fontSize = [UIFont smallSystemFontSize] + 4;
  CGFloat toolBarHeight = _topBar.frame.size.height;
  NSUInteger i;
    
  if (UIDeviceOrientationIsPortrait( [[UIApplication sharedApplication] statusBarOrientation] ))
  {
    CGRect contentBounds = self.view.bounds;
    
    [navControl setNavigationBarHidden: NO];
    [navControl showAudioControls: YES];
    if ([_imageArea superview] == nil)
    {
      [_portraitView insertSubview: _imageArea belowSubview: _topBar];
      _imageArea.frame = CGRectMake( contentBounds.origin.x, contentBounds.origin.y + toolBarHeight - 1, 
                                    contentBounds.size.width, contentBounds.size.height - (toolBarHeight * 3) + 1 );
    }
    _currentFullImage.frame = CGRectMake( 0, 0, 320, 240 );
    _currentFullTitle.frame = CGRectMake( 0, 240, _imageArea.bounds.size.width, fontSize );
    _fourImagesView.frame = CGRectMake( 0, 0, _imageArea.bounds.size.width, _imageArea.bounds.size.height - toolBarHeight );

    for (i = 0; i < 4; ++i)
    {
      ((UIImageView *) [_fourImages objectAtIndex: i]).frame =
        CGRectMake( 160 * (i % 2), (120 + fontSize) * (i / 2), 160, 120 );
      ((UILabel *) [_fourTitles objectAtIndex: i]).frame =
        CGRectMake( 2 + 160 * (i % 2), 120 + ((120 + fontSize) * (i / 2)), 156, fontSize );
    }
    _slideshowBar.frame = CGRectMake( 0, CGRectGetMaxY( _imageArea.bounds ) - toolBarHeight,
                                     CGRectGetWidth( _imageArea.bounds ), toolBarHeight );
  }
  else
  {
    [navControl setNavigationBarHidden: YES];
    [navControl showAudioControls: NO];
    _currentFullImage.frame = CGRectMake( toolBarHeight, 0, _imageArea.bounds.size.width - toolBarHeight,
                                         _imageArea.bounds.size.height );
    _currentFullTitle.frame = CGRectMake( toolBarHeight, _imageArea.bounds.size.height - 20,
                                         _imageArea.bounds.size.width - toolBarHeight, fontSize );
    _fourImagesView.frame = _currentFullImage.frame;

    CGFloat smallImageWidth = _currentFullImage.frame.size.width / 2;

    for (i = 0; i < 4; ++i)
    {
      ((UIImageView *) [_fourImages objectAtIndex: i]).frame = 
        CGRectMake( smallImageWidth * (i % 2), 160 * (i / 2), smallImageWidth, 160 );
      ((UILabel *) [_fourTitles objectAtIndex: i]).frame = 
        CGRectMake( 5 + smallImageWidth * (i % 2), 140 + (160 * (i / 2)), smallImageWidth - 10, fontSize );
    }
    _slideshowBar.frame = CGRectMake( 0, 0, toolBarHeight, 320 );
  }
  [_slideshowBar setNeedsLayout];
  [_slideshowBar setNeedsDisplay];
  _controlsOverlay.view.frame = _fourImagesView.frame;
  [_controlsOverlay ensureArrowsCorrect];
  _tappedImage.frame = _fourImagesView.frame;
}

- (NSString *) listTitle
{
  return NSLocalizedString( @"Cameras", @"Title of the list of available cameras" );
}

- (NSUInteger) countOfList
{
  return _cameras.cameraCount;
}

- (BOOL) canBeRefreshed
{
  return NO;
}

- (void) refresh
{
}

- (BOOL) refreshIsComplete
{
  return YES;
}

- (id) itemAtIndex: (NSUInteger) index
{
  return [_cameras cameraAtIndex: index];
}

- (NSString *) titleForItemAtIndex: (NSUInteger) index
{
  if (index < _cameras.cameraCount)
    return [_cameras cameraAtIndex: index].displayName;
  else
    return @"";
}

- (BOOL) itemIsSelectedAtIndex: (NSUInteger) index
{
  return (index == _currentCamera);
}

- (id<ListDataSource>) selectItemAtIndex:(NSUInteger)index
{
  return [self selectItemAtIndex: index executeAction: YES];
}

- (id<ListDataSource>) selectItemAtIndex: (NSUInteger) index  executeAction: (BOOL) executeAction
{
  _currentCamera = index;
  return nil;
}

- (BOOL) itemIsSelectableAtIndex: (NSUInteger) index
{
  return (index < _cameras.cameraCount);
}

- (NSUInteger) countOfSections
{
  return 1;
}

- (NSString *) titleForSection: (NSUInteger) section
{
  return @"";
}

- (NSUInteger) sectionForPrefix: (NSString *) prefix
{
  return 0;
}

- (NSUInteger) countOfListInSection: (NSUInteger) section
{
  if (section == 0)
    return [self countOfList];
  else
    return 0;
}

- (NSUInteger) convertFromOffset: (NSUInteger) index inSection: (NSUInteger) section
{
  if (section == 0)
    return index;
  else
    return [self countOfList];
}

- (NSIndexPath *) indexPathFromIndex: (NSUInteger) index
{
  return [NSIndexPath indexPathForRow: index inSection: 0];
}

- (id) itemAtOffset: (NSUInteger) index inSection: (NSUInteger) section
{
  return [self itemAtIndex: [self convertFromOffset: index inSection: section]];
}

- (NSString *) titleForItemAtOffset: (NSUInteger) index inSection: (NSUInteger) section
{
  return [self titleForItemAtIndex: [self convertFromOffset: index inSection: section]];
}

- (BOOL) itemIsSelectedAtOffset: (NSUInteger) index inSection: (NSUInteger) section
{
  return [self itemIsSelectedAtIndex: [self convertFromOffset: index inSection: section]];
}

- (id<ListDataSource>) selectItemAtOffset: (NSUInteger) index inSection: (NSUInteger) section
{
  return [self selectItemAtIndex: [self convertFromOffset: index inSection: section]];
}

- (BOOL) itemIsSelectableAtOffset: (NSUInteger) index inSection: (NSUInteger) section
{
  return [self itemIsSelectableAtIndex: [self convertFromOffset: index inSection: section]];
}

- (void) addDelegate: (id<ListDataDelegate>) delegate
{
}

- (void) removeDelegate: (id<ListDataDelegate>) delegate
{
}

- (id) listDataCurrentItem
{
  if (_cameras.cameraCount == 0)
    return nil;
  else
    return [_cameras cameraAtIndex: _currentCamera];
}

- (NSUInteger) listDataCurrentItemIndex
{
  return _currentCamera;
}

- (NSIndexPath *) listDataCurrentItemIndexPath
{
  return [NSIndexPath indexPathForRow: _currentCamera inSection: 0];
}

- (void) selectCamera: (id) button
{
  [ChangeSelectionHelper showDialogOver: [self navigationController] withListData: self];  
}

- (void) pressedControls: (id) button
{
  if ([_controlsOverlay.view superview] == nil)
    [_imageArea addSubview: _controlsOverlay.view];
  else
    [_controlsOverlay.view removeFromSuperview];
}

- (void) pressedNext: (id) button
{
  NSUInteger increment;
  
  if (_fourImagesView.hidden)
    increment = 1;
  else
    increment = 4;

  _previousCamera = _currentCamera;
  if (_currentCamera + increment >= _cameras.cameraCount)
    _currentCamera = 0;
  else
    _currentCamera += increment;
  [self setCurrentCamera];
}

- (void) pressedPrevious: (id) button
{
  NSUInteger decrement;
  
  if (_fourImagesView.hidden)
    decrement = 1;
  else
    decrement = 4;
  
  _previousCamera = _currentCamera;
  if (_currentCamera < decrement)
    _currentCamera = _cameras.cameraCount - (((_cameras.cameraCount - 1) % decrement) + 1);
  else
    _currentCamera -= decrement;
  [self setCurrentCamera];
}

- (void) pressedPlay: (UIButton *) button
{
  if (_slideshowTimer == nil)
  {
    _slideshowTimer = [NSTimer
                       scheduledTimerWithTimeInterval: SLIDESHOW_INTERVAL target: self
                       selector: @selector(slideshowTimerFired:) userInfo: nil repeats: TRUE];
    [button setImage: [UIImage imageNamed: @"SmallPause.png"] forState: UIControlStateNormal];
  }
  else
  {
    [_slideshowTimer invalidate];
    _slideshowTimer = nil;
    [button setImage: [UIImage imageNamed: @"SmallPlay.png"] forState: UIControlStateNormal];
  }
}

- (void) tappedImage: (UIButton *) button withEvent: (UIEvent *) event
{
  UITouch *touch = [[event touchesForView: button] anyObject];
  
  if (touch != nil)
  {
    if (_fourImagesView.hidden)
      [self setFourCameraView: YES];
    else
    {
      CGPoint pos = [touch locationInView: button];
      CGSize size = button.frame.size;
      CGFloat imageHeight = ((UIView *) [_fourImages objectAtIndex: 2]).frame.origin.y;
      NSUInteger imageNo = (NSUInteger) (pos.x / (size.width / 2)) + (2 * (NSUInteger) (pos.y / imageHeight));
      
      if (imageNo > 3)
        imageNo = 3;
      if (_currentCamera + imageNo < _cameras.cameraCount)
      {
        _currentCamera += imageNo;
        [self setFourCameraView: NO];
      }
    }
  }
}

- (void) slideshowTimerFired: (NSTimer *) timer
{
  [self pressedNext: nil];
}

- (void) deregisterCamerasFromIndex: (NSUInteger) index
{
  if (_fourImagesView.hidden)
  {
    if (index < _cameras.cameraCount)
      [[_cameras cameraAtIndex: index] removeDelegate: self];
  }
  else
  {
    NSUInteger count;
    NSUInteger i;
    
    if (index < _cameras.cameraCount)
    {
      count = _cameras.cameraCount - index;
      if (count > 4)
        count = 4;
      for (i = 0; i < count; ++i)
        [[_cameras cameraAtIndex: index + i] removeDelegate: self];
    }
  }
}

- (void) setCurrentCamera
{
  if (_cameraSelectButton != nil)
  {
    BOOL fourCameraView = !_fourImagesView.hidden;
    NLCamera *currentCamera = [_cameras cameraAtIndex: _currentCamera];

    _cameraSelectButton.title = currentCamera.displayName;
    [self deregisterCamerasFromIndex: _previousCamera];

    if (fourCameraView)
    {
      NSUInteger count = _cameras.cameraCount - _currentCamera;
      NSUInteger i;
      
      if (count > 4)
        count = 4;
      for (i = 0; i < count; ++i)
      {
        currentCamera = [_cameras cameraAtIndex: _currentCamera + i];
        ((UIImageView *) [_fourImages objectAtIndex: i]).image = currentCamera.image;
        ((UILabel *) [_fourTitles objectAtIndex: i]).text = currentCamera.displayName;
        [currentCamera addDelegate: self];
      }
      for ( ; i < 4; ++i)
      {
        ((UIImageView *) [_fourImages objectAtIndex: i]).image = nil;
        ((UILabel *) [_fourTitles objectAtIndex: i]).text = @"";
      }
      ((UIButton *) [_slideshowBar.items objectAtIndex: 0]).enabled = NO;
    }
    else
    {
      if (_previousCamera < _cameras.cameraCount)
        [[_cameras cameraAtIndex: _previousCamera] removeDelegate: self];
      
      _currentFullImage.image = currentCamera.image;
      _currentFullTitle.text = currentCamera.displayName;
      [currentCamera addDelegate: self];
      [_controlsOverlay setCamera: currentCamera];
      ((UIButton *) [_slideshowBar.items objectAtIndex: 0]).enabled = (currentCamera.capabilities != 0);
    }
  }
}

- (void) setSlideshowControlsEnabled: (BOOL) enabled
{
  NSArray *items = _slideshowBar.items;
  NSUInteger i;

  for (i = 1; i < [items count] - 1; ++i)
    ((UIButton *) [items objectAtIndex: i]).enabled = enabled;
}

- (void) toggleCameraView: (id) button
{
  [self setFourCameraView: _fourImagesView.hidden];
}

- (void) setFourCameraView: (BOOL) on
{
  BOOL showingFourCameras = !_fourImagesView.hidden;
  
  if (on && !showingFourCameras)
  {
    NSUInteger oldCurrentCamera = _currentCamera;

    [self setSlideshowControlsEnabled: (_cameras.cameraCount > 4)];
    [(UIButton *) [_slideshowBar.items lastObject] setImage: [UIImage imageNamed: @"CameraViewSingle.png"]
     forState: UIControlStateNormal];
    [self deregisterCamerasFromIndex: _currentCamera];
    _fourImagesView.hidden = NO;
    _currentFullImage.hidden = YES;
    _currentFullTitle.hidden = YES;
    [_controlsOverlay.view removeFromSuperview];
    
    _currentCamera = (_currentCamera / 4) * 4;
    [self setCurrentCamera];
    
    UIImageView *imageView = [_fourImages objectAtIndex: (oldCurrentCamera % 4)];
    CGRect savedFrame = imageView.frame;
    
    imageView.frame = CGRectMake( 0, 0, _currentFullImage.frame.size.width, _currentFullImage.frame.size.height );
    [_fourImagesView insertSubview: imageView belowSubview: [_fourTitles objectAtIndex: 0]];
    
    [UIView beginAnimations: @"CameraViewMultiple" context: nil];
    [UIView setAnimationDuration: 0.3];
    imageView.frame = savedFrame;
    [UIView commitAnimations];
  }
  else if (!on && showingFourCameras)
  {
    [self setSlideshowControlsEnabled: (_cameras.cameraCount > 1)];
    [(UIButton *) [_slideshowBar.items lastObject] setImage: [UIImage imageNamed: @"CameraViewMultiple.png"]
     forState: UIControlStateNormal];
    [self deregisterCamerasFromIndex: (_currentCamera / 4) * 4];
    _currentFullImage.hidden = NO;
    _currentFullTitle.hidden = NO;
    _fourImagesView.hidden = YES;
    [self setCurrentCamera];
    
    CGRect savedFrame = _currentFullImage.frame;
    CGRect newFrame = ((UIImageView *) [_fourImages objectAtIndex: _currentCamera % 4]).frame;
    
    _currentFullImage.frame = CGRectOffset( newFrame, savedFrame.origin.x, savedFrame.origin.y );
    
    [UIView beginAnimations: @"CameraViewSingle" context: nil];
    [UIView setAnimationDuration: 0.3];
    _currentFullImage.frame = savedFrame;
    [UIView commitAnimations];
  }
}

- (void) prepareForOrientation: (UIInterfaceOrientation) orientation
{
  if (UIDeviceOrientationIsPortrait( orientation ))
  {
    [[UIApplication sharedApplication] setStatusBarHidden: NO];
    self.view = _portraitView;
    [_portraitView insertSubview: _imageArea belowSubview: _topBar];
    
    CGRect contentBounds = _portraitView.bounds;
    CGFloat toolBarHeight = _topBar.frame.size.height;
    
    _imageArea.frame = CGRectMake( contentBounds.origin.x, contentBounds.origin.y + toolBarHeight - 1, 
                                  contentBounds.size.width, contentBounds.size.height - (toolBarHeight * 2) + 1 );
  }
  else
  {
    [[UIApplication sharedApplication] setStatusBarHidden: YES];
    self.view = _imageArea;
  }
}

- (void) camera: (NLCamera *) camera hasNewImage: (UIImage *) image
{
  NSUInteger limit = 4;
  NSUInteger i;
  
  if (_currentCamera + limit > _cameras.cameraCount)
    limit = _cameras.cameraCount - _currentCamera;

  for (i = 0; i < limit; ++i)
  {
    if (camera == [_cameras cameraAtIndex: _currentCamera + i])
    {
      if (i == 0)
        _currentFullImage.image = image;
      ((UIImageView *) [_fourImages objectAtIndex: i]).image = image;
      break;
    }
  }
}

- (void) dealloc
{
  [_cameraSelectButton release];
  [_portraitView release];
  [_currentFullImage release];
  [_currentFullTitle release];
  [_fourImagesView release];
  [_fourImages release];
  [_fourTitles release];
  [_tappedImage release];
  [_imageArea release];
  [_cameraViewButton release];
  [_slideshowTimer invalidate];
  [_slideshowBar release];
  [_controlsOverlay release];
  [super dealloc];
}


@end
