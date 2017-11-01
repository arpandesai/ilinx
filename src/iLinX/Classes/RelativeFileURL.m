//
//  RelativeFileURL.m
//  iLinX
//
//  Created by mcf on 23/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "RelativeFileURL.h"


@implementation NSURL (iLinXRelativeFileURL)

+ (NSURL *) URLWithILinXString: (NSString *) iLinXString
{
  NSURL *result;

  if ([iLinXString rangeOfString: @":"].length > 0)
    result = [NSURL URLWithString: iLinXString];
  else if ([iLinXString rangeOfString: @"/"].location == 0)
    result = [NSURL fileURLWithPath: iLinXString];
  else
  {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES )
                                    objectAtIndex: 0];
    
    result = [NSURL fileURLWithPath: [documentsDirectory stringByAppendingPathComponent: iLinXString]];
  }
  
  return result;
}

@end
