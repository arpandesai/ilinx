//
//  HVACDisplayViewController.m
//  iLinX
//
//  Created by mcf on 13/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "HVACDisplayViewController.h"
#import "HVACSetPointViewController.h"
#import "XIBViewController.h"

@implementation HVACDisplayViewController

- (id) initWithHvacService: (NLServiceHVAC *) hvacService parentController: (UIViewController *) parentController
{
  if ((self = [super initWithNibName: @"HVAC" bundle: nil]) != nil)
  {
    _hvacService = [hvacService retain];
    _parentController = parentController;
  }

  return self;
}

- (void) viewDidLoad
{
  [super viewDidLoad];

  BOOL indoorHumidity = ((_hvacService.capabilities & SERVICE_HVAC_HAS_INDOOR_HUMIDITY) != 0);
  BOOL outdoorTemp = ((_hvacService.capabilities & SERVICE_HVAC_HAS_OUTDOOR_TEMP) != 0);
  BOOL outdoorHumidity = ((_hvacService.capabilities & SERVICE_HVAC_HAS_OUTDOOR_HUMIDITY) != 0);
  
  _zoneLabel.font = [UIFont boldSystemFontOfSize: _zoneLabel.font.pointSize];
  _zoneHumidityLabel.hidden = !indoorHumidity;
  _zoneHumidity.hidden = !indoorHumidity;
  _zoneSetPointLabel.font = [UIFont boldSystemFontOfSize: _zoneSetPointLabel.font.pointSize];
  _outsideLabel.font = [UIFont boldSystemFontOfSize: _outsideLabel.font.pointSize];
  _outsideLabel.hidden = !(outdoorTemp || outdoorHumidity);
  _outsideTemp.hidden = !outdoorTemp;
  _outsideTempType.hidden = !outdoorTemp;
  _outsideHumidityLabel.hidden = !outdoorHumidity;
  _outsideHumidity.hidden = !outdoorHumidity;
  _modeTitle.font = [UIFont boldSystemFontOfSize: _modeTitle.font.pointSize];
  [XIBViewController setFontForControl: _setSetPointButton];
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  [self service: _hvacService changed: 0xFFFFFFFF];
  [_hvacService addDelegate: self];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_hvacService removeDelegate: self];
  [super viewWillDisappear: animated];
}

- (IBAction) pressedSetSetPointButton: (UIButton *) button
{
  HVACSetPointViewController *setSetPoints = [[[HVACSetPointViewController alloc] initWithHvacService: _hvacService] autorelease];
  
  setSetPoints.navigationItem.leftBarButtonItem =
  [[[UIBarButtonItem alloc] 
    initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
    target: nil
    action: nil] autorelease];
  setSetPoints.navigationItem.rightBarButtonItem =
  [[[UIBarButtonItem alloc] 
    initWithBarButtonSystemItem: UIBarButtonSystemItemDone
    target: nil
    action: nil] autorelease];
  [_parentController.navigationController presentModalViewController: setSetPoints animated: YES];
}

- (IBAction) nothing
{
}

- (void) service: (NLServiceHVAC *) service changed: (NSUInteger) changed
{
  if ((changed & SERVICE_HVAC_OUTSIDE_TEMP_CHANGED) != 0)
    _outsideTemp.text = _hvacService.outsideTemperature;
  if ((changed & SERVICE_HVAC_OUTSIDE_HUMIDITY_CHANGED) != 0)
    _outsideHumidity.text = _hvacService.outsideHumidity;
  if ((changed & SERVICE_HVAC_ZONE_TEMP_CHANGED) != 0)
    _zoneTemp.text = _hvacService.zoneTemperature;
  if ((changed & SERVICE_HVAC_ZONE_HUMIDITY_CHANGED) != 0)
    _zoneHumidity.text = _hvacService.zoneHumidity;
  if ((changed & SERVICE_HVAC_CURRENT_SETPOINT_CHANGED) != 0)
    _zoneSetPointTemp.text = _hvacService.currentSetPointTemperature;
  if ((changed & SERVICE_HVAC_TEMP_SCALE_CHANGED) != 0)
  {
    _zoneTempType.text = _hvacService.temperatureScale;
    _zoneSetPointTempType.text = _hvacService.temperatureScale;
    _outsideTempType.text = _hvacService.temperatureScale;
  }
  if ((changed & SERVICE_HVAC_STATE_HEADER_CHANGED) != 0)
    _modeTitle.text = _hvacService.currentStateHeader;
  if ((changed & SERVICE_HVAC_STATE_LINE1_CHANGED) != 0)
    _modeLine1.text = _hvacService.currentStateLine1;
  if ((changed & SERVICE_HVAC_STATE_LINE2_CHANGED) != 0)
    _modeLine2.text = _hvacService.currentStateLine2NoIcon;
  if ((changed & SERVICE_HVAC_STATE_LINE2I_CHANGED) != 0)
    _modeLine2WithIcon.text = _hvacService.currentStateLine2WithIcon;
  if ((changed & SERVICE_HVAC_SHOW_ICON_CHANGED) != 0)
  {
    BOOL show = _hvacService.showIcon;
    
    _modeLine2.hidden = show;
    _modeLine2WithIcon.hidden = !show;
    _modeIcon.hidden = !show;
  }
}

- (void) dealloc
{
  [_hvacService release];
  [_zoneLabel release];
  [_zoneTemp release];
  [_zoneTempType release];
  [_zoneHumidityLabel release];
  [_zoneHumidity release];
  [_zoneSetPointLabel release];
  [_zoneSetPointTemp release];
  [_zoneSetPointTempType release];
  [_setSetPointButton release];
  [_outsideLabel release];
  [_outsideTemp release];
  [_outsideTempType release];
  [_outsideHumidityLabel release];
  [_outsideHumidity release];
  [_modeTitle release];
  [_modeLine1 release];
  [_modeLine2 release];
  [_modeIcon release];
  [_modeLine2WithIcon release];
  [super dealloc];
}

@end
