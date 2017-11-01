//
//  DiscoveryFailureAlert.h
//  iLinX
//
//  Created by mcf on 05/11/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DiscoveryFailureAlert : NSObject 
{
}

+ (void) showAlertWithError: (NSError *) error;

@end
