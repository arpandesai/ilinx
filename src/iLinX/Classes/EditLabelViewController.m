//
//  EditLabelViewController.m
//  iLinX
//
//  Created by mcf on 09/06/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "EditLabelViewController.h"
#import "BorderedTableViewCell.h"
#import "DeprecationHelper.h"
#import "NLTimer.h"
#import "StandardPalette.h"

@implementation EditLabelViewController

- (id) initWithTimer: (NLTimer *) timer
{
  if (self = [super initWithStyle: UITableViewStyleGrouped])
  {
    _timer = [timer retain];
    _labelText = [UITextField new];
    _labelText.textColor = [StandardPalette editableTextColour];
    _labelText.backgroundColor = [UIColor clearColor];
    _labelText.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.title = NSLocalizedString( @"Label", @"Title of the timer label editing view" );
  }
  
  return self;
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  _labelText.text = _timer.name;
  self.tableView.scrollEnabled = NO;
}

- (void) viewWillDisappear: (BOOL) animated
{
  _timer.name = _labelText.text;
  [super viewWillDisappear: animated];
}

#pragma mark Table view methods

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  return 1;
}

- (CGFloat) tableView: (UITableView *) tableView heightForHeaderInSection: (NSInteger) section
{
  return 72;
}

- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section
{
  return @" ";
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  static NSString *CellIdentifier = @"EditLabelCell";
  BorderedTableViewCell *cell = (BorderedTableViewCell *) [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  CGRect area = CGRectInset( [tableView rectForRowAtIndexPath: indexPath], 15, 0 );

  if (cell == nil)
    cell = [[[BorderedTableViewCell alloc] initDefaultWithFrame: CGRectZero reuseIdentifier: CellIdentifier
                                                          table: tableView] autorelease];
  else
  {
    for (UIView *subview in cell.contentView.subviews)
      [subview removeFromSuperview];
  }
  
  [_labelText sizeToFit];
  _labelText.frame = CGRectMake( 10, (int) ((area.size.height - _labelText.frame.size.height) / 2),
                                area.size.width, _labelText.frame.size.height );
  [cell.contentView addSubview: _labelText];
  [_labelText becomeFirstResponder];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  [cell setBorderTypeForIndex: 0 totalItems: 1];

  return cell;
}

- (NSIndexPath *) tableView: (UITableView *) tableView willSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  return nil;
}

- (void) dealloc
{
  [_timer release];
  [_labelText release];
  [super dealloc];
}


@end

