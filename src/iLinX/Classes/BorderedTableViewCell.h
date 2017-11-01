//
//  BorderedTableViewCell.h
//  iLinX
//
//  Created by mcf on 05/05/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BorderedTableViewCell : UITableViewCell
{
@private
  UITableViewStyle _tableStyle;
  UITableViewCellSeparatorStyle _separatorStyle;
  BOOL _usable;
@protected
  NSUInteger _paletteVersion;
}

@property (nonatomic, retain) UIColor *fillColour;
@property (nonatomic, retain) UIColor *selectedFillColour;
@property (nonatomic, retain) UIColor *borderColour;

- (id) initDefaultWithFrame: (CGRect) frame reuseIdentifier: (NSString *) reuseIdentifier
                      table: (UITableView *) table;
- (void) setBorderTypeForIndex: (NSInteger) index totalItems: (NSInteger) totalItems;
- (void) refreshPaletteToVersion: (NSUInteger) version;
- (void) adjustCellForResize;

// For subclasses to override
- (void) adjustCellForSelected: (BOOL) selected;

@end
