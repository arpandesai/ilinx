//
//  HVACSetPointViewController.m
//  iLinX
//
//  Created by mcf on 16/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "HVACSetPointViewController.h"


@interface HVACSetPointViewController ()

- (NSInteger) valueForRow: (NSInteger) row forComponent: (NSInteger) component;

@end

@implementation HVACSetPointViewController

- (id) initWithHvacService: (NLServiceHVAC *) hvacService
{
  if (self = [super initWithNibName: @"HVACSetPoint" bundle: nil])
    _hvacService = [hvacService retain];
  
  return self;
}

- (void) viewWillAppear: (BOOL) animated
{
  UIFont *font = [UIFont boldSystemFontOfSize: 20];

  [super viewWillAppear: animated];

  _coolLabel.hidden = ((_hvacService.capabilities & SERVICE_HVAC_HAS_COOLING) == 0);
  _coolScaleLabel.hidden = _coolLabel.hidden;
  [self numberOfComponentsInPickerView: _setPointChoice];
	_heatScaleLabel.font = font;
  _heatScaleLabel.text = _hvacService.temperatureScale;
	_coolScaleLabel.font = font;
  _coolScaleLabel.text = _hvacService.temperatureScale;
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];

  [self service: _hvacService changed: 0xFFFFFFFF];
  [_hvacService addDelegate: self];
  [_setPointChoice becomeFirstResponder];
}

- (IBAction) saveSetPoint
{
  [_hvacService removeDelegate: self];

  if ((_hvacService.capabilities & SERVICE_HVAC_HAS_COOLING) != 0)
    [_hvacService setCoolSetPoint: _coolSetPoint];
  [_hvacService setHeatSetPoint: _heatSetPoint];

  [self dismissModalViewControllerAnimated: YES];
}

- (IBAction) cancel
{
  [_hvacService removeDelegate: self];
  [self dismissModalViewControllerAnimated: YES];
}

- (void) service: (NLServiceHVAC *) service changed: (NSUInteger) changed
{
  NSInteger row;

  if ((changed & SERVICE_HVAC_HEAT_SETPOINT_CHANGED) != 0 && _heatRows > 0)
  {
    CGFloat minValue = [_hvacService heatSetPointMin];
    CGFloat maxValue = [_hvacService heatSetPointMax];
    BOOL reload = ((_heatRows == 1) ^ (minValue == maxValue));

    if (reload)
      [self numberOfComponentsInPickerView: _setPointChoice];

    _heatSetPoint = [_hvacService.heatSetPointTemperature floatValue];
    row = (NSInteger) ((_heatSetPoint - [_hvacService heatSetPointMin]) / [_hvacService heatSetPointStep]);
    if (row < 0)
      row = 0;
    else if (row >= _heatRows)
      row = _heatRows - 1;

    if (reload || _heatRows == 1)
      [_setPointChoice reloadComponent: 0];

    [_setPointChoice selectRow: row inComponent: 0 animated: YES];
    
  }
  
  if ((changed & SERVICE_HVAC_COOL_SETPOINT_CHANGED) != 0 && _coolRows > 0)
  {
    CGFloat minValue = [_hvacService coolSetPointMin];
    CGFloat maxValue = [_hvacService coolSetPointMax];
    BOOL reload = ((_coolRows == 1) ^ (minValue == maxValue));
    
    if (reload)
      [self numberOfComponentsInPickerView: _setPointChoice];
    
    _coolSetPoint = [_hvacService.coolSetPointTemperature floatValue];
    row = (NSInteger) ((_coolSetPoint - [_hvacService coolSetPointMin]) / [_hvacService coolSetPointStep]);
    if (row < 0)
      row = 0;
    else if (row >= _coolRows)
      row = _coolRows - 1;

    if (reload || _coolRows == 1)
      [_setPointChoice reloadComponent: 1];
    [_setPointChoice selectRow: row inComponent: 1 animated: YES];
  }
}

- (NSInteger) numberOfComponentsInPickerView: (UIPickerView *) pickerView
{
  NSInteger components;
  
  if ((_hvacService.capabilities & SERVICE_HVAC_HAS_COOLING) == 0)
  {
    components = 1;
    _coolRows = 0;
  }
  else
  {
    components = 2;
    _coolRows = (NSInteger) (([_hvacService coolSetPointMax] - [_hvacService coolSetPointMin]) / [_hvacService coolSetPointStep]) + 1;
  }

  _heatRows = (NSInteger) (([_hvacService heatSetPointMax] - [_hvacService heatSetPointMin]) / [_hvacService heatSetPointStep]) + 1;
  
  return components;
}

- (NSInteger) pickerView: (UIPickerView *) pickerView numberOfRowsInComponent: (NSInteger) component
{
  NSInteger count;

  if (component == 0)
    count = _heatRows;
  else
    count = _coolRows;
  
  return count;
}

- (NSString *) pickerView: (UIPickerView *) pickerView titleForRow: (NSInteger) row forComponent: (NSInteger) component
{
  return [NSString stringWithFormat: @"%d.0", [self valueForRow: row forComponent: component]];
}

- (void) pickerView: (UIPickerView *) pickerView didSelectRow: (NSInteger) row inComponent: (NSInteger) component
{
  NSInteger value = [self valueForRow: row forComponent: component];
  
  if (component == 0)
    _heatSetPoint = value;
  else
    _coolSetPoint = value;
}

- (NSInteger) valueForRow: (NSInteger) row forComponent: (NSInteger) component
{
  NSInteger value;
  
  if (component == 0)
  {
    if (row == _heatRows - 1)
      value = (NSInteger) [_hvacService heatSetPointMax];
    else
      value = (NSInteger) ((row * [_hvacService heatSetPointStep]) + [_hvacService heatSetPointMin]);
  }
  else
  {
    if (row == _coolRows - 1)
      value = (NSInteger) [_hvacService coolSetPointMax];
    else
      value = (NSInteger) ((row * [_hvacService coolSetPointStep]) + [_hvacService coolSetPointMin]);
  }

  return value;
}

- (void) dealloc
{
  [_hvacService release];
  [_coolLabel release];
  [_heatScaleLabel release];
  [_coolScaleLabel release];
  [_setPointChoice release];
  [super dealloc];
}


@end
