//
//  MediaViewControllerIPad.h
//  iLinX
//
//  Created by mcf on 09/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioSubViewControllerIPad.h"
#import "DataSourceViewController.h"
#import "MediaSubMenuViewController.h"
#import "NLSourceMediaServer.h"


@class CustomSliderIPad;
@class MediaRootMenuViewController;
@class MediaNowPlayingController;

@interface MediaViewControllerIPad : AudioSubViewControllerIPad <NLSourceMediaServerDelegate, 
                                                                 DataSourceViewControllerDelegate, 
                                                                 MediaSubMenuDelegate>
{
@private
  IBOutlet CustomSliderIPad *_progress;
  IBOutlet UILabel *_timeSoFar;
  IBOutlet UILabel *_timeRemaining;
  IBOutlet UIButton *_playButton;
  IBOutlet UIButton *_pauseButton;
  IBOutlet UIButton *_repeatButton;
  IBOutlet UIButton *_shuffleButton;
  IBOutlet UILabel *_songIndex;
  IBOutlet UIView *_nowPlayingSummaryArea;
  IBOutlet UIImageView *_coverArt;
  IBOutlet UILabel *_artist;
  IBOutlet UILabel *_song;
  IBOutlet UILabel *_album;
  IBOutlet UILabel *_nextSong;
  IBOutlet UISegmentedControl *_listingStyle;
  IBOutlet MediaRootMenuViewController *_rootMenuViewController;
  IBOutlet UIView *_subMenuArea;
  IBOutlet UINavigationController *_subMenuNavigationController;
  IBOutlet MediaNowPlayingController *_mediaNowPlayingController;
  UIView *_nowPlayingView; 
  CGRect _nowPlayingSmallRect;
  UIImageView *_nowPlayingSnapshot;
  UIImage *_cacheRepeatImage;
  UIImage *_cacheRepeatOneImage;
  
  NLSourceMediaServer *_mediaServer;
  BOOL _ignorePositionUpdates;
  NSUInteger _debouncePlayState;
  NSTimer *_ignorePositionUpdatesDebounceTimer;
  NSString *_nowPlayingTitleFormat;
  NSString *_nextTrackTitleFormat;
  BOOL _stabilised;
  NSTimer *_playNotPossibleTimer;
}

@property (readonly) NLSourceMediaServer *mediaServer;
@property (readonly) UILabel *timeSoFar;
@property (readonly) UILabel *timeRemaining;
@property (readonly) CustomSliderIPad *progress;
@property (readonly) UILabel *songIndex;
@property (readonly) UILabel *nextSong;
@property (readonly) UIButton *playButton;
@property (readonly) UIButton *pauseButton;
@property (readonly) UIButton *repeatButton;
@property (readonly) UIButton *shuffleButton;
@property (readonly) UIImageView *coverArt;

- (IBAction) sourcesPressed: (id) button;
- (IBAction) pressedStop: (id) button;
- (IBAction) pressedPlay: (id) button;
- (IBAction) pressedPause: (id) button;
- (IBAction) toggledPlayPause: (id) button;
- (IBAction) pressedRewind: (id) button;
- (IBAction) pressedFastForward: (id) button;
- (IBAction) toggleShuffle;
- (IBAction) toggleRepeat;
- (IBAction) setPosition: (id) slider;
- (IBAction) disablePositionUpdates;
- (IBAction) enablePositionUpdatesAfterDelay;
- (IBAction) pressedNowPlaying: (id) button;
- (IBAction) dismissNowPlaying: (id) button;
- (IBAction) listingStyleChanged: (id) control;

@end
