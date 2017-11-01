//
//  PlaceholderViewControllerIPad.m
//  iLinX
//
//  Created by mcf on 07/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <QuartzCore/CALayer.h>
#import "CameraViewControllerIPad.h"
#import "NLService.h"
#import "MainNavigationController.h"
#import "NLServiceCameras.h"
#import "UncodableObjectArchiver.h"

@implementation CameraViewControllerIPad

- (void) dealloc
{
  [_cameraListTableView release];
  [_currentCameraImageView release];
  [_cameraLabel release];
  [_panUp release];
  [_panDown release];
  [_panLeft release];
  [_panRight release];
  [_panCentre release];
  [_zoomIn release];
  [_zoomOut release];
  [_playButton release];
  [_pauseButton release];
  [_presetButton release];
  [_cameraControlsBackImage release];
  [_cameras release];
  [_visibleCells release];
  [_presetViewController release];
  [_presetPopover release];
  [_thumbnailCellTemplatesView release];
  [_thumbnailCellTemplates release];
  [super dealloc];
}

-(NLCamera*)currentCamera
{
  return [_cameras cameraAtIndex:_currentCameraID];
}

- (id) initWithOwner: (RootViewControllerIPad *) owner service: (NLService *) service
{
  if(self = [super initWithOwner: owner service: service
			 nibName: @"CameraViewIPad" bundle: nil])
    _cameras = [(NLServiceCameras *)service retain];
  
  return self;
}

-(void) setCapabilities: (NLCamera *) camera
{
  NSUInteger capabilities = (camera != nil) ? camera.capabilities : 0;
  BOOL enabled = ((capabilities & NLCAMERA_CAPABILITY_LEFT_RIGHT) != 0);

  _panLeft.enabled = enabled;
  _panRight.enabled = enabled;
  
  if (enabled)
    [_cameraControlsBackImage setImage: [UIImage imageNamed: @"cameraSelectBG.png"]];
  else
    [_cameraControlsBackImage setImage: [UIImage imageNamed: @"cameraSelectBG-2.png"]];
  
  enabled = ((capabilities & NLCAMERA_CAPABILITY_UP_DOWN) != 0);
  _panUp.enabled = enabled;
  _panDown.enabled = enabled;
  _panCentre.enabled = ((capabilities & NLCAMERA_CAPABILITY_CENTRE) != 0);
  
  enabled = ((capabilities & NLCAMERA_CAPABILITY_ZOOM) != 0);
  _zoomIn.enabled = enabled;
  _zoomOut.enabled = enabled;
  _presetButton.enabled = ((camera != nil) && [camera.presetNames count] > 0);
  _playButton.enabled = (camera != nil);
}

// Can disable all controls if playing through cameras
- (void) movementControlsEnabled: (BOOL) enabled
{
  if (enabled)
    [self setCapabilities: self.currentCamera];
  else
  {
    _panLeft.enabled = NO;
    _panRight.enabled = NO;
    _panUp.enabled = NO;
    _panDown.enabled = NO;
    _panCentre.enabled = NO;
    _zoomIn.enabled = NO;
    _zoomOut.enabled = NO;
    _presetButton.enabled = NO;
    [_cameraControlsBackImage setImage: [UIImage imageNamed: @"cameraSelectBG-2.png"]];
  }
}

- (void) setCurrentCamera: (NSInteger) cameraID
{
  if ((_currentCameraID == 0) || (_currentCameraID != cameraID))
  {
    if (_cameras.cameraCount == 0)
    {
      [self setCapabilities: nil];
      return;
    }

    // Remove delegate from previous camera
    [self.currentCamera removeDelegate: self];
    
    // Set current camera to new ID
    _currentCameraID = cameraID;
    _cameraLabel.text = self.currentCamera.displayName;
    [self.currentCamera addDelegate: self];
    
    // Move current camera to centre of table view display
    NSIndexPath *currIndexPath = [NSIndexPath indexPathForRow: _currentCameraID inSection: 0];

    [_cameraListTableView selectRowAtIndexPath: currIndexPath animated: YES 
                                scrollPosition: UITableViewScrollPositionMiddle];
    
    _currentCameraImageView.image = self.currentCamera.image;
    
    if (!_playButton.selected)
      [self setCapabilities: self.currentCamera];
  }
}

- (void) refreshCellDelegates
{
  // Remove delegates from all previous cells
  if (_visibleCells != nil)
  {
    for (CameraThumbnailTableViewCell *cell in _visibleCells)
      [cell.camera removeDelegate: cell];
    [_visibleCells release];
  }
  
  // Add new visible cells
  _visibleCells = [[NSMutableArray alloc] initWithArray: _cameraListTableView.visibleCells];
  for(CameraThumbnailTableViewCell *cell in _visibleCells)
    [cell.camera addDelegate: cell];
}

- (void) advanceCamera
{
  NSInteger nextCameraID = _currentCameraID + 1;

  if (nextCameraID == _cameras.cameraCount)
    nextCameraID = 0;
  
  [self setCurrentCamera: nextCameraID];

  // Delay to be after scrolling of selected cell has finished
  [self performSelector: @selector(refreshCellDelegates) withObject: nil afterDelay: 0.3];
  [self performSelector: @selector(advanceCamera) withObject: nil afterDelay: PlayInterval];
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  
  _templateID = 0;
  
  _thumbnailCellTemplates = [[NSMutableArray alloc] init];
  
  for (UIView *view in _thumbnailCellTemplatesView.subviews)
  {
    if (![view isKindOfClass: [UITableViewCell class]])
      continue;
    
    UITableViewCell *tableViewCell = (UITableViewCell *) view;
    ThumbnailCellTemplate *template = [[ThumbnailCellTemplate alloc] init];

    template.rowData = [UncodableObjectArchiver dictionaryEncodingWithRootObject: tableViewCell];
    template.cellHeight = tableViewCell.frame.size.height;
    
    NSArray *cellSubViews = [tableViewCell.contentView subviews];
    NSInteger count = [cellSubViews count];
    NSInteger i;
    
    for (i = 0; i < count; ++i)
    {
      UIView *cellSubView = [cellSubViews objectAtIndex: i];
      
      switch (cellSubView.tag)
      {
	case 1:
	  if ([cellSubView isKindOfClass: [UIImageView class]])
	    template.thumbnailImageViewOffset = cellSubView.tag;
	  break;
	case 2:
	  if ([cellSubView isKindOfClass: [UILabel class]])
	    template.thumbnailLabelOffset = cellSubView.tag;
	  break;
	case 3:
	  if ([cellSubView isKindOfClass: [UIActivityIndicatorView class]])
	    template.activityViewOffset = cellSubView.tag;
	  break;
	case 4:
	  if ([cellSubView isKindOfClass: [UILabel class]])
	    template.cameraImageUnavailableLabelOffset = cellSubView.tag;
	  break;
	default:
	  break;
      }
    }
    [_thumbnailCellTemplates addObject: template];
    [template release];
  }
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  
  [_cameraListTableView reloadData];
  
  [self setCurrentCamera: 0];
  
  [self refreshCellDelegates];
}

- (void) scrollViewDidEndDragging: (UIScrollView *) scrollView willDecelerate: (BOOL) decelerate
{
  [self refreshCellDelegates];
}

- (void) scrollViewDidEndDecelerating: (UIScrollView *) scrollView
{
  [self refreshCellDelegates];
}

// NLCameraDelegate methods
- (void) camera: (NLCamera *) camera hasNewImage: (UIImage *) image
{
  NSInteger cameraID = [_cameras.cameras indexOfObject: camera];

  if (cameraID == NSNotFound)
    return;
  
  if (_currentCameraID == cameraID)
    _currentCameraImageView.image = image;
}

- (void) panUp: (id) sender
{
  [self.currentCamera panUp];
}

- (void) panDown: (id) sender
{
  [self.currentCamera panDown];
}

- (void) panLeft: (id) sender
{
  [self.currentCamera panLeft];
}

- (void) panRight: (id) sender
{
  [self.currentCamera panRight];
}

- (void) panCentre: (id) sender
{
  [self.currentCamera recentre];
}

- (void) zoomIn: (id) sender
{
  [self.currentCamera zoomIn];
}

- (void) zoomOut: (id) sender
{
  [self.currentCamera zoomOut];
}

- (void) playPressed: (id) sender
{
  _pauseButton.hidden = NO;
  _playButton.hidden = YES;
  [self performSelector: @selector(advanceCamera) withObject: nil afterDelay: PlayInterval];
}

- (void) pausePressed: (id) sender
{
  _pauseButton.hidden = YES;
  _playButton.hidden = NO;
  [NSRunLoop cancelPreviousPerformRequestsWithTarget: self];
}

- (void) presetPressed: (id) sender
{
  if (_presetViewController == nil)
  {
    _presetViewController = [[CameraPresetViewController alloc] initWithNibName: @"CameraPresetViewIPad" bundle: nil];
    _presetViewController.delegate = self;
    _presetPopover = [[UIPopoverController alloc] initWithContentViewController: _presetViewController];
  }
  
  if (_presetPopover.popoverVisible)
    [_presetPopover dismissPopoverAnimated: YES];
  else
  {
    [_presetViewController setCamera: self.currentCamera];
    [_presetPopover setPopoverContentSize: _presetViewController.contentSizeForViewInPopover];
    [_presetPopover presentPopoverFromRect: _presetButton.frame inView: _presetButton.superview
                  permittedArrowDirections: UIPopoverArrowDirectionAny animated: YES];	
  }
}

- (void) presetChosen: (NSInteger) preset
{
  [self.currentCamera selectPreset: preset];
  [_presetPopover dismissPopoverAnimated: YES];
}

// UITableViewDelegate / Data Source methods

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  return _cameras.cameraCount;
}

- (void) initialiseCellView: (CameraThumbnailTableViewCell *) cell withTemplateID: (NSInteger) templateID andCameraID: (NSInteger) cameraID
{
  ThumbnailCellTemplate *template = [_thumbnailCellTemplates objectAtIndex: templateID];
  
  cell.camera = [_cameras cameraAtIndex:cameraID];	
  cell.thumbnailImageView.image = cell.camera.image;
  
  UIView *bView = [[UIView alloc] initWithFrame: cell.frame];

  cell.selectedBackgroundView = bView;
  [bView release];
  cell.selectedBackgroundView.backgroundColor = [UIColor darkGrayColor];
  cell.selectedBackgroundView.layer.cornerRadius = 5.0;
  
  for (UIView *view in cell.contentView.subviews)
  {
    if (view.tag == template.thumbnailImageViewOffset)
    {
      UIImageView *thumbnailImageView = (UIImageView *) [cell viewWithTag: template.thumbnailImageViewOffset];

      cell.thumbnailImageView = thumbnailImageView;
    }
    else if (view.tag == template.thumbnailLabelOffset)
    {
      UILabel *thumbnailLabelView = (UILabel *) view;

      if (thumbnailLabelView != nil)
	thumbnailLabelView.text = cell.camera.displayName;
    }
    else if (view.tag == template.activityViewOffset)
    {
      UIActivityIndicatorView *activityView = (UIActivityIndicatorView *) view;

      if (activityView != nil)
	cell.activityView = activityView;
    }
    else if (view.tag == template.cameraImageUnavailableLabelOffset)
    {
      cell.cameraImageUnavailableLabel = (UILabel *) view;
      [cell performSelector: @selector(imageLoadTimeout) withObject: nil afterDelay: 3];
    }
  }
}

- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath
{
  return ((ThumbnailCellTemplate *) [_thumbnailCellTemplates objectAtIndex: _templateID]).cellHeight;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  CameraThumbnailTableViewCell *cell = [UncodableObjectUnarchiver unarchiveObjectWithDictionary:
                                        ((ThumbnailCellTemplate *) [_thumbnailCellTemplates objectAtIndex: _templateID]).rowData];
  
  [self initialiseCellView: cell withTemplateID: _templateID andCameraID: indexPath.row];
  
  return cell;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  // Stop playback
  if (_playButton.selected)
    [self playPressed: nil];
  
  [self setCurrentCamera: indexPath.row];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [super viewWillDisappear: animated];
  
  // Removes camera advancement calls
  [NSRunLoop cancelPreviousPerformRequestsWithTarget: self];
  
  if (_visibleCells != nil)
  {
    for (CameraThumbnailTableViewCell *cell in _visibleCells)
      [cell.camera removeDelegate: cell];
    [_visibleCells release];
    _visibleCells = nil;
  }
  
  [self.currentCamera removeDelegate: self];
}

- (void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation) fromInterfaceOrientation
{
  if (_presetPopover.popoverVisible)
    [_presetPopover presentPopoverFromRect: _presetButton.frame inView: _presetButton.superview 
                  permittedArrowDirections: UIPopoverArrowDirectionAny animated: YES];
  
  // Rotation can cause more/fewer cameras to be on display, so adapt to this
  [self performSelector: @selector(refreshCellDelegates) withObject: nil afterDelay: 1];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
  // Overriden to allow any orientation.
  return YES;
}

@end

@implementation CameraThumbnailTableViewCell

@synthesize camera = _camera;
@synthesize thumbnailImageView = _thumbnailImageView;
@synthesize activityView = _activityView;
@synthesize cameraImageUnavailableLabel = _cameraImageUnavailableLabel;

- (void) dealloc
{
  [super dealloc];
  [_thumbnailImageView release];
  [_camera release];
  [_activityView release];
  [_cameraImageUnavailableLabel release];
}

- (void) imageLoadTimeout
{
  _cameraImageUnavailableLabel.hidden = (_thumbnailImageView.image != nil);
  [_activityView stopAnimating];
}

// NLCameraDelegate methods
- (void) camera: (NLCamera *) camera hasNewImage: (UIImage *) image
{
  _cameraImageUnavailableLabel.hidden = (image != nil);
  [_thumbnailImageView setImage: image];
  [_activityView stopAnimating];
  //	NSLog( @"Received thumbnail image update: %@", camera.displayName );
}

@end

@implementation ThumbnailCellTemplate

@synthesize thumbnailImageViewOffset = _thumbnailImageViewOffset;
@synthesize thumbnailLabelOffset = _thumbnailLabelOffset;
@synthesize activityViewOffset = _activityViewOffset;
@synthesize cameraImageUnavailableLabelOffset = _cameraImageUnavailableLabelOffset;
@synthesize rowData = _rowData;
@synthesize cellHeight = _cellHeight;

- (void) dealloc
{
  [super dealloc];
  [_rowData release];
}

@end
