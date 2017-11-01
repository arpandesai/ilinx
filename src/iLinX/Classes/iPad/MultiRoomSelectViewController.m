//
//  MultiRoomSelectViewController.m
//  iLinX
//
//  Created by Tony Short on 01/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "MultiRoomSelectViewController.h"
#import "UncodableObjectArchiver.h"
#import "NLZone.h"

@implementation MultiRoomSelectViewController

@synthesize delegate = _delegate;

#pragma mark -
#pragma mark Initialization

-(void)setZones:(NSArray*)zones
{
  if(_multiRoomSelectNames != nil)
    [_multiRoomSelectNames release];
  
  _multiRoomSelectNames = [zones copy];
  
  self.contentSizeForViewInPopover = CGSizeMake(320, 44 + ([_multiRoomSelectNames count] * 44));
}

- (void)dealloc 
{
  [_multiRoomSelectTableView release];
  [_multiRoomSelectCellTemplatesView release];
  [_multiRoomSelectNames release];
  [_multiRoomSelectTableView release];
  [super dealloc];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad 
{
  [super viewDidLoad];
  
  _templateID = 0;
  
  _multiRoomSelectCellTemplates = [[NSMutableArray alloc] init];
  for(UIView *view in _multiRoomSelectCellTemplatesView.subviews)
  {
    if(![view isKindOfClass:[UITableViewCell class]])
      continue;
    
    UITableViewCell *tableViewCell = (UITableViewCell *)view;
    MultiRoomSelectCellTemplate *template = [[MultiRoomSelectCellTemplate alloc] init];
    template.rowData = [UncodableObjectArchiver dictionaryEncodingWithRootObject: tableViewCell];
    template.cellHeight = tableViewCell.frame.size.height;
    
    [_multiRoomSelectCellTemplates addObject:template];
    [template release];
  }
}

- (void)viewWillAppear:(BOOL)animated 
{
  [super viewWillAppear:animated];
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
  // Override to allow orientations other than the default portrait orientation.
  return YES;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section 
{
  // Return the number of sections.
  return [_multiRoomSelectNames count];
}

-(void)initialiseCellView:(UITableViewCell *)cell withMultiRoomID:(NSInteger)multiRoomSelectID
{	
  cell.textLabel.text = ((NLZone*)[_multiRoomSelectNames objectAtIndex:multiRoomSelectID]).displayName;
  cell.selectionStyle = UITableViewCellSelectionStyleBlue;
}

- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath
{
  return ((MultiRoomSelectCellTemplate*)[_multiRoomSelectCellTemplates objectAtIndex:_templateID]).cellHeight;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  NSString *reuseStr = [NSString stringWithFormat:@"MultiRoomSelect"];
  UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:reuseStr];
  
  if(cell == nil)
  {
    cell = [UncodableObjectUnarchiver unarchiveObjectWithDictionary:((MultiRoomSelectCellTemplate*)[_multiRoomSelectCellTemplates objectAtIndex:_templateID]).rowData];
  }
  [self initialiseCellView:cell withMultiRoomID:indexPath.row];
  return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
  [_delegate multiRoomChosen:indexPath.row];
  [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning 
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
  // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
  // For example: self.myOutlet = nil;
}

@end

@implementation MultiRoomSelectCellTemplate

@synthesize rowData = _rowData;
@synthesize cellHeight = _cellHeight;

-(void)dealloc
{
  [super dealloc];
  [_rowData release];
}

@end
