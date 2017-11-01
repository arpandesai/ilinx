//
//  ProfileViewController.h
//  iLinX
//
//  Created by mcf on 27/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConfigOptionViewController.h"
#import "TintedTableViewController.h"

@class ConfigProfile;
@class SettingAndValueCell;

@interface ProfileViewController : TintedTableViewController <UITextFieldDelegate, ConfigOptionDelegate>
{
@private
  ConfigProfile *_profile;
  SettingAndValueCell *_currentCell;
}

- (id) initWithProfile: (ConfigProfile *) profile;

@end
