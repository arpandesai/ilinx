//
//  AppStateNotification.m
//  iLinX
//
//  Created by mcf on 08/11/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "AppStateNotification.h"

static int g_backgroundStateSupported = -1;

@implementation AppStateNotification

+ (void) initStateSupportedFlag
{
  UIDevice *device = [UIDevice currentDevice];
  
  if ([device respondsToSelector: @selector(isMultitaskingSupported)] &&
      [device isMultitaskingSupported])
    g_backgroundStateSupported = 1;
  else
    g_backgroundStateSupported = 0;
}

+ (void) addWillEnterForegroundObserver: (id) observer selector: (SEL) selector
{
  if (g_backgroundStateSupported < 0)
    [self initStateSupportedFlag];

  if (g_backgroundStateSupported > 0)
    [[NSNotificationCenter defaultCenter] addObserver: observer selector: selector
                                                 name: UIApplicationWillEnterForegroundNotification 
                                               object: nil];
}

+ (void) addDidEnterBackgroundObserver: (id) observer selector: (SEL) selector
{
  if (g_backgroundStateSupported < 0)
    [self initStateSupportedFlag];
  
  if (g_backgroundStateSupported > 0)
    [[NSNotificationCenter defaultCenter] addObserver: observer selector: selector
                                                 name: UIApplicationDidEnterBackgroundNotification 
                                               object: nil];
}

+ (void) removeObserver: (id) observer
{
  if (g_backgroundStateSupported < 0)
    [self initStateSupportedFlag];

  if (g_backgroundStateSupported > 0)
  {
    [[NSNotificationCenter defaultCenter] removeObserver: observer
                                                 name: UIApplicationWillEnterForegroundNotification 
                                               object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: observer
                                                    name: UIApplicationDidEnterBackgroundNotification 
                                                  object: nil];
  }
}

@end
