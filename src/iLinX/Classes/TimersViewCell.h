//
//  TimersViewCell.h
//  iLinX
//
//  Created by mcf on 15/06/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NLTimer;

@interface TimersViewCell : UITableViewCell
{
@protected
  NLTimer * _timer;
  NSInteger _timerTag;
  UILabel *_timeLabel;
  UILabel *_ampmSuffixLabel;
  UILabel *_dateLabel;
  UILabel *_nameLabel;
  UISwitch *_enabledSwitch;
}

@property (nonatomic, retain) NLTimer *timer;
@property (assign) NSInteger timerTag;

- (id) initDefaultWithFrame: (CGRect) frame reuseIdentifier: (NSString *) reuseIdentifier
               switchTarget: (id) target switchSelector: (SEL) selector;

@end
