//
//  ConfigRootController.m
//  iLinX
//
//  Created by mcf on 27/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "ConfigRootController.h"
#import "ConfigViewController.h"
#import "StandardPalette.h"

@implementation ConfigRootController

- (void) _refreshAndDismiss
{
  [self setProfileRefresh];
  [[self topViewController] dismissModalViewControllerAnimated: YES];
}

- (id) initWithRootClass: (Class) rootClass startupTypeDelegate: (id<ConfigStartupDelegate>) startupTypeDelegate
{
  UIViewController *tableView = [[rootClass alloc] initWithStyle: UITableViewStyleGrouped];
  
  self = [super initWithRootViewController: tableView];
  if (tableView != nil)
  {
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem: UIBarButtonSystemItemRefresh
                                   target: self action: @selector(_refreshAndDismiss)];
    
    tableView.navigationItem.leftBarButtonItem = leftButton;
    [leftButton release];
    [tableView release];
    self.view.backgroundColor = [StandardPalette standardTintColour];
    _startupTypeDelegate = startupTypeDelegate;
  }

  return self;
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
#if defined(IPAD_BUILD)
  // Overriden to allow any orientation.
  return YES;
#else
  return UIInterfaceOrientationIsPortrait(interfaceOrientation);
#endif
}

- (void) setProfileRefresh
{
  [_startupTypeDelegate setConfigStartupType: STARTUP_TYPE_AUTO_DETECT];
}

@end
