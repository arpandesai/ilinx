//
//  EditTimerViewCell.h
//  iLinX
//
//  Created by mcf on 09/06/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BorderedTableViewCell.h"

@interface EditTimerViewCell : BorderedTableViewCell
{
@private
  UILabel *_title;
  UILabel *_content;
  CGRect _contentArea;
}

- (id) initWithArea: (CGRect) area maxWidth: (CGFloat) maxWidth reuseIdentifier: (NSString *) reuseIdentifier
              table: (UITableView *) table;

@property (assign) NSString *title;
@property (assign) NSString *content;

@end
