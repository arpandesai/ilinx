//
//  SelectableListViewCell.m
//  iLinX
//
//  Created by mcf on 09/06/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "SelectableListViewCell.h"
#import "DeprecationHelper.h"
#import "StandardPalette.h"

@implementation SelectableListViewCell

- (id) initDefaultWithFrame: (CGRect) frame reuseIdentifier: (NSString *) reuseIdentifier
                      table: (UITableView *) table
{
  if (self = [super initDefaultWithFrame: frame reuseIdentifier: reuseIdentifier table: table]) 
  {
    _title = [UILabel new];
    _title.text = @"1";
    _title.font = [UIFont boldSystemFontOfSize: [UIFont labelFontSize]];
    [_title sizeToFit];
    _title.frame = CGRectMake( self.contentView.bounds.origin.x + 10,
                              self.contentView.bounds.origin.y + (int) ((self.contentView.bounds.size.height - _title.frame.size.height) / 2),
                              _title.frame.size.width, _title.frame.size.height );
    _title.text = @"";
    _title.backgroundColor = [UIColor clearColor];
    _title.textColor = [StandardPalette tableTextColour];
    [self.contentView addSubview: _title];
  }

  return self;
}

- (void) adjustCellForSelected: (BOOL) selected
{
  if (selected)
    _title.textColor = [StandardPalette selectedTableTextColour];
  else if (self.accessoryType == UITableViewCellAccessoryNone)
    _title.textColor = [StandardPalette tableTextColour];
  else
    _title.textColor = [StandardPalette highlightedTableTextColour];
}

- (NSString *) title
{
  return _title.text;
}

- (void) setTitle: (NSString *) title
{
  _title.text = title;
  [_title sizeToFit];
}

- (void) setAccessoryType: (UITableViewCellAccessoryType) accessoryType
{
  super.accessoryType = accessoryType;
  [self adjustCellForSelected: self.selected];
}

- (void) dealloc
{
  [_title release];
  [super dealloc];
}

@end
