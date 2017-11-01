//
//  SettingAndValueCell.h
//  iLinX
//
//  Created by mcf on 27/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BorderedTableViewCell.h"

@interface SettingAndValueCell : BorderedTableViewCell 
{
@private
  UILabel *_nameLabel;
  UILabel *_valueLabel;
  UITextField *_valueEdit;
  UIColor *_nameColor;
  UIColor *_valueColor;
  BOOL _showPlaceholder;
}

@property (nonatomic, copy) NSString *nameText;
@property (nonatomic, retain) UIColor *nameTextColor;
@property (nonatomic, copy) NSString *detailText;
@property (nonatomic, retain) UIColor *detailTextColor;
@property (nonatomic, copy) NSString *detailPlaceholder;
@property (nonatomic) CGFloat detailMinimumFontSize;
@property (nonatomic) BOOL detailAdjustsFontSizeToFitWidth;
@property (readonly) UITextField *editableDetailField;

- (id) initDefaultWithFrame: (CGRect) frame reuseIdentifier: (NSString *) reuseIdentifier
                      table: (UITableView *) table;
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;

@end
