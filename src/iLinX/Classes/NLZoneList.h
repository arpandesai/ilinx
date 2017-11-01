//
//  NLZoneList.h
//  iLinX
//
//  Created by mcf on 12/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLListDataSource.h"

@class NLZone;

@interface NLZoneList : NLListDataSource
{
@private
  NSMutableArray *_zones;
}

@property (nonatomic, retain) NSMutableArray *zones;

- (void) addZone: (NLZone *) zone;
- (NLZone *) zoneAtIndex: (NSUInteger) index;
- (void) setCurrentZoneToMatchAudioSession: (NSString *) audioSessionName;

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects;

@end
