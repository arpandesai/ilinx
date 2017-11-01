//
//  TimersViewCellIPad.h
//  iLinX
//
//  Created by mcf on 25/10/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NLTimer;

@interface TimersViewCellIPad : UITableViewCell <NSCoding>
{
@protected
  NLTimer * _timer;
  NSInteger _timerTag;
  UILabel *_timeLabel;
  UILabel *_ampmSuffixLabel;
  UILabel *_dateLabel;
  UILabel *_nameLabel;
  UIControl *_enabledSwitch;
  UIImage *_switchOffImage;
  UIImage *_switchOnImage;
}

@property (nonatomic, retain) IBOutlet UILabel *timeLabel;
@property (nonatomic, retain) IBOutlet UILabel *ampmSuffixLabel;
@property (nonatomic, retain) IBOutlet UILabel *dateLabel;
@property (nonatomic, retain) IBOutlet UILabel *nameLabel;
@property (nonatomic, retain) IBOutlet UIControl *enabledSwitch;
@property (nonatomic, retain) NLTimer *timer;
@property (assign) NSInteger timerTag;

- (IBAction) toggleEnabledSwitch;
- (IBAction) enabledSwitchOff;
- (IBAction) enabledSwitchOn;

@end
