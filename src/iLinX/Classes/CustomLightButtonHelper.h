//
//  CustomLightButtonHelper.h
//  iLinX
//
//  Created by mcf on 23/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CustomLightButtonHelper : NSObject
{
@private
  UIButton *_button;
  BOOL _hasIndicator;
  BOOL _indicatorState;
}

@property (readonly) UIButton *button;
@property (assign) BOOL hasIndicator;
@property (assign) BOOL indicatorState;

@end
