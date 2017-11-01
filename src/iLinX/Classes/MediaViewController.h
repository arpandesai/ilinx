//
//  MediaViewController.h
//  iLinX
//
//  Created by mcf on 19/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVViewController.h"
#import "NLSourceMediaServer.h"

@class CustomSlider;

@interface MediaViewController : AVViewController <NLSourceMediaServerDelegate, UITableViewDataSource, UITableViewDelegate>
{
@private
  NLSourceMediaServer *_mediaServer;
  UIButton *_flipButton;
  UIImageView *_repeatImage;
  UIImageView *_shuffleImage;
  UIView *_flipBase;
  UIView *_flippingView;
  UITableView *_detailView;
  UIImageView *_backdrop;
  UIImageView *_reflection;
  UIView *_transportBar;
  UILabel *_artist;
  UILabel *_song;
  UILabel *_album;
  UIButton *_overlayView;
  UILabel *_songIndex;
  CustomSlider *_progress;
  UILabel *_timeSoFar;
  UILabel *_timeRemaining;
  UILabel *_nextLabel;
  UILabel *_nextSong;
  UIButton *_playPause;
  NSUInteger _detailDataRows;
  CGFloat _detailTextHeight;
  BOOL _ignorePositionUpdates;
  NSTimer *_ignorePositionUpdatesDebounceTimer;
  BOOL _stabilised;
  NSTimer *_playNotPossibleTimer;
}

@end
