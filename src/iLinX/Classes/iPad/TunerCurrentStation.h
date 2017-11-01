//
//  TunerCurrentStation.h
//  iLinX
//
//  Created by Tony Short on 08/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLSourceTuner.h"
#import "TunerViewControllerIPad.h"

@interface TunerCurrentStation : UIView 
{
  TunerViewControllerIPad *_parentController;
  
  IBOutlet UILabel *_channelNameLabel;
  IBOutlet UILabel *_genreLabel;
  IBOutlet UILabel *_genre;
  IBOutlet UILabel *_noLogoCaptionLabel;
  IBOutlet UIImageView *_logoImageView;
  IBOutlet UILabel *_artistLabel;
  IBOutlet UILabel *_artist;
  IBOutlet UILabel *_radioTextLabel;
  IBOutlet UILabel *_radioText;
  IBOutlet UILabel *_songLabel;
  IBOutlet UILabel *_song;
  IBOutlet UILabel *_channelNum;
  NSInteger _radioTextVisibleOffset;
  NSString *_pendingRadioText;	
}

- (void) source: (NLSourceTuner *) source stateChanged: (NSUInteger) flags;
- (void) positionControls;

@property (nonatomic, assign) IBOutlet TunerViewControllerIPad *parentController;
@property (readonly) NSString *channelName;
@property (readonly) NSString *channelNum;

@end
