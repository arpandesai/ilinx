//
//  XIBViewController.h
//  iLinX
//
//  Created by mcf on 26/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface XIBViewController : UIViewController
{
}

+ (void) setFontForControl: (UIView *) control;
+ (void) setFontsForControlsInView: (UIView *) view;
- (void) setFontsForControls;

@end
