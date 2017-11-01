//
//  ButtonPageViewController.h
//  iLinX
//
//  Created by mcf on 11/11/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ButtonPageViewController : UIViewController
{
@protected
  IBOutlet UIView *_contentView;
  NSUInteger _offset;
  NSUInteger _count;
  NSUInteger _buttonsPerRow; 
  NSUInteger _buttonsPerPage;
  NSMutableArray *_buttonArray;  
}

- (id) initWithNibName: (NSString *) nibName bundle: (NSBundle *) bundle offset: (NSUInteger) offset 
         buttonsPerRow: (NSUInteger) buttonsPerRow buttonsPerPage: (NSUInteger) buttonsPerPage 
           buttonTotal: (NSUInteger) buttonTotal flash: (BOOL) flash;

- (void) viewDidLoadWithButtonTemplate: (id) buttonTemplate frame: (CGRect) frame;
- (id) createButtonAtIndex: (NSUInteger) index buttonTemplate: (id) buttonTemplate frame: (CGRect) frame;

@end
