//
//  ConfigViewController.h
//  iLinX
//
//  Created by mcf on 27/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConfigOptionViewController.h"
#import "TintedTableViewController.h"

@class ConfigProfile;

@interface ConfigViewController : TintedTableViewController <ConfigOptionDelegate>
{
@private
  ConfigProfile *_originalProfile;
}

@end
