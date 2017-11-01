//
//  NLServiceList.h
//  iLinX
//
//  Created by mcf on 15/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLListDataSource.h"

@class NLService;

@interface NLServiceList : NLListDataSource
{
@private
  NSMutableArray *_services;
  NLService *_currentService;
}

@property (nonatomic, retain) NSMutableArray *services;

- (void) addService: (NLService *) service;
- (void) insertService: (NLService *) service atIndex: (NSUInteger) index;
- (NLService *) serviceAtIndex: (NSUInteger) index;

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects;

@end
