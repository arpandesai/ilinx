//
//  Icons.h
//  iLinX
//
//  Created by mcf on 22/05/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Icons : NSObject
{
}

+ (UIImage *) browseIconForItemName: (NSString *) itemName;
+ (UIImage *) selectedBrowseIconForItemName: (NSString *) itemName;
+ (UIImage *) tabBarBrowseIconForItemName: (NSString *) itemName;
+ (UIImage *) largeBrowseIconForItemName: (NSString *) itemName;
+ (UIImage *) homeIconForServiceName: (NSString *) serviceName;
+ (UIImage *) selectedHomeIconForServiceName: (NSString *) serviceName;

@end
