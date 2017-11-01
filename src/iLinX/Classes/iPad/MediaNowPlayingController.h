//
//  MediaNowPlayingController.h
//  iLinX
//
//  Created by mcf on 14/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLSourceMediaServer.h"

@class CustomSliderIPad;
@class MediaViewControllerIPad;
@class PseudoBarButton;
@interface MediaNowPlayingController : UIViewController <UITableViewDelegate, UITableViewDataSource,
                                                         NLSourceMediaServerDelegate>
{
@private
  IBOutlet UIView 		   *_topBar;
  IBOutlet UIView 		*_bottomBar;
  IBOutlet CustomSliderIPad 	*_progress;
  IBOutlet UILabel  		*_timeSoFar;
  IBOutlet UILabel  		*_timeRemaining;
  IBOutlet UIButton 		*_playButton;
  IBOutlet UIButton 		*_pauseButton;
  IBOutlet PseudoBarButton 	*_sourcesButton;
  IBOutlet UILabel  		*_songIndex;
  IBOutlet UIView               *_coverArtArea;
  IBOutlet UIImageView 		*_coverArt;
  IBOutlet UIImageView          *_coverArtReflection;
  IBOutlet UILabel   		*_artist;
  IBOutlet UILabel 		*_song;
  IBOutlet UILabel 		*_album;
  IBOutlet UILabel 		*_nextSong;
  IBOutlet UIButton 		*_shuffleButton;
  IBOutlet UIButton 		*_repeatButton;
  IBOutlet UIView               *_detailsFlipBase;
  IBOutlet UIButton		*_detailsButton;
  IBOutlet UIImageView          *_secondaryCoverArt;
  IBOutlet UIView 		*_flipBase;
  IBOutlet UIView 		*_detailsView;
  IBOutlet UITableView 		*_detailsTable;
  MediaViewControllerIPad *_owner;
  NSUInteger _detailDataRows;
  NSUInteger _minRows;
  CGFloat _detailTextHeight;
  UIImage *_cacheDetailOffBackground;
  UIImage *_cacheDetailOffForeground;
  UIImage *_cacheDetailOnBackground;
  UIImage *_cacheDetailOnForeground;
  UIImage *_cacheRepeatImage;
  UIImage *_cacheRepeatOneImage;
}

@property (nonatomic, assign) IBOutlet MediaViewControllerIPad *owner;
@property (readonly) UIView *coverArtView;

- (IBAction) toggleControls;
- (IBAction) toggleDetails;
- (IBAction) resetToCoverArt;

@end
