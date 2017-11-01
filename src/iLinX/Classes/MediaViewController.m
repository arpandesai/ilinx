//
//  MediaViewController.m
//  iLinX
//
//  Created by mcf on 19/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "MediaViewController.h"
#import "BrowseViewController.h"
#import "ChangeSelectionHelper.h"
#import "CustomSlider.h"
#import "DeprecationHelper.h"
#import "MainNavigationController.h"
#import "NLSourceMediaServer.h"
#import "NLRenderer.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLSource.h"
#import "NLSourceList.h"
#import "StandardPalette.h"

@interface MediaViewController ()

- (void) setPlaying;
- (void) setPausedOrStopped;
- (void) setShuffle: (BOOL) shuffle;
- (void) setRepeat: (NSUInteger) repeat;
- (void) goBack: (id) control;
- (void) flipCurrentView: (UIButton *) button;
- (void) pressedPlay: (UIButton *) button;
- (void) pressedPause: (UIButton *) button;
- (void) pressedStop: (UIButton *) button;
- (void) pressedRewind: (UIButton *) button;
- (void) pressedFastForward: (UIButton *) button;
- (void) pressedRepeat: (UIButton *) button;
- (void) pressedShuffle: (UIButton *) button;
- (void) pressedBackdrop: (UIButton *) button;
- (void) pressedOverlay: (UIButton *) button;
- (void) setPosition: (id) control;
- (void) updatePosition;
- (void) disablePositionUpdates;
- (void) enablePositionUpdatesAfterDelay;
- (void) enablePositionUpdates;
- (void) releasePositionUpdatesTimer;
- (void) playNotPossibleTimerFired: (NSTimer *) timer;
- (void) releasePlayNotPossibleTimer;

@end

@implementation MediaViewController

- initWithRoomList: (NLRoomList *) roomList service: (NLService *) service source: (NLSource *) source
{
  if ((self = [super initWithRoomList: roomList service: service source: source]) != nil)
  {    
    // Cast here as a convenience to avoid having to cast every time its used
    _mediaServer = (NLSourceMediaServer *) source;
  }
  
  return self;
}

- (BOOL) isBrowseable
{
  return (_mediaServer != nil && _mediaServer.browseMenu != nil);
}

- (id<ControlViewProtocol>) allocBrowseViewController
{
  if (_mediaServer == nil || _mediaServer.browseMenu == nil)
    return nil;
  else
    return [[BrowseViewController alloc] initWithRoomList: _roomList service: _service
                                                   source: _source nowPlaying: self];
}

- (void) loadView
{
  [super loadView];

  CGRect contentBounds = self.view.bounds;
  
  // Custom title
  UIView *customTitle = [[UIView alloc] initWithFrame:
                         CGRectMake( 0, 0, CGRectGetWidth( self.navigationController.navigationBar.bounds ), 
                                    CGRectGetHeight( self.navigationController.navigationBar.bounds ) )];
  
  customTitle.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  customTitle.autoresizesSubviews = YES;
  
  UIFont *customTitleFont = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]];
  CGFloat lineHeight = customTitleFont.pointSize + 1;
  CGFloat linesTop = (CGRectGetHeight( self.navigationController.navigationBar.bounds ) - (3 * lineHeight)) / 2;
  
  _artist = [[UILabel alloc] initWithFrame: CGRectMake( 0, linesTop, customTitle.bounds.size.width, lineHeight )];
  _artist.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  _artist.font = customTitleFont;
  _artist.lineBreakMode = UILineBreakModeMiddleTruncation;
  _artist.textAlignment = UITextAlignmentCenter;
  _artist.textColor = [UIColor lightGrayColor];
  _artist.shadowColor = [UIColor darkGrayColor];
  _artist.backgroundColor = [UIColor clearColor];
  [customTitle addSubview: _artist];
  
  _song = [[UILabel alloc] initWithFrame: CGRectMake( 0, linesTop + lineHeight, customTitle.bounds.size.width, lineHeight )];
  _song.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  _song.font = customTitleFont;
  _song.lineBreakMode = UILineBreakModeMiddleTruncation;
  _song.textAlignment = UITextAlignmentCenter;
  _song.textColor = [UIColor whiteColor];
  _song.shadowColor = [UIColor darkGrayColor];
  _song.backgroundColor = [UIColor clearColor];
  [customTitle addSubview: _song];
  
  _album = [[UILabel alloc] initWithFrame: CGRectMake( 0, linesTop + (lineHeight * 2), customTitle.bounds.size.width, lineHeight )];
  _album.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  _album.font = customTitleFont;
  _album.lineBreakMode = UILineBreakModeMiddleTruncation;
  _album.textAlignment = UITextAlignmentCenter;
  _album.textColor = [UIColor lightGrayColor];
  _album.backgroundColor = [UIColor clearColor];
  [customTitle addSubview: _album];
  
  self.navigationItem.titleView = customTitle;
  [customTitle release];
  
  UIBarButtonItem *barButton;
  UIButton *buttonControl = [UIButton buttonWithType: UIButtonTypeCustom];
  
  [buttonControl setBackgroundImage: [UIImage imageNamed: @"PlayerBackArrow.png"] forState: UIControlStateNormal];
  [buttonControl addTarget: self action: @selector(goBack:) forControlEvents: UIControlEventTouchDown];
  [buttonControl sizeToFit];
  [buttonControl setBackgroundColor: [UIColor clearColor]];
  buttonControl.opaque = NO;
  barButton = [[UIBarButtonItem alloc] initWithCustomView: buttonControl];  
  self.navigationItem.leftBarButtonItem = barButton;
  self.navigationItem.hidesBackButton = YES;
  [barButton release];
  
  _flipButton = [[UIButton alloc] initWithFrame: CGRectMake( 0, 0, 30, 30 )];
  [_flipButton setBackgroundImage: [UIImage imageNamed: @"DetailsList.png"] forState: UIControlStateNormal];
  [_flipButton addTarget: self action: @selector(flipCurrentView:) forControlEvents: UIControlEventTouchDown];
  barButton = [[UIBarButtonItem alloc] initWithCustomView: _flipButton];
  [self.navigationItem setRightBarButtonItem: barButton animated: YES];
  [barButton release];
  
  // Flipping view
  _flipBase = [[UIView alloc] initWithFrame: 
               CGRectMake( 0, 0, contentBounds.size.width, contentBounds.size.height )];
  [self.view addSubview: _flipBase];
  _flippingView = [[UIView alloc] initWithFrame: _flipBase.frame];
  [_flipBase addSubview: _flippingView];
  
  CGFloat toolBarHeight = _toolBar.frame.size.height;
  
  _toolBar.alpha = 0.7;
  [self.view insertSubview: _toolBar aboveSubview: _flipBase];

  NSMutableArray *items = [_toolBar.items mutableCopy];
  UIBarButtonItem *button = [[UIBarButtonItem alloc]
                             initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target: nil action: nil];
  
  [items addObject: button];
  [button release];
  if ((((NLSourceMediaServer *) _source).capabilities & SOURCE_MEDIA_SERVER_CAPABILITY_REPEAT) != 0)
  {
    button = [[UIBarButtonItem alloc]
              initWithImage: [UIImage imageNamed: @"Shim.png"] style: UIBarButtonItemStyleBordered 
              target: self action: @selector(pressedRepeat:)];
    [items addObject: button];
    [button release];
    _repeatImage = [[UIImageView alloc] initWithFrame:
                     CGRectMake( contentBounds.size.width - 69, _toolBar.frame.origin.y + 16, 20, 15 )];
    _repeatImage.image = [UIImage imageNamed: @"Repeat.png"];
    _repeatImage.alpha = 0.7;
    [self.view addSubview: _repeatImage];
  }
  button = [[UIBarButtonItem alloc]
            initWithImage: [UIImage imageNamed: @"Shim.png"] style: UIBarButtonItemStyleBordered 
            target: self action: @selector(pressedShuffle:)];
  [items addObject: button];
  [button release];
  _toolBar.items = items;
  [items release];
  _shuffleImage = [[UIImageView alloc] initWithFrame:
                   CGRectMake( contentBounds.size.width - 31, _toolBar.frame.origin.y + 16, 20, 15 )];
  _shuffleImage.image = [UIImage imageNamed: @"Shuffle.png"];
  _shuffleImage.alpha = 0.7;
  [self.view addSubview: _shuffleImage];
  
  // Image
  _backdrop = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"DefaultCoverArt.png"]];
  [_backdrop sizeToFit];
  _backdrop.contentMode = UIViewContentModeScaleAspectFit;
  [_flippingView addSubview: _backdrop];
  
  buttonControl = [[UIButton alloc] initWithFrame: _backdrop.frame];
  buttonControl.backgroundColor = [UIColor clearColor];
  [buttonControl addTarget: self action: @selector(pressedBackdrop:) forControlEvents: UIControlEventTouchDown];
  [_flippingView addSubview: buttonControl];
  [buttonControl release];
  
  // Image reflection
  _reflection = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"DefaultCoverArt.png"]];
  _reflection.frame = CGRectMake( _backdrop.frame.origin.x, _backdrop.frame.origin.y + _backdrop.frame.size.height, 
                                 _backdrop.frame.size.width, _backdrop.frame.size.height );
  [_reflection setTransform: CGAffineTransformMake( 1, 0, 0, -1, 0, 1 )];
  _reflection.alpha = 0.5;
  _reflection.contentMode = UIViewContentModeScaleAspectFit;
  [_flippingView addSubview: _reflection];
  
  // Transport controls
  CGFloat verticalPos = _flippingView.frame.origin.y + _backdrop.frame.size.height + 1;
  UIButton *controlButton = [UIButton buttonWithType: UIButtonTypeCustom];
  
  _transportBar = [[UIView alloc] initWithFrame: 
                   CGRectMake( _flippingView.frame.origin.x, verticalPos, _flippingView.frame.size.width,
                              contentBounds.size.height - verticalPos - toolBarHeight )];
  _transportBar.backgroundColor = [UIColor colorWithWhite: 0 alpha: 0.3];
  [self.view addSubview: _transportBar];
  
  [controlButton setImage: [UIImage imageNamed: @"Rewind.png"] forState: UIControlStateNormal];
  controlButton.showsTouchWhenHighlighted = YES;
  [controlButton sizeToFit];
  controlButton.frame = CGRectOffset( controlButton.frame, 40, 9 );
  [controlButton addTarget: self action: @selector(pressedRewind:) forControlEvents: UIControlEventTouchDown];
  [_transportBar addSubview: controlButton];
  
  controlButton = [UIButton buttonWithType: UIButtonTypeCustom];
  [controlButton setImage: [UIImage imageNamed: @"Stop.png"] forState: UIControlStateNormal];
  [controlButton sizeToFit];
  controlButton.frame = CGRectOffset( controlButton.frame, 115, 9 );
  controlButton.showsTouchWhenHighlighted = YES;
  [controlButton addTarget: self action: @selector(pressedStop:) forControlEvents: UIControlEventTouchDown];
  [_transportBar addSubview: controlButton];
  
  controlButton = [UIButton buttonWithType: UIButtonTypeCustom];
  [controlButton setImage: [UIImage imageNamed: @"Play.png"] forState: UIControlStateNormal];
  [controlButton sizeToFit];
  controlButton.frame = CGRectOffset( controlButton.frame, 178, 9 );
  controlButton.showsTouchWhenHighlighted = YES;
  [controlButton addTarget: self action: @selector(pressedPlay:) forControlEvents: UIControlEventTouchDown];
  [_transportBar addSubview: controlButton];
  _playPause = [controlButton retain];
  
  controlButton = [UIButton buttonWithType: UIButtonTypeCustom];
  [controlButton setImage: [UIImage imageNamed: @"FastForward.png"] forState: UIControlStateNormal];
  [controlButton sizeToFit];
  controlButton.frame = CGRectOffset( controlButton.frame, 242, 9 );
  controlButton.showsTouchWhenHighlighted = YES;
  [controlButton addTarget: self action: @selector(pressedFastForward:) forControlEvents: UIControlEventTouchDown];
  [_transportBar addSubview: controlButton];
  
  // Overlay view
  _overlayView = [[UIButton buttonWithType: UIButtonTypeCustom] retain];
  _overlayView.frame = CGRectMake( _backdrop.frame.origin.x, _backdrop.frame.origin.y + toolBarHeight - 1,
                                  _backdrop.frame.size.width, _backdrop.frame.size.height - toolBarHeight + 1 );
  _overlayView.backgroundColor = [UIColor colorWithWhite: 0 alpha: 0.5];
  _overlayView.hidden = YES;
  [_overlayView addTarget: self action: @selector(pressedOverlay:) forControlEvents: UIControlEventTouchDown];
  [_flippingView addSubview: _overlayView];
  
  _songIndex = [[UILabel alloc] initWithFrame:
                CGRectMake( 0, lineHeight, _overlayView.bounds.size.width, lineHeight )];
  _songIndex.font = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]];
  _songIndex.backgroundColor = [UIColor clearColor];
  _songIndex.textAlignment = UITextAlignmentCenter;
  [_overlayView addSubview: _songIndex];
  if ((((NLSourceMediaServer *) _source).capabilities & SOURCE_MEDIA_SERVER_CAPABILITY_SONG_COUNT) == 0)
    _songIndex.textColor = [UIColor clearColor];
  else
    _songIndex.textColor = [UIColor whiteColor];

  _timeSoFar = [[UILabel alloc] initWithFrame: CGRectMake( 5, lineHeight * 3 - 3, 20, lineHeight )];
  _timeSoFar.font = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize] + 2];
  _timeSoFar.textColor = [UIColor whiteColor];
  _timeSoFar.backgroundColor = [UIColor clearColor];
  _timeSoFar.textAlignment = UITextAlignmentRight;
  _timeSoFar.text = @"-88:88";
  [_timeSoFar sizeToFit];
  [_overlayView addSubview: _timeSoFar];

  _timeRemaining = [[UILabel alloc] initWithFrame:
                CGRectMake( contentBounds.size.width - _timeSoFar.frame.size.width - 5, lineHeight * 3 - 3, 20, lineHeight )];
  _timeRemaining.font = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize] + 2];
  _timeRemaining.textColor = [UIColor whiteColor];
  _timeRemaining.backgroundColor = [UIColor clearColor];
  _timeRemaining.textAlignment = UITextAlignmentLeft;
  _timeRemaining.text = @"-88:88";
  [_timeRemaining sizeToFit];
  [_overlayView addSubview: _timeRemaining];

  CGFloat progressLeft = _timeSoFar.frame.origin.x + _timeSoFar.frame.size.width + 10;
  CGFloat progressWidth = _timeRemaining.frame.origin.x - progressLeft - 10;
  if ((((NLSourceMediaServer *) _source).capabilities & SOURCE_MEDIA_SERVER_CAPABILITY_POSITION) == 0)
    _progress = [[CustomSlider alloc] initWithFrame: 
                 CGRectMake( progressLeft, lineHeight * 3 - 5, progressWidth, lineHeight )
                                               tint: nil progressOnly: YES];
  else
  {
    _progress = [[CustomSlider alloc] initWithFrame: 
                 CGRectMake( progressLeft, lineHeight * 3 - 5, progressWidth, lineHeight )
                                               tint: nil progressOnly: NO];
    [_progress addTarget: self action: @selector(setPosition:) forControlEvents: UIControlEventValueChanged];
    [_progress addTarget: self action: @selector(disablePositionUpdates) forControlEvents: UIControlEventTouchDown];
    [_progress addTarget: self action: @selector(enablePositionUpdatesAfterDelay)
      forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
    
  }

  [_overlayView addSubview: _progress];
  
  _nextLabel = [UILabel new];  
  _nextLabel.font = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]];
  if ((((NLSourceMediaServer *) _source).capabilities & SOURCE_MEDIA_SERVER_CAPABILITY_NEXT_TRACK) == 0)
    _nextLabel.textColor = [UIColor clearColor];
  else
    _nextLabel.textColor = [UIColor whiteColor];
  _nextLabel.backgroundColor = [UIColor clearColor];
  _nextLabel.text = NSLocalizedString( @"Next song: ", @"Label for the next song info in media server player view" );
  [_nextLabel sizeToFit];
  _nextLabel.frame = CGRectMake( 5, lineHeight * 5, _nextLabel.frame.size.width, _nextLabel.frame.size.height );
  [_overlayView addSubview: _nextLabel];
  
  _nextSong = [[UILabel alloc] initWithFrame:
               CGRectMake( _nextLabel.frame.size.width + 5, lineHeight * 5,
                          _overlayView.bounds.size.width - _nextLabel.frame.size.width - 10, _nextLabel.frame.size.height )];
  _nextSong.font = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]];
  _nextSong.backgroundColor = [UIColor clearColor];
  _nextSong.textAlignment = UITextAlignmentLeft;
  _nextSong.lineBreakMode = UILineBreakModeMiddleTruncation;
  [_overlayView addSubview: _nextSong];
  if ((((NLSourceMediaServer *) _source).capabilities & SOURCE_MEDIA_SERVER_CAPABILITY_NEXT_TRACK) == 0)
    _nextSong.textColor = [UIColor clearColor];
  else
    _nextSong.textColor = [UIColor whiteColor];

  // The table that will be shown if the view is flipped
  
  _detailView = [[UITableView alloc] initWithFrame: _flipBase.frame style: UITableViewStylePlain];
  _detailView.backgroundColor = [UIColor colorWithWhite: 0.1 alpha: 1.0];
  _detailView.separatorStyle = UITableViewCellSeparatorStyleNone;
  _detailView.dataSource = self;
  _detailView.delegate = self;
}

- (void) viewWillAppear: (BOOL) animated
{
  MainNavigationController *mainController = (MainNavigationController *) self.navigationController;

  [super viewWillAppear: animated];
  
  mainController.navigationBar.barStyle = UIBarStyleBlackOpaque;
  mainController.navigationBar.tintColor = nil;
  [mainController setAudioControlsStyle: UIBarStyleBlackTranslucent];
  [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque animated: YES];
  
  _stabilised = NO;
  [self releasePlayNotPossibleTimer];
  [self source: _mediaServer stateChanged: 0xFFFFFFFF];
  [_mediaServer addDelegate: self];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  
  if (_location != nil && _service != nil)
  {    
    //[self source: _mediaServer stateChanged: 0xFFFFFFFF];
    //[_mediaServer addDelegate: self];
    [(MainNavigationController *) self.navigationController showAudioControls: YES];
  }
}

- (void) viewWillDisappear: (BOOL) animated
{
  _stabilised = NO;
  [self releasePositionUpdatesTimer];
  [self releasePlayNotPossibleTimer];
  [super viewWillDisappear: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
  [_mediaServer removeDelegate: self];
  [super viewDidDisappear: animated];
}

- (void) source: (NLSourceMediaServer *) source stateChanged: (NSUInteger) flags
{
  if ((flags & SOURCE_MEDIA_SERVER_SONG_CHANGED) != 0)
    _song.text = source.song;
  if ((flags & SOURCE_MEDIA_SERVER_ALBUM_CHANGED) != 0)
    _album.text = source.album;
  if ((flags & SOURCE_MEDIA_SERVER_ARTIST_CHANGED) != 0)
    _artist.text = source.artist;
  if ((flags & (SOURCE_MEDIA_SERVER_GENRE_CHANGED|SOURCE_MEDIA_SERVER_COMPOSERS_CHANGED|
       SOURCE_MEDIA_SERVER_CONDUCTORS_CHANGED|SOURCE_MEDIA_SERVER_PERFORMERS_CHANGED|
       SOURCE_MEDIA_SERVER_SUB_GENRE_CHANGED)) != 0)
  {
    _detailDataRows = 2 + [source.composers count] + [source.conductors count] + [source.performers count];
    if (source.song != nil && [source.song length] > 0)
      ++_detailDataRows;
    if (source.artist != nil && [source.artist length] > 0)
      ++_detailDataRows;
    if (source.album != nil && [source.album length] > 0)
      ++_detailDataRows;
    if ((source.genre != nil && [source.genre length] > 0) || (source.subGenre != nil && [source.subGenre length] > 0))
      ++_detailDataRows;
    _detailTextHeight = [[UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]] lineSpacing];
  }
  
  if ((flags & (SOURCE_MEDIA_SERVER_SONG_CHANGED|SOURCE_MEDIA_SERVER_ALBUM_CHANGED|
                SOURCE_MEDIA_SERVER_ARTIST_CHANGED|SOURCE_MEDIA_SERVER_GENRE_CHANGED|
                SOURCE_MEDIA_SERVER_COMPOSERS_CHANGED|SOURCE_MEDIA_SERVER_CONDUCTORS_CHANGED|
                SOURCE_MEDIA_SERVER_PERFORMERS_CHANGED|SOURCE_MEDIA_SERVER_SUB_GENRE_CHANGED)) != 0)
  {
    [_detailView reloadData];
    [_detailView scrollToRowAtIndexPath: [NSIndexPath indexPathForRow: 0 inSection: 0]
                       atScrollPosition: UITableViewScrollPositionTop animated: NO];
  }

  if ((flags & SOURCE_MEDIA_SERVER_COVER_ART_CHANGED) != 0)
  {
    _backdrop.image = source.coverArt;
    _reflection.image = source.coverArt;
    if ([_detailView superview] == _flipBase)
      [_flipButton setBackgroundImage: source.coverArt forState: UIControlStateNormal];
  }
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
    _songIndex.text = [NSString stringWithFormat: 
                  NSLocalizedString( @"%u of %u", @"Format of song m of n" ),
                  source.songIndex, source.songTotal];
    if (source.songIndex == 0 || source.songTotal == 0)
      _songIndex.textColor = [UIColor clearColor];
    else
      _songIndex.textColor = [UIColor whiteColor];
  }
  if ((flags & SOURCE_MEDIA_SERVER_TRANSPORT_STATE_CHANGED) != 0)
  {
    if (_mediaServer.transportState == TRANSPORT_STATE_PLAY)
      [self setPlaying];
    else
      [self setPausedOrStopped];
  }
  if ((flags & SOURCE_MEDIA_SERVER_SHUFFLE_CHANGED) != 0)
    [self setShuffle: source.shuffle];
  if ((flags & SOURCE_MEDIA_SERVER_REPEAT_CHANGED) != 0)
    [self setRepeat: source.repeat];
  if ((flags & SOURCE_MEDIA_SERVER_NEXT_SONG_CHANGED) != 0)
  {
    NSString *nextSong = source.nextSong;
    
    _nextSong.text = nextSong;
    if ([nextSong length] == 0)
    {
      _nextLabel.textColor = [UIColor clearColor];
      _nextSong.textColor = [UIColor clearColor];
    }
    else
    {
      _nextLabel.textColor = [UIColor whiteColor];
      _nextSong.textColor = [UIColor whiteColor];
    }
  }
  
  // If we've nothing to show, go back to the library
  if (!_stabilised)
    _stabilised = (_isCurrentView && !source.playNotPossible);

  if (_isCurrentView && _stabilised && source.playNotPossible)
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

- (void) goBack: (id) control
{
  [self.navigationController popViewControllerAnimated: YES];
}

- (void) flipCurrentView: (UIButton *) button
{
  // Swap the image and rotate
  BOOL swapIn = [_flippingView superview] == _flipBase;
  
  [UIView beginAnimations: nil context: nil];
  [UIView setAnimationDuration: 0.75];

  if (swapIn)
  {
    [UIView setAnimationTransition: UIViewAnimationTransitionFlipFromRight forView: _flipBase cache: YES];
    [_flippingView removeFromSuperview];
    [_flipBase addSubview: _detailView];
  }
  else
  {
    [UIView setAnimationTransition: UIViewAnimationTransitionFlipFromLeft forView: _flipBase cache: YES];
    [_detailView removeFromSuperview];
    [_flipBase addSubview: _flippingView];
  }
  
  [UIView commitAnimations];
  
  [UIView beginAnimations: nil context: nil];
  [UIView setAnimationDuration: 0.75];
  
  if (swapIn)
  {
    [UIView setAnimationTransition: UIViewAnimationTransitionFlipFromRight forView: _flipButton cache: YES];
    [_flipButton setBackgroundImage: _mediaServer.coverArt forState: UIControlStateNormal];
  }
  else
  {
    [UIView setAnimationTransition: UIViewAnimationTransitionFlipFromLeft forView: _flipButton cache: YES];
    [_flipButton setBackgroundImage: [UIImage imageNamed: @"DetailsList.png"] forState: UIControlStateNormal];
  }
  
  [UIView commitAnimations];
}

- (void) setPlaying
{
  [_playPause setImage: [UIImage imageNamed: @"Pause.png"] forState: UIControlStateNormal];
  [_playPause removeTarget: self action: @selector(pressedPlay:) forControlEvents: UIControlEventTouchDown];
  [_playPause addTarget: self action: @selector(pressedPause:) forControlEvents: UIControlEventTouchDown];
}

- (void) setPausedOrStopped
{
  [_playPause setImage: [UIImage imageNamed: @"Play.png"] forState: UIControlStateNormal];
  [_playPause removeTarget: self action: @selector(pressedPause:) forControlEvents: UIControlEventTouchDown];
  [_playPause addTarget: self action: @selector(pressedPlay:) forControlEvents: UIControlEventTouchDown];
}

- (void) setShuffle: (BOOL) shuffle
{
  if (shuffle)
    _shuffleImage.image = [UIImage imageNamed: @"Shuffle-selected.png"];
  else
    _shuffleImage.image = [UIImage imageNamed: @"Shuffle.png"];
}

- (void) setRepeat: (NSUInteger) repeat
{
  switch (repeat)
  {
    case 1:
      _repeatImage.image = [UIImage imageNamed: @"Repeat-single.png"];
      break;
    case 2:
      _repeatImage.image = [UIImage imageNamed: @"Repeat-selected.png"];
      break;
    default:
      _repeatImage.image = [UIImage imageNamed: @"Repeat.png"];
      break;
  }
}

- (void) pressedPlay: (UIButton *) button
{
  [self setPlaying];
  _mediaServer.transportState = TRANSPORT_STATE_PLAY;
}

- (void) pressedPause: (UIButton *) button
{
  [self setPausedOrStopped];
  _mediaServer.transportState = TRANSPORT_STATE_PAUSE;
}

- (void) pressedStop: (UIButton *) button
{
  [self setPausedOrStopped];
  _mediaServer.transportState = TRANSPORT_STATE_STOP;
}

- (void) pressedRewind: (UIButton *) button
{
  [_mediaServer playPreviousTrack];
}

- (void) pressedFastForward: (UIButton *) button
{
  [_mediaServer playNextTrack];
}

- (void) pressedShuffle: (UIButton *) button
{
  BOOL newShuffle = !_mediaServer.shuffle;

  _mediaServer.shuffle = newShuffle;
  [self setShuffle: newShuffle];
}

- (void) pressedRepeat: (UIButton *) button
{
  NSUInteger newRepeat = _mediaServer.repeat;
  
  if (newRepeat == 0)
    newRepeat = _mediaServer.maxRepeat;
  else
    --newRepeat;
  
  _mediaServer.repeat = newRepeat;
  [self setRepeat: newRepeat];
}

- (void) pressedBackdrop: (UIButton *) button
{
  _overlayView.hidden = NO;
}

- (void) pressedOverlay: (UIButton *) button
{
  _overlayView.hidden = YES;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  return _detailDataRows;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"MyIdentifier"];
  if (cell == nil)
    cell = [[[UITableViewCell alloc] initDefaultWithFrame: CGRectMake( 0, 0, tableView.frame.size.width, (_detailTextHeight * 4) + 4 )
                                   reuseIdentifier: @"MyIdentifier"] autorelease];

  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
  NSArray *subviews = [cell.contentView subviews];
  NSUInteger count = [subviews count];
  NSUInteger i;
  
  for (i = 0; i < count; ++i)
    [[subviews objectAtIndex: i] removeFromSuperview];

  if (indexPath.row > 0 && indexPath.row < _detailDataRows - 1)
  {
    NSUInteger index = indexPath.row - 1;
    NSString *iconName;
    NSString *titleText;
    NSString *contentText;
    
    if (_mediaServer.song == nil || [_mediaServer.song length] == 0)
      ++index;
    if ((_mediaServer.artist == nil || [_mediaServer.artist length] == 0) && index > 0)
      ++index;
    if ((_mediaServer.album == nil || [_mediaServer.album length] == 0) && index > 1)
      ++index;
    if (((_mediaServer.genre == nil || [_mediaServer.genre length] == 0) &&
      (_mediaServer.subGenre == nil || [_mediaServer.subGenre length] == 0)) && index > 2)
      ++index;
    
    switch (index)
    {
      case 0:
        iconName = @"Songs-selected.png";
        titleText = NSLocalizedString( @"Title", @"Label for title of song" );
        contentText = _mediaServer.song;
        break;
      case 1:
        iconName = @"Artists-selected.png";
        titleText = NSLocalizedString( @"Artist", @"Label for artist for song" );
        contentText = _mediaServer.artist;
        break;
      case 2:
        iconName = @"Albums-selected.png";
        titleText = NSLocalizedString( @"Album", @"Label for album for song" );
        contentText = _mediaServer.album;
        break;
      case 3:
        iconName = @"Genres-selected.png";
        titleText = NSLocalizedString( @"Genre", @"Label for genre of song" );
        contentText = _mediaServer.genre;
        if (_mediaServer.subGenre != nil && [_mediaServer.subGenre length] > 0)
        {
          if (contentText == nil || [contentText length] == 0 || [contentText isEqualToString: @"<Root>"])
            contentText = _mediaServer.subGenre;
          else
            contentText = [NSString stringWithFormat: @"%@, %@", contentText, _mediaServer.subGenre];
        }
        break;
      default:
        index -= 4;
        if (index < [_mediaServer.composers count])
        {
          iconName = @"Composers-selected.png";
          titleText = NSLocalizedString( @"Composer", @"Label for composer of song" );
          contentText = [_mediaServer.composers objectAtIndex: index];
        }
        else
        {
          index -= [_mediaServer.composers count];
          if (index < [_mediaServer.conductors count])
          {
            iconName = @"Conductors-selected.png";
            titleText = NSLocalizedString( @"Conductor", @"Label for conductor of song" );
            contentText = [_mediaServer.conductors objectAtIndex: index];
          }
          else
          {
            index -= [_mediaServer.conductors count];
            if (index >= [_mediaServer.performers count])
              titleText = nil;
            else
            {
              iconName = @"Performers-selected.png";
              titleText = NSLocalizedString( @"Performer", @"Label for performer of song" );
              contentText = [_mediaServer.performers objectAtIndex: index];
            }
          }
        }
        break;
    }
    
    if (titleText != nil)
    {
      CGFloat rowHeight = (_detailTextHeight * 4) + 4;
      UIView *backdrop = [[UIView alloc] initWithFrame: CGRectMake( 0, 0, tableView.frame.size.width, rowHeight )];
      UIImageView *icon = [[UIImageView alloc] initWithImage: [UIImage imageNamed: iconName]];

      if (indexPath.row % 2 == 1)
        backdrop.backgroundColor = [UIColor colorWithWhite: 0.3 alpha: 1.0];
      else
        backdrop.backgroundColor = [UIColor darkGrayColor];

      [icon sizeToFit];
      icon.frame = CGRectOffset( icon.frame, 5, (40 - icon.frame.size.height + 1) / 2 );
      [backdrop addSubview: icon];
      [icon release];

      UILabel *title = [[UILabel alloc] initWithFrame:
                        CGRectMake( icon.frame.size.width + 10, 2,
                                   tableView.frame.size.width - icon.frame.size.width - 10, _detailTextHeight )];
      UILabel *details = [UILabel new];
      UIFont *textFont = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]];

      title.font = textFont;
      title.textColor = [UIColor whiteColor];
      title.text = titleText;
      title.backgroundColor = [UIColor clearColor];
      title.lineBreakMode = UILineBreakModeMiddleTruncation;
      [backdrop addSubview: title];
      [title release];
    
      details.font = textFont;
      details.textColor = [UIColor lightGrayColor];
      details.text = contentText;
      details.backgroundColor = [UIColor clearColor];
      [details sizeToFit];

      CGFloat maxWidth = tableView.frame.size.width - icon.frame.size.width - 15;
      CGSize maxTextArea = CGSizeMake( maxWidth, _detailTextHeight * 3 );
      CGSize actualTextArea = [contentText sizeWithFont: textFont constrainedToSize: maxTextArea
                                          lineBreakMode: UILineBreakModeWordWrap];
      NSUInteger numberOfLines = (NSUInteger) (3 * (actualTextArea.height / maxTextArea.height));
     
      details.numberOfLines = 3;
      details.frame = CGRectMake( icon.frame.size.width + 10, _detailTextHeight + 2, maxWidth, _detailTextHeight * numberOfLines );
      
      [backdrop addSubview: details];
      [details release];
      
      [cell.contentView addSubview: backdrop];
      [backdrop release];
    }
  }
  
  return cell;
}

- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath
{
  if (indexPath.row == 0)
    return 43;
  else if (indexPath.row >= _detailDataRows - 1)
    return _flipBase.frame.size.height - _backdrop.frame.size.height; 
  else
    return (_detailTextHeight * 4) + 4;
}

- (void) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags
{
  [super renderer: renderer stateChanged: flags];

  if ((flags & NLRENDERER_AUDIO_SESSION_CHANGED) != 0)
  {
    if (renderer.audioSessionActive)
      _transportBar.backgroundColor = [StandardPalette multizoneTintColourWithAlpha: 0.7];
    else
      _transportBar.backgroundColor = [UIColor colorWithWhite: 0 alpha: 0.3];
  }
}

- (void) setPosition: (id) position
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
  if (_isCurrentView && _stabilised && ((NLSourceMediaServer *) _source).playNotPossible)
    [self.navigationController popViewControllerAnimated: YES];
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
  [_artist release];
  [_song release];
  [_album release]; 
  [_backdrop release];
  [_reflection release];
  [_flipButton release];
  [_repeatImage release];
  [_shuffleImage release];
  [_flipBase release];
  [_flippingView release];
  [_detailView release];
  [_playPause release];
  [_overlayView release];
  [_songIndex release];
  [_progress release];
  [_timeSoFar release];
  [_timeRemaining release];
  [_nextSong release];
  [self releasePositionUpdatesTimer];
  [self releasePlayNotPossibleTimer];
  [super dealloc];
}

@end
