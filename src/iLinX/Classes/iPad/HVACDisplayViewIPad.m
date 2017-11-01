//
//  HVACDisplayViewControllerIPad.m
//  iLinX
//
//  Created by Tony Short on 15/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <QuartzCore/CALayer.h>
#import "HVACDisplayViewIPad.h"

@implementation HVACDisplayViewIPad

@synthesize hvacService = _hvacService;

- (void) dealloc 
{
  [_hvacService release];
  [_currentTempView release];
  [_outsideTempView release];
  [_setPointView release];
  [_setPointView1 release];
  [_setPointView2 release];
  [_feedbackView release];
  [_controlView release];
  [_zoneTemp release];
  [_zoneTempType release];
  [_zoneHumidityLabel release];
  [_zoneHumidity release];
  [_setPointTemp release];
  [_setPointTempType release];
  [_coolSetPointTemp release];
  [_coolSetPointTempType release];
  [_warmSetPointTemp release];
  [_warmSetPointTempType release];
  [_setPointSlider release];
  [_coolSetPointSlider release];
  [_warmSetPointSlider release];
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

-(void)setViewBorder:(UIView*)suppliedView
{
  suppliedView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
  suppliedView.layer.borderWidth = 1.0;
}

-(void)setViewBorders
{
  [self setViewBorder:_currentTempView];
  [self setViewBorder:_outsideTempView];
  [self setViewBorder:_setPointView];
  [self setViewBorder:_feedbackView];
  [self setViewBorder:_controlView];
}	

- (void) service: (NLServiceHVAC *) service changed: (NSUInteger) changed
{
  BOOL indoorHumidity = ((service.capabilities & SERVICE_HVAC_HAS_INDOOR_HUMIDITY) != 0);
  BOOL outdoorTemp = ((service.capabilities & SERVICE_HVAC_HAS_OUTDOOR_TEMP) != 0);
  BOOL outdoorHumidity = ((service.capabilities & SERVICE_HVAC_HAS_OUTDOOR_HUMIDITY) != 0);
  BOOL dualSetPoints = ((service.capabilities & SERVICE_HVAC_HAS_COOLING) != 0);
  //	BOOL dualSetPoints = YES;
  
  _zoneHumidityLabel.hidden = !indoorHumidity;
  _zoneHumidity.hidden = !indoorHumidity;
  _outsideLabel.hidden = !(outdoorTemp || outdoorHumidity);
  _outsideTemp.hidden = !outdoorTemp;
  _outsideTempType.hidden = !outdoorTemp;
  _outsideHumidityLabel.hidden = !outdoorHumidity;
  _outsideHumidity.hidden = !outdoorHumidity;
  _setPointView1.hidden = dualSetPoints;
  _setPointView2.hidden = !dualSetPoints;
  
  NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
  [formatter setMaximumFractionDigits: 0];

  if (dualSetPoints)
  {
    float heatMin = [service heatSetPointMin];
    float heatMax = [service heatSetPointMax];
    float heatCurrent = (service.heatSetPointTemperature != nil) ? [[formatter numberFromString: service.heatSetPointTemperature] intValue] : heatMin;
    float coolMin = [service coolSetPointMin];
    float coolMax = [service coolSetPointMax];
    float coolCurrent = (service.coolSetPointTemperature != nil) ? [[formatter numberFromString: service.coolSetPointTemperature] intValue] : coolMin;
    
    if (heatMin == heatMax)
    {
      _warmSetPointSlider.minimumValue = coolMin;
      _warmSetPointSlider.maximumValue = coolMax;
      _warmSetPointSlider.enabled = false;
    }
    else
    {
      _warmSetPointSlider.minimumValue = heatMin;
      _warmSetPointSlider.maximumValue = heatMax;
      _warmSetPointSlider.enabled = true;      
    }
    _warmSetPointSlider.value = heatCurrent;

    if (coolMin == coolMax)
    {
      _coolSetPointSlider.minimumValue = heatMin;
      _coolSetPointSlider.maximumValue = heatMax;
      _coolSetPointSlider.enabled = false;
    }
    else
    {
      _coolSetPointSlider.minimumValue = coolMin;
      _coolSetPointSlider.maximumValue = coolMax;
      _coolSetPointSlider.enabled = true;      
    }
    _coolSetPointSlider.value = coolCurrent;
  }
  else
  {
    _setPointSlider.minimumValue = [service heatSetPointMin];
    _setPointSlider.maximumValue = [service heatSetPointMax];
    _setPointSlider.value = (service.currentSetPointTemperature != nil) ? [[formatter numberFromString:service.currentSetPointTemperature] intValue] : 
      _setPointSlider.minimumValue;
  }

  [formatter release];
  
  if ((changed & SERVICE_HVAC_OUTSIDE_TEMP_CHANGED) != 0)
    _outsideTemp.text = service.outsideTemperature;
  if ((changed & SERVICE_HVAC_OUTSIDE_HUMIDITY_CHANGED) != 0)
    _outsideHumidity.text = service.outsideHumidity;
  if ((changed & SERVICE_HVAC_ZONE_TEMP_CHANGED) != 0)
    _zoneTemp.text = service.zoneTemperature;
  if ((changed & SERVICE_HVAC_ZONE_HUMIDITY_CHANGED) != 0)
    _zoneHumidity.text = service.zoneHumidity;
  if ((changed & SERVICE_HVAC_CURRENT_SETPOINT_CHANGED) != 0)
    [self setPointChanged];
  if((changed & SERVICE_HVAC_HEAT_SETPOINT_CHANGED) != 0)
    [self warmSetPointChanged];
  if((changed & SERVICE_HVAC_COOL_SETPOINT_CHANGED) != 0)
    [self coolSetPointChanged];
  
  if ((changed & SERVICE_HVAC_TEMP_SCALE_CHANGED) != 0)
  {
    _zoneTempType.text = service.temperatureScale;
    _setPointTempType.text = service.temperatureScale;
    _outsideTempType.text = service.temperatureScale;
    _warmSetPointTempType.text = service.temperatureScale;
    _coolSetPointTempType.text = service.temperatureScale;
  }
  if ((changed & SERVICE_HVAC_STATE_HEADER_CHANGED) != 0)
    _modeTitle.text = service.currentStateHeader;
  if ((changed & SERVICE_HVAC_STATE_LINE1_CHANGED) != 0)
    _modeLine1.text = service.currentStateLine1;
  if ((changed & SERVICE_HVAC_STATE_LINE2_CHANGED) != 0)
    _modeLine2.text = service.currentStateLine2NoIcon;
  if ((changed & SERVICE_HVAC_STATE_LINE2I_CHANGED) != 0)
    _modeLine2WithIcon.text = service.currentStateLine2WithIcon;
  if ((changed & SERVICE_HVAC_SHOW_ICON_CHANGED) != 0)
  {
    BOOL show = service.showIcon;
    
    _modeLine2.hidden = show;
    _modeLine2WithIcon.hidden = !show;
    _modeIcon.hidden = !show;
  }	
}

- (IBAction) setPointChanged
{
  _setPointTemp.text = [NSString stringWithFormat: @"%0.1f", _setPointSlider.value];
}

- (IBAction) coolSetPointChanged
{
  _coolSetPointTemp.text = [NSString stringWithFormat: @"%0.1f", _coolSetPointSlider.value];
}

- (IBAction) warmSetPointChanged
{
  _warmSetPointTemp.text = [NSString stringWithFormat: @"%0.1f", _warmSetPointSlider.value];
}

- (IBAction) setPointUpdateService
{
  [_hvacService setHeatSetPoint: _setPointSlider.value];
}

- (IBAction) coolSetPointUpdateService
{
  [_hvacService setCoolSetPoint: _coolSetPointSlider.value];
}

- (IBAction) warmSetPointUpdateService
{
  [_hvacService setHeatSetPoint: _warmSetPointSlider.value];
}


@end
