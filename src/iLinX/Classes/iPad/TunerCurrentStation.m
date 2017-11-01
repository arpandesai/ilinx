//
//  TunerCurrentStation.m
//  iLinX
//
//  Created by Tony Short on 08/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <QuartzCore/CALayer.h>
#import "TunerCurrentStation.h"
#import "DeprecationHelper.h"

@interface TunerCurrentStation ()

- (void) noFeedbackSource: (NLSourceTuner *) source stateChanged: (NSUInteger) flags;
- (void) digitalSource: (NLSourceTuner *) source stateChanged: (NSUInteger) flags;
- (void) handleRadioText: (NSString *) radioText;
- (void) analogSource: (NLSourceTuner *) source stateChanged: (NSUInteger) flags;
- (void) satelliteSource: (NLSourceTuner *) source stateChanged: (NSUInteger) flags;

@end

@implementation TunerCurrentStation

@synthesize parentController = _parentController;

- (NSString *) channelName
{
  return _channelNameLabel.text;
}

- (NSString *) channelNum
{
  return _channelNum.text;
}

- (void) dealloc 
{
  [_channelNameLabel release];
  [_genreLabel release];
  [_genre release];
  [_noLogoCaptionLabel release];
  [_logoImageView release];
  [_artistLabel release];
  [_artist release];
  [_radioTextLabel release];
  [_radioText release];
  [_songLabel release];
  [_song release];
  [_channelNum release];
  [_pendingRadioText release];
  [super dealloc];
}

- (void) hideControls
{	
  _artistLabel.hidden = ![_parentController isSatellite];
  _artist.hidden = ![_parentController isSatellite];
  _songLabel.hidden = ![_parentController isSatellite];
  _song.hidden = ![_parentController isSatellite];
  _radioTextLabel.hidden = [_parentController isIRTuner];
  _radioText.hidden = [_parentController isIRTuner];
}

- (void) positionControls
{
  _noLogoCaptionLabel.layer.borderColor = [[UIColor grayColor] CGColor];
  _noLogoCaptionLabel.layer.borderWidth = 1.0;
  
  NSInteger yCursor = 0;
  CGRect frame;
  
  // Channel num relevant for analog
  if ([_parentController isAnalog])
  {
    if (_channelNum.superview.tag == 99)
    {
      frame = _channelNum.frame;
      _channelNum.frame = CGRectMake( frame.origin.x, yCursor, frame.size.width, frame.size.height );
    }
  }
  
  if (_genreLabel.superview.tag == 99)
  {
    frame = _genreLabel.frame;
    _genreLabel.frame = CGRectMake( frame.origin.x, yCursor, frame.size.width, frame.size.height );
  }
  
  if (_genre.superview.tag == 99)
  {
    frame = _genre.frame;
    _genre.frame = CGRectMake( frame.origin.x, yCursor, frame.size.width, frame.size.height );
    yCursor += 29;
  }
  yCursor += 59;	// Past station name
  
  // Radio Text needs to be below Song / artist for satellite
  if ([_parentController isSatellite])
  {
    if (_songLabel.superview.tag == 99)
    {
      frame = _songLabel.frame;
      _songLabel.frame = CGRectMake( frame.origin.x, yCursor, frame.size.width, frame.size.height );
    }
    
    if (_song.superview.tag == 99)
    {
      frame = _song.frame;
      _song.frame = CGRectMake( frame.origin.x, yCursor, frame.size.width, frame.size.height );
      yCursor += 29;
    }
    
    if (_artistLabel.superview.tag == 99)
    {
      frame = _artistLabel.frame;
      _artistLabel.frame = CGRectMake( frame.origin.x, yCursor, frame.size.width, frame.size.height );
    }
    
    if (_artist.superview.tag == 99)
    {
      frame = _artist.frame;
      _artist.frame = CGRectMake( frame.origin.x, yCursor, frame.size.width, frame.size.height );
      yCursor += 29;
    }
    
  }
  
  if (_radioTextLabel.superview.tag == 99)
  {
    frame = _radioTextLabel.frame;
    _radioTextLabel.frame = CGRectMake( frame.origin.x, yCursor, frame.size.width, frame.size.height );
  }
  
  if (_radioText.superview.tag == 99)
  {
    frame = _radioText.frame;
    _radioText.frame = CGRectMake( frame.origin.x, yCursor, frame.size.width, self.frame.size.height - yCursor );
  }
}

- (void) source: (NLSourceTuner *) source stateChanged: (NSUInteger) flags
{
  [self hideControls];
  
  if ((flags & SOURCE_TUNER_BAND_CHANGED) != 0)
    [self positionControls];			// Maybe need to add/remove channel frequency
  
  if ([_parentController isIRTuner])
  {
    [self noFeedbackSource: source stateChanged: flags];
    return;
  }
  
  if ([_parentController isSatellite])
    [self satelliteSource: source stateChanged: flags];
  else if ([_parentController isDAB])
    [self digitalSource: source stateChanged: flags];
  else /*if ([_parentController isAnalog]) - assume this, so we at least get some output */
    [self analogSource: source stateChanged: flags];
  
  if ((flags & SOURCE_TUNER_GENRE_CHANGED) != 0)
  {
    if (source.genre == nil || [source.genre length] == 0)
      _genre.text = @"";
    else
      _genre.text = source.genre;
  }
  
  if ((flags & SOURCE_TUNER_ARTWORK_CHANGED) != 0)
  {
    _noLogoCaptionLabel.hidden = (source.artwork != nil);
    _logoImageView.image = source.artwork;
    [_logoImageView sizeToFit];
  }
}

- (void) noFeedbackSource: (NLSourceTuner *) source stateChanged: (NSUInteger) flags
{
  if ((flags & SOURCE_TUNER_CAPTION_CHANGED) != 0)
  {
    if (source.caption == nil || [source.caption length] == 0)
      _channelNameLabel.text = source.displayName;
    else
      _channelNameLabel.text = source.caption;
    
    _noLogoCaptionLabel.text = source.caption;
    _logoImageView.image = nil;		
  }
}

- (void) digitalSource: (NLSourceTuner *) source stateChanged: (NSUInteger) flags
{
  BOOL bandChanged = ((flags & SOURCE_TUNER_BAND_CHANGED) != 0);
  
  if (bandChanged)
  {
    _channelNameLabel.text = @"";
    _song.text = @"";
    _artist.text = @"";
    _genre.text = @"";
    _radioText.text = @"";
    _channelNum.text = source.channelNum;
  }
  
  if ([source.controlState isEqualToString: @"REFRESH"])
  {
    _channelNameLabel.text = NSLocalizedString( @"Refreshing", @"Title when refreshing DAB tuner stations" );
    _genre.text = @"";
    _noLogoCaptionLabel.text = @"";
    _radioText.text = @"";
  }
  else
  {
    BOOL changed = bandChanged || ((flags & SOURCE_TUNER_CONTROL_STATE_CHANGED) != 0);
    
    if (changed || (flags & SOURCE_TUNER_CHANNEL_NAME_CHANGED) != 0)
    {
      _channelNameLabel.text = source.channelName;
      _noLogoCaptionLabel.text = source.channelName;
      _radioText.text = @"";
    }
    
    if ((changed || (flags & SOURCE_TUNER_CAPTION_CHANGED) != 0) && (source.caption != nil) && ([source.caption length] > 0))
      [self handleRadioText: source.caption];
  }
}

- (void) analogSource: (NLSourceTuner *) source stateChanged: (NSUInteger) flags
{
  BOOL bandChanged = ((flags & SOURCE_TUNER_BAND_CHANGED) != 0);
  BOOL changed = bandChanged || ((flags & SOURCE_TUNER_CONTROL_STATE_CHANGED) != 0);
  
  if (changed || (flags & (SOURCE_TUNER_CHANNEL_NUM_CHANGED|SOURCE_TUNER_CHANNEL_NAME_CHANGED)) != 0)
    _radioText.text = @"";
  
  if (changed || (flags & (SOURCE_TUNER_CHANNEL_NUM_CHANGED|SOURCE_TUNER_CHANNEL_NAME_CHANGED|SOURCE_TUNER_CAPTION_CHANGED)) != 0)
  {
    if (source.channelName != nil && [source.channelName length] > 0)
    {
      _channelNameLabel.text = source.channelName;
      _channelNum.text = source.channelNum;
      _noLogoCaptionLabel.text = source.channelName;
    }
    else if (source.channelNum != nil && [source.channelNum length] > 0)
    {
      _channelNameLabel.text = source.caption;
      _channelNum.text = source.channelNum;
      _noLogoCaptionLabel.text = source.channelNum;
    }
    else
    {
      _channelNameLabel.text = source.caption;
      _channelNum.text = @"";
      _noLogoCaptionLabel.text = source.caption;      
    }
  }

  // Caption is overused - can sometimes be radio text but can also sometimes just be a caption
  // Only handle it as radio text if that's what we're fairly sure it is.	
  if ((changed || (flags & SOURCE_TUNER_CAPTION_CHANGED) != 0))
  {
    if ((source.capabilities & SOURCE_TUNER_HAS_FEEDBACK) == 0 ||
        (source.caption != nil &&
         ([source.caption isEqualToString: source.channelName] ||
          [source.caption isEqualToString: source.channelNum] ||
          [source.caption isEqualToString: source.displayName] ||
          [source.caption isEqualToString: source.serviceName] ||
          [source.caption isEqualToString: source.frequency] ||
          [source.caption isEqualToString: [NSString stringWithFormat: @"%@%@", source.band, source.frequency]] ||
          [source.caption isEqualToString: [NSString stringWithFormat: @"%@ %@", source.band, source.frequency]])))
    {
      _radioTextLabel.hidden = YES;
      _radioText.hidden = YES;
    }
    else
      [self handleRadioText: source.caption];
  }
}

- (void) satelliteSource: (NLSourceTuner *) source stateChanged: (NSUInteger) flags
{
  BOOL bandChanged = ((flags & SOURCE_TUNER_BAND_CHANGED) != 0);
  
  if (bandChanged)
  {
    _songLabel.hidden = NO;
    _artistLabel.hidden = NO;
    _genreLabel.hidden = NO;
    _radioTextLabel.hidden = YES;
    _radioText.hidden = YES;
    _radioText.text = @"";
  }
  
  if ([source.controlState isEqualToString: @"REFRESH"])
  {
    _song.text = @"";
    _artist.text = @"";
    _genre.text = @"";
    _noLogoCaptionLabel.text = @"";
    _channelNameLabel.text = @"";
    _channelNum.text = @"";
  }
  else
  {
    BOOL changed = bandChanged || ((flags & SOURCE_TUNER_CONTROL_STATE_CHANGED) != 0);
    
    if (changed || (flags & SOURCE_TUNER_SONG_CHANGED) != 0)
      _song.text = source.song;
    if (changed || (flags & SOURCE_TUNER_ARTIST_CHANGED) != 0)
      _artist.text = source.artist;
    if (changed || (flags & SOURCE_TUNER_GENRE_CHANGED) != 0)
      _genre.text = source.genre;
    if (changed || (flags & (SOURCE_TUNER_CHANNEL_NUM_CHANGED|SOURCE_TUNER_CHANNEL_NAME_CHANGED)) != 0)
    {
      _noLogoCaptionLabel.text = source.channelName;
      _channelNameLabel.text = source.channelName;
      _channelNum.text = source.channelNum;
    }
  }
}

- (void) handleRadioText: (NSString *) radioText
{
  radioText = [radioText stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  
  if ([radioText length] > 0)
  {
    static NSString *NEWLINES = @"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
    NSString *newRadioText = _radioText.text;
    CGFloat lineHeight = [_radioText.font lineSpacing];
    NSUInteger visibleLines = (_radioText.frame.size.height / lineHeight) - 1;
    
    _radioText.numberOfLines = visibleLines * 2;
    
    CGSize actualNewTextArea = [radioText sizeWithFont: _radioText.font
                                     constrainedToSize: CGSizeMake( _radioText.frame.size.width, 1024 )
                                         lineBreakMode: UILineBreakModeWordWrap];
    NSUInteger numberOfNewLines = (NSUInteger) (actualNewTextArea.height / lineHeight);
    
    if (newRadioText == nil || [newRadioText length] == 0)
      newRadioText = [NEWLINES substringToIndex: numberOfNewLines];
    else
    {
      newRadioText = [newRadioText substringFromIndex: _radioTextVisibleOffset];
      newRadioText = [newRadioText stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
      newRadioText = [newRadioText stringByAppendingFormat: @"\n\n%@", [NEWLINES substringToIndex: numberOfNewLines]];
    }
    
    _pendingRadioText = [radioText retain];
    
    CGSize actualTextArea = [newRadioText sizeWithFont: _radioText.font 
                                     constrainedToSize: CGSizeMake( _radioText.frame.size.width, 1024 )
                                         lineBreakMode: UILineBreakModeWordWrap];
    NSUInteger numberOfLines = (NSUInteger) (actualTextArea.height / lineHeight);
    NSUInteger linesToScroll = 0;
    
    if (numberOfLines == 0)
      numberOfLines = 1;
    if (numberOfLines <= visibleLines)
    {
      newRadioText = [[NEWLINES substringToIndex: visibleLines - numberOfLines] stringByAppendingFormat: @"%@",
                      newRadioText];//, [NEWLINES substringToIndex: visibleLines - numberOfLines]];
      _radioTextVisibleOffset = visibleLines - numberOfLines;
    }
    else if (numberOfLines > visibleLines)
    {
      NSString *candidate;
      
      linesToScroll = numberOfLines - visibleLines;
      _radioTextVisibleOffset = 0;
      do
      {
        ++_radioTextVisibleOffset;
        candidate = [newRadioText substringFromIndex: _radioTextVisibleOffset];
        actualTextArea = [candidate sizeWithFont: _radioText.font 
                               constrainedToSize: _radioText.frame.size 
                                   lineBreakMode: UILineBreakModeWordWrap];
        numberOfLines = (NSUInteger) (actualTextArea.height / lineHeight);
      }
      while (numberOfLines > visibleLines);
      newRadioText = [newRadioText substringFromIndex:_radioTextVisibleOffset];
      _radioTextVisibleOffset = 0;
    }
    
    _radioTextLabel.hidden = NO;
    _radioText.hidden = NO;
    
    
    CGRect frame = _radioText.frame;
    if (linesToScroll > 0)
    {
      CGRect newFrame = CGRectOffset( frame, 0, (lineHeight * linesToScroll) );			
      _radioText.frame = newFrame;
    }
    
    [UIView beginAnimations: nil context: nil];
    [UIView setAnimationDuration: 0.25 * linesToScroll];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationStopped)];		
    _radioText.text = newRadioText;
    _radioText.frame = frame;
    [UIView commitAnimations];
  }
}

- (void) animationStopped
{
  CGFloat lineHeight = [_radioText.font lineSpacing];
  CGSize actualTextArea = [_pendingRadioText sizeWithFont: _radioText.font 
                                        constrainedToSize: CGSizeMake( _radioText.frame.size.width, 1024 )
                                            lineBreakMode: UILineBreakModeWordWrap];
  NSUInteger numberOfLines = (NSUInteger) (actualTextArea.height / lineHeight);
  
  _radioText.text = [_radioText.text substringToIndex:_radioText.text.length - numberOfLines];
  _radioText.text = [_radioText.text stringByAppendingString:_pendingRadioText]; 
  [_pendingRadioText release];
  _pendingRadioText = nil;
}

@end
