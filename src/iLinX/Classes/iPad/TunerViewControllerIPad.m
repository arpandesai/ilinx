//
//  TunerViewControllerIPad.m
//  iLinX
//
//  Created by Tony Short on 01/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <QuartzCore/CALayer.h>

#import "TunerViewControllerIPad.h"
#import "NLBrowseListNetStreamsRoot.h"
#import "AudioViewControllerIPad.h"
#import "TunerCurrentStation.h"
#import "ActivityViewController.h"
#import "NLService.h"
#import "NLRenderer.h"

static NSString *TUNE_TYPE_TITLES[5];

@implementation TunerViewControllerIPad

- (id) initWithOwner: (AudioViewControllerIPad *) owner service: (NLService *) service source: (NLSource *) source
{
  if(self = [super initWithOwner:owner service:service source:source nibName: @"TunerViewIPad" bundle: nil])
  {
    _tuner = [(NLSourceTuner*)source retain];
    
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

-(void)viewWillAppear:(BOOL)animated
{
  _keypadButton.enabled = ([_tuner capabilities] & SOURCE_TUNER_HAS_DIRECT_TUNE) ? YES : NO;
  _storePresetButton.enabled = ([_tuner capabilities] & SOURCE_TUNER_HAS_DYNAMIC_PRESETS) ? YES : NO;
  
  _presetView.tuner = _tuner;	
  BOOL currentHiddenState = _presetView.hidden;
  [_presetView setupOnViewWillAppear];
  if(currentHiddenState != _presetView.hidden)	// Move main view accordingly
  {
    if(_presetView.hidden)
      _mainView.frame = CGRectMake(0, 72, _mainView.frame.size.width + 215, _mainView.frame.size.height);
    else
      _mainView.frame = CGRectMake(215, 72, _mainView.frame.size.width - 215, _mainView.frame.size.height);
  }
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  
  if (_service != nil)
  {    
    [_tuner resetListCount];
    [self source: _tuner stateChanged: 0xFFFFFFFF];
    [_tuner addDelegate: self];
  }
}

- (void) viewDidDisappear: (BOOL) animated
{
  [_tuner removeDelegate: self];
  [_presetView cleanupOnViewDidDisappear];
  
  [super viewDidDisappear: animated];
}

-(BOOL)isIRTuner
{
  return ((_tuner.capabilities & SOURCE_TUNER_HAS_FEEDBACK) == 0);
}

-(BOOL)isSatellite
{
  //	return YES;
  
  if ([[_tuner sourceControlType] isEqualToString: @"XM TUNER"] ||
      [_tuner.band isEqualToString: @"XM"] || [_tuner.band isEqualToString: @"Sirius"])
    return YES;
  else
    return NO;
}

-(BOOL)isDAB
{
  return [_tuner.band isEqualToString: @"DAB"];
}

-(BOOL)isAnalog
{
  return [_tuner.band hasPrefix: @"FM"] || [_tuner.band hasPrefix: @"AM"];
}

-(void)updateTuneTypeButton:(NSString*)buttonTitle
{
  // Need to iterate through because different types of tuner have a different set of tune types
  for(int i = 0; i < NUM_TUNE_TYPES; i++)
    if([buttonTitle isEqualToString:TUNE_TYPE_TITLES[i]])
    {
      _tuneType = i;
      NSString *str = [NSString stringWithFormat:@"tunerControlsButtons%@.png", TUNE_TYPE_TITLES[i]];
      [_tuneTypeButton setBackgroundImage:[UIImage imageNamed:str] forState:UIControlStateNormal];
      [_tuneTypeButton setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"tunerControlsButtons%@Pressed.png", TUNE_TYPE_TITLES[i]]] forState:UIControlStateHighlighted];
    }
}

-(void)adaptTuneType
{
  _tuneTypeButton.enabled = YES;
  
  if([self isDAB])
  {
    // For DAB change Tune to Seek
    if (_tuneType == TUNE_TYPE_TUNE)
      _tuneType = TUNE_TYPE_SEEK;
  }
  else if ([self isAnalog] || [self isIRTuner])
  {
    // For Analog and IR change Channel to Tune
    if (_tuneType == TUNE_TYPE_CHANNEL)
      _tuneType = TUNE_TYPE_TUNE;
  }
  else if ([self isSatellite])
  {
    // For Satellite change Tune to Channel
    if(_tuneType == TUNE_TYPE_TUNE)
      _tuneType = TUNE_TYPE_CHANNEL;
  }
  
  [self updateTuneTypeButton:TUNE_TYPE_TITLES[_tuneType]];
}

-(void) setStationLogo: (UIImage *) artwork redraw: (BOOL) redraw
{
  if(redraw)
    for(UIView *view in _stationLogoView.subviews)
      if(view.tag != 99)
	[view removeFromSuperview];
  
  if ([_stationLogoView isKindOfClass: [UIImageView class]])
  {
    ((UIImageView *) _stationLogoView).image = artwork;
  }
  else
  {
    if(_stationLogoView.subviews.count == 1)	// Just template there
    {
      UIImageView *templateLogo = (UIImageView *) [_stationLogoView viewWithTag: 99];
      if (templateLogo == nil)
	return;
      
      BOOL finished = NO;
      NSInteger xOffset = 0, yOffset = 0;
      NSInteger width = templateLogo.frame.size.width, height = templateLogo.frame.size.height, startOffset = -width;
      
      while (!finished)
      {
	UIImageView *logo = [[UIImageView alloc] initWithFrame: CGRectMake( xOffset, yOffset, width, height )];
	logo.backgroundColor = templateLogo.backgroundColor;
	logo.alpha = templateLogo.alpha;
	[_stationLogoView addSubview:logo];
	[logo release];
	
	xOffset += width;
	if(xOffset > _stationLogoView.frame.size.width)
	{
	  startOffset += 50;
	  if(startOffset > 0)
	    startOffset = -width;
	  
	  xOffset = startOffset;
	  yOffset += height;
	  if(yOffset > _stationLogoView.frame.size.height)
	    finished = YES;
	}
      }
    }
    
    for (UIImageView *logo in _stationLogoView.subviews)
    {
      logo.image = artwork;
    }
  }
}

- (void) source: (NLSourceTuner *) source stateChanged: (NSUInteger) flags
{
  _titleLabel.text = source.displayName;	// Set window title to be source display name
  _storePresetButton.hidden = [self isIRTuner];	// Hide 'Store preset' if an IR Tuner	
  _bandLabel.text = source.band;
  [self adaptTuneType];
  
  // Current station contains controls related to station information
  [_currentStationView source:source stateChanged:flags];
  
  if ((flags & SOURCE_TUNER_BAND_CHANGED) != 0)		// Updates preset reference and delegates
  {
    //		NSLog(@"***Band Changed");
    [_presetView reassignBrowseList];
  }
  
  else if ((flags != 0xFFFFFFFF) && ((flags & SOURCE_TUNER_LIST_COUNT_CHANGED) != 0))	// Upon the preset list changing
  {
    //		NSLog(@"***List Count Changed");
    [_presetView setStartingList];
  }
  
  if ((flags & SOURCE_TUNER_STEREO_CHANGED) != 0)
  {
    if (source.stereo == nil || [source.stereo length] == 0)
      _stereoLabel.text = @"";
    else if ([[source.stereo uppercaseString] isEqualToString: @"STEREO"])
    {
      _isStereo = YES;
      _stereoLabel.text = NSLocalizedString( @"STEREO", @"Label indicating stereo reception" );
    }
    else
    {
      _isStereo = NO;
      _stereoLabel.text = NSLocalizedString( @"MONO", @"Label indicating mono reception" );
    }
  }	
  
  // Tuning indicator
  if ((flags & (SOURCE_TUNER_CONTROL_STATE_CHANGED|SOURCE_TUNER_BITRATE_CHANGED|SOURCE_TUNER_FORMAT_CHANGED|
		SOURCE_TUNER_RESCAN_COMPLETE_CHANGED|SOURCE_TUNER_STATIONS_FOUND_CHANGED)) != 0)
  {
    BOOL showActivityView = NO;
    
    if (source.controlState == nil || [source.controlState length] == 0 || [source.controlState isEqualToString: @"UNLOCKED"])
      _tuningIndicatorLabel.text = @"";
    else if ([source.controlState isEqualToString: @"TUNE_UP"] || [source.controlState isEqualToString: @"TUNE_DOWN"] ||
	     [source.controlState isEqualToString: @"TUNING_UP"] || [source.controlState isEqualToString: @"TUNING_DOWN"])
      _tuningIndicatorLabel.text = NSLocalizedString( @"TUNING", @"Label indicating that the tuner is retuning" );
    else if ([source.controlState isEqualToString: @"SCANNING_UP"] || [source.controlState isEqualToString: @"SCANNING_DOWN"])
      _tuningIndicatorLabel.text = NSLocalizedString( @"SCANNING", @"Label indicating that the tuning is scanning" );
    else if ([source.controlState isEqualToString: @"SEEKING_UP"] || [source.controlState isEqualToString: @"SEEKING_DOWN"])
      _tuningIndicatorLabel.text = NSLocalizedString( @"SEEKING", @"Label indicating that the tuning is seeking" );
    else if ([source.controlState isEqualToString: @"REFRESH"])
    {
      showActivityView = YES;
    }
    else
    {
      if (source.format == nil)
	_tuningIndicatorLabel.text = NSLocalizedString( @"", @"Label indicating that the tuner is locked onto a station" );
      else
      {
	if (source.bitrate == nil)
	  _tuningIndicatorLabel.text = NSLocalizedString( source.format, @"ANALOG/DIGITAL radio format" );
	else
	{
	  NSString *bitrate = source.bitrate;
	  
	  if ([bitrate hasSuffix: @"000"])
	    bitrate = [NSString stringWithFormat: @"%@K", [bitrate substringToIndex: [bitrate length] - 3]];
	  _tuningIndicatorLabel.text = [NSString stringWithFormat: @"%@ %@", bitrate,
					NSLocalizedString( source.format, @"ANALOG/DIGITAL radio format" )];
	}
      }
    }
    if(showActivityView)
    {
      [[ActivityView instance] overlayOnView:self.view];
      [ActivityView instance].limit = 100;
      NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			    [NSNumber numberWithInt:source.rescanComplete], @"Progress", 
			    [NSString stringWithFormat:@"Found %d channels"
			     , source.stationsFound], @"Label", nil ];
      
      [[ActivityView instance] updateActivityProgress:dict]; 
    }
    else
      [[ActivityView instance] cancelPressed];
    
  }
  
  // Backdrop view
  if ([self isSatellite])
  {
    if ([[_tuner sourceType] isEqualToString: @"Sirius"])
      _tunerTypeLogo.image = [UIImage imageNamed: @"DefaultSiriusTunerArtwork.png"];
    else
      _tunerTypeLogo.image = [UIImage imageNamed: @"DefaultXMTunerArtwork.png"];
  }
  else
    _tunerTypeLogo.image = [UIImage imageNamed: @"DefaultTunerArtwork.png"];
  
  // Artwork
  if((flags & SOURCE_TUNER_ARTWORK_CHANGED) != 0)
  {
    [self setStationLogo: source.artwork redraw: NO];
  }
}

- (IBAction) pressedStorePreset: (id) control
{
  if(_addPresetPopover != nil)
  {
    if(_addPresetPopover.popoverVisible)
      [_addPresetPopover dismissPopoverAnimated:YES];
    
    [_addPresetPopover release];
    [_addPresetViewController release];
  }
  
  NSString *presetName;
  if((_currentStationView.channelName == nil) || (_currentStationView.channelName.length == 0))
    presetName = _currentStationView.channelNum;
  else
    presetName = _currentStationView.channelName;
  
  _addPresetViewController = [[TunerAddPresetViewControllerIPad alloc] initWithTuner:_tuner parentController:self presetName:presetName];
  _addPresetPopover = [[UIPopoverController alloc] initWithContentViewController:_addPresetViewController];
  _addPresetViewController.contentSizeForViewInPopover = CGSizeMake(320, 351);
  _addPresetPopover.popoverContentSize = _addPresetViewController.contentSizeForViewInPopover;
  
  [_addPresetPopover presentPopoverFromRect:_storePresetButton.frame inView:_storePresetButton.superview permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];	
}

-(void)dismissAddPresetView
{
  [_addPresetPopover dismissPopoverAnimated:YES];
  [_presetView performSelector:@selector(reloadTableView) withObject:nil afterDelay:2];
}

- (IBAction) pressedBand: (id) control
{
  [_tuner nextBand];
}

- (IBAction) pressedMode: (id) control
{
  [_tuneTypeActionSheet release];
  _tuneTypeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Tune Type" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
  
  for(int i = 0; i < NUM_TUNE_TYPES; i++)
  {
    switch (i)
    {
      case TUNE_TYPE_TUNE:
	// Exclude Tune if not analog or IRTuner
	if(!([self isAnalog] || [self isIRTuner]))
	  continue;
	break;
      case TUNE_TYPE_CHANNEL:
	// Exclude Channcel if analog or IRTuner
	if([self isAnalog] || [self isIRTuner])
	  continue;
	break;
      case TUNE_TYPE_PRESET:
	// Exclude Preset if Browse menu doesn't exist
	if(_tuner.browseMenu == nil)
	  continue;
      default:
	break;
    }
    [_tuneTypeActionSheet addButtonWithTitle:TUNE_TYPE_TITLES[i]];
  }
  [_tuneTypeActionSheet showFromRect:_tuneTypeButton.frame inView:_tuneTypeButton.superview animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if(buttonIndex == actionSheet.cancelButtonIndex)
    return;
  
  _tuneType = buttonIndex;
  [self updateTuneTypeButton:[actionSheet buttonTitleAtIndex:_tuneType]];
}

- (IBAction) pressedTuneDown: (id) control
{
  [_presetView deselectPreset];
  
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
    case TUNE_TYPE_CHANNEL:
      [_tuner channelDown];
      break;
  }	
}

- (IBAction) pressedTuneUp: (id) control
{
  [_presetView deselectPreset];
  
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

-(IBAction)pressedStereo: (id) control
{
  if(_isStereo)
    [_tuner setMono];
  else
    [_tuner setStereo];
}

- (IBAction) pressedKeypad: (id) control
{
  if(_keypadPopover == nil)
  {
    _keypadViewController = [[TunerKeypadViewControllerIPad alloc] initWithTuner:_tuner parentController:(TunerViewControllerIPad*)self];
    _keypadPopover = [[UIPopoverController alloc] initWithContentViewController:_keypadViewController];
    _keypadViewController.contentSizeForViewInPopover = CGSizeMake(320, 373);
    _keypadPopover.popoverContentSize = _keypadViewController.contentSizeForViewInPopover;
  }
  
  if(_keypadPopover.popoverVisible)
    [_keypadPopover dismissPopoverAnimated:YES];
  else
    [_keypadPopover presentPopoverFromRect:_keypadButton.frame inView:_keypadButton.superview permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

-(void)dismissKeyboard
{
  [_keypadPopover dismissPopoverAnimated:YES];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
  return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  [_currentStationView positionControls];  // Typically Radio Text control will have more/less space
  
  [self setStationLogo: _tuner.artwork
		redraw: YES];
  
  if(_keypadPopover.popoverVisible)
    [_keypadPopover presentPopoverFromRect:_keypadButton.frame inView:_keypadButton.superview permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
  
  if(_addPresetPopover.popoverVisible)
    [_addPresetPopover presentPopoverFromRect:_storePresetButton.frame inView:_storePresetButton.superview permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
  
  if(_tuneTypeActionSheet.visible)
  {
    // tuneType button has not updated frame at this point for some reason, so need to redisplay after a minimal delay
    [_tuneTypeActionSheet dismissWithClickedButtonIndex:_tuneTypeActionSheet.cancelButtonIndex animated:NO];
    [self performSelector:@selector(pressedMode:) withObject:nil afterDelay:0.1];
  }
  
  [_presetView rotated];
}

- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}

-(void)handleInitialSelection
{
  /*
   _initialSelectionKey = [[NSString stringWithFormat: @":%@", kFirstChoiceTunerKey,
   _delegate.roomList.currentRoom.sources.currentSource.serviceName] retain];
   
   _initialSelection = [[NSUserDefaults standardUserDefaults] objectForKey: _initialSelectionKey];
   
   if (_initialSelection == nil)
   {
   
   }
   
   [_initialSelection retain];
   [_genericInitialSelection retain];
   
   _selectInitialSelection = ![self selectInitialSelection];
   */
}

- (void)viewDidUnload {
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}

- (void) dealloc 
{
  [_mainView release];
  [_titleLabel release];
  [_bandLabel release];
  [_stereoLabel release];
  [_tunerTypeLogo release];
  [_tuningIndicatorLabel release];
  [_stationLogoView release];
  [_currentStationView release];
  [_tuneTypeButton release];
  [_tuner release];
  [_tuneTypeActionSheet release];
  [_keypadButton release];
  [_storePresetButton release];
  [_presetView release];
  [_keypadViewController release];
  [_keypadPopover release];
  [_addPresetPopover release];
  [_addPresetViewController release];
  [super dealloc];
}

@end
