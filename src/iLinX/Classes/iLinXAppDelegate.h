//
//  iLinXAppDelegate.h
//  iLinX
//
//  Created by mcf on 19/12/2008.
//  Copyright Micropraxis Ltd 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface iLinXAppDelegate : NSObject <UIApplicationDelegate>
{
@private
  UIWindow *_window;
  
  // iPhone version
  UINavigationController *_navigationController;
  
  // iPad version
  UIViewController *_rootViewControllerIPad;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet UIViewController *rootViewControllerIPad;

@end
