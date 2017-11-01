//
//  TimersViewCellIPad.m
//  iLinX
//
//  Created by mcf on 25/10/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "TimersViewCellIPad.h"
#import "DeprecationHelper.h"
#import "StandardPalette.h"
#import "TimersViewControllerIPad.h"
#import "NLTimer.h"

@interface TimersViewCellIPad ()

- (void) setTimerEnabled: (BOOL) on;
- (void) setEnabledSwitchState: (BOOL) on;

@end

@implementation TimersViewCellIPad

@synthesize
  timeLabel = _timeLabel,
  ampmSuffixLabel = _ampmSuffixLabel,
  dateLabel = _dateLabel,
  nameLabel = _nameLabel,
  enabledSwitch = _enabledSwitch,
  timer = _timer;


- (id) initWithCoder: (NSCoder *) decoder
{
  if (self = [super initWithCoder: decoder])
  {
    self.timeLabel = [decoder decodeObjectForKey: @"timeLabel"];
    self.ampmSuffixLabel = [decoder decodeObjectForKey: @"ampmSuffixLabel"];
    self.dateLabel = [decoder decodeObjectForKey: @"dateLabel"];
    self.nameLabel = [decoder decodeObjectForKey: @"nameLabel"];
    self.enabledSwitch = [decoder decodeObjectForKey: @"enabledSwitch"];
  }
  
  return self;
}

- (void) encodeWithCoder: (NSCoder *) encoder
{
  [super encodeWithCoder: encoder];
  [encoder encodeObject: _timeLabel forKey: @"timeLabel"];
  [encoder encodeObject: _ampmSuffixLabel forKey: @"ampmSuffixLabel"];
  [encoder encodeObject: _dateLabel forKey: @"dateLabel"];
  [encoder encodeObject: _nameLabel forKey: @"nameLabel"];
  [encoder encodeObject: _enabledSwitch forKey: @"enabledSwitch"];
}

- (void) setEditing: (BOOL) editing animated: (BOOL) animated
{
  [super setEditing: editing animated: animated];
  
  if (editing)
  {
    _enabledSwitch.hidden = YES;
  }
  else
  {
    _enabledSwitch.hidden = NO;
  }
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
    [self setEnabledSwitchState: NO]; 
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
      _dateLabel.text = [TimersViewControllerIPad dayListForRepeatMask: timer.repeatedDayBitmask];
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
    [self setEnabledSwitchState: timer.enabled];
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

- (IBAction) toggleEnabledSwitch
{
  [self setTimerEnabled: !_timer.enabled];
}

- (IBAction) enabledSwitchOff
{
  [self setTimerEnabled: NO];
}

- (IBAction) enabledSwitchOn
{
  [self setTimerEnabled: YES];
}

- (void) setTimerEnabled: (BOOL) on
{
  _timer.enabled = on;
  [_timer commitChanges];
  [self setEnabledSwitchState: on];
}

- (void) setEnabledSwitchState: (BOOL) on
{
  if (_enabledSwitch != nil)
  {
    if ([_enabledSwitch isKindOfClass: [UISwitch class]])
      ((UISwitch *) _enabledSwitch).on = on;
    else if ([_enabledSwitch isKindOfClass: [UIButton class]])
    {
      UIButton *button = (UIButton *) _enabledSwitch;

      if (_switchOffImage == nil)
      {
        _switchOffImage = [[button backgroundImageForState: UIControlStateNormal] retain];
        _switchOnImage = [[button backgroundImageForState: UIControlStateSelected] retain];
        [button setBackgroundImage: nil forState: UIControlStateSelected];
      }
      
      if (on)
        [button setBackgroundImage: _switchOnImage forState: UIControlStateNormal];
      else
        [button setBackgroundImage: _switchOffImage forState: UIControlStateNormal];
    }
  }
}

- (void) dealloc 
{
  [_timeLabel release];
  [_ampmSuffixLabel release];
  [_dateLabel release];
  [_nameLabel release];
  [_enabledSwitch release];
  [_switchOnImage release];
  [_switchOffImage release];
  [_timer release];
  [super dealloc];
}

@end
