//
//  ButtonBar.h
//  iLinX
//
//  Created by mcf on 06/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ButtonBar : UIView
{
@private
  NSArray *_items;
}

@property (nonatomic, retain) NSArray *items;

@end
