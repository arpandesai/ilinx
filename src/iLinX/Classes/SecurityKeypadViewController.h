//
//  SecurityKeypadViewController.h
//  iLinX
//
//  Created by mcf on 18/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XIBViewController.h"
#import "NLServiceSecurity.h"

@interface SecurityKeypadViewController : XIBViewController <NLServiceSecurityDelegate, UIActionSheetDelegate>
{
@private
  IBOutlet UITextField *_numberDisplay;
  IBOutlet UIButton *_policeButton;
  IBOutlet UIButton *_fireButton;
  IBOutlet UIButton *_ambulanceButton;
  IBOutlet UIButton *_deleteButton;
  IBOutlet UIButton *_enterButton;
  IBOutlet UIButton *_starButton;
  IBOutlet UIButton *_hashButton;
  NLServiceSecurity *_securityService;
  UIViewController *_parentController;
  NSString *_pendingEmergencyAction;
}

- (id) initWithSecurityService: (NLServiceSecurity *) securityService parentController: (UIViewController *) parentController;

- (IBAction) pressedButton: (UIButton *) button;
- (IBAction) releasedButton: (UIButton *) button;

@end
