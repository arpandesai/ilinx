//
//  iLinXAppDelegate.m
//  iLinX
//
//  Created by mcf on 19/12/2008.
//  Copyright Micropraxis Ltd 2008. All rights reserved.
//

#import "iLinXAppDelegate.h"
#import "ArtworkRequest.h"
#import "ConfigManager.h"
#import "ConfigProfile.h"
#import "CustomViewController.h"
#import "MainNavigationController.h"
#import "RootViewController.h"
#import "StandardPalette.h"


// preference key to obtain our restore state
static NSString *kVersionKey = @"versionKey";
static NSString *kFirstVersionKey = @"firstVersionKey";
static NSString * const kEnableSkinKey = @"enableSkinKey";

@implementation iLinXAppDelegate

@synthesize
  window = _window,
  navigationController = _navigationController,
  rootViewControllerIPad = _rootViewControllerIPad;

- (void) applicationDidFinishLaunching: (UIApplication *) application
{
  [self application: application didFinishLaunchingWithOptions: [NSDictionary dictionary]];
}

- (BOOL) application: (UIApplication *) application didFinishLaunchingWithOptions: (NSDictionary *) options 
{
	
#if (TARGET_IPHONE_SIMULATOR)
  Class webView = NSClassFromString(@"WebView");
  
  if ([webView respondsToSelector: @selector(_enableRemoteInspector)])
    [webView _enableRemoteInspector]; // Private API call.
#endif
	
  // Ensure that the program version shown in the settings view is the correct one
  NSString *versionStr = [NSString stringWithFormat: @"%@ (%@)",
                          [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
                          [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"]];
  NSString *firstVersionStr = [[NSUserDefaults standardUserDefaults] objectForKey: kFirstVersionKey];
  
  // Record the first version of iLinX that was installed on this device.  We may use this
  // in future to offer discounts or the such like to early adopters.
  if (firstVersionStr == nil)
  {
    firstVersionStr = [[NSUserDefaults standardUserDefaults] objectForKey: kVersionKey];
    if (firstVersionStr == nil)
      firstVersionStr = versionStr;
    [[NSUserDefaults standardUserDefaults] setObject: firstVersionStr forKey: kFirstVersionKey];
  }
  [[NSUserDefaults standardUserDefaults] setObject: versionStr forKey: kVersionKey];
  [[NSUserDefaults standardUserDefaults] synchronize];

  // Make sure we've updated to the latest configuration settings
  [ConfigManager ensureLatestConfigFormat];

#if !defined(IPAD_BUILD)
  // Maybe fetch new custom view configuration
  [CustomViewController maybeFetchConfig];
#endif

  // Initialise our colour scheme
  [StandardPalette initialise];

  // Create and configure the navigation and view controllers
#if defined(IPAD_BUILD)
    //[_window setRootViewController:_rootViewControllerIPad];
#else
  RootViewController *rootViewController = [RootViewController new];
  UINavigationController *aNavigationController = [[MainNavigationController alloc] initWithRootViewController: rootViewController];
  self.navigationController = aNavigationController;
  
  [aNavigationController release];
  [rootViewController release];
  
  // Configure and show the window
    [_window setRootViewController:_navigationController];
  //_window.rootViewController = _navigationController;
#endif

  _window.backgroundColor = [StandardPalette standardTintColour];
  [_window makeKeyAndVisible];
  
  return YES;
}

- (void) applicationDidReceiveMemoryWarning: (UIApplication *) application
{
  [ArtworkRequest flushCache];
}

- (void) applicationWillEnterForeground: (UIApplication *) application
{
  // Pick up any changes made to the settings while we were away
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) applicationDidEnterBackground: (UIApplication *) application
{
  // Save our current state to preferences
  [ConfigManager saveConfiguration];
}

- (void) applicationWillTerminate: (UIApplication *) application
{
  // Save our current state to preferences
  [ConfigManager saveConfiguration];
}

- (void) dealloc
{
  [_navigationController release];
  [_rootViewControllerIPad release];
  [_window release];
  [super dealloc];
}


@end
