//
//  PresetViewController.m
//  iLinX
//
//  Created by Tony Short on 01/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "CameraPresetViewController.h"
#import "UncodableObjectArchiver.h"

@implementation CameraPresetViewController

@synthesize delegate = _delegate;

#pragma mark -
#pragma mark Initialization

- (void) setCamera: (NLCamera *) camera
{
  [_presetNames release];
  _presetNames = [camera.presetNames copy];
  
  self.contentSizeForViewInPopover = CGSizeMake( 320, 44 + ([_presetNames count] * 44 ));
  [_presetTableView reloadData];
}

- (void) dealloc 
{
  [_presetCellTemplatesView release];
  [_presetNames release];
  [_presetTableView release];
  [super dealloc];
}

#pragma mark -
#pragma mark View lifecycle

- (void) viewDidLoad 
{
  [super viewDidLoad];
  
  _templateID = 0;
  
  _presetCellTemplates = [[NSMutableArray alloc] init];
  for (UIView *view in _presetCellTemplatesView.subviews)
  {
    if(![view isKindOfClass: [UITableViewCell class]])
      continue;
    
    UITableViewCell *tableViewCell = (UITableViewCell *) view;

    PresetCellTemplate *template = [[PresetCellTemplate alloc] init];
    template.rowData = [UncodableObjectArchiver dictionaryEncodingWithRootObject: tableViewCell];
    template.cellHeight = tableViewCell.frame.size.height;
    
    [_presetCellTemplates addObject: template];
    [template release];
  }
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation 
{
  // Override to allow orientations other than the default portrait orientation.
  return YES;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section 
{
  // Return the number of sections.
  return [_presetNames count];
}

- (void) initialiseCellView: (UITableViewCell *) cell withPresetID: (NSInteger) presetID
{	
  cell.textLabel.text = [_presetNames objectAtIndex: presetID];
  cell.selectionStyle = UITableViewCellSelectionStyleBlue;
}

- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath
{
  return ((PresetCellTemplate *) [_presetCellTemplates objectAtIndex: _templateID]).cellHeight;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  NSString *reuseStr = [NSString stringWithFormat: @"Preset"];
  UITableViewCell *cell = (UITableViewCell *) [tableView dequeueReusableCellWithIdentifier: reuseStr];
  
  if (cell == nil)
    cell = [UncodableObjectUnarchiver unarchiveObjectWithDictionary: 
            ((PresetCellTemplate *) [_presetCellTemplates objectAtIndex: _templateID]).rowData];

  [self initialiseCellView:cell withPresetID: indexPath.row];

  return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath 
{
  [_delegate presetChosen: indexPath.row];
}

@end

@implementation PresetCellTemplate

@synthesize rowData = _rowData;
@synthesize cellHeight = _cellHeight;

- (void) dealloc
{
  [super dealloc];
  [_rowData release];
}

@end
