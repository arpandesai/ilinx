//
//  ConfigRootController.h
//  iLinX
//
//  Created by mcf on 27/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConfigManager.h"

@interface ConfigRootController : UINavigationController
{
@private
  id<ConfigStartupDelegate> _startupTypeDelegate;
}

- (id) initWithRootClass: (Class) rootClass startupTypeDelegate: (id<ConfigStartupDelegate>) startupTypeDelegate;
- (void) setProfileRefresh;

@end
