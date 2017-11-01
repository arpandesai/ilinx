//
//  ConfigManager.m
//  iLinX
//
//  Created by mcf on 27/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "ConfigManager.h"
#import "ConfigProfile.h"
#import "ConfigViewController.h"
#import "JavaScriptSupport.h"
#import "NLListDataSource.h"
#import "ProfileListController.h"
#import "StandardPalette.h"

static NSString * const kCurrentProfileKey = @"currentProfileKey";
static NSString * const kProfileListKey = @"profileListKey";
static NSString * const kStartupTypeKey = @"startupTypeKey";
static NSString * const kConnectionTypeKey = @"connectionTypeKey";
static NSString * const kSettingsKey = @"settingsKey";
static NSString * const kStayConnectedKey = @"stayConnectedKey";

static NSArray *g_profileList = nil;
static NSInteger g_currentProfile = 0;
static NSArray *g_startupTypes = nil;
static NSInteger g_currentStartupType = STARTUP_TYPE_USE_CURRENT_PROFILE;
static BOOL g_stayConnected = NO;

@interface ProfileListDataSource : NLListDataSource
{
}

@end

@implementation ProfileListDataSource

- (id) itemAtIndex: (NSUInteger) index
{
  return [ConfigManager profileAtIndex: index];
}

- (NSString *) titleForItemAtIndex: (NSUInteger) index
{
  ConfigProfile *profile = [ConfigManager profileAtIndex: index];
  
  if (profile == nil)
    return @"";
  else
    return profile.name;
}

- (BOOL) itemIsSelectedAtIndex: (NSUInteger) index
{
  return (index == [ConfigManager currentProfile]);
}

- (id<ListDataSource>) selectItemAtIndex: (NSUInteger) index executeAction: (BOOL) executeAction
{
  [ConfigManager setCurrentProfile: index];
  _currentIndex = index;

  // No child list, so return nil
  return nil;
}

- (BOOL) itemIsSelectableAtIndex: (NSUInteger) index
{
  return YES;
}

- (id) listDataCurrentItem
{
  return [ConfigManager currentProfileData];
}

@end

@interface ConfigManager ()

+ (void) initStartupTypes;

@end

@implementation ConfigManager

+ (Class) settingsViewClass
{
  id settingsObj = [[NSUserDefaults standardUserDefaults] objectForKey: kSettingsKey];
  Class viewClass;
  
  if (settingsObj == nil)
  {
    // no default value has been set; create it here based on what's in our Settings bundle info
    
    NSString *pathStr = [[NSBundle mainBundle] bundlePath];
    NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent: @"Settings.bundle"];
    NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent: @"Root.plist"];
    NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile: finalPath];
    NSArray *prefSpecifierArray = [settingsDict objectForKey: @"PreferenceSpecifiers"];
    id settingsDefaultValue = nil;
    NSDictionary *prefItem;
    
    for (prefItem in prefSpecifierArray)
    {
      NSString *keyValueStr = [prefItem objectForKey: @"Key"];
      id defaultValue = [prefItem objectForKey: @"DefaultValue"];
      
      if ([keyValueStr isEqualToString: kSettingsKey])
        settingsDefaultValue = defaultValue;
    }
    
    // since no default values have been set (i.e. no preferences file created), create it here
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                 settingsDefaultValue, kSettingsKey,
                                 nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults: appDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
  
  switch ([[NSUserDefaults standardUserDefaults] integerForKey: kSettingsKey])
  {
    case 1:
      viewClass = [ProfileListController class];
      break;
    case 2:
      viewClass = [ConfigViewController class];
      break;
    default:
      viewClass = nil;
      break;
  }
  
  return viewClass;
}

+ (void) ensureLatestConfigFormat {
	/*
	// Has the user set the reconfigure flag in the iOS settings app?
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kReconfigureKey]) {
		// Yes, so nuke the profile so that we start from scratch below
		NSLog(@"Nuking current profile here as user set reconfigure flagg in iOS settings");
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:kCurrentProfileKey];
		// Unset the reconfigure flag now that we've done it
		[[NSUserDefaults standardUserDefaults] setBool:false forKey:kReconfigureKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	 */
	// If we don't have a current profile key we're either a new instance of iLinX or an old version that has just been upgraded
	if ([[NSUserDefaults standardUserDefaults] objectForKey: kCurrentProfileKey] == nil) {
		// No connection type key either indicates a new instance - create a default profile otherwise copy the old settings to create a partially initialised profile
		ConfigProfile *defaultProfile;
		if ([[NSUserDefaults standardUserDefaults] objectForKey: kConnectionTypeKey] == nil)
			defaultProfile = [[ConfigProfile alloc] init];
		else defaultProfile = [[ConfigProfile alloc] initWithOldSettings];
		g_profileList = [NSArray arrayWithObject: defaultProfile];
		[g_profileList retain];
		[defaultProfile release];
		// Either way, store the new profile, make it the default and make the default startup behaviour be to use the default profile.
		g_currentProfile = 0;
		g_currentStartupType = STARTUP_TYPE_USE_CURRENT_PROFILE;
		[self saveConfiguration];
	}
}

+ (void) saveConfiguration
{
  [[NSUserDefaults standardUserDefaults] setObject: [NSKeyedArchiver archivedDataWithRootObject: g_profileList]
                                            forKey: kProfileListKey];
  [[NSUserDefaults standardUserDefaults] setInteger: g_currentProfile forKey: kCurrentProfileKey];
  [[NSUserDefaults standardUserDefaults] setInteger: g_currentStartupType forKey: kStartupTypeKey];
  [[NSUserDefaults standardUserDefaults] setBool: g_stayConnected forKey: kStayConnectedKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSArray *) profileList
{
  if (g_profileList == nil)
  {
    NSData *profileListData = [[NSUserDefaults standardUserDefaults] objectForKey: kProfileListKey];
    
    if (profileListData == nil)
      [self ensureLatestConfigFormat];
    else
    {
      g_profileList = (NSArray *) [[NSKeyedUnarchiver unarchiveObjectWithData: profileListData] retain];
      g_currentProfile = [[NSUserDefaults standardUserDefaults] integerForKey: kCurrentProfileKey];
      if (g_currentProfile >= [g_profileList count])
        g_currentProfile = 0;
    }
  }
  
  return g_profileList;
}

+ (id<ListDataSource>) profileListDataSource
{
  return [[[ProfileListDataSource alloc] init] autorelease];
}

+ (void) setProfileList: (NSArray *) profileList
{
  if (profileList != g_profileList)
  {
    [g_profileList release];
    g_profileList = [profileList retain];
  }
  
  if (g_currentProfile >= [g_profileList count])
    g_currentProfile = 0;
  
  [self saveConfiguration];
  [StandardPalette initialise];
}

+ (ConfigProfile *) profileAtIndex: (NSInteger) index
{
  ConfigProfile *profile;

  if (g_profileList == nil)
    [self profileList];
  
  if (index >= 0 && index < [g_profileList count])
    profile = [g_profileList objectAtIndex: index];
  else
    profile = nil;
  
  return profile;
}

+ (NSInteger) currentProfile
{
  if (g_profileList == nil)
    [self profileList];
  
  return g_currentProfile;
}

+ (ConfigProfile *) currentProfileData
{
  NSInteger currentProfile = [self currentProfile];
  ConfigProfile *profileData;
  
  if (currentProfile < [g_profileList count])
    profileData = (ConfigProfile *) [g_profileList objectAtIndex: currentProfile];
  else
    profileData = nil;
  
  return profileData;
}

+ (void) setCurrentProfile: (NSInteger) currentProfile
{
  if (g_profileList == nil)
    [self profileList];
  
  if (currentProfile >= 0 && currentProfile < [g_profileList count] && currentProfile != g_currentProfile)
  {
    g_currentProfile = currentProfile;
    [self saveConfiguration];
    [StandardPalette initialise];
  }
}

+ (NSArray *) startupTypes
{
  if (g_startupTypes == nil)
    [self initStartupTypes];
  
  return g_startupTypes;
}

+ (NSString *) startupTypeAtIndex: (NSInteger) index
{
  NSString *typeName;

  if (g_startupTypes == nil)
    [self initStartupTypes];
  
  
  if (index >= 0 && index < [g_startupTypes count])
    typeName = [g_startupTypes objectAtIndex: index];
  else
    typeName = @"";
  
  return typeName;
}

+ (NSInteger) currentStartupType
{
  if (g_startupTypes == nil)
    [self initStartupTypes];

  return g_currentStartupType;
}

+ (NSString *) currentStartupTypeName
{
  NSInteger currentStartupType = [self currentStartupType];
  NSString *typeName;
  
  if (currentStartupType < [g_startupTypes count])
    typeName = (NSString *) [g_startupTypes objectAtIndex: currentStartupType];
  else
    typeName = @"";
  
  return typeName;
}

+ (void) setCurrentStartupType: (NSInteger) currentStartupType
{
  if (g_startupTypes == nil)
    [self initStartupTypes];

  if (currentStartupType >= 0 && currentStartupType < [g_startupTypes count])
  {
    g_currentStartupType = currentStartupType;
    [self saveConfiguration];
  }
}

+ (BOOL) stayConnected
{
  return g_stayConnected;
}

+ (void) setStayConnected: (BOOL) stayConnected
{
  g_stayConnected = stayConnected;
  [UIApplication sharedApplication].idleTimerDisabled = g_stayConnected;
  [[NSUserDefaults standardUserDefaults] setBool: stayConnected forKey: kStayConnectedKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects
{
  NSString *result;
  
  if ((statusMask & JSON_CURRENT_PROFILE) == 0)
    result = @"{}";
  else
  {
    NSInteger count = [g_profileList count];
    
    result = [NSString stringWithFormat: @"{ currentIndex: %d, length: %d", g_currentProfile, count];

    if ((statusMask & JSON_ALL_PROFILES) == 0)
      result = [result stringByAppendingFormat: @", %d: %@", g_currentProfile,
                [[self profileAtIndex: g_currentProfile] jsonStringForStatus: statusMask withObjects: withObjects]];
    else
    {
      for (NSInteger i = 0; i < count; ++i)
        result = [result stringByAppendingFormat: @", %d: %@", i,
                  [[self profileAtIndex: i] jsonStringForStatus: statusMask withObjects: withObjects]];
    }
    
    result = [result stringByAppendingString: @" }"];
  }
  
  return result;
}

+ (void) initStartupTypes
{
  g_startupTypes = [[NSArray arrayWithObjects: 
                     NSLocalizedString( @"Use Current", @"Startup option of using the current profile on startup" ),
                     NSLocalizedString( @"Show Profiles", @"Startup option of listing the profiles each time" ),
#if AUTO_DETECT_PROFILE_IMPLEMENTED
                     NSLocalizedString( @"Auto-Detect", @"Startup option of auto-detecting the right profile to use" ),
#endif
                     nil] retain];
  g_currentStartupType = [[NSUserDefaults standardUserDefaults] integerForKey: kStartupTypeKey];
  g_stayConnected = [[NSUserDefaults standardUserDefaults] boolForKey: kStayConnectedKey];
  [UIApplication sharedApplication].idleTimerDisabled = g_stayConnected;
}

@end
