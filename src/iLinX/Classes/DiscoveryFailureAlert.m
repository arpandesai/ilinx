//
//  DiscoveryFailureAlert.m
//  iLinX
//
//  Created by mcf on 05/11/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "DiscoveryFailureAlert.h"
#import "ConfigManager.h"
#import "ConfigProfile.h"

@implementation DiscoveryFailureAlert

+ (void) showAlertWithError: (NSError *) error
{
  ConfigProfile *profile = [ConfigManager currentProfileData];
  NSString *errorMessage;
  
  if (error != nil)
    errorMessage = [NSString stringWithFormat: NSLocalizedString( @"Network problem: %@", 
                                                                 @"Message shown if there is a networking problem during discovery; parameter is OS localized error string" ),
                    [error localizedDescription]];
  else if ([profile autoDiscovery])
    errorMessage = NSLocalizedString( @"No devices responded to the discovery broadcast",
                                     @"Message shown if no NetStreams devices found but there isn't any other network problem" );
  else
    errorMessage = [NSString stringWithFormat: NSLocalizedString( @"Unable to contact the system specified in the %@ profile (%@:%d)",
                                                                 @"Message shown if unable to connect to a direct connect system; parameters are the profile name, host address and port" ),
                    profile.name, profile.directAddress, profile.directPort];
  
  UIAlertView *alert = [[UIAlertView alloc] 
                        initWithTitle: NSLocalizedString( @"Discovery failed", @"Title of alert when discovery finds no devices" )
                        message: errorMessage delegate: nil
                        cancelButtonTitle: NSLocalizedString( @"OK", @"Title of button to dismiss discovery failure alert" )
                        otherButtonTitles: nil];
  
  [alert show];
  [alert release];
}

@end
