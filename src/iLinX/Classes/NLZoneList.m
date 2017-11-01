//
//  NLZoneList.m
//  iLinX
//
//  Created by mcf on 12/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLZoneList.h"
#import "NLZone.h"
#import "JavaScriptSupport.h"

@implementation NLZoneList

@synthesize
  zones = _zones;

- (id) init
{
  if (self = [super init])
    self.zones = [NSMutableArray arrayWithCapacity: 10];
  
  return self;
}

- (void) setZones: (NSMutableArray *) zones
{
  [_zones release];
  _zones = [zones retain];
  _currentIndex = [_zones count];
}

- (void) addZone: (NLZone *) zone
{
  if (_currentIndex == [_zones count])
    ++_currentIndex;

  [_zones addObject: zone];
}

- (NLZone *) zoneAtIndex: (NSUInteger) index
{
  return [self itemAtIndex: index];
}

- (void) setCurrentZoneToMatchAudioSession: (NSString *) audioSessionName
{
  NSUInteger count = [_zones count];
  
  for (_currentIndex = 0; _currentIndex < count; ++_currentIndex)
  {
    if ([[self zoneAtIndex: _currentIndex].audioSessionName compare: audioSessionName 
                                                           options: NSCaseInsensitiveSearch] == NSOrderedSame)
      break;
  }
}

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects
{
  NSString *result;

  if ((statusMask & JSON_CURRENT_ZONE) == 0)
    result = @"{}";
  else
  {
    NSInteger mainCount = [_zones count];
    
    result = [NSString stringWithFormat: @"{ length: %d, currentIndex: %u", mainCount, _currentIndex];
  
    if ((statusMask & JSON_ALL_ZONES) == 0)
      result = [result stringByAppendingFormat: @", %d: %@", _currentIndex,
                [[_zones objectAtIndex: _currentIndex] jsonStringForStatus: statusMask withObjects: withObjects]];
    else
    {
      for (int i = 0; i < mainCount; ++i)
        result = [result stringByAppendingFormat: @", %d: %@", i,
                  [[_zones objectAtIndex: i] jsonStringForStatus: statusMask withObjects: withObjects]];
    }
    
    result = [result stringByAppendingString: @" }"];
  }
  
  return result;
}

- (void) dealloc
{
  [_zones release];
  [super dealloc];
}

- (NSString *) listTitle
{
  return NSLocalizedString( @"Join MultiRoom", @"Title of list of zones" );
}

- (NSUInteger) countOfList
{
  return [_zones count];
}

- (id) itemAtIndex: (NSUInteger) index
{
  if (index >= [_zones count])
    return nil;
  else
    return [_zones objectAtIndex: index];
}

- (NSString *) titleForItemAtIndex: (NSUInteger) index
{
  NLZone *zone = [self itemAtIndex: index];
  
  return zone.displayName;
}

- (BOOL) itemIsSelectedAtIndex: (NSUInteger) index
{
  return (index == _currentIndex);
}

- (id<ListDataSource>) selectItemAtIndex: (NSUInteger) index executeAction: (BOOL) executeAction
{
  if (index < [_zones count] && index != _currentIndex)
  {
    NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
    NSEnumerator *enumerator = [delegates objectEnumerator];
    id<ListDataDelegate> delegate;
    NLZone *oldZone;
    
    if (index < [_zones count])
      oldZone = [_zones objectAtIndex: index];
    else
      oldZone = nil;
    _currentIndex = index;
    
    while ((delegate = [enumerator nextObject]))
    {
      if ([delegate respondsToSelector: @selector(currentItemForListData:changedFrom:to:at:)])
        [delegate currentItemForListData: self changedFrom: oldZone to: [_zones objectAtIndex: index] at: index];
    }
  }
  
  // No child list, so return nil
  return nil;
}

- (BOOL) itemIsSelectableAtIndex: (NSUInteger) index
{
  return YES;
}

- (id) listDataCurrentItem
{
  if (_currentIndex < [_zones count])
    return [_zones objectAtIndex: _currentIndex];
  else
    return nil;
}

@end
