//
//  SecurityViewControllerIPad.h
//  iLinX
//
//  Created by James Stamp on 29/09/2010.
//  Copyright 2010 Janus Technology. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ServiceViewControllerIPad.h"
#import "NLServiceSecurity.h"
#import "PagedScrollViewController.h"

@interface SecurityViewControllerIPad : ServiceViewControllerIPad <PagedScrollViewDelegate, UITextFieldDelegate,
                                                                   UIWebViewDelegate, NLServiceSecurityDelegate,
                                                                   UIAlertViewDelegate>
{
  IBOutlet UILabel *_serviceName;
  IBOutlet UIView *_emergency;
  IBOutlet UIButton *_policeButton;
  IBOutlet UIButton *_fireButton;
  IBOutlet UIButton *_ambulanceButton;
  IBOutlet UITextField *_numberDisplay;
  IBOutlet UIButton *_deleteButton;
  IBOutlet UIButton *_enterButton;
  IBOutlet UIButton *_starButton;
  IBOutlet UIButton *_hashButton;
  IBOutlet UIView *_openAreas;
  IBOutlet UIScrollView *_scroller;
  IBOutlet UITableView *_tableView;
  IBOutlet UILabel *_buttonsTitle;
  IBOutlet UILabel *_tableTitle;
  IBOutlet PagedScrollViewController *_pageController;
  
  NLServiceSecurity *_securityService;
  NSUInteger _tableControlMode;
  NSUInteger _buttonsControlMode;
  NSUInteger _buttonCount;
  NSUInteger _buttonsOnPage;
  NSUInteger _numberOfColumns;
  NSString *_pendingEmergencyAction;
}

- (IBAction) pressedButton: (UIButton *) button;
- (IBAction) releasedButton: (UIButton *) button;

@property (readonly) UITableView *tableView;

@end
