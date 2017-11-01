//
//  TimersViewCell.m
//  iLinX
//
//  Created by mcf on 15/06/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "TimersViewCell.h"
#import "DeprecationHelper.h"
#import "StandardPalette.h"
#import "TimersViewController.h"
#import "NLTimer.h"

@implementation TimersViewCell

@synthesize
  timer = _timer;

- (id) initDefaultWithFrame: (CGRect) frame reuseIdentifier: (NSString *) reuseIdentifier
               switchTarget: (id) target switchSelector: (SEL) selector
{
  if (self = [super initDefaultWithFrame: frame reuseIdentifier: reuseIdentifier])
  {
    UIImageView *fade = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"TimerItemFade.png"]];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryType = UITableViewCellAccessoryNone;
    [self setHasAccessoryWhenEditing: YES];
    [self setAccessoryWhenEditing: UITableViewCellAccessoryDisclosureIndicator];
    fade.backgroundColor = [StandardPalette timerBarTint];
    self.backgroundView = fade;
    [fade release];
    
    fade = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"TimerItemFade.png"]];
    fade.backgroundColor = [StandardPalette selectedTableCellColour];
    self.selectedBackgroundView = fade;
    [fade release];
    
    _timeLabel = [[UILabel alloc] initWithFrame: CGRectMake( 10, 14, 200, 28 )];
    _timeLabel.font = [UIFont boldSystemFontOfSize: 24];
    _timeLabel.backgroundColor = [UIColor clearColor];
    _timeLabel.shadowOffset = CGSizeMake( 0, 1 );
    [self.contentView addSubview: _timeLabel];
    
    _ampmSuffixLabel = [[UILabel alloc] initWithFrame: CGRectMake( 40, 24, 100, 14 )];
    _ampmSuffixLabel.font = [UIFont systemFontOfSize: 12];
    _ampmSuffixLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview: _ampmSuffixLabel];
    
    _dateLabel = [[UILabel alloc] initWithFrame: CGRectMake( 10, 42, 200, 18 )];
    _dateLabel.font = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]];
    _dateLabel.backgroundColor = [UIColor clearColor];
    _dateLabel.shadowOffset = CGSizeMake( 0, 1 );
    [self.contentView addSubview: _dateLabel];
    
    _nameLabel = [[UILabel alloc] initWithFrame: CGRectMake( 10, 60, 200, 18 )];
    _nameLabel.font = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]];
    _nameLabel.backgroundColor = [UIColor clearColor];
    _nameLabel.shadowOffset = CGSizeMake( 0, 1 );
    [self.contentView addSubview: _nameLabel];
    
    _enabledSwitch = [[UISwitch alloc] initWithFrame: CGRectMake( 216, 32, 94, 27 )];
    [_enabledSwitch addTarget: target action: selector forControlEvents: UIControlEventValueChanged];
    [self.contentView addSubview: _enabledSwitch];
  }
  
  return self;
}

- (void) setTimer: (NLTimer *) timer
{
  [_timer release];
  _timer = [timer retain];

  if (timer == nil)
  {
    _timeLabel.text = @"";
    _ampmSuffixLabel.text = @"";
    _dateLabel.text = @"";
    _nameLabel.text = @"";
    _enabledSwitch.on = NO;
  }
  else
  {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    NSDate *time = [NSDate dateWithTimeIntervalSince1970: timer.eventTime * 60];
    NSString *timeString;
    NSString *suffix = [dateFormatter AMSymbol];

    [dateFormatter setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: 0]];
    [dateFormatter setDateStyle: NSDateFormatterNoStyle];
    [dateFormatter setTimeStyle: NSDateFormatterShortStyle];
    timeString = [dateFormatter stringFromDate: time];
    

    if (![timeString hasSuffix: suffix])
    {
      suffix = [dateFormatter PMSymbol];
      if (![timeString hasSuffix: suffix])
        suffix = nil;
    }
    
    if (suffix == nil)
    {
      _timeLabel.text = timeString;
      _ampmSuffixLabel.text = @"";      
    }
    else
    {
      CGSize timeSize;

      timeString = [[timeString substringToIndex: [timeString length] - [suffix length]]
                    stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
      timeSize = [timeString sizeWithFont: _timeLabel.font];
      _timeLabel.text = timeString;
      _ampmSuffixLabel.text = suffix;
      _ampmSuffixLabel.frame = CGRectMake( _timeLabel.frame.origin.x + timeSize.width, _ampmSuffixLabel.frame.origin.y,
                                          _ampmSuffixLabel.frame.size.width, _ampmSuffixLabel.frame.size.height );
    }
    
    if (timer.singleEventDate == nil)
      _dateLabel.text = [TimersViewController dayListForRepeatMask: timer.repeatedDayBitmask];
    else
    {
#if TIME_ZONES_REQUIRED
      [dateFormatter setTimeZone: [NSTimeZone localTimeZone]];
#else
      [dateFormatter setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: 0]];
#endif
      [dateFormatter setDateStyle: NSDateFormatterMediumStyle];
      [dateFormatter setTimeStyle: NSDateFormatterNoStyle];
      _dateLabel.text = [dateFormatter stringFromDate: timer.singleEventDate];
    }
    
    _nameLabel.text = timer.name;
    _enabledSwitch.on = timer.enabled;
    [dateFormatter release];
  }
}

- (NSInteger) timerTag
{
  return _timerTag;
}

- (void) setTimerTag: (NSInteger) tag
{
  _timerTag = tag;
  _enabledSwitch.tag = tag;
}

- (void) dealloc 
{
  [_timer release];
  [_timeLabel release];
  [_ampmSuffixLabel release];
  [_dateLabel release];
  [_nameLabel release];
  [_enabledSwitch release];
  [super dealloc];
}

- (void) setEditing: (BOOL) editing animated: (BOOL) animated
{
  [super setEditing: editing animated: animated];
  
  if (editing)
  {
    self.selectionStyle = UITableViewCellSelectionStyleBlue;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    _enabledSwitch.hidden = YES;
    _enabledSwitch.enabled = NO;
  }
  else
  {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryType = UITableViewCellAccessoryNone;
    _enabledSwitch.hidden = NO;
    _enabledSwitch.enabled = YES;
  }
}

// Update the text color of each label when entering and exiting selected mode.
- (void) setSelected: (BOOL) selected animated: (BOOL) animated
{
  [super setSelected: selected animated: animated];
  
  if (selected && self.editing)
  {
    _timeLabel.textColor = [StandardPalette selectedTableTextColour];
    _timeLabel.shadowColor = [UIColor blackColor];
    _ampmSuffixLabel.textColor = [StandardPalette selectedTableTextColour];
    _dateLabel.textColor = [StandardPalette selectedTableTextColour];
    _dateLabel.shadowColor = [UIColor blackColor];
    _nameLabel.textColor = [StandardPalette selectedTableTextColour];
    _nameLabel.shadowColor = [UIColor blackColor];
  } 
  else
  {
    _timeLabel.textColor = [StandardPalette tableTextColour];
    _timeLabel.shadowColor = [UIColor whiteColor];
    _ampmSuffixLabel.textColor = [StandardPalette tableTextColour];
    _dateLabel.textColor = [StandardPalette tableTextColour];
    _dateLabel.shadowColor = [UIColor whiteColor];
    _nameLabel.textColor = [StandardPalette alternativeTableTextColour];
    _nameLabel.shadowColor = [UIColor whiteColor];
  }
}

@end
