//
//  SelectableListViewCell.h
//  iLinX
//
//  Created by mcf on 09/06/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BorderedTableViewCell.h"

@interface SelectableListViewCell : BorderedTableViewCell
{
@private
  UILabel *_title;
}

@property (assign) NSString *title;

@end
