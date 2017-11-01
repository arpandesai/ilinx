//
//  ConfigManager.h
//  iLinX
//
//  Created by mcf on 27/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ListDataSource.h"

#define STARTUP_TYPE_USE_CURRENT_PROFILE 0
#define STARTUP_TYPE_PRESENT_CHOICE      1
#define STARTUP_TYPE_AUTO_DETECT         2

@class ConfigProfile;

@protocol ConfigStartupDelegate

- (void) setConfigStartupType: (NSInteger) startupType;

@end

@interface ConfigManager : NSObject
{
}

+ (Class) settingsViewClass;
+ (void) ensureLatestConfigFormat;
+ (void) saveConfiguration;

+ (NSArray *) profileList;
+ (id<ListDataSource>) profileListDataSource;
+ (void) setProfileList: (NSArray *) profileList;
+ (ConfigProfile *) profileAtIndex: (NSInteger) index;
+ (NSInteger) currentProfile;
+ (ConfigProfile *) currentProfileData;
+ (void) setCurrentProfile: (NSInteger) currentProfile;

+ (NSArray *) startupTypes;
+ (NSString *) startupTypeAtIndex: (NSInteger) index;
+ (NSInteger) currentStartupType;
+ (NSString *) currentStartupTypeName;
+ (void) setCurrentStartupType: (NSInteger) currrentStartupType;
+ (BOOL) stayConnected;
+ (void) setStayConnected: (BOOL) stayConnected;

+ (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects;

@end
