//
//  AppStateNotification.h
//  iLinX
//
//  Created by mcf on 08/11/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AppStateNotification : NSObject 
{
}

+ (void) addWillEnterForegroundObserver: (id) observer selector: (SEL) selector;
+ (void) addDidEnterBackgroundObserver: (id) observer selector: (SEL) selector;
+ (void) removeObserver: (id) observer;

@end
