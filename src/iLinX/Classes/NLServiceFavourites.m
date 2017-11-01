//
//  NLServiceFavourites.m
//  iLinX
//
//  Created by mcf on 06/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLServiceFavourites.h"
#import "NetStreamsComms.h"
#import "NLRoom.h"
#import "NLServiceList.h"
#import "NLSource.h"
#import "NLSourceList.h"
#import "JavaScriptSupport.h"

@implementation NLServiceFavourites

- (id) initWithServiceData: (NSDictionary *) serviceData room: (NLRoom *) room comms: (NetStreamsComms *) comms
{
  if (self = [super initWithServiceData: serviceData room: room comms: comms])
    _favourites = [NSMutableArray new];
  
  return self;
}

- (void) parserDidStartElement: (NSString *) elementName attributes: (NSDictionary *) attributeDict
{
  if ([elementName isEqualToString: @"favorite"])
  {
    NSDictionary *copy = [attributeDict mutableCopy];
    
    [_favourites addObject: copy];
    [copy release];
  }
}

- (NSUInteger) favouriteCount
{
  return [_favourites count];
}

- (NLService *) executeFavourite: (NSUInteger) index returnExecutionDelay: (NSTimeInterval *) pDelay
{
  NLService *newService = nil;

  if (index < [_favourites count])
  {
    NSString *macroName = [[_favourites objectAtIndex: index] objectForKey: @"macro"];
    
    if (macroName != nil)
      newService = [_room executeMacro: macroName returnExecutionDelay: pDelay];
  }
  
  return newService;
}

- (NSString *) nameForFavourite: (NSUInteger) index
{
  NSString *name;
  
  if (index >= [_favourites count])
    name = nil;
  else
    name = [[_favourites objectAtIndex: index] objectForKey: @"display"];
  
  return name;
}

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects
{
  NSString *result = [super jsonStringForStatus: statusMask withObjects: withObjects];
  
  if ([result length] >= 2)
  {
    NSString *favourites = nil;
    NSUInteger count = [_favourites count];
    
    for (NSUInteger i = 0; i < count; ++i)
    {
      NSDictionary *favourite = [_favourites objectAtIndex: i];
      NSString *favouriteData = nil;
      
      for (NSString *key in [favourite allKeys])
      {
        if (favouriteData == nil)
          favouriteData = [NSString stringWithFormat: @"\"%@\": \"%@\"", [key javaScriptEscapedString],
                           [[favourite objectForKey: key] javaScriptEscapedString]];
        else
          favouriteData = [favouriteData stringByAppendingFormat: @", \"%@\": \"%@\"", [key javaScriptEscapedString],
                           [[favourite objectForKey: key] javaScriptEscapedString]];
      }

      if (favourites == nil)
        favourites = [NSString stringWithFormat: @"favorites: [{ %@ }", favouriteData];
      else
        favourites = [favourites stringByAppendingFormat: @", { %@ }", favouriteData];
    }
    
    if (favourites != nil)
      result = [NSString stringWithFormat: @"{ %@],%@", favourites, [result substringFromIndex: 1]];
  }
  
  return result; 
}


- (void) dealloc
{
  [_favourites release];
  [_macros release];
  [super dealloc];
}

@end
