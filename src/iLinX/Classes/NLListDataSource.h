//
//  NLListDataSource.h
//  iLinX
//
//  Created by mcf on 26/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DebugTracing.h"
#import "ListDataSource.h"

@interface NLListDataSource : NSDebugObject <ListDataSource>
{
@protected
  NSMutableSet *_listDataDelegates;
  NSUInteger _currentIndex;
}

- (NSUInteger) convertFromOffset: (NSUInteger) index inSection: (NSUInteger) section;
- (NSIndexPath *) indexPathFromIndex: (NSUInteger) index;

@end
