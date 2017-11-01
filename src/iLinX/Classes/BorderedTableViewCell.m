//
//  BorderedTableViewCell.m
//  iLinX
//
//  Created by mcf on 05/05/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "BorderedTableViewCell.h"
#import "BorderedCellBackgroundView.h"
#import "DeprecationHelper.h"
#import "StandardPalette.h"

@interface BorderedTableViewCell ()

- (UIView *) backgroundViewWithFillColour: (UIColor *) fillColour borderColour: (UIColor *) borderColour;

@end

@implementation BorderedTableViewCell

- (UIColor *) fillColour
{
  if ([self.backgroundView isKindOfClass: [BorderedCellBackgroundView class]])
    return ((BorderedCellBackgroundView *) self.backgroundView).fillColour;
  else
    return nil;
}

- (void) setFillColour: (UIColor *) fillColour
{
  if ([self.backgroundView isKindOfClass: [BorderedCellBackgroundView class]])
    ((BorderedCellBackgroundView *) self.backgroundView).fillColour = fillColour;
  else 
    self.backgroundView = [self backgroundViewWithFillColour: fillColour
                                                borderColour: [StandardPalette tableSeparatorColour]];
}

- (UIColor *) selectedFillColour
{
  if ([self.selectedBackgroundView isKindOfClass: [BorderedCellBackgroundView class]])
    return ((BorderedCellBackgroundView *) self.selectedBackgroundView).fillColour;
  else
    return nil;
}

- (void) setSelectedFillColour: (UIColor *) fillColour
{
  if ([self.selectedBackgroundView isKindOfClass: [BorderedCellBackgroundView class]])
    ((BorderedCellBackgroundView *) self.selectedBackgroundView).fillColour = fillColour;
  else
    self.selectedBackgroundView = [self backgroundViewWithFillColour: fillColour
                                                        borderColour: [StandardPalette tableSeparatorColour]];
}

- (UIColor *) borderColour
{
  if ([self.backgroundView isKindOfClass: [BorderedCellBackgroundView class]])
    return ((BorderedCellBackgroundView *) self.backgroundView).borderColour;
  else if ([self.selectedBackgroundView isKindOfClass: [BorderedCellBackgroundView class]])
    return ((BorderedCellBackgroundView *) self.selectedBackgroundView).borderColour;
  else
    return nil;
}

- (void) setBorderColour: (UIColor *) borderColour
{
  if ([self.backgroundView isKindOfClass: [BorderedCellBackgroundView class]])
    ((BorderedCellBackgroundView *) self.backgroundView).borderColour = borderColour;
  else 
    self.backgroundView = [self backgroundViewWithFillColour: [StandardPalette tableCellColour]
                                                borderColour: borderColour];

  if ([self.selectedBackgroundView isKindOfClass: [BorderedCellBackgroundView class]])
    ((BorderedTableViewCell *) self.selectedBackgroundView).borderColour = borderColour;
  else
    self.selectedBackgroundView = [self backgroundViewWithFillColour: [StandardPalette selectedTableCellColour]
                                                borderColour: borderColour];
}

- (id) initDefaultWithFrame: (CGRect) frame reuseIdentifier: (NSString *) reuseIdentifier
                      table: (UITableView *) table
{
  if (self = [super initDefaultWithFrame: frame reuseIdentifier: reuseIdentifier]) 
  {
    _tableStyle = table.style;
    _separatorStyle = table.separatorStyle;
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    _paletteVersion = 1;
    [self refreshPaletteToVersion: 0];
    _usable = YES;
  }

  return self;
}

- (void) setBorderTypeForIndex: (NSInteger) index totalItems: (NSInteger) totalItems
{
  if (_tableStyle == UITableViewStyleGrouped)
  {
    NSInteger borderType = BORDER_LINE_SECTION_SIDES;
    
    if ([self.backgroundView isKindOfClass: [BorderedCellBackgroundView class]])
      borderType |= (((BorderedCellBackgroundView *) self.backgroundView).borderType & BORDER_LINE_SEPARATOR);
    else if ([self.selectedBackgroundView isKindOfClass: [BorderedCellBackgroundView class]])
      borderType |= (((BorderedCellBackgroundView *) self.selectedBackgroundView).borderType & BORDER_LINE_SEPARATOR);

    if (index == 0)
      borderType |= BORDER_LINE_SECTION_TOP;
    if (index >= totalItems - 1)
      borderType |= BORDER_LINE_SECTION_BOTTOM;
  
    if ([self.backgroundView isKindOfClass: [BorderedCellBackgroundView class]])
      ((BorderedCellBackgroundView *) self.backgroundView).borderType = borderType;
    if ([self.selectedBackgroundView isKindOfClass: [BorderedCellBackgroundView class]])
      ((BorderedCellBackgroundView *) self.selectedBackgroundView).borderType = borderType;
  }
}

- (void) refreshPaletteToVersion: (NSUInteger) version
{
  if (version != _paletteVersion)
  {
    UIColor *borderColour = [StandardPalette tableSeparatorColour];
  
    self.backgroundView = [self backgroundViewWithFillColour: [StandardPalette tableCellColour]
                                                borderColour: borderColour];
    self.selectedBackgroundView = [self backgroundViewWithFillColour: [StandardPalette selectedTableCellColour]
                                                        borderColour: borderColour];
    _paletteVersion = version;
  }
}

- (void) adjustCellForResize
{
  [self.backgroundView setNeedsLayout];
  [self.backgroundView setNeedsDisplay];
  [self.selectedBackgroundView setNeedsLayout];
  [self.selectedBackgroundView setNeedsDisplay];
}

// For subclasses to override
- (void) adjustCellForSelected: (BOOL) selected
{
}

- (void) delayedAdjust
{
  [self adjustCellForSelected: self.selected];
}

- (void) setSelected: (BOOL) selected animated: (BOOL) animated
{
  [super setSelected: selected animated: animated];
  if (!selected)
    [self performSelector: @selector(delayedAdjust) withObject: nil afterDelay: 0.3];
}

- (void) didAddSubview: (UIView *) subview
{
  if (subview == self.selectedBackgroundView)
    [self adjustCellForSelected: YES];
}

- (void) willRemoveSubview: (UIView *) subview
{
  if (_usable && subview == self.selectedBackgroundView)
    [self adjustCellForSelected: NO];
}

- (UIView *) backgroundViewWithFillColour: (UIColor *) fillColour borderColour: (UIColor *) borderColour
{
  BorderedCellBackgroundView *view;

  if (fillColour == nil)
    view = nil;
  else
  {
    view = [[[BorderedCellBackgroundView alloc] initWithFrame: CGRectZero] autorelease]; 
    if (_separatorStyle == UITableViewCellSeparatorStyleNone || _tableStyle == UITableViewStylePlain)
      view.borderType = BORDER_TYPE_NONE;
    else
      view.borderType = BORDER_TYPE_SEPARATOR_ONLY;
    view.fillColour = fillColour;
    view.borderColour = borderColour;
  }
  
  return view;
}

- (void) dealloc
{
  _usable = NO;
  [super dealloc];
}


@end
