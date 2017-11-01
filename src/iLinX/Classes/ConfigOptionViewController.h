//
//  ConfigOptionViewController.h
//  iLinX
//
//  Created by mcf on 28/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TintedTableViewController.h"

@class ConfigOptionViewController;

@protocol ConfigOptionDelegate

- (void) chosenConfigOption: (NSInteger) option;

@end

@interface ConfigOptionViewController : TintedTableViewController
{
@private
  NSArray *_options;
  NSInteger _chosenOption;
  id<ConfigOptionDelegate> _delegate;
}

@property (assign) id<ConfigOptionDelegate> delegate;

- (id) initWithTitle: (NSString *) title options: (NSArray *) options chosenOption: (NSInteger) chosenOption;

@end
