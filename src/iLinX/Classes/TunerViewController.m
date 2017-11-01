//
//  TunerViewController.m
//  iLinX
//
//  Created by mcf on 18/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "TunerViewController.h"
#import "BrowseTunerViewController.h"
#import "ChangeSelectionHelper.h"
#import "DeprecationHelper.h"
#import "MainNavigationController.h"
#import "NLRenderer.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLSource.h"
#import "NLSourceList.h"
#import "OS4ToolbarFix.h"
#import "StandardPalette.h"
#import "TunerAddPresetViewController.h"
#import "TunerKeypadViewController.h"

#define TUNE_TYPE_CHANNEL 0
#define TUNE_TYPE_TUNE    1
#define TUNE_TYPE_SEEK    2
#define TUNE_TYPE_SCAN    3
#define TUNE_TYPE_PRESET  4

static NSString *TUNE_TYPE_TITLES[5];

@interface TunerViewController ()

- (void) noFeedbackSource: (NLSourceTuner *) source stateChanged: (NSUInteger) flags;
- (void) satelliteSource: (NLSourceTuner *) source stateChanged: (NSUInteger) flags;
- (void) digitalSource: (NLSourceTuner *) source stateChanged: (NSUInteger) flags;
- (void) analogSource: (NLSourceTuner *) source stateChanged: (NSUInteger) flags;
- (void) handleRadioText: (NSString *) radioText;
- (void) goBack: (id) control;
- (void) pressedBackdrop: (UIButton *) button;
- (void) pressedOverlay: (UIButton *) button;
- (void) pressedSavePreset: (id) control;
- (void) pressedBand: (id) control;
- (void) pressedMode: (UIBarButtonItem *) button;
- (void) pressedStereo: (id) control;
- (void) pressedTuneDown: (id) control;
- (void) pressedTuneUp: (id) control;
- (UILabel *) allocLabelInView: (UIView *) view bold: (BOOL) isBold withFrame: (CGRect) frame;

@end

@implementation TunerViewController

- initWithRoomList: (NLRoomList *) roomList service: (NLService *) service source: (NLSource *) source
{
  if ((self = [super initWithRoomList: roomList service: service source: source]) != nil)
  {    
    // Cast here as a convenience to avoid having to cast every time its used
    _tuner = (NLSourceTuner *) source;
    
    if (TUNE_TYPE_TITLES[0] == nil)
    {
      TUNE_TYPE_TITLES[0] = [NSLocalizedString( @"Channel", @"Title of channel tuning mode" ) retain];
      TUNE_TYPE_TITLES[1] = [NSLocalizedString( @"Tune", @"Title of frequency tuning mode" ) retain];
      TUNE_TYPE_TITLES[2] = [NSLocalizedString( @"Seek", @"Title of signal seek tuning mode" ) retain];
      TUNE_TYPE_TITLES[3] = [NSLocalizedString( @"Scan", @"Title of scan tuning mode" ) retain];
      TUNE_TYPE_TITLES[4] = [NSLocalizedString( @"Preset", @"Title of preset tuning mode" ) retain];
    }
  }
  
  return self;
}

- (BOOL) isBrowseable
{
  return (_tuner != nil && _tuner.browseMenu != nil);
}

- (id<ControlViewProtocol>) allocBrowseViewController
{
  if (_tuner == nil || _tuner.browseMenu == nil)
    return nil;
  else
  {
    if (_browseViewController == nil)
    {
      _browseViewController = [[BrowseTunerViewController alloc] initWithRoomList: _roomList service: _service
                                                                           source: _source nowPlaying: self];
    }
    else
    {
      [_browseViewController retain];
#if defined(DEBUG)
      //**/NSLog( @"Refresh browse list to re-use browse controller" );
#endif
      [_browseViewController refreshBrowseList];
    }

    return _browseViewController;
  }
}

- (void) loadView
{
  [super loadView];
  
  CGRect contentBounds = self.view.bounds;
  
  // Custom title
  UIView *customTitle = [[UIView alloc] initWithFrame:
                         CGRectMake( 0, 0, CGRectGetWidth( self.navigationController.navigationBar.bounds ), 
                                    CGRectGetHeight( self.navigationController.navigationBar.bounds ) )];
  
  customTitle.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  customTitle.autoresizesSubviews = YES;
  
  UIFont *customTitleFont = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]];
  CGFloat lineHeight = customTitleFont.pointSize + 1;
  CGFloat linesTop = (CGRectGetHeight( self.navigationController.navigationBar.bounds ) - (3 * lineHeight)) / 2;
  _titleLine1 = [[UILabel alloc] initWithFrame: CGRectMake( 0, linesTop, customTitle.bounds.size.width, lineHeight )];
  _titleLine1.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  _titleLine1.font = customTitleFont;
  _titleLine1.lineBreakMode = UILineBreakModeMiddleTruncation;
  _titleLine1.textAlignment = UITextAlignmentCenter;
  _titleLine1.textColor = [UIColor lightGrayColor];
  _titleLine1.shadowColor = [UIColor darkGrayColor];
  _titleLine1.backgroundColor = [UIColor clearColor];
  [customTitle addSubview: _titleLine1];
  
  _titleLine2 = [[UILabel alloc] initWithFrame: CGRectMake( 0, linesTop + lineHeight, customTitle.bounds.size.width, lineHeight )];
  _titleLine2.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  _titleLine2.font = customTitleFont;
  _titleLine2.lineBreakMode = UILineBreakModeMiddleTruncation;
  _titleLine2.textAlignment = UITextAlignmentCenter;
  _titleLine2.textColor = [UIColor whiteColor];
  _titleLine2.shadowColor = [UIColor darkGrayColor];
  _titleLine2.backgroundColor = [UIColor clearColor];
  [customTitle addSubview: _titleLine2];
  
  _titleLine3 = [[UILabel alloc] initWithFrame: CGRectMake( 0, linesTop + (lineHeight * 2), customTitle.bounds.size.width, lineHeight )];
  _titleLine3.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  _titleLine3.font = customTitleFont;
  _titleLine3.lineBreakMode = UILineBreakModeMiddleTruncation;
  _titleLine3.textAlignment = UITextAlignmentCenter;
  _titleLine3.textColor = [UIColor lightGrayColor];
  _titleLine3.backgroundColor = [UIColor clearColor];
  [customTitle addSubview: _titleLine3];

  _titleLines12 = [[UILabel alloc] initWithFrame: CGRectMake( 0, linesTop, customTitle.bounds.size.width, lineHeight * 2 )];
  _titleLines12.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  _titleLines12.font = [UIFont boldSystemFontOfSize: [UIFont labelFontSize]];
  _titleLines12.lineBreakMode = UILineBreakModeMiddleTruncation;
  _titleLines12.textAlignment = UITextAlignmentCenter;
  _titleLines12.textColor = [UIColor whiteColor];
  _titleLines12.shadowColor = [UIColor darkGrayColor];
  _titleLines12.backgroundColor = [UIColor clearColor];
  [customTitle addSubview: _titleLines12];
  
  _titleLines123 = [[UILabel alloc] initWithFrame: CGRectMake( 0, linesTop, customTitle.bounds.size.width, lineHeight * 3 )];
  _titleLines123.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  _titleLines123.font = [UIFont boldSystemFontOfSize: 20];
  _titleLines123.lineBreakMode = UILineBreakModeMiddleTruncation;
  _titleLines123.textAlignment = UITextAlignmentCenter;
  _titleLines123.textColor = [UIColor whiteColor];
  _titleLines123.shadowColor = [UIColor darkGrayColor];
  _titleLines123.backgroundColor = [UIColor clearColor];
  [customTitle addSubview: _titleLines123];
  
  self.navigationItem.titleView = customTitle;
  [customTitle release];
  
  UIBarButtonItem *barButton;
  UIButton *buttonControl = [UIButton buttonWithType: UIButtonTypeCustom];
  
  [buttonControl setBackgroundImage: [UIImage imageNamed: @"PlayerBackArrow.png"] forState: UIControlStateNormal];
  [buttonControl addTarget: self action: @selector(goBack:) forControlEvents: UIControlEventTouchDown];
  [buttonControl sizeToFit];
  [buttonControl setBackgroundColor: [UIColor clearColor]];
  buttonControl.opaque = NO;
  barButton = [[UIBarButtonItem alloc] initWithCustomView: buttonControl];  
  self.navigationItem.leftBarButtonItem = barButton;
  self.navigationItem.hidesBackButton = YES;
  [barButton release];
    
  _flipButton = [[UIButton alloc] initWithFrame: CGRectMake( 0, 0, 30, 30 )];
  if (([_tuner capabilities] & SOURCE_TUNER_HAS_DIRECT_TUNE) != 0)
  {
    [_flipButton setBackgroundImage: [UIImage imageNamed: @"KeyPad.png"] forState: UIControlStateNormal];
    [_flipButton addTarget: self action: @selector(flipCurrentView:) forControlEvents: UIControlEventTouchDown];
    _keypadViewController = [[TunerKeypadViewController alloc] initWithTuner: _tuner parentController: self];
  }
  barButton = [[UIBarButtonItem alloc] initWithCustomView: _flipButton];
  [self.navigationItem setRightBarButtonItem: barButton animated: YES];
  [barButton release];
  
  // Flipping view
  _flipBase = [[UIView alloc] initWithFrame: 
               CGRectMake( 0, 0, contentBounds.size.width, contentBounds.size.height )];
  [self.view addSubview: _flipBase];
  _flippingView = [[UIView alloc] initWithFrame: _flipBase.frame];
  [_flipBase addSubview: _flippingView];
  
  CGFloat toolBarHeight = _toolBar.frame.size.height;
  
  _toolBar.alpha = 0.7;
  [self.view insertSubview: _toolBar aboveSubview: _flipBase];
  
  if (([_tuner capabilities] & SOURCE_TUNER_HAS_DYNAMIC_PRESETS) != 0)
  {
    NSMutableArray *items = [_toolBar.items mutableCopy];
    UIBarButtonItem *button = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target: nil action: nil];
  
    [items addObject: button];
    [button release];
    button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd 
                                                           target: self action: @selector(pressedSavePreset:)];
    [items addObject: button];
    [button release];
    ((UIBarButtonItem *) [items lastObject]).style = UIBarButtonItemStyleBordered;
    _toolBar.items = items;
    [items release];
  }

  // Image
  UIImage *backdropImage;
  
  if (![[_tuner sourceControlType] isEqualToString: @"XM TUNER"])
    backdropImage = [UIImage imageNamed: @"DefaultTunerArtwork.png"];
  else if ([[_tuner sourceType] isEqualToString: @"Sirius"])
    backdropImage = [UIImage imageNamed: @"DefaultSiriusTunerArtwork.png"];
  else
    backdropImage = [UIImage imageNamed: @"DefaultXMTunerArtwork.png"];

  _backdrop = [[UIImageView alloc] initWithImage: backdropImage];
  [_backdrop sizeToFit];
  [_flippingView addSubview: _backdrop];
  
  buttonControl = [[UIButton alloc] initWithFrame: _backdrop.frame];
  buttonControl.backgroundColor = [UIColor clearColor];
  [buttonControl addTarget: self action: @selector(pressedBackdrop:) forControlEvents: UIControlEventTouchDown];
  [_flippingView addSubview: buttonControl];
  [buttonControl release];
  
  // Image reflection
  _reflection = [[UIImageView alloc] initWithImage: backdropImage];
  _reflection.frame = CGRectMake( _backdrop.frame.origin.x, _backdrop.frame.origin.y + _backdrop.frame.size.height, 
                                 _backdrop.frame.size.width, _backdrop.frame.size.height );
  [_reflection setTransform: CGAffineTransformMake( 1, 0, 0, -1, 0, 1 )];
  _reflection.alpha = 0.5;
  [_flippingView addSubview: _reflection];
  
  _logo = [[UIImageView alloc] initWithFrame: CGRectMake( 0, toolBarHeight + 11, 192, 108 )];
  [_flippingView addSubview: _logo];
  _noLogoCaption = [[UILabel alloc] initWithFrame: _logo.frame];
  _noLogoCaption.font = [UIFont systemFontOfSize: 30];
  _noLogoCaption.textColor = [UIColor whiteColor];
  _noLogoCaption.textAlignment = UITextAlignmentCenter;
  _noLogoCaption.shadowColor = [UIColor lightGrayColor];
  _noLogoCaption.backgroundColor = [UIColor clearColor];
  _noLogoCaption.shadowOffset = CGSizeMake( 0, -1 );
  _noLogoCaption.adjustsFontSizeToFitWidth = YES;
  _noLogoCaption.minimumFontSize = [UIFont smallSystemFontSize];
  [_flippingView addSubview: _noLogoCaption];
  
  _controlBar = [[UIToolbar alloc] initWithFrame: CGRectMake( 0, CGRectGetMaxY( contentBounds ) - (toolBarHeight * 3),
                                                             CGRectGetWidth( contentBounds ), toolBarHeight)];

  UIBarButtonItem *band = [[[UIBarButtonItem alloc] initWithTitle: @"Band" style: UIBarButtonItemStyleBordered
                                                           target: self action: @selector(pressedBand:)] autorelease];
  UIBarButtonItem *fix2 = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFixedSpace target: nil action: nil] autorelease];
  _tuneTypeButton = [[UIBarButtonItem alloc] initWithTitle: TUNE_TYPE_TITLES[0] style: UIBarButtonItemStyleBordered
                                                           target: self action: @selector(pressedMode:)];
  UIBarButtonItem *fix3 = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFixedSpace target: nil action: nil] autorelease];
  _stereoButton = [[UIBarButtonItem alloc] initWithTitle: @"Stereo" style: UIBarButtonItemStyleBordered
                                                             target: self action: @selector(pressedStereo:)];
  
  band.width = 60;
  fix2.width = 10;
  fix3.width = 10;
  _stereoButton.width = 60;
  if ([[_tuner sourceControlType] isEqualToString: @"XM TUNER"])
  {
    // XM only
    _tuneTypeButton.enabled = NO;
    _controlBar.items = [NSArray arrayWithObjects: 
                         [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target: nil action: nil] autorelease],
                         [[[UIBarButtonItem alloc] initWithImage: [UIImage imageNamed: @"SmallPlayBack.png"] style: UIBarButtonItemStylePlain
                                                          target: self action: @selector(pressedTuneDown:)] autorelease],
                         fix2, _tuneTypeButton, fix3,
                         [[[UIBarButtonItem alloc] initWithImage: [UIImage imageNamed: @"SmallPlay.png"] style: UIBarButtonItemStylePlain
                                                          target: self action: @selector(pressedTuneUp:)] autorelease],
                         [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target: nil action: nil] autorelease],
                         nil];
  }
  else
  {
    _controlBar.items = [NSArray arrayWithObjects: band,
                         [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target: nil action: nil] autorelease],
                         [[[UIBarButtonItem alloc] initWithImage: [UIImage imageNamed: @"SmallPlayBack.png"] style: UIBarButtonItemStylePlain
                                                          target: self action: @selector(pressedTuneDown:)] autorelease],
                         fix2, _tuneTypeButton, fix3,
                         [[[UIBarButtonItem alloc] initWithImage: [UIImage imageNamed: @"SmallPlay.png"] style: UIBarButtonItemStylePlain
                                                          target: self action: @selector(pressedTuneUp:)] autorelease],
                         [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target: nil action: nil] autorelease],
                         _stereoButton, nil];
  }
  _controlBar.barStyle = UIBarStyleBlackOpaque;
  _controlBar.alpha = 0.7;
  [self.view addSubview: _controlBar];
  
  if (([_tuner capabilities] & SOURCE_TUNER_HAS_FEEDBACK) != 0)
  {
    // Overlay view
    _overlayView = [[UIButton buttonWithType: UIButtonTypeCustom] retain];
    _overlayView.frame = CGRectMake( _backdrop.frame.origin.x, _backdrop.frame.origin.y + toolBarHeight - 1,
                                    _backdrop.frame.size.width, _backdrop.frame.size.height - toolBarHeight + 1 );
    _overlayView.backgroundColor = [UIColor colorWithWhite: 0 alpha: 0.5];
    _overlayView.hidden = YES;
    [_overlayView addTarget: self action: @selector(pressedOverlay:) forControlEvents: UIControlEventTouchDown];
    [_flippingView addSubview: _overlayView];
    
    lineHeight = [[UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]] lineSpacing];
    _songLabel = [self allocLabelInView: _overlayView bold: YES withFrame: CGRectMake( 10, 10, contentBounds.size.width - 20, lineHeight )];
    _songLabel.text = NSLocalizedString( @"Song", @"Title of label showing the title of the current song playing on the tuner" );
    _song = [self allocLabelInView: _overlayView bold: NO withFrame: CGRectMake( 10, lineHeight + 10, contentBounds.size.width - 20, lineHeight )];
    _artistLabel = [self allocLabelInView: _overlayView bold: YES withFrame: CGRectMake( 10, (2 * lineHeight) + 18, contentBounds.size.width - 20, lineHeight )];
    _artistLabel.text = NSLocalizedString( @"Artist", @"Title of label showing the title of the current artist playing on the tuner" );
    _artist = [self allocLabelInView: _overlayView bold: NO withFrame: CGRectMake( 10, (3 * lineHeight) + 18, contentBounds.size.width - 20, lineHeight )];
    _genreLabel = [self allocLabelInView: _overlayView bold: YES withFrame: CGRectMake( 10, (4 * lineHeight) + 26, contentBounds.size.width - 20, lineHeight )];
    _genreLabel.text = NSLocalizedString( @"Category", @"Title of label showing the category (genre) of the current station on the tuner" );
    _genre = [self allocLabelInView: _overlayView bold: NO withFrame: CGRectMake( 10, (5 * lineHeight) + 26, contentBounds.size.width - 20, lineHeight )];
    _stationLabel = [self allocLabelInView: _overlayView bold: YES withFrame: CGRectMake( 10, (6 * lineHeight) + 34, contentBounds.size.width - 20, lineHeight )];
    _station = [self allocLabelInView: _overlayView bold: NO withFrame: CGRectMake( 10, (7 *lineHeight) + 34, contentBounds.size.width - 20, lineHeight )];
    _radioTextLabel = [self allocLabelInView: _overlayView bold: YES withFrame: CGRectMake( 10, (8 * lineHeight) + 42, contentBounds.size.width - 20, lineHeight )];
    _radioTextLabel.text = NSLocalizedString( @"Radio Text", @"Title of the area showing the radio text received from the tuner" );
    
    UIView *radioTextContainer = [[UIView alloc] initWithFrame: CGRectMake( 10, (9 * lineHeight) + 42, contentBounds.size.width - 20, lineHeight * 6 )];
    
    radioTextContainer.backgroundColor = [UIColor clearColor];
    radioTextContainer.clipsToBounds = YES;
    [_overlayView addSubview: radioTextContainer];
    [radioTextContainer release];
    
    _radioText = [self allocLabelInView: radioTextContainer bold: NO withFrame: CGRectMake( 0, -(lineHeight * 6), contentBounds.size.width - 20, lineHeight * 12 )];
    _radioText.numberOfLines = 12;
  }

  _bandIndicator = [[UILabel alloc] initWithFrame: CGRectMake( 8, _controlBar.frame.origin.y - 12, 60, 12 )];
  _bandIndicator.font = [UIFont boldSystemFontOfSize: 10];
  _bandIndicator.textColor = [UIColor whiteColor];
  _bandIndicator.backgroundColor = [UIColor clearColor];
  _bandIndicator.textAlignment = UITextAlignmentCenter;
  [self.view addSubview: _bandIndicator];
  _tuningIndicator = [[UILabel alloc] initWithFrame: CGRectMake( 68, _controlBar.frame.origin.y - 12, 184, 12 )];
  _tuningIndicator.font = [UIFont boldSystemFontOfSize: 10];
  _tuningIndicator.textColor = [UIColor whiteColor];
  _tuningIndicator.backgroundColor = [UIColor clearColor];
  _tuningIndicator.textAlignment = UITextAlignmentCenter;
  [self.view addSubview: _tuningIndicator];
  _stereoIndicator = [[UILabel alloc] initWithFrame: CGRectMake( 252, _controlBar.frame.origin.y - 12, 60, 12 )];
  _stereoIndicator.font = [UIFont boldSystemFontOfSize: 10];
  _stereoIndicator.textColor = [UIColor whiteColor];
  _stereoIndicator.backgroundColor = [UIColor clearColor];
  _stereoIndicator.textAlignment = UITextAlignmentCenter;
  [self.view addSubview: _stereoIndicator];
}

- (void) viewWillAppear: (BOOL) animated
{
  MainNavigationController *mainController = (MainNavigationController *) self.navigationController;
  
  [super viewWillAppear: animated];
  
  mainController.navigationBar.barStyle = UIBarStyleBlackOpaque;
  mainController.navigationBar.tintColor = nil;
  [mainController setAudioControlsStyle: UIBarStyleBlackTranslucent];
  [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque animated: YES];
  [self source: _tuner stateChanged: 0xFFFFFFFF];
}

- (void) viewDidDisappear: (BOOL) animated
{
  [_tuner removeDelegate: self];
  [super viewDidDisappear: animated];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  
  if (_location != nil && _service != nil)
  {    
    [self source: _tuner stateChanged: 0xFFFFFFFF];
    [_tuner addDelegate: self];
    [(MainNavigationController *) self.navigationController showAudioControls: YES];
  }
}

- (void) source: (NLSourceTuner *) source stateChanged: (NSUInteger) flags
{
  BOOL bandChanged = ((flags & SOURCE_TUNER_BAND_CHANGED) != 0);

  if (_bandIndicator != nil)
  {
    if (bandChanged)
      _bandIndicator.text = source.band;

    if ((source.capabilities & SOURCE_TUNER_HAS_FEEDBACK) == 0)
      [self noFeedbackSource: source stateChanged: flags];
    else
    {
      if ([[source sourceControlType] isEqualToString: @"XM TUNER"] ||
          [source.band isEqualToString: @"XM"] || [source.band isEqualToString: @"Sirius"])
        [self satelliteSource: source stateChanged: flags];
      else if ([source.band isEqualToString: @"DAB"])
        [self digitalSource: source stateChanged: flags];
      else
        [self analogSource: source stateChanged: flags];
      
      if ((flags & SOURCE_TUNER_STEREO_CHANGED) != 0)
      {
        if (source.stereo == nil || [source.stereo length] == 0)
          _stereoIndicator.text = @"";
        else if ([[source.stereo uppercaseString] isEqualToString: @"STEREO"])
          _stereoIndicator.text = NSLocalizedString( @"STEREO", @"Label indicating stereo reception" );
        else
          _stereoIndicator.text = NSLocalizedString( @"MONO", @"Label indicating mono reception" );
      }
      
      if ((flags & SOURCE_TUNER_CONTROL_STATE_CHANGED) != 0)
      {
        NSUInteger count = [_controlBar.items count];
        NSUInteger i;
        
        if ([source.controlState isEqualToString: @"REFRESH"])
        {
          for (i = 1; i < count; ++i)
            ((UIBarButtonItem *) [_controlBar.items objectAtIndex: i]).enabled = NO;
          
          UIBarButtonItem *lastItem = [_toolBar.items lastObject];
          
          if (lastItem.action == @selector(pressedSavePreset:))
            lastItem.enabled = NO;
          _flipButton.enabled = NO;
          if ([_flippingView superview] == nil)
            [self flipCurrentView: _flipButton];
        }
        else
        {
          for (i = 1; i < count; ++i)
            ((UIBarButtonItem *) [_controlBar.items objectAtIndex: i]).enabled = YES;
          if ([source.band isEqualToString: @"XM"] || [source.band isEqualToString: @"Sirius"])
            _tuneTypeButton.enabled = NO;
          
          UIBarButtonItem *lastItem = [_toolBar.items lastObject];
          
          if (lastItem.action == @selector(pressedSavePreset:))
            lastItem.enabled = YES;
          _flipButton.enabled = YES;
        }
      }
      
      if ((flags & (SOURCE_TUNER_CONTROL_STATE_CHANGED|SOURCE_TUNER_BITRATE_CHANGED|SOURCE_TUNER_FORMAT_CHANGED|
                    SOURCE_TUNER_RESCAN_COMPLETE_CHANGED|SOURCE_TUNER_STATIONS_FOUND_CHANGED)) != 0)
      {
        if (source.controlState == nil || [source.controlState length] == 0 || [source.controlState isEqualToString: @"UNLOCKED"])
          _tuningIndicator.text = @"";
        else if ([source.controlState isEqualToString: @"TUNE_UP"] || [source.controlState isEqualToString: @"TUNE_DOWN"] ||
                 [source.controlState isEqualToString: @"TUNING_UP"] || [source.controlState isEqualToString: @"TUNING_DOWN"])
          _tuningIndicator.text = NSLocalizedString( @"TUNING", @"Label indicating that the tuner is retuning" );
        else if ([source.controlState isEqualToString: @"SCANNING_UP"] || [source.controlState isEqualToString: @"SCANNING_DOWN"])
          _tuningIndicator.text = NSLocalizedString( @"SCANNING", @"Label indicating that the tuning is scanning" );
        else if ([source.controlState isEqualToString: @"SEEKING_UP"] || [source.controlState isEqualToString: @"SEEKING_DOWN"])
          _tuningIndicator.text = NSLocalizedString( @"SEEKING", @"Label indicating that the tuning is seeking" );
        else if ([source.controlState isEqualToString: @"REFRESH"])
        {
          _tuningIndicator.text = [NSString stringWithFormat: NSLocalizedString( @"REFRESH %u%% COMPLETE", @"Tuner refresh status message" ),
                                   source.rescanComplete];
        }
        else
        {
          if (source.format == nil)
            _tuningIndicator.text = NSLocalizedString( @"", @"Label indicating that the tuner is locked onto a station" );
          else
          {
            if (source.bitrate == nil)
              _tuningIndicator.text = NSLocalizedString( source.format, @"ANALOG/DIGITAL radio format" );
            else
            {
              NSString *bitrate = source.bitrate;
              
              if ([bitrate hasSuffix: @"000"])
                bitrate = [NSString stringWithFormat: @"%@K", [bitrate substringToIndex: [bitrate length] - 3]];
              _tuningIndicator.text = [NSString stringWithFormat: @"%@ %@", bitrate,
                                       NSLocalizedString( source.format, @"ANALOG/DIGITAL radio format" )];
            }
          }
        }
      }
      
      if ((flags & SOURCE_TUNER_GENRE_CHANGED) != 0)
      {
        if (source.genre == nil || [source.genre length] == 0)
          _genre.text = @"";
        else
        {
          _genreLabel.hidden = NO;
          _genre.text = source.genre;
        }
      }
      
      if ((flags & SOURCE_TUNER_ARTWORK_CHANGED) != 0)
      {
        _noLogoCaption.hidden = (source.artwork != nil);
        _logo.image = source.artwork;
        [_logo sizeToFit];
      }
    }
  }
}

- (void) noFeedbackSource: (NLSourceTuner *) source stateChanged: (NSUInteger) flags
{
  if ((flags & SOURCE_TUNER_CAPTION_CHANGED) != 0)
  {
    _titleLines12.text = @"";
    _titleLine1.text = @"";
    _titleLine2.text = @"";
    _titleLine3.text = @"";
    if (source.caption == nil || [source.caption length] == 0)
      _titleLines123.text = source.displayName;
    else
      _titleLines123.text = source.caption;
    _noLogoCaption.text = source.caption;
    _logo.image = nil;
    if (![[_tuner sourceControlType] isEqualToString: @"XM TUNER"])
    {
      _backdrop.image = [UIImage imageNamed: @"DefaultTunerArtwork.png"];
      if (_tuneType == TUNE_TYPE_CHANNEL)
        _tuneType = TUNE_TYPE_TUNE;
      _tuneTypeButton.enabled = YES;
    }
    else
    {
      if ([[_tuner sourceType] isEqualToString: @"Sirius"])
        _backdrop.image = [UIImage imageNamed: @"DefaultSiriusTunerArtwork.png"];
      else
        _backdrop.image = [UIImage imageNamed: @"DefaultXMTunerArtwork.png"];
      _tuneType = TUNE_TYPE_CHANNEL;
      _tuneTypeButton.enabled = NO;
    }
    _reflection.image = _backdrop.image;
    _tuneTypeButton.title = TUNE_TYPE_TITLES[_tuneType];
  }
}

- (void) satelliteSource: (NLSourceTuner *) source stateChanged: (NSUInteger) flags
{
  BOOL bandChanged = ((flags & SOURCE_TUNER_BAND_CHANGED) != 0);
  
  if (bandChanged)
  {
    _titleLines12.text = @"";
    _titleLines123.text = @"";
    _tuneType = TUNE_TYPE_CHANNEL;
    _tuneTypeButton.title = TUNE_TYPE_TITLES[_tuneType];
    _tuneTypeButton.enabled = NO;
    _songLabel.hidden = NO;
    _artistLabel.hidden = NO;
    _genreLabel.hidden = NO;
    _stationLabel.text = NSLocalizedString( @"Channel", @"Title for station label on tuner with channel-based tuning" );
    _radioTextLabel.hidden = YES;
    _radioText.hidden = YES;
    _radioText.text = @"";
    if ([source.band length] > 0)
    {
      if ([source.band isEqualToString: @"Sirius"])
        _backdrop.image = [UIImage imageNamed: @"DefaultSiriusTunerArtwork.png"];
      else
        _backdrop.image = [UIImage imageNamed: @"DefaultXMTunerArtwork.png"];
    }
    _reflection.image = _backdrop.image;
  }
  
  if ([source.controlState isEqualToString: @"REFRESH"])
  {
    _titleLines123.text = NSLocalizedString( @"Refreshing", @"Title when refreshing satellite tuner channels" );
    _titleLine1.text = @"";
    _titleLine2.text = @"";
    _titleLine3.text = @"";
    _song.text = @"";
    _artist.text = @"";
    _genre.text = @"";
    _station.text = @"";
    _noLogoCaption.text = @"";
  }
  else
  {
    BOOL changed = bandChanged || ((flags & SOURCE_TUNER_CONTROL_STATE_CHANGED) != 0);
    
    _titleLines123.text = @"";
  
    if (changed || (flags & SOURCE_TUNER_SONG_CHANGED) != 0)
    {
      _titleLine2.text = source.song;
      _song.text = source.song;
    }
    if (changed || (flags & SOURCE_TUNER_ARTIST_CHANGED) != 0)
    {
      _titleLine1.text = source.artist;
      _artist.text = source.artist;
    }
    if (changed || (flags & SOURCE_TUNER_GENRE_CHANGED) != 0)
      _genre.text = source.genre;
    if (changed || (flags & (SOURCE_TUNER_CHANNEL_NUM_CHANGED|SOURCE_TUNER_CHANNEL_NAME_CHANGED)) != 0)
    {
      _noLogoCaption.text = source.channelName;
      _titleLine3.text = [NSString stringWithFormat: @"%@ - %@", source.channelNum, source.channelName];
      _station.text = _titleLine3.text;
    }
  }
}

- (void) digitalSource: (NLSourceTuner *) source stateChanged: (NSUInteger) flags
{
  BOOL bandChanged = ((flags & SOURCE_TUNER_BAND_CHANGED) != 0);
  
  if (bandChanged)
  {
    _titleLines12.text = @"";
    _titleLine1.text = @"";
    _titleLine2.text = @"";
    _titleLine3.text = @"";
    if (_tuneType == TUNE_TYPE_CHANNEL || _tuneType == TUNE_TYPE_TUNE)
      _tuneType = TUNE_TYPE_SEEK;
    _tuneTypeButton.title = TUNE_TYPE_TITLES[_tuneType];
    _tuneTypeButton.enabled = YES;
    _songLabel.hidden = YES;
    _song.text = @"";
    _artistLabel.hidden = YES;
    _artist.text = @"";
    _genreLabel.hidden = NO;
    _genre.text = @"";
    _stationLabel.text = NSLocalizedString( @"Station", @"Title for station label on tuner with station-based tuning" );
    _radioText.hidden = NO;
    _radioTextLabel.hidden = NO;
    _radioText.text = @"";
    _backdrop.image = [UIImage imageNamed: @"DefaultTunerArtwork.png"];
    _reflection.image = _backdrop.image;
  }
  
  if ([source.controlState isEqualToString: @"REFRESH"])
  {
    _titleLines123.text = NSLocalizedString( @"Refreshing", @"Title when refreshing DAB tuner stations" );
    _genre.text = @"";
    _station.text = @"";
    _noLogoCaption.text = @"";
    _radioText.text = @"";
  }
  else
  {
    BOOL changed = bandChanged || ((flags & SOURCE_TUNER_CONTROL_STATE_CHANGED) != 0);
    
    if (changed || (flags & SOURCE_TUNER_CHANNEL_NAME_CHANGED) != 0)
    {
      _titleLines123.text = source.channelName;
      _noLogoCaption.text = source.channelName;
      _station.text = source.channelName;
      _radioText.text = @"";
    }
  
    if ((changed || (flags & SOURCE_TUNER_CAPTION_CHANGED) != 0) && source.caption != nil && [source.caption length] > 0)
      [self handleRadioText: source.caption];
  }
}

- (void) analogSource: (NLSourceTuner *) source stateChanged: (NSUInteger) flags
{
  BOOL bandChanged = ((flags & SOURCE_TUNER_BAND_CHANGED) != 0);
  BOOL changed = bandChanged || ((flags & SOURCE_TUNER_CONTROL_STATE_CHANGED) != 0);
    
  if (bandChanged)
  {
    _songLabel.hidden = YES;
    _song.text = @"";
    _artistLabel.hidden = YES;
    _artist.text = @"";
    _stationLabel.text = NSLocalizedString( @"Station", @"Title for station label on tuner with station-based tuning" );
    _backdrop.image = [UIImage imageNamed: @"DefaultTunerArtwork.png"];
    _reflection.image = _backdrop.image;
  }
  
  if (bandChanged && _tuneType == TUNE_TYPE_CHANNEL)
  {
    _tuneType = TUNE_TYPE_TUNE;
    _tuneTypeButton.title = TUNE_TYPE_TITLES[_tuneType];
    _tuneTypeButton.enabled = YES;
  }
  
  if (changed || (flags & (SOURCE_TUNER_CHANNEL_NUM_CHANGED|SOURCE_TUNER_CHANNEL_NAME_CHANGED)) != 0)
    _radioText.text = @"";

  if (changed || (flags & (SOURCE_TUNER_CHANNEL_NUM_CHANGED|SOURCE_TUNER_CHANNEL_NAME_CHANGED|SOURCE_TUNER_CAPTION_CHANGED)) != 0)
  {
    if (source.channelName != nil && [source.channelName length] > 0)
    {
      _titleLines123.text = @"";
      _titleLines12.text = source.channelName;
      _titleLine3.text = source.channelNum;
      _noLogoCaption.text = source.channelName;
    }
    else
    {
      if (source.channelNum != nil && [source.channelNum length] > 0)
        _titleLines123.text = source.channelNum;        
      else
        _titleLines123.text = source.caption;
      
      _noLogoCaption.text = _titleLines123.text;
      _titleLines12.text = @"";
      _titleLine3.text = @"";
    }
    
    _titleLine1.text = @"";
    _titleLine2.text = @"";
    _station.text = _noLogoCaption.text;
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

- (void) handleRadioText: (NSString *) radioText
{
  radioText = [radioText stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];

  if ([radioText length] > 0)
  {
    static NSString *NEWLINES = @"\n \n \n \n \n \n \n ";
    NSString *newRadioText = _radioText.text;
    CGFloat lineHeight = [_radioText.font lineSpacing];
    NSUInteger visibleLines = _radioText.numberOfLines / 2;
    
    if (newRadioText == nil || [newRadioText length] == 0)
      newRadioText = radioText;
    else
    {
      newRadioText = [newRadioText substringFromIndex: _radioTextVisibleOffset];
      newRadioText = [newRadioText stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
      newRadioText = [newRadioText stringByAppendingFormat: @"\n%@", radioText];
    }
    
    CGSize actualTextArea = [newRadioText sizeWithFont: _radioText.font constrainedToSize: _radioText.frame.size lineBreakMode: UILineBreakModeWordWrap];
    NSUInteger numberOfLines = (NSUInteger) (actualTextArea.height / lineHeight);
    NSUInteger linesToScroll = 0;
    
    if (numberOfLines == 0)
      numberOfLines = 1;
    if (numberOfLines <= visibleLines)
    {
      newRadioText = [[NEWLINES substringToIndex: (visibleLines * 2) - 1] stringByAppendingFormat: @"%@%@",
                      newRadioText, [NEWLINES substringToIndex: (visibleLines - numberOfLines) * 2]];
      _radioTextVisibleOffset = (visibleLines * 2) - 1;
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
        actualTextArea = [candidate sizeWithFont: _radioText.font constrainedToSize: _radioText.frame.size lineBreakMode: UILineBreakModeWordWrap];
        numberOfLines = (NSUInteger) (actualTextArea.height / lineHeight);
      }
      while (numberOfLines > visibleLines);
      newRadioText = [[NEWLINES substringToIndex: ((visibleLines - linesToScroll) * 2) - 1] stringByAppendingString: newRadioText];
      _radioTextVisibleOffset += ((visibleLines - linesToScroll) * 2) - 1;
    }
    
    _radioText.text = newRadioText;
    _radioTextLabel.hidden = NO;
    _radioText.hidden = NO;
    
    if (linesToScroll > 0)
    {
      CGRect frame = _radioText.frame;
      CGRect newFrame = CGRectOffset( frame, 0, (lineHeight * linesToScroll) );
      
      _radioText.frame = newFrame;
      
      [UIView beginAnimations: nil context: nil];
      [UIView setAnimationDuration: 0.25 * linesToScroll];
      _radioText.frame = frame;
      [UIView commitAnimations];
    }
  }
}

- (void) goBack: (id) control
{
  [self.navigationController popViewControllerAnimated: YES];
}

- (void) flipCurrentView: (UIButton *) button
{
  // Swap the image and rotate
  BOOL swapIn = [_flippingView superview] == _flipBase;
  
  [UIView beginAnimations: nil context: nil];
  [UIView setAnimationDuration: 0.75];
  
  if (swapIn)
  {
    [UIView setAnimationTransition: UIViewAnimationTransitionFlipFromRight forView: _flipBase cache: YES];
    [_flippingView removeFromSuperview];
    [_keypadViewController viewWillAppear: YES];
    [_flipBase addSubview: _keypadViewController.view];
    [_keypadViewController viewDidAppear: YES];
  }
  else
  {
    [UIView setAnimationTransition: UIViewAnimationTransitionFlipFromLeft forView: _flipBase cache: YES];
    [_keypadViewController viewWillDisappear: YES];
    [_keypadViewController.view removeFromSuperview];
    [_keypadViewController viewDidDisappear: YES];
    [_flipBase addSubview: _flippingView];
  }
  
  [UIView commitAnimations];
  
  [UIView beginAnimations: nil context: nil];
  [UIView setAnimationDuration: 0.75];
  
  if (swapIn)
  {
    [UIView setAnimationTransition: UIViewAnimationTransitionFlipFromRight forView: _flipButton cache: YES];
    [_flipButton setBackgroundImage: _backdrop.image forState: UIControlStateNormal];
  }
  else
  {
    [UIView setAnimationTransition: UIViewAnimationTransitionFlipFromLeft forView: _flipButton cache: YES];
    [_flipButton setBackgroundImage: [UIImage imageNamed: @"KeyPad.png"] forState: UIControlStateNormal];
  }
  
  [UIView commitAnimations];
}

- (void) pressedBackdrop: (UIButton *) button
{
  _overlayView.hidden = NO;
}

- (void) pressedOverlay: (UIButton *) button
{
  _overlayView.hidden = YES;
}

- (void) pressedSavePreset: (id) control
{
  TunerAddPresetViewController *addPreset = [[[TunerAddPresetViewController alloc] initWithTuner: _tuner presetName: _noLogoCaption.text] autorelease];
  
  addPreset.navigationItem.leftBarButtonItem =
  [[[UIBarButtonItem alloc] 
    initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
    target: nil
    action: nil] autorelease];
  addPreset.navigationItem.rightBarButtonItem =
  [[[UIBarButtonItem alloc] 
    initWithBarButtonSystemItem: UIBarButtonSystemItemDone
    target: nil
    action: nil] autorelease];
  [self.navigationController presentModalViewController: addPreset animated: YES];
}

- (void) pressedBand: (id) control
{
  [_tuner nextBand];
}

- (void) pressedMode: (UIBarButtonItem *) button
{
  if (_tuneType > 0)
  {
    _tuneType = (_tuneType % 4) + 1;
    if (_tuneType == TUNE_TYPE_TUNE && [_tuner.band isEqualToString: @"DAB"])
      ++_tuneType;
  }
  button.title = TUNE_TYPE_TITLES[_tuneType];
}

- (void) pressedStereo: (id) control
{
  if (_tuner.stereo != nil)
  {
    if ([_tuner.stereo isEqualToString: @"FMONO"])
      [_tuner setStereo];
    else
      [_tuner setMono];
  }
}

- (void) pressedTuneDown: (id) control
{
  switch (_tuneType)
  {
    case TUNE_TYPE_TUNE:
      [_tuner tuneDown];
      break;
    case TUNE_TYPE_SEEK:
      [_tuner seekDown];
      break;
    case TUNE_TYPE_SCAN:
      [_tuner scanDown];
      break;
    case TUNE_TYPE_PRESET:
      [_tuner presetDown];
      break;
    default:
      [_tuner channelDown];
      break;
  }
}

- (void) pressedTuneUp: (id) control
{
  switch (_tuneType)
  {
    case TUNE_TYPE_TUNE:
      [_tuner tuneUp];
      break;
    case TUNE_TYPE_SEEK:
      [_tuner seekUp];
      break;
    case TUNE_TYPE_SCAN:
      [_tuner scanUp];
      break;
    case TUNE_TYPE_PRESET:
      [_tuner presetUp];
      break;
    default:
      [_tuner channelUp];
      break;
  }
}

- (void) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags
{
  [super renderer: renderer stateChanged: flags];
  
  if ((flags & NLRENDERER_AUDIO_SESSION_CHANGED) != 0)
  {
    if (renderer.audioSessionActive)
      [_controlBar fixedSetTint: [StandardPalette multizoneTintColour]];
    else
      [_controlBar fixedSetTint: nil];
  }
}

- (UILabel *) allocLabelInView: (UIView *) view bold: (BOOL) isBold withFrame: (CGRect) frame
{
  UILabel * label = [[UILabel alloc] initWithFrame: frame];
  
  if (isBold)
    label.font = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]];
  else
    label.font = [UIFont systemFontOfSize: [UIFont smallSystemFontSize]];
  label.textColor = [UIColor whiteColor];
  label.backgroundColor = [UIColor clearColor];
  label.textAlignment = UITextAlignmentLeft;
  [view addSubview: label];
  
  return label;
}

- (void) dealloc
{
  [_titleLine1 release];
  [_titleLine2 release];
  [_titleLine3 release]; 
  [_titleLines12 release];
  [_titleLines123 release];
  [_backdrop release];
  [_reflection release];
  [_flipButton release];
  [_flipBase release];
  [_flippingView release];
  [_logo release];
  [_noLogoCaption release];
  [_bandIndicator release];
  [_tuningIndicator release];
  [_stereoIndicator release];
  [_stereoButton release];
  [_tuneTypeButton release];
  [_controlBar release];
  [_overlayView release];
  [_songLabel release];
  [_song release];
  [_artistLabel release];
  [_artist release];
  [_genreLabel release];
  [_genre release];
  [_stationLabel release];
  [_station release];
  [_radioTextLabel release];
  [_radioText release];
  [_keypadViewController release];
  [super dealloc];
}

@end
