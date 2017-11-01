//
//  ServiceViewController.m
//  NetStreams
//
//  Created by mcf on 29/12/2008.
//  Copyright 2008 Micropraxis Ltd. All rights reserved.
//

#import "ServiceViewController.h"
#import "DetailViewController.h"

@implementation ServiceViewController

@synthesize serviceList;

- (void) viewWillAppear: (BOOL) animated
{
  // Update the view with current data before it is displayed
  [super viewWillAppear: animated];
  
  // Scroll the table view to the top before it appears
  [self.tableView reloadData];
  [self.tableView setContentOffset: CGPointZero animated: NO];
  
  if (serviceList != nil && [serviceList count] > 0)
  {
    NSString *title = [(NSDictionary *) [serviceList objectAtIndex: 0] valueForKey: @"room"];
    self.title = NSLocalizedString( title, @"Service view navigation title" );
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Table view methods

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
  return 1;
}


// Customize the number of rows in the table view.
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  if (serviceList == nil)
    return 0;
  else
    return [serviceList count];
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  NSDictionary *itemAtIndex = (NSDictionary *) [serviceList objectAtIndex: indexPath.row];
  NSString *title = [itemAtIndex valueForKey: @"name"];
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyIdentifier2"];
  
  if (cell == nil)
    cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"MyIdentifier2"] autorelease];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  
  // Get the object to display and set the value in the cell
  cell.text = title;
  return cell;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  NSDictionary *itemAtIndex = (NSDictionary *) [serviceList objectAtIndex: indexPath.row];
  
  /*
   Create the detail view controller and set its inspected item to the currently-selected item
   */
  DetailViewController *detailViewController = [[DetailViewController alloc] initWithStyle: UITableViewStyleGrouped];
  
  detailViewController.serviceItem = itemAtIndex;
  
  // Push the detail view controller
  [[self navigationController] pushViewController: detailViewController animated: YES];
  [detailViewController release];
}

- (void) dealloc
{
  [super dealloc];
}


@end

