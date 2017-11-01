//
//  SecurityListViewController.h
//  iLinX
//
//  Created by mcf on 27/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLServiceSecurity.h"

@interface SecurityListViewController : UIViewController <NLServiceSecurityDelegate, UITableViewDelegate, UITableViewDataSource>
{
@private
  NLServiceSecurity *_securityService;
  NSUInteger _controlMode;
  IBOutlet UITableView *_tableView;
}

@property (readonly) UITableView *tableView;

- initWithSecurityService: (NLServiceSecurity *) securityService controlMode: (NSUInteger) controlMode;

@end
