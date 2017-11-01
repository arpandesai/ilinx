//
//  CameraControlsViewController.m
//  iLinX
//
//  Created by mcf on 30/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "CameraControlsViewController.h"
#import "DeprecationHelper.h"
#import "GreyRoundedRect.h"
#import "NLCamera.h"

@interface CameraControlsViewController ()

- (void) selectedPreset: (UIButton *) button;
- (void) setCapabilities;

@end

@implementation CameraControlsViewController

- (id) initWithCamera: (NLCamera *) camera
{
  if (self = [super initWithNibName: @"CameraControls" bundle: nil])
    _camera = camera;
  
  return self;
}

- (void) setCamera: (NLCamera *) camera
{
  _camera = camera;
  [self setCapabilities];
}

- (void) enableHideBackdrop: (BOOL) enable
{
  _hideBackdrop.hidden = !enable;
}

- (void) ensureArrowsCorrect
{
  CGRect backdropRect = _centreBackdrop.frame;
  CGRect centreRect = _panCentre.frame;
  
  _panUp.frame = CGRectMake( centreRect.origin.x, backdropRect.origin.y,
                            _panUp.frame.size.width, _panUp.frame.size.height );
  _panDown.frame = CGRectMake( centreRect.origin.x, 
                              backdropRect.origin.y + backdropRect.size.height - _panDown.frame.size.height,
                              _panUp.frame.size.width, _panUp.frame.size.height );
  _panLeft.frame = CGRectMake( backdropRect.origin.x, centreRect.origin.y,
                              _panLeft.frame.size.width, _panLeft.frame.size.height );
  _panRight.frame = CGRectMake( backdropRect.origin.x + backdropRect.size.width - _panRight.frame.size.width,
                               centreRect.origin.y, _panRight.frame.size.width, _panRight.frame.size.height );
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  
  [self setCapabilities];
  _presets.delegate = self;
  _presets.dataSource = self;
  _presets.separatorColor = [UIColor clearColor];
  _presets.alwaysBounceVertical = NO;
  self.view.alpha = 0.65;
}

- (IBAction) pressedPanUp: (id) sender
{
  [_camera panUp];
}

- (IBAction) pressedPanDown: (id) sender
{
  [_camera panDown];
}

- (IBAction) pressedPanLeft: (id) sender
{
  [_camera panLeft];
}

- (IBAction) pressedPanRight: (id) sender
{
  [_camera panRight];
}

- (IBAction) pressedPanCentre: (id) sender
{
  [_camera recentre];
}

- (IBAction) pressedZoomIn: (id) sender
{
  [_camera zoomIn];
}

- (IBAction) pressedZoomOut: (id) sender
{
  [_camera zoomOut];
}

- (IBAction) pressedHide: (id) sender
{
  [self.view removeFromSuperview];
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  return [_camera.presetNames count];
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"MyIdentifier"];
  UIButton *title = [UIButton buttonWithType: UIButtonTypeCustom];
  
  if (cell == nil)
    cell = [[[UITableViewCell alloc] initDefaultWithFrame: CGRectZero reuseIdentifier: @"MyIdentifier"] autorelease];
  else if ([cell.contentView.subviews count] > 0)
    [[cell.contentView.subviews objectAtIndex: 0] removeFromSuperview];

  title.frame = CGRectMake( 0, 0, tableView.frame.size.width, tableView.rowHeight - 1 );
  [title setTitle: [NSString stringWithFormat: @"  %@", [_camera.presetNames objectAtIndex: indexPath.row]]
                                     forState: UIControlStateNormal];
  [title addTarget: self action: @selector(selectedPreset:) forControlEvents: UIControlEventTouchDown];
  [title setTitleLabelFont: [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]]];
  title.backgroundColor = [UIColor colorWithWhite: 0.2 alpha: 0.8];
  [title setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
  [title setTitleShadowColor: [UIColor darkGrayColor] forState: UIControlStateNormal];
  title.showsTouchWhenHighlighted = YES;
  [cell.contentView addSubview: title];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
  return cell;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath: indexPath animated: NO];
}

- (void) selectedPreset: (UIButton *) button
{
  UIView *cell = [[button superview] superview];
  
  if (cell != nil && [cell isKindOfClass: [UITableViewCell class]])
  {
    NSIndexPath *indexPath = [_presets indexPathForCell: (UITableViewCell *) cell];
  
    if (indexPath != nil)
      [_camera selectPreset: indexPath.row];
  }
}

- (void) setCapabilities
{
  BOOL anythingEnabled = NO;
  BOOL directionsEnabled = NO;
  NSUInteger capabilities = _camera.capabilities;
  BOOL hide;

  hide = ((capabilities & NLCAMERA_CAPABILITY_UP_DOWN) == 0);
  _panUp.hidden = hide;
  _panDown.hidden = hide;
  anythingEnabled |= !hide;
  directionsEnabled |= !hide;
  
  hide = ((capabilities & NLCAMERA_CAPABILITY_LEFT_RIGHT) == 0);
  _panLeft.hidden = hide;
  _panRight.hidden = hide;
  anythingEnabled |= !hide;
  directionsEnabled |= !hide;
  
  hide = ((capabilities & NLCAMERA_CAPABILITY_CENTRE) == 0);
  _panCentre.hidden = hide;
  anythingEnabled |= !hide;
  directionsEnabled |= !hide;
  
  hide = ((capabilities & NLCAMERA_CAPABILITY_ZOOM) == 0);
  _zoomIn.hidden = hide;
  _zoomOut.hidden = hide;
  _zoomInBackdrop.hidden = hide;
  _zoomOutBackdrop.hidden = hide;
  anythingEnabled |= !hide;
  
  if ([_camera.presetNames count] == 0)
  {
    _presets.hidden = YES;
    _presetsTitle.hidden = YES;
  }
  else
  {
    _presets.hidden = NO;
    _presetsTitle.hidden = NO;
    anythingEnabled = YES;
  }
  
  _unavailable.hidden = anythingEnabled;
  _centreBackdrop.hidden = (!directionsEnabled && anythingEnabled);
  [_presets reloadData];
}

- (void) dealloc
{
  [_panUp release];
  [_panDown release];
  [_panLeft release];
  [_panRight release];
  [_panCentre release];
  [_zoomIn release];
  [_zoomOut release];
  [_zoomInBackdrop release];
  [_zoomOutBackdrop release];
  [_centreBackdrop release];
  [_hideBackdrop release];
  [_presetsTitle release];
  [_presets release];
  [_unavailable release];
  [super dealloc];
}

@end
