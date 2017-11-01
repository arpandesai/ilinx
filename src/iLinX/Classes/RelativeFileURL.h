//
//  RelativeFileURL.h
//  iLinX
//
//  Created by mcf on 23/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSURL (iLinXRelativeFileURL)

+ (NSURL *) URLWithILinXString: (NSString *) iLinXString;

@end
