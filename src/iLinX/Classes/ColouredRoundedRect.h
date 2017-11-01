//
//  ColouredRoundedRect.h
//  iLinX
//
//  Created by mcf on 07/05/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ColouredRoundedRect : UIView
{
@private
  UIColor *_fillColour;
  CGFloat _radius;
}

- (id) initWithFrame: (CGRect) frame fillColour: (UIColor *) fillColour radius: (CGFloat) radius;

@end
