//
//  IROnlyPageViewController.h
//  iLinX
//
//  Created by mcf on 24/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XIBViewController.h"

@class NLSourceIROnly;

@interface IROnlyPageViewController : XIBViewController
{
@private
  NLSourceIROnly *_irOnlySource;
  IBOutlet UIButton *_redButton;
  IBOutlet UIButton *_yellowButton;
  IBOutlet UIButton *_blueButton;
  IBOutlet UIButton *_greenButton;
}

- (id) initWithNibName: (NSString *) nibName irOnlySource: (NLSourceIROnly *) irOnlySource;

- (IBAction) pressedButton: (UIButton *) button;
- (IBAction) releasedButton: (UIButton *) button;

@end
