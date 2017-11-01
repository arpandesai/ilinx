//
//  EditLabelViewController.h
//  iLinX
//
//  Created by mcf on 09/06/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TintedTableViewController.h"

@class NLTimer;

@interface EditLabelViewController : TintedTableViewController 
{
@private
  NLTimer *_timer;
  UITextField *_labelText;
}

- (id) initWithTimer: (NLTimer *) timer;

@end
