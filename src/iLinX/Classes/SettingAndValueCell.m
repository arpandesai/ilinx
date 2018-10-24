//
//  SettingAndValueCell.m
//  iLinX
//
//  Created by mcf on 27/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "SettingAndValueCell.h"
#import "BorderedCellBackgroundView.h"
#import "DeprecationHelper.h"
#import "StandardPalette.h"

#define NAME_WIDTH                125
#define VALUE_MINIMUM_WIDTH_PC     0.25  
#define MARGIN                     10

@interface SettingAndValueCell ()

- (void) checkPlaceholder;
- (void) setLabelColours;

@end

@implementation SettingAndValueCell

@synthesize
editableDetailField = _valueEdit;

- (id) initDefaultWithFrame: (CGRect) frame reuseIdentifier: (NSString *) reuseIdentifier
                      table: (UITableView *) table
{
  if (self = [super initDefaultWithFrame: frame reuseIdentifier: reuseIdentifier table: table])
  {
    CGRect tableSize = table.frame;
    CGFloat dataWidth = tableSize.size.width - NAME_WIDTH - (MARGIN * 3);

    self.frame = CGRectMake( 0, 0, tableSize.size.width, table.rowHeight );
    self.selectionStyle = UITableViewCellSelectionStyleBlue;
    self.accessoryType = UITableViewCellAccessoryNone;

    _nameLabel = [[UILabel alloc] initWithFrame: CGRectMake( MARGIN, 0, NAME_WIDTH, 50 )];
    _nameLabel.font = [UIFont boldSystemFontOfSize: [UIFont labelFontSize]];
    _nameLabel.backgroundColor = [UIColor clearColor];
    _nameLabel.lineBreakMode = UILineBreakModeTailTruncation;
    _nameLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.contentView addSubview: _nameLabel];
    
    _valueLabel = [[UILabel alloc] initWithFrame: CGRectMake( NAME_WIDTH + (MARGIN * 2), 0, dataWidth, 50 )];
    _valueLabel.font = [UIFont systemFontOfSize: [UIFont labelFontSize]];
    _valueLabel.backgroundColor = [UIColor clearColor];
    _valueLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
    _valueLabel.textAlignment = UITextAlignmentRight;
    _valueLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.contentView addSubview: _valueLabel];
    
    _valueEdit = [[UITextField alloc] initWithFrame: CGRectMake( NAME_WIDTH + (MARGIN * 2), 0, dataWidth, 50 )];
    _valueEdit.font = [UIFont systemFontOfSize: [UIFont labelFontSize]];
    _valueEdit.text = @"Temp writing";
    [_valueEdit sizeToFit];
    _valueEdit.text = @"";
    if (_valueEdit.frame.size.height < table.rowHeight)
      _valueEdit.frame = CGRectMake( NAME_WIDTH + (MARGIN * 2), (NSUInteger) ((table.rowHeight - _valueEdit.frame.size.height) / 2) + 1, 
                                    dataWidth, _valueEdit.frame.size.height );
    else
      _valueEdit.frame = CGRectMake( NAME_WIDTH + (MARGIN * 2), 0, dataWidth, _valueEdit.frame.size.height );
    _valueEdit.backgroundColor = [UIColor clearColor];
    _valueEdit.textAlignment = UITextAlignmentRight;
    _valueEdit.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    _valueEdit.borderStyle = UITextBorderStyleNone;
    [self.contentView addSubview: _valueEdit];
    _valueEdit.hidden = YES;
    
    [self setLabelColours];
    _showPlaceholder = YES;
  }
  
  return self;
}

- (void) refreshPaletteToVersion: (NSUInteger) version
{
  if (version != _paletteVersion)
  {
    [super refreshPaletteToVersion: version];
    [self setLabelColours];
  }
}

- (NSString *) nameText
{
  return _nameLabel.text;
}

- (void) setNameText: (NSString *) nameText
{
  _nameLabel.text = nameText;
}

- (UIColor *) nameTextColor
{
  return _nameColor;
}

- (void) setNameTextColor: (UIColor *) color
{
  [_nameColor release];
  _nameColor = [color retain];
  _nameLabel.textColor = color;
}

- (NSString *) detailText
{
  return _valueEdit.text;
}

- (void) setDetailText: (NSString *) detailText
{
  CGFloat textWidth = [detailText sizeWithFont: _valueLabel.font].width;
  CGFloat cellWidth = CGRectGetMaxX( _valueLabel.frame ) - _nameLabel.frame.origin.x;
  
  if (textWidth < (cellWidth * VALUE_MINIMUM_WIDTH_PC))
    textWidth = (NSInteger) (cellWidth * VALUE_MINIMUM_WIDTH_PC);

  CGFloat beginX = CGRectGetMaxX( _valueLabel.frame ) - textWidth;

  if (beginX < NAME_WIDTH + (2 * MARGIN))
  {
    beginX = NAME_WIDTH + (2 * MARGIN);
    textWidth = CGRectGetMaxX( _valueLabel.frame ) - beginX;
  }
  _valueEdit.text = detailText;
  _valueEdit.frame = CGRectMake( beginX, _valueEdit.frame.origin.y, textWidth, _valueEdit.frame.size.height );
  _valueLabel.frame = CGRectMake( beginX, _valueLabel.frame.origin.y, textWidth, _valueLabel.frame.size.height );
  _nameLabel.frame = CGRectMake( _nameLabel.frame.origin.x, _nameLabel.frame.origin.y,
                                beginX - MARGIN - _nameLabel.frame.origin.x, _nameLabel.frame.size.height );
  [self checkPlaceholder];
}

- (UIColor *) detailTextColor
{
  return _valueColor;
}

- (void) setDetailTextColor: (UIColor *) color
{
  [_valueColor release];
  _valueColor = [color retain];
  _valueEdit.textColor = color;
  _valueLabel.textColor = color;
}

- (CGFloat) detailMinimumFontSize
{
  return _valueEdit.minimumFontSize;
}

- (void) setDetailMinimumFontSize: (CGFloat) minimumFontSize
{
  _valueEdit.minimumFontSize = minimumFontSize;
  _valueLabel.minimumFontSize = minimumFontSize;
}

- (BOOL) detailAdjustsFontSizeToFitWidth
{
  return _valueEdit.adjustsFontSizeToFitWidth;
}

- (void) setDetailAdjustsFontSizeToFitWidth: (BOOL) adjustsFontSizeToFitWidth
{
  _valueEdit.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth;
  _valueLabel.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth;
}

- (NSString *) detailPlaceholder
{
  return _valueEdit.placeholder;
}

- (void) setDetailPlaceholder: (NSString *) placeholder
{
  _valueEdit.placeholder = placeholder;
  [self checkPlaceholder];
}

- (BOOL) becomeFirstResponder
{
  _valueLabel.hidden = YES;
  _valueEdit.hidden = NO;
  return [_valueEdit becomeFirstResponder];
}

- (BOOL) resignFirstResponder
{
  BOOL retValue = [_valueEdit resignFirstResponder];
  [self checkPlaceholder];
  _valueEdit.hidden = YES;
  _valueLabel.hidden = NO;
  
  return retValue;
}

- (void) adjustCellForSelected: (BOOL) selected
{
  if (selected)
  {
    _nameLabel.textColor = [StandardPalette selectedTableTextColour];
    _valueEdit.textColor = [StandardPalette selectedTableTextColour];
    _valueLabel.textColor = [StandardPalette selectedTableTextColour];
  }
  else 
  {
    _nameLabel.textColor = _nameColor;
    _valueEdit.textColor = _valueColor;
    if (_showPlaceholder)
      _valueLabel.textColor = [StandardPalette placeholderTextColour];
    else
      _valueLabel.textColor = _valueEdit.textColor;
  }
}

- (void) checkPlaceholder
{
  _showPlaceholder = ([_valueEdit.placeholder length] > 0 && [_valueEdit.text length] == 0);
  if (_showPlaceholder)
  {
    _valueLabel.textColor = [UIColor colorWithWhite: 0.7 alpha: 1.0];
    _valueLabel.text = _valueEdit.placeholder;
  }
  else if (_valueEdit.secureTextEntry)
  {
    NSUInteger len = [_valueEdit.text length];
    NSString *coverUp = @"";
    
    for (NSUInteger i = 0; i < len; ++i)
      coverUp = [coverUp stringByAppendingString: @"\u25cf"];
    _valueLabel.textColor = _valueEdit.textColor;
    _valueLabel.text = coverUp;
  }
  else
  {
    _valueLabel.textColor = _valueEdit.textColor;
    _valueLabel.text = _valueEdit.text;
  }
}

- (void) setLabelColours
{
  _nameColor = [[StandardPalette tableTextColour] retain];
  _nameLabel.textColor = _nameColor;
  _valueColor = [[StandardPalette editableTextColour] retain];
  _valueLabel.textColor = _valueColor;
  _valueEdit.textColor = _valueColor;
}

- (void) dealloc 
{
  [_nameLabel release];
  [_valueLabel release];
  [_valueEdit release];
  [_nameColor release];
  [_valueColor release];
  [super dealloc];
}

@end
