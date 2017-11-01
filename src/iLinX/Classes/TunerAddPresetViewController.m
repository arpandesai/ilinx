
//  TunerAddPresetViewController.m
//  iLinX
//
//  Created by mcf on 23/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "TunerAddPresetViewController.h"
#import "NLBrowseList.h"
#import "NLSourceTuner.h"


@implementation TunerAddPresetViewController

- (id) initWithTuner: (NLSourceTuner *) tuner presetName: (NSString *) presetName
{
  if (self = [super initWithNibName: @"TunerAddPreset" bundle: nil])
  {
    self.title = NSLocalizedString( @"Add Preset", @"Title of the add preset modal dialog" );
    _presetName = [presetName retain];
    _presetList = [((id<NLBrowseListRoot>) (tuner.browseMenu)).presetsList retain];
    _tuner = [tuner retain];
  }
  
  return self;
}

- (void) viewDidLoad
{
  [super viewDidLoad];

  _presetTitle.text = _presetName;
  _presetTitle.clearButtonMode = UITextFieldViewModeWhileEditing;
  [_navBar pushNavigationItem: _navItem animated: NO];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  [_presetList addDelegate: self];
  [_presetChoice becomeFirstResponder];
}

- (IBAction) savePreset
{
  if ([_presetTitle.text length] > 0)
  {
    [_presetList removeDelegate: self];
    [_tuner savePreset: _savedPresetIndex withTitle: _presetTitle.text];
    [self dismissModalViewControllerAnimated: YES];
  }
  else
  {
    UIAlertView *alert = [[UIAlertView alloc] 
                          initWithTitle: NSLocalizedString( @"Preset Name", @"Title for the preset title warning dialog" )
                          message: NSLocalizedString( @"Please enter a name for the preset",
                                                     @"Message for preset title warning dialog" ) 
                          delegate: nil
                          cancelButtonTitle: NSLocalizedString( @"OK", @"Title of button dismissing the preset title warning dialog" )
                          otherButtonTitles: nil];

    [alert show];
    [alert release];
  }
}

- (IBAction) cancel
{
  [_presetList removeDelegate: self];
  [self dismissModalViewControllerAnimated: YES];

  
}

- (void) itemsChangedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [_presetChoice reloadAllComponents];
}

- (BOOL) textFieldShouldReturn: (UITextField *) textField
{
  [textField resignFirstResponder];
  return NO;
}

- (NSInteger) numberOfComponentsInPickerView: (UIPickerView *) pickerView
{
  return 1;
}

- (NSInteger) pickerView: (UIPickerView *) pickerView numberOfRowsInComponent: (NSInteger) component
{
  return [_presetList countOfList];
}

- (NSString *) pickerView: (UIPickerView *) pickerView titleForRow: (NSInteger) row forComponent: (NSInteger) component
{
  return [_presetList titleForItemAtIndex: row];
}

- (void) pickerView: (UIPickerView *) pickerView didSelectRow: (NSInteger) row inComponent: (NSInteger) component
{
  _savedPresetIndex = row;
}

- (void) dealloc
{
  [_presetTitle release];
  [_presetChoice release];
  [_navBar release];
  [_navItem release];
  [_tuner release];
  [_presetName release];
  [_presetList release];
  [super dealloc];
}

@end
