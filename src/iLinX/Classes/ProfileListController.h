//
//  ProfileListController.h
//  iLinX
//
//  Created by mcf on 27/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TintedTableViewController.h"

@class ConfigProfile;
@class CustomViewController;

@interface ProfileListController : TintedTableViewController
{
@private
  NSMutableArray *_profileListCopy;
  NSInteger _currentProfile;
  ConfigProfile *_originalProfile;
  BOOL _inEditMode;
#if !defined(IPAD_BUILD)
  CustomViewController *_customPage;
#endif
}

@end
