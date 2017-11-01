//
//  PseudoBarButton.h
//  iLinX
//
//  Created by mcf on 01/11/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PseudoBarButton : UISegmentedControl <NSCoding>
{
@private
  UISegmentedControl *_selectedOverlay;
  UIButton *_button;
}

@property (nonatomic, assign) NSString *title;
@property (nonatomic, assign) UIImage *image;

@end
