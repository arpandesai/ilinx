//
//  ChangeSelectionHelper.h
//  iLinX
//
//  Created by mcf on 13/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ListDataSource.h"

@class NLRoomList;

@interface ChangeSelectionHelper : NSObject
{
}

+ (UIToolbar *) addToolbarToView: (UIView *) view withTitle: (NSString *) title1 target: (id) target1 selector: (SEL) selector1
                title: (NSString *) title2 target: (id) target2 selector: (SEL) selector2;
+ (void) showDialogOver: (UINavigationController *) currentNavigationController
  withListData: (id<ListDataSource>) dataSource;
+ (void) showDialogOver: (UINavigationController *) currentNavigationController
           withListData: (id<ListDataSource>) dataSource headerView: (UIView *) view;

@end
