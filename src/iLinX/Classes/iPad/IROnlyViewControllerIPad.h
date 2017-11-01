//
//  IROnlyViewController.h
//  iLinX
//
//  Created by mcf on 24/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioSubViewControllerIPad.h"
#import "ListDataSource.h"
#import "NLSourceLocal.h"
#import "NLSourceIROnly.h"

@class NLSourceList;

@interface IROnlyViewControllerIPad :  AudioSubViewControllerIPad <UITextFieldDelegate, UIWebViewDelegate, ListDataDelegate, NLSourceIROnlyDelegate, UITableViewDelegate, UITableViewDataSource>
{
@private
  IBOutlet UILabel *_redButton;
  IBOutlet UILabel *_yellowButton;
  IBOutlet UILabel *_blueButton;
  IBOutlet UILabel *_greenButton;
  IBOutlet UILabel *_sourceTitle;
  NLSourceIROnly *_irOnlySource;
  UITableView *_tableView;
  NLBrowseList *_presets;
}

@property (nonatomic, retain) IBOutlet UITableView  *tableView;

- (IBAction) pressedButton: (UIButton *) button;
- (IBAction) releasedButton: (UIButton *) button;
- initWithPresets: (NLBrowseList *) presets;

@end
