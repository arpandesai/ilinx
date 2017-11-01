//
//  NLServiceList.m
//  iLinX
//
//  Created by mcf on 15/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLServiceList.h"
#import "NLService.h"
#import "NLServiceFavourites.h"
#import "JavaScriptSupport.h"

@implementation NLServiceList

@synthesize
 services = _services;

- (id) init
{
  if (self = [super init])
    self.services = [NSMutableArray arrayWithCapacity: 10];
  
  return self;
}

- (void) addService: (NLService *) service
{
  [_services addObject: service];
  ++_currentIndex;
}

- (void) insertService: (NLService *) service atIndex: (NSUInteger) index
{
  [_services insertObject: service atIndex: index];
  ++_currentIndex;
}

- (NLService *) serviceAtIndex: (NSUInteger) index
{
  return [self itemAtIndex: index];
}

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects
{
  NSString *result;

  if ((statusMask & (JSON_CURRENT_SERVICE|JSON_FAVOURITES)) == 0)
    result = @"[]";
  else
  {
    NSInteger count = [_services count];
    NSInteger currentService = count;
    NSInteger favouritesService = count;

    result = [NSString stringWithFormat: @"{ length: %d", count];

    for (int i = 0; i < count; ++i)
    {
      NLService *service = [_services objectAtIndex: i];

      if (service == _currentService)
        currentService = i;
      if ([service isKindOfClass: [NLServiceFavourites class]])
        favouritesService = i;

      if ((statusMask & JSON_ALL_SERVICES) != 0 ||
          (currentService == i && (statusMask & JSON_CURRENT_SERVICE) != 0) || 
          (favouritesService == i && (statusMask & JSON_FAVOURITES) != 0))
        result = [result stringByAppendingFormat: @", %d: %@", i,
                  [service jsonStringForStatus: statusMask withObjects: withObjects]];
    }

    result = [result stringByAppendingFormat: @", currentIndex: %d, favoritesIndex: %d }",
              currentService, favouritesService];
  }
  
  return result;
}

- (void) dealloc
{
  [_services release];
  [super dealloc];
}

- (NSString *) listTitle
{
  return NSLocalizedString( @"Service", @"Title of list of services" );
}

- (NSUInteger) countOfList
{
  return [_services count];
}

- (id) itemAtIndex: (NSUInteger) index
{
  if (index >= [_services count])
    return nil;
  else
    return [_services objectAtIndex: index];
}

- (NSString *) titleForItemAtIndex: (NSUInteger) index
{
  NLService *service = [self itemAtIndex: index];
  
  return service.displayName;
}

- (id<ListDataSource>) selectItemAtIndex: (NSUInteger) index executeAction: (BOOL) executeAction
{
  if (index < [_services count])
  {
    NLService *oldService = _currentService;
    NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
    NSEnumerator *enumerator = [delegates objectEnumerator];
    id<ListDataDelegate> delegate;
    
    _currentService = [_services objectAtIndex: index];
    _currentIndex = index;
    
    if (_currentService != oldService)
    {
      while ((delegate = [enumerator nextObject]))
      {
        if ([delegate respondsToSelector: @selector(currentItemForListData:changedFrom:to:at:)])
          [delegate currentItemForListData: self changedFrom: oldService to: _currentService at: index];
      }
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
  return _currentService;
}

@end
