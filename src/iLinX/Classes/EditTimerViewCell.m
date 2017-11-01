//
//  EditTimerViewCell.m
//  iLinX
//
//  Created by mcf on 09/06/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "EditTimerViewCell.h"
#import "DeprecationHelper.h"
#import "StandardPalette.h"

@implementation EditTimerViewCell

- (id) initWithArea: (CGRect) area maxWidth: (CGFloat) maxWidth reuseIdentifier: (NSString *) reuseIdentifier
              table: (UITableView *) table
{
  if ((self = [super initDefaultWithFrame: CGRectZero reuseIdentifier: reuseIdentifier table: table]) != nil)
  {
    _title = [[UILabel alloc] initWithFrame: CGRectMake( 10, 0, maxWidth, area.size.height )];
    _title.font = [UIFont boldSystemFontOfSize: [UIFont buttonFontSize]];
    _title.textColor = [StandardPalette tableTextColour];
    _title.backgroundColor = [UIColor clearColor];
    
    _contentArea = CGRectMake( maxWidth + 10, 0, area.size.width - (maxWidth + 40), area.size.height );
    _content = [[UILabel alloc] initWithFrame: _contentArea];
    _content.font = [UIFont systemFontOfSize: [UIFont buttonFontSize]];
    _content.backgroundColor = [UIColor clearColor];
    _content.textColor = [StandardPalette editableTextColour];
    _content.textAlignment = UITextAlignmentRight;
    
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [self.contentView addSubview: _title];
    [self.contentView addSubview: _content];
  }
  
  return self;
}

- (NSString *) title
{
  return _title.text;
}

- (void) setTitle: (NSString *) title
{
  _title.text = title;
}

- (NSString *) content
{
  return _content.text;
}

- (void) setContent: (NSString *) content
{
  _content.text = content;
}

- (void) setAccessoryType: (UITableViewCellAccessoryType) accessoryType
{
  if (accessoryType == UITableViewCellAccessoryNone)
    _content.frame = CGRectMake( _contentArea.origin.x, _contentArea.origin.y, 
                                _contentArea.size.width + 20, _contentArea.size.height );
  else
    _content.frame = _contentArea;
  
  super.accessoryType = accessoryType;
}

- (void) setSelected: (BOOL) selected animated: (BOOL) animated
{
  [super setSelected: selected animated: animated];

  // Configure the view for the selected state
  if (selected)
  {
    _title.textColor = [StandardPalette selectedTableTextColour];
    _content.textColor = [StandardPalette selectedTableTextColour];
  }
  else
  {
    _title.textColor = [StandardPalette tableTextColour];
    _content.textColor = [StandardPalette editableTextColour];
  }
}

- (void) dealloc 
{
  [_title release];
  [_content release];
  [super dealloc];
}

@end
