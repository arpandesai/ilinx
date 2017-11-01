    //
//  MediaNowPlayingController.m
//  iLinX
//
//  Created by mcf on 14/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "MediaNowPlayingController.h"
#import "MediaViewControllerIPad.h"
#import "NLSourceMediaServer.h"
#import "CustomSliderIPad.h"
#import "DeprecationHelper.h"
#import "PseudoBarButton.h"

@implementation MediaNowPlayingController

@synthesize
  owner = _owner,
  coverArtView = _coverArt;

- (void) viewDidLoad
{
  [super viewDidLoad];

  _sourcesButton.title = _owner.mediaServer.displayName;
  if ((_owner.mediaServer.capabilities & SOURCE_MEDIA_SERVER_CAPABILITY_NEXT_TRACK) == 0)
    _nextSong.hidden = YES;
  else
    _nextSong.text = @"";
  _progress.progressOnly = ((_owner.mediaServer.capabilities & SOURCE_MEDIA_SERVER_CAPABILITY_POSITION) == 0);

  _repeatButton.hidden = ((_owner.mediaServer.capabilities & SOURCE_MEDIA_SERVER_CAPABILITY_REPEAT) == 0);
  if (!_repeatButton.hidden)
  {
    _cacheRepeatImage = [_repeatButton imageForState: UIControlStateSelected];
    _cacheRepeatOneImage = [_repeatButton imageForState: UIControlStateHighlighted];
    [_repeatButton setImage: nil forState: UIControlStateHighlighted];
  }
  if (_coverArtReflection != nil)
    _coverArtReflection.transform = CGAffineTransformMake( 1, 0, 0, -1, 0, 1 );
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
  // Overriden to allow any orientation.
  return YES;
}

- (IBAction) toggleControls
{
  if (_topBar.hidden)
  {
    _topBar.hidden = NO;
    _bottomBar.hidden = NO;
  }
  else
  {
    _topBar.hidden = YES;
    _bottomBar.hidden = YES;
  }
}

- (IBAction) toggleDetails
{
  // Swap the image and rotate
  BOOL swapIn = _detailsView.hidden;
  
  [UIView beginAnimations: nil context: nil];
  [UIView setAnimationDuration: 0.75];
  
  if (swapIn)
    [UIView setAnimationTransition: UIViewAnimationTransitionFlipFromRight forView: _flipBase cache: YES];
  else
    [UIView setAnimationTransition: UIViewAnimationTransitionFlipFromLeft forView: _flipBase cache: YES];
  
  _coverArtArea.hidden = swapIn;
  _detailsView.hidden = !swapIn;
  
  [UIView commitAnimations];
  
  [UIView beginAnimations: nil context: nil];
  [UIView setAnimationDuration: 0.75];
  
  if (swapIn)
  {
    UIImage *coverArtSurround = [_detailsButton backgroundImageForState: UIControlStateSelected];
    
    if (coverArtSurround == [_detailsButton backgroundImageForState: UIControlStateNormal])
      coverArtSurround = nil;
    [UIView setAnimationTransition: UIViewAnimationTransitionFlipFromRight forView: _detailsFlipBase cache: YES];
    _cacheDetailOffBackground = [[_detailsButton backgroundImageForState: UIControlStateNormal] retain];
    _cacheDetailOffForeground = [[_detailsButton imageForState: UIControlStateNormal] retain];
    _cacheDetailOnBackground = [[_detailsButton backgroundImageForState: UIControlStateHighlighted] retain];
    _cacheDetailOnForeground = [[_detailsButton imageForState: UIControlStateHighlighted] retain];
    [_detailsButton setBackgroundImage: coverArtSurround forState: UIControlStateNormal];
    [_detailsButton setImage: nil forState: UIControlStateNormal];
    [_detailsButton setBackgroundImage: coverArtSurround forState: UIControlStateHighlighted];
    [_detailsButton setImage: nil forState: UIControlStateHighlighted];
  }
  else
  {
    [UIView setAnimationTransition: UIViewAnimationTransitionFlipFromLeft forView: _detailsFlipBase cache: YES];
    [_detailsButton setBackgroundImage: _cacheDetailOffBackground forState: UIControlStateNormal];
    [_detailsButton setImage: _cacheDetailOffForeground forState: UIControlStateNormal];
    [_detailsButton setBackgroundImage: _cacheDetailOnBackground forState: UIControlStateHighlighted];
    [_detailsButton setImage: _cacheDetailOnForeground forState: UIControlStateHighlighted];
    [_cacheDetailOffBackground release];
    [_cacheDetailOffForeground release];
    [_cacheDetailOnBackground release];
    [_cacheDetailOnForeground release];
    _cacheDetailOffBackground = nil;
    _cacheDetailOffForeground = nil;
    _cacheDetailOnBackground = nil;
    _cacheDetailOnForeground = nil;
  }

  _secondaryCoverArt.hidden = !swapIn;
  [UIView commitAnimations];
}

- (IBAction) resetToCoverArt
{
  if (!_detailsView.hidden)
    [self toggleDetails];
}

- (void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation) fromInterfaceOrientation
{
  [super didRotateFromInterfaceOrientation: fromInterfaceOrientation];
  
  _minRows = (NSUInteger) ((_detailsTable.frame.size.height - 1) / _detailsTable.rowHeight) + 1;
  [_detailsTable reloadData];
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
    _detailDataRows = [source.composers count] + [source.conductors count] + [source.performers count];
    if (source.song != nil && [source.song length] > 0)
      ++_detailDataRows;
    if (source.artist != nil && [source.artist length] > 0)
      ++_detailDataRows;
    if (source.album != nil && [source.album length] > 0)
      ++_detailDataRows;
    if ((source.genre != nil && [source.genre length] > 0) || (source.subGenre != nil && [source.subGenre length] > 0))
      ++_detailDataRows;
    _detailTextHeight = [[UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]] lineSpacing];
    _detailsTable.rowHeight = (_detailTextHeight * 4) + 4;
    _minRows = (NSUInteger) ((_detailsTable.frame.size.height - 1) / _detailsTable.rowHeight) + 1;
  }
  
  if ((flags & (SOURCE_MEDIA_SERVER_SONG_CHANGED|SOURCE_MEDIA_SERVER_ALBUM_CHANGED|
                SOURCE_MEDIA_SERVER_ARTIST_CHANGED|SOURCE_MEDIA_SERVER_GENRE_CHANGED|
                SOURCE_MEDIA_SERVER_COMPOSERS_CHANGED|SOURCE_MEDIA_SERVER_CONDUCTORS_CHANGED|
                SOURCE_MEDIA_SERVER_PERFORMERS_CHANGED|SOURCE_MEDIA_SERVER_SUB_GENRE_CHANGED)) != 0)
  {
    [_detailsTable reloadData];
    [_detailsTable scrollToRowAtIndexPath: [NSIndexPath indexPathForRow: 0 inSection: 0]
                         atScrollPosition: UITableViewScrollPositionTop animated: NO];
  }
  
  if ((flags & SOURCE_MEDIA_SERVER_COVER_ART_CHANGED) != 0)
  {
    _coverArt.image = source.coverArt;
    if (_coverArtReflection != nil)
      _coverArtReflection.image = source.coverArt;
    if (_secondaryCoverArt != nil)
      _secondaryCoverArt.image = source.coverArt;
  }
  if ((flags & (SOURCE_MEDIA_SERVER_TIME_CHANGED|SOURCE_MEDIA_SERVER_ELAPSED_CHANGED)) != 0)
  {
    _timeSoFar.text = _owner.timeSoFar.text;
    _timeRemaining.text = _owner.timeRemaining.text;
    _progress.value = _owner.progress.value;
  }
  if ((flags & (SOURCE_MEDIA_SERVER_SONG_INDEX_CHANGED|SOURCE_MEDIA_SERVER_SONG_TOTAL_CHANGED)) != 0)
  {
    _songIndex.text = _owner.songIndex.text;
    _songIndex.hidden = _owner.songIndex.hidden;
  }

  if ((flags & SOURCE_MEDIA_SERVER_NEXT_SONG_CHANGED) != 0)
  {
    _nextSong.text = _owner.nextSong.text;
    _nextSong.hidden = _owner.nextSong.hidden;
  }
  
  _playButton.hidden = _owner.playButton.hidden;
  _pauseButton.hidden = _owner.pauseButton.hidden;
  _timeSoFar.hidden = _owner.timeSoFar.hidden;
  _timeSoFar.enabled = _owner.timeSoFar.enabled;
  _timeRemaining.hidden = _owner.timeRemaining.hidden;
  _timeRemaining.enabled = _owner.timeRemaining.enabled;
  _progress.hidden = _owner.progress.hidden;
  _progress.enabled = _owner.progress.enabled;
  _shuffleButton.selected = _owner.shuffleButton.selected;
  _shuffleButton.hidden = _owner.shuffleButton.hidden;
  _shuffleButton.enabled = _owner.shuffleButton.enabled;
  _repeatButton.selected = _owner.repeatButton.selected;
  _repeatButton.hidden = _owner.repeatButton.hidden;
  _repeatButton.enabled = _owner.repeatButton.enabled;
  if (source.repeat == 1)
    [_repeatButton setImage: _cacheRepeatOneImage forState: UIControlStateSelected];
  else
    [_repeatButton setImage: _cacheRepeatImage forState: UIControlStateSelected];
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  if (_detailDataRows < _minRows)
    return _minRows;
  else
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
  
  NSUInteger index = indexPath.row;
  NSString *iconName;
  NSString *titleText;
  NSString *contentText;
  
  if (_owner.mediaServer.song == nil || [_owner.mediaServer.song length] == 0)
    ++index;
  if ((_owner.mediaServer.artist == nil || [_owner.mediaServer.artist length] == 0) && index > 0)
    ++index;
  if ((_owner.mediaServer.album == nil || [_owner.mediaServer.album length] == 0) && index > 1)
    ++index;
  if (((_owner.mediaServer.genre == nil || [_owner.mediaServer.genre length] == 0) &&
       (_owner.mediaServer.subGenre == nil || [_owner.mediaServer.subGenre length] == 0)) && index > 2)
    ++index;
  
  switch (index)
  {
    case 0:
      iconName = @"Songs-selected.png";
      titleText = NSLocalizedString( @"Title", @"Label for title of song" );
      contentText = _owner.mediaServer.song;
      break;
    case 1:
      iconName = @"Artists-selected.png";
      titleText = NSLocalizedString( @"Artist", @"Label for artist for song" );
      contentText = _owner.mediaServer.artist;
      break;
    case 2:
      iconName = @"Albums-selected.png";
      titleText = NSLocalizedString( @"Album", @"Label for album for song" );
      contentText = _owner.mediaServer.album;
      break;
    case 3:
      iconName = @"Genres-selected.png";
      titleText = NSLocalizedString( @"Genre", @"Label for genre of song" );
      contentText = _owner.mediaServer.genre;
      if (_owner.mediaServer.subGenre != nil && [_owner.mediaServer.subGenre length] > 0)
      {
        if (contentText == nil || [contentText length] == 0 || [contentText isEqualToString: @"<Root>"])
          contentText = _owner.mediaServer.subGenre;
        else
          contentText = [NSString stringWithFormat: @"%@, %@", contentText, _owner.mediaServer.subGenre];
      }
      break;
    default:
      index -= 4;
      if (index < [_owner.mediaServer.composers count])
      {
        iconName = @"Composers-selected.png";
        titleText = NSLocalizedString( @"Composer", @"Label for composer of song" );
        contentText = [_owner.mediaServer.composers objectAtIndex: index];
      }
      else
      {
        index -= [_owner.mediaServer.composers count];
        if (index < [_owner.mediaServer.conductors count])
        {
          iconName = @"Conductors-selected.png";
          titleText = NSLocalizedString( @"Conductor", @"Label for conductor of song" );
          contentText = [_owner.mediaServer.conductors objectAtIndex: index];
        }
        else
        {
          index -= [_owner.mediaServer.conductors count];
          if (index >= [_owner.mediaServer.performers count])
            titleText = nil;
          else
          {
            iconName = @"Performers-selected.png";
            titleText = NSLocalizedString( @"Performer", @"Label for performer of song" );
            contentText = [_owner.mediaServer.performers objectAtIndex: index];
          }
        }
      }
      break;
  }
  
  UIView *backdrop = [[UIView alloc] initWithFrame: CGRectMake( 0, 0, tableView.frame.size.width, tableView.rowHeight )];

  if (indexPath.row % 2 == 1)
    backdrop.backgroundColor = [UIColor colorWithWhite: 0.3 alpha: 1.0];
  else
    backdrop.backgroundColor = [UIColor darkGrayColor];
  
  if (titleText != nil)
  {
    UIImageView *icon = [[UIImageView alloc] initWithImage: [UIImage imageNamed: iconName]];
    
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
  }

  [cell.contentView addSubview: backdrop];
  [backdrop release];
  
  return cell;
}

- (void) dealloc
{
  [_topBar release];
  [_bottomBar release];
  [_progress release];
  [_timeSoFar release];
  [_timeRemaining release];
  [_playButton release];
  [_pauseButton release];
  [_sourcesButton release];
  [_songIndex release];
  [_coverArtArea release];
  [_coverArt release];
  [_coverArtReflection release];
  [_artist release];
  [_song release];
  [_album release];
  [_nextSong release];
  [_shuffleButton release];
  [_repeatButton release];
  [_detailsFlipBase release];
  [_detailsButton release];
  [_secondaryCoverArt release];
  [_flipBase release];
  [_detailsView release];
  [_detailsTable release];
  [_cacheDetailOffBackground release];
  [_cacheDetailOffForeground release];
  [_cacheDetailOnBackground release];
  [_cacheDetailOnForeground release];
  [super dealloc];
}

@end
