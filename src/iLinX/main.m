//
//  main.m
//  iLinX
//
//  Created by mcf on 19/12/2008.
//  Copyright Micropraxis Ltd 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iLinXAppDelegate.h"

int main(int argc, char *argv[])
{
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  int retVal = UIApplicationMain( argc, argv, nil, NSStringFromClass([iLinXAppDelegate class]) );

  [pool release];
  return retVal;
}
