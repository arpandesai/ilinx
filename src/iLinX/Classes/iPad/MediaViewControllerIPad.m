    //
//  MediaViewControllerIPad.m
//  iLinX
//
//  Created by mcf on 09/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MediaViewControllerIPad.h"
#import "CustomSliderIPad.h"
#import "MediaNowPlayingController.h"
#import "MediaRootMenuViewController.h"
#import "AudioViewControllerIPad.h"
#import "NLSourceMediaServer.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLSource.h"
#import "NLSourceList.h"
#if DEBUG
#import "DebugTracing.h"
#define TRACE_RETAIN 0
#endif

@interface MediaViewControllerIPad ()

- (void) updateControlsForPlayState;
- (void) setShuffle: (BOOL) shuffle;
- (void) setRepeat: (NSUInteger) repeat;
- (void) calculateNowPlayingSmallRect;
- (void) releasePositionUpdatesTimer;
- (void) playNotPossibleTimerFired: (NSTimer *) timer;
- (void) releasePlayNotPossibleTimer;

@end

@implementation MediaViewControllerIPad

@synthesize
  timeSoFar = _timeSoFar,
  timeRemaining = _timeRemaining,
  progress = _progress,
  songIndex = _songIndex,
  nextSong = _nextSong,
  playButton = _playButton,
  pauseButton = _pauseButton,
  repeatButton = _repeatButton,
  shuffleButton = _shuffleButton,
  coverArt = _coverArt,
  mediaServer = _mediaServer;

- (id) initWithOwner: (AudioViewControllerIPad *) owner service: (NLService *) service source: (NLSource *) source;
{
  if ((self = [super initWithOwner: owner service: service source: source
                      nibName: @"MediaViewIPad" bundle: nil]) != nil)
    _mediaServer = (NLSourceMediaServer *) source;
  
#if TRACE_RETAIN
  NSLog( @"%@ init\n%@", self, [self stackTraceToDepth: 10] );
#endif
  return self;
}

#if TRACE_RETAIN
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

- (IBAction) sourcesPressed: (id) button
{
  [_owner presentSourcesPopoverFromButton: button
                  permittedArrowDirections: UIPopoverArrowDirectionAny animated: YES];
}

- (void) viewDidLoad
{
  [super viewDidLoad];

  // Avoid recursion caused by this the loadNibNamed call below causing this method
  // to be called.
  if (_nowPlayingView == nil)
  {
    _nowPlayingTitleFormat = [_songIndex.text retain];
    _nextTrackTitleFormat = [_nextSong.text retain];
    
    _songIndex.text = [NSString stringWithFormat: _nowPlayingTitleFormat, @""];
    
    if ((_mediaServer.capabilities & SOURCE_MEDIA_SERVER_CAPABILITY_NEXT_TRACK) == 0)
      _nextSong.hidden = YES;
    else
      _nextSong.text = [NSString stringWithFormat: _nextTrackTitleFormat, @""];
    _progress.progressOnly = ((_mediaServer.capabilities & SOURCE_MEDIA_SERVER_CAPABILITY_POSITION) == 0);
    [_subMenuArea addSubview: _subMenuNavigationController.view];
    _subMenuNavigationController.view.frame = _subMenuArea.bounds;
    _listingStyle.hidden = YES;
    
    _repeatButton.hidden = ((_mediaServer.capabilities & SOURCE_MEDIA_SERVER_CAPABILITY_REPEAT) == 0);
    if (!_repeatButton.hidden)
    {
      _cacheRepeatImage = [_repeatButton imageForState: UIControlStateSelected];
      _cacheRepeatOneImage = [_repeatButton imageForState: UIControlStateHighlighted];
      [_repeatButton setImage: nil forState: UIControlStateHighlighted];
    }
    
    NSDictionary *proxies = [NSDictionary dictionaryWithObject: self forKey: @"owner"];
    NSDictionary *options = [NSDictionary dictionaryWithObject: proxies forKey: UINibExternalObjects];
    
    // Set to a non-nil value to prevent this code being recursively called when
    // this sub-nib is loaded.
    _nowPlayingView = self.view;
    if ([[NSBundle mainBundle] loadNibNamed: @"MediaNowPlayingIPad"
                                      owner: _mediaNowPlayingController options: options] == nil)
      _nowPlayingView = nil;
    else
    {
      _nowPlayingView = _mediaNowPlayingController.view;
      _nowPlayingView.frame = self.view.bounds;
      _nowPlayingView.hidden = YES;
      [self.view addSubview: _nowPlayingView];
      [_mediaNowPlayingController viewDidLoad];

      [self calculateNowPlayingSmallRect];
    }
  }
}

- (void) viewDidUnload
{
  [_mediaNowPlayingController viewDidUnload];
  _nowPlayingView = nil;
  [super viewDidUnload];
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  _stabilised = NO;
  [self releasePlayNotPossibleTimer];
  [self calculateNowPlayingSmallRect];
  [_rootMenuViewController viewWillAppear: animated];
  [_subMenuNavigationController viewWillAppear: animated];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  [_rootMenuViewController viewDidAppear: animated];
  [_subMenuNavigationController viewDidAppear: animated];
  
  [_mediaServer addDelegate: self];
  [self source: _mediaServer stateChanged: 0xFFFFFFFF];
  
  if (_nowPlayingView != nil)
  {
    [_mediaNowPlayingController source: _mediaServer stateChanged: 0xFFFFFFFF];
    if (!_nowPlayingView.hidden)
      [_mediaNowPlayingController viewDidAppear: animated];
  }
}

- (void) viewWillDisappear: (BOOL) animated
{
  _stabilised = NO;
  [_mediaServer removeDelegate: self];
  [self releasePlayNotPossibleTimer];
  [self releasePositionUpdatesTimer];
  [_rootMenuViewController viewWillDisappear: animated];
  [_subMenuNavigationController viewWillDisappear: animated];
  if (_nowPlayingView != nil && !_nowPlayingView.hidden)
    [_mediaNowPlayingController viewWillDisappear: animated];
  [super viewWillDisappear: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
  [_rootMenuViewController viewDidDisappear: animated];
  [_subMenuNavigationController viewDidDisappear: animated];
  if (_nowPlayingView != nil && !_nowPlayingView.hidden)
    [_mediaNowPlayingController viewDidDisappear: animated];
  [super viewDidDisappear: animated];
}

- (void) willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation 
                                          duration: (NSTimeInterval) duration
{
  [super willAnimateRotationToInterfaceOrientation: interfaceOrientation duration: duration];
  [_rootMenuViewController willAnimateRotationToInterfaceOrientation: interfaceOrientation duration: duration];
  [_subMenuNavigationController willAnimateRotationToInterfaceOrientation: interfaceOrientation duration: duration];
  if (_nowPlayingView != nil && !_nowPlayingView.hidden)
    [_mediaNowPlayingController willAnimateRotationToInterfaceOrientation: interfaceOrientation duration: duration];
}

- (void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation) fromInterfaceOrientation
{
  [super didRotateFromInterfaceOrientation: fromInterfaceOrientation];
  [_rootMenuViewController didRotateFromInterfaceOrientation: fromInterfaceOrientation];
  [_subMenuNavigationController didRotateFromInterfaceOrientation: fromInterfaceOrientation];
  if (_nowPlayingView != nil && !_nowPlayingView.hidden)
    [_mediaNowPlayingController didRotateFromInterfaceOrientation: fromInterfaceOrientation];
  [self calculateNowPlayingSmallRect];
}

- (void) source: (NLSourceMediaServer *) source stateChanged: (NSUInteger) flags
{
  if ((flags & SOURCE_MEDIA_SERVER_SONG_CHANGED) != 0)
    _song.text = source.song;
  if ((flags & SOURCE_MEDIA_SERVER_ALBUM_CHANGED) != 0)
    _album.text = source.album;
  if ((flags & SOURCE_MEDIA_SERVER_ARTIST_CHANGED) != 0)
    _artist.text = source.artist;
  
  if ((flags & SOURCE_MEDIA_SERVER_COVER_ART_CHANGED) != 0)
    _coverArt.image = source.coverArt;
  if (!_ignorePositionUpdates && (flags & (SOURCE_MEDIA_SERVER_TIME_CHANGED|SOURCE_MEDIA_SERVER_ELAPSED_CHANGED)) != 0)
  {
    NSUInteger time = source.time;
    NSUInteger elapsed = source.elapsed;
    
    _timeSoFar.text = [NSString stringWithFormat: 
                       NSLocalizedString( @"%u:%02u", @"Format of minutes:seconds of elapsed song time" ),
                       elapsed / 60, elapsed % 60];
    _timeRemaining.text = [NSString stringWithFormat: 
                           NSLocalizedString( @"-%u:%02u", @"Format of minutes:seconds of remaining song time" ),
                           (time - elapsed) / 60, (time - elapsed) % 60];
    _progress.value = source.elapsedPercent / 100.0;
  }
  if ((flags & (SOURCE_MEDIA_SERVER_SONG_INDEX_CHANGED|SOURCE_MEDIA_SERVER_SONG_TOTAL_CHANGED)) != 0)
  {
    if (source.songIndex == 0 || source.songTotal == 0)
      _songIndex.hidden = YES;
    else
    {
      _songIndex.text = [NSString stringWithFormat: _nowPlayingTitleFormat,
                       [NSString stringWithFormat: NSLocalizedString( @"%u of %u", @"Format of song m of n" ),
                        source.songIndex, source.songTotal]];
      _songIndex.hidden = NO;
    }
  }

  if ((((flags & SOURCE_MEDIA_SERVER_TRANSPORT_STATE_CHANGED) != 0) && _debouncePlayState == 0) ||
    (_debouncePlayState > 0 && --_debouncePlayState == 0))
    [self updateControlsForPlayState];

  if ((flags & SOURCE_MEDIA_SERVER_SHUFFLE_CHANGED) != 0)
    [self setShuffle: source.shuffle];
  if ((flags & SOURCE_MEDIA_SERVER_REPEAT_CHANGED) != 0)
    [self setRepeat: source.repeat];

  if ((flags & SOURCE_MEDIA_SERVER_NEXT_SONG_CHANGED) != 0)
  {
    NSString *nextSong = source.nextSong;
    
    _nextSong.text = [NSString stringWithFormat: _nextTrackTitleFormat, nextSong];
    if ([nextSong length] == 0)
      _nextSong.hidden = YES;
    else
      _nextSong.hidden = NO;
  }
  
  if (_nowPlayingView != nil)
    [_mediaNowPlayingController source: source stateChanged: flags];
  
  // If play is not possible, hide the now playing view and disable the ability
  // to select it.
  if (!_stabilised)
    _stabilised = !source.playNotPossible;
  
  if (_stabilised && source.playNotPossible)
  {
    if (_playNotPossibleTimer == nil)
      _playNotPossibleTimer =
      [[NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector(playNotPossibleTimerFired:) 
                                      userInfo: nil repeats: NO] retain];
  }
  else if (_playNotPossibleTimer != nil)
  {
    [self releasePlayNotPossibleTimer];
  }
}

- (void) updateControlsForPlayState
{
  NSUInteger playState = _mediaServer.transportState;
  BOOL fullStop = (playState == TRANSPORT_STATE_STOP && [_song.text length] == 0);

  _playButton.hidden = (playState == TRANSPORT_STATE_PLAY);
  _pauseButton.hidden = (playState != TRANSPORT_STATE_PLAY);
#if HIDE_CONTROLS_ON_FULL_STOP
  _timeRemaining.hidden = fullStop;
  _timeSoFar.hidden = fullStop;
  _progress.hidden = fullStop;
  _shuffleButton.hidden = fullStop;
  if ((_mediaServer.capabilities & SOURCE_MEDIA_SERVER_CAPABILITY_REPEAT) != 0)
    _repeatButton.hidden = fullStop;
#else
  _timeRemaining.enabled = !fullStop;
  _timeSoFar.enabled = !fullStop;
  _progress.enabled = !fullStop;
  _shuffleButton.enabled = !fullStop;
  if (!_repeatButton.hidden)
    _repeatButton.enabled = !fullStop;
#endif
  if (_nowPlayingView == nil || _nowPlayingView.hidden)
    _nowPlayingSummaryArea.hidden = fullStop;
  [self.view setNeedsDisplay];
}


- (void) setShuffle: (BOOL) shuffle
{
  _shuffleButton.selected = shuffle;
  [self.view setNeedsDisplay];
}

- (void) setRepeat: (NSUInteger) repeat
{
  switch (repeat)
  {
    case 1:
      [_repeatButton setImage: _cacheRepeatOneImage forState: UIControlStateSelected];
      _repeatButton.selected = YES;
      break;
    case 2:
      [_repeatButton setImage: _cacheRepeatImage forState: UIControlStateSelected];
      _repeatButton.selected = YES;
      break;
    default:
      _repeatButton.selected = NO;
      break;
  }
  [self.view setNeedsDisplay];
}

- (void) calculateNowPlayingSmallRect
{
  CGRect artOldFrame = [self.view convertRect: _coverArt.frame fromView: [_coverArt superview]];
  UIView *newArtView = _mediaNowPlayingController.coverArtView;
  CGRect artNewFrame;
  
  if (newArtView != nil)
    artNewFrame = [self.view convertRect: _mediaNowPlayingController.coverArtView.frame 
                                fromView: [_mediaNowPlayingController.coverArtView superview]];
  else
  {
    artNewFrame = self.view.bounds;
    if (artNewFrame.size.width > artNewFrame.size.height)
      artNewFrame = CGRectMake( artNewFrame.origin.x + ((artNewFrame.size.width - artNewFrame.size.height) / 2), 
                               artNewFrame.origin.y, artNewFrame.size.height, artNewFrame.size.height );
    else
      artNewFrame = CGRectMake( artNewFrame.origin.x, 
                               artNewFrame.origin.y + ((artNewFrame.size.height - artNewFrame.size.width) / 2),
                               artNewFrame.size.width, artNewFrame.size.width );
  }
  
  CGFloat widthScale = artOldFrame.size.width / artNewFrame.size.width;
  CGFloat heightScale = artOldFrame.size.height / artNewFrame.size.height;
  CGFloat xOffset = artOldFrame.origin.x - ((artNewFrame.origin.x - self.view.bounds.origin.x) * widthScale) -
  self.view.bounds.origin.x;
  CGFloat yOffset = artOldFrame.origin.y - ((artNewFrame.origin.y - self.view.bounds.origin.y) * heightScale) -
  self.view.bounds.origin.y;
  
  _nowPlayingSmallRect = CGRectMake( self.view.bounds.origin.x + xOffset, 
                                    self.view.bounds.origin.y + yOffset,
                                    self.view.bounds.size.width * widthScale, 
                                    self.view.bounds.size.height * heightScale );
}

- (IBAction) pressedPlay: (id) button
{
  _mediaServer.transportState = TRANSPORT_STATE_PLAY;
  _debouncePlayState = 2;
  [self updateControlsForPlayState];
}

- (IBAction) pressedPause: (id) button
{
  _mediaServer.transportState = TRANSPORT_STATE_PAUSE;
  _debouncePlayState = 2;
  [self updateControlsForPlayState];
}

- (IBAction) toggledPlayPause: (id) button
{
  if (_mediaServer.transportState == TRANSPORT_STATE_PLAY)
     _mediaServer.transportState = TRANSPORT_STATE_PAUSE;
   else
    _mediaServer.transportState = TRANSPORT_STATE_PLAY;

  _debouncePlayState = 2;
  [self updateControlsForPlayState];
}

- (IBAction) pressedStop: (id) button
{
  _mediaServer.transportState = TRANSPORT_STATE_STOP;
  _debouncePlayState = 2;
  [self updateControlsForPlayState];
}

- (IBAction) pressedRewind: (id) button
{
  [_mediaServer playPreviousTrack];
}

- (IBAction) pressedFastForward: (id) button
{
  [_mediaServer playNextTrack];
}


- (IBAction) toggleShuffle
{
  BOOL newShuffle = !_mediaServer.shuffle;
  
  _mediaServer.shuffle = newShuffle;
  [self setShuffle: newShuffle];  
}

- (IBAction) toggleRepeat
{
  NSUInteger newRepeat = _mediaServer.repeat;
  
  if (newRepeat == 0)
    newRepeat = _mediaServer.maxRepeat;
  else
    --newRepeat;
  
  _mediaServer.repeat = newRepeat;
  [self setRepeat: newRepeat];
}

- (IBAction) pressedNowPlaying: (id) button
{
  if (_nowPlayingView.hidden && _nowPlayingSnapshot == nil && !((NLSourceMediaServer *) _source).playNotPossible)
  {    
    [_mediaNowPlayingController viewWillAppear: YES];
    [_mediaNowPlayingController source: _mediaServer stateChanged: 0xFFFFFFFF];
    
    UIGraphicsBeginImageContext( _nowPlayingView.bounds.size );
    _nowPlayingView.hidden = NO;
    [_nowPlayingView.layer renderInContext: UIGraphicsGetCurrentContext()];
    _nowPlayingView.hidden = YES;
    _nowPlayingSnapshot = [[UIImageView alloc] initWithImage: UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();
    _nowPlayingSnapshot.frame = _nowPlayingSmallRect;
    _nowPlayingSnapshot.alpha = 0.2;
    [self.view addSubview: _nowPlayingSnapshot];
    [_nowPlayingSnapshot release];
    
    [UIView beginAnimations: @"ShowNowPlayingView" context: nil];
    [UIView setAnimationDuration: 0.5];
    [UIView setAnimationDelegate: self];
    [UIView setAnimationDidStopSelector: @selector(animationDidStop:finished:context:)];
    
    _nowPlayingSnapshot.alpha = 1.0;
    _nowPlayingSnapshot.frame = self.view.bounds;
    
    [UIView commitAnimations];
  }
}

- (IBAction) dismissNowPlaying: (id) button
{
  if (!_nowPlayingView.hidden && _nowPlayingSnapshot == nil)
  {
    UIGraphicsBeginImageContext( _nowPlayingView.bounds.size );
    [_nowPlayingView.layer renderInContext: UIGraphicsGetCurrentContext() ];
    _nowPlayingSnapshot = [[UIImageView alloc] initWithImage: UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();
    _nowPlayingSnapshot.frame = self.view.bounds;
    [self.view addSubview: _nowPlayingSnapshot];
    [_nowPlayingSnapshot release];
    
    [_mediaNowPlayingController viewWillDisappear: YES];
    _nowPlayingView.hidden = YES;
    [_mediaNowPlayingController viewDidDisappear: YES];
    
    [UIView beginAnimations: @"HideNowPlayingView" context: nil];
    [UIView setAnimationDuration: 0.5];
    [UIView setAnimationDelegate: self];
    [UIView setAnimationDidStopSelector: @selector(animationDidStop:finished:context:)];
    
    _nowPlayingSnapshot.frame = _nowPlayingSmallRect;
    _nowPlayingSnapshot.alpha = 0.2;
    
    [UIView commitAnimations];
    [_mediaNowPlayingController resetToCoverArt];
  }
}

- (void) animationDidStop: (NSString *) animationID finished: (NSNumber *) finished context: (void *) context
{
  [_nowPlayingSnapshot removeFromSuperview];
  _nowPlayingSnapshot = nil;

  if ([animationID isEqualToString: @"ShowNowPlayingView"])
  {
    _nowPlayingView.hidden = NO;
    [_mediaNowPlayingController viewDidAppear: YES];
  }
  
}

- (IBAction) setPosition: (id) position
{
  [self releasePositionUpdatesTimer];
  _ignorePositionUpdatesDebounceTimer =
  [[NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector(updatePosition) 
                                  userInfo: nil repeats: NO] retain];
}

- (void) updatePosition
{
  float value = _progress.value;
  
  _mediaServer.elapsed = (NSUInteger) (value * _mediaServer.time);
  [self releasePositionUpdatesTimer];
  _ignorePositionUpdates = NO;
  [self source: _mediaServer stateChanged: SOURCE_MEDIA_SERVER_ELAPSED_CHANGED];
  _ignorePositionUpdates = YES;
}

- (void) disablePositionUpdates
{
  _ignorePositionUpdates = YES;
  [self releasePositionUpdatesTimer];
}

- (void) enablePositionUpdatesAfterDelay
{
  [self releasePositionUpdatesTimer];
  _mediaServer.elapsed = (NSUInteger) (_progress.value * _mediaServer.time);
  _ignorePositionUpdates = NO;
  [self source: _mediaServer stateChanged: SOURCE_MEDIA_SERVER_ELAPSED_CHANGED];
  _ignorePositionUpdates = YES;
  _ignorePositionUpdatesDebounceTimer =
  [[NSTimer scheduledTimerWithTimeInterval: 2.0 target: self selector: @selector(enablePositionUpdates) 
                                  userInfo: nil repeats: NO] retain];
}

- (void) enablePositionUpdates
{
  [self releasePositionUpdatesTimer];
  _ignorePositionUpdates = NO;
  [self source: _mediaServer stateChanged: SOURCE_MEDIA_SERVER_ELAPSED_CHANGED];
}

- (IBAction) listingStyleChanged: (id) control
{
  UIViewController *top = _subMenuNavigationController.topViewController;
  
  if ([top isKindOfClass: [MediaSubMenuViewController class]])
    [(MediaSubMenuViewController *) top setDisplayOption: _listingStyle.selectedSegmentIndex];
}

- (NLRoomList *) roomList
{
  return _owner.roomList;
}

- (void) dataSource: (DataSourceViewController *) dataSource selectedItemChanged: (id) item
{
  NLBrowseList *rootMenu = _owner.roomList.currentRoom.sources.currentSource.browseMenu;
  NSUInteger count = [rootMenu countOfList];
  NLBrowseList *browseList = nil;
  
  if (count != NSUIntegerMax)
  {
    for (NSUInteger i = 0; i < count; ++i)
    {
      if ([rootMenu itemAtIndex: i] == item)
      {
        browseList = (NLBrowseList *) [rootMenu selectItemAtIndex: i executeAction: NO];
        break;
      }
    }
  }
  
  if (browseList == nil)
  {
    _subMenuNavigationController.view.hidden = YES;
    _listingStyle.hidden = YES;
  }
  else
  {
    MediaSubMenuViewController *newController = 
  [[MediaSubMenuViewController alloc] initWithNibName: @"MediaSubMenuViewController" bundle: nil];
  
    _subMenuNavigationController.view.hidden = NO;
    _subMenuNavigationController.navigationBarHidden = YES;
    newController.title = [browseList listTitle];
    newController.browseList = browseList;
    newController.displayOptionsDelegate = self;
    [_subMenuNavigationController.visibleViewController viewWillDisappear: YES];
    _subMenuNavigationController.viewControllers = [NSArray arrayWithObject: newController];
    [newController release];
  }
}

- (void) subMenu: (MediaSubMenuViewController *) subMenu hasDisplayOptions: (NSArray *) displayOptions
{
  if (subMenu == _subMenuNavigationController.topViewController)
  {
    NSInteger count = [displayOptions count];
    CGRect oldFrame = _listingStyle.frame;
    
    [_listingStyle removeAllSegments];
    for (NSInteger i = 0; i < count; ++i)
    {
      UIButton *option = [displayOptions objectAtIndex: i];
      UIImage *image = [option imageForState: UIControlStateNormal];
      
      if (image == nil)
        [_listingStyle insertSegmentWithTitle: [option titleForState: UIControlStateNormal] atIndex: i animated: NO];
      else if (option.enabled)
        [_listingStyle insertSegmentWithImage: image atIndex: i animated: NO];
      else
        [_listingStyle insertSegmentWithImage: [option imageForState: UIControlStateDisabled] atIndex: i animated: NO];
      //[_listingStyle setEnabled: option.enabled forSegmentAtIndex: i];  
    }
    
    [_listingStyle sizeToFit];
    switch (_listingStyle.autoresizingMask & (UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin))
    {
      case UIViewAutoresizingFlexibleLeftMargin:
        // Right aligned; adjust left position to account for change in size
        _listingStyle.frame = CGRectMake( oldFrame.origin.x + oldFrame.size.width - _listingStyle.frame.size.width,
                                         _listingStyle.frame.origin.y, _listingStyle.frame.size.width,
                                         _listingStyle.frame.size.height );
        break;
      case UIViewAutoresizingFlexibleRightMargin:
        // Left aligned, no change needed.
        break;
      default:
        // Centered, adjust left position to centre in available area
        _listingStyle.frame = CGRectMake( oldFrame.origin.x + (int) ((oldFrame.size.width - _listingStyle.frame.size.width) / 2),
                                         _listingStyle.frame.origin.y, _listingStyle.frame.size.width,
                                         _listingStyle.frame.size.height );
        break;
    }
    _listingStyle.hidden = NO;
  }
}

- (void) subMenu: (MediaSubMenuViewController *) subMenu didChangeToDisplayOption: (NSUInteger) displayOption
{
  if (subMenu == _subMenuNavigationController.topViewController &&
      displayOption < _listingStyle.numberOfSegments && displayOption != _listingStyle.selectedSegmentIndex &&
    [_listingStyle isEnabledForSegmentAtIndex: displayOption])
    _listingStyle.selectedSegmentIndex = displayOption;
}
   
- (void) releasePositionUpdatesTimer
{
  if (_ignorePositionUpdatesDebounceTimer != nil)
  {
    if ([_ignorePositionUpdatesDebounceTimer isValid])
      [_ignorePositionUpdatesDebounceTimer invalidate];
    [_ignorePositionUpdatesDebounceTimer release];
    _ignorePositionUpdatesDebounceTimer = nil;
  }
}
   
- (void) playNotPossibleTimerFired: (NSTimer *) timer
{
  [self releasePlayNotPossibleTimer];
  if (_stabilised && ((NLSourceMediaServer *) _source).playNotPossible)
    [self dismissNowPlaying: nil];
}

- (void) releasePlayNotPossibleTimer
{
  if (_playNotPossibleTimer != nil)
  {
    if ([_playNotPossibleTimer isValid])
      [_playNotPossibleTimer invalidate];
    [_playNotPossibleTimer release];
    _playNotPossibleTimer = nil;
  }
}

- (void) dealloc
{
#if TRACE_RETAIN
  NSLog( @"%@ dealloc\n%@", self, [self stackTraceToDepth: 10] );
#endif
  [_progress release];
  [_timeSoFar release];
  [_timeRemaining release];
  [_playButton release];
  [_pauseButton release];
  [_repeatButton release];
  [_shuffleButton release];
  [_songIndex release];
  [_nowPlayingSummaryArea release];
  [_coverArt release];
  [_artist release];
  [_song release];
  [_album release];
  [_nextSong release];
  [_listingStyle release];
  [_rootMenuViewController release];
  [_subMenuArea release];
  [_subMenuNavigationController release];
  [_mediaNowPlayingController release];
  [self releasePositionUpdatesTimer];
  [self releasePlayNotPossibleTimer];
  [_nowPlayingTitleFormat release];
  [_nextTrackTitleFormat release];
  [super dealloc];
}

@end
