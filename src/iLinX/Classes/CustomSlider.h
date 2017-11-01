//
//  CustomSlider.h
//  iLinX
//
//  Created by mcf on 23/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CustomSlider : UISlider
{
@private
  BOOL _progressOnly;
  UIColor *_tint;
}

@property (nonatomic, retain) UIColor *tint;

- (id) initWithFrame: (CGRect) frame tint: (UIColor *) tint progressOnly: (BOOL) progressOnly;

@end
