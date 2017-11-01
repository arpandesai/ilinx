//
//  NLService.m
//  iLinX
//
//  Created by mcf on 15/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLService.h"
#import "NLRoom.h"
#import "NLServiceCameras.h"
#import "NLServiceFavourites.h"
#import "NLServiceGenericIR.h"
#import "NLServiceHVAC1.h"
#import "NLServiceHVAC2.h"
#import "NLServiceSecurity1.h"
#import "NLServiceSecurity2.h"
#import "NLServiceTimers.h"

#import "GuiXmlParser.h"
#import "JavaScriptSupport.h"

@interface NLService ()

+ (NSDictionary *) allocCompleteServiceData: (NSDictionary *) serviceData;

@end

@implementation NLService

+ (id) allocServiceWithServiceData: (NSDictionary *) serviceData room: (NLRoom *) room comms: (NetStreamsComms *) comms
{
  NSDictionary *completeServiceData = [NLService allocCompleteServiceData: serviceData];
  NSString *serviceType = [completeServiceData objectForKey: @"type"];
  NLService *newService;
  
  if ([serviceType isEqualToString: @"generic-ir"])
    newService = [NLServiceGenericIR alloc];
  else if ([serviceType isEqualToString: @"lighting"] || [serviceType hasPrefix: @"generic-"])
    newService = [NLServiceGeneric alloc];
  else if ([serviceType isEqualToString: @"hvac"])
    newService = [NLServiceHVAC1 alloc];
  else if ([serviceType isEqualToString: @"hvac2"])
    newService = [NLServiceHVAC2 alloc];
  else if ([serviceType isEqualToString: @"security"])
    newService = [NLServiceSecurity1 alloc];
  else if ([serviceType isEqualToString: @"security2"])
    newService = [NLServiceSecurity2 alloc];
  else if ([serviceType isEqualToString: @"Cameras"])
    newService = [NLServiceCameras alloc];
  else if ([serviceType isEqualToString: @"Favorites"])
    newService = [NLServiceFavourites alloc];
  else if ([serviceType isEqualToString: @"Timers"])
    newService = [NLServiceTimers alloc];
  else
    newService = [NLService alloc];
  
  newService = [newService initWithServiceData: completeServiceData room: room comms: comms];
  [completeServiceData release];

  return newService;
}

- (id) initWithServiceData: (NSDictionary *) serviceData room: (NLRoom *) room comms: (NetStreamsComms *) comms
{
  if (self = [super init])
  {
    _serviceData = [NLService allocCompleteServiceData: serviceData];
    if (_serviceData == serviceData)
      [_serviceData retain];

    _room = room;  // Not retained as room retains this.
    _comms = comms;//[comms retain];
  }

#if DEBUG
  //**/NSLog( @"Service created: %@ (%08X)", [self displayName], self );
#endif

  return self;
}

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects
{
  NSString *result = [NSString stringWithFormat: @"{ displayName: \"%@\"", [self displayName]];
  
  for (NSString *key in [_serviceData allKeys])
    result = [result stringByAppendingFormat: @", \"%@\": \"%@\"",
              [key javaScriptEscapedString], [[_serviceData objectForKey: key] javaScriptEscapedString]];
  
  return [result stringByAppendingString: @" }"];
}

- (void) parserDidStartElement: (NSString *) elementName attributes: (NSDictionary *) attributeDict
{
}

- (void) parserDidEndElement: (NSString *) elementName
{
}

- (void) parserFoundCharacters: (NSString *) string
{
}

- (void) parserFoundTrailingDataOfType: (NSString *) type data: (NSDictionary *) data
{
}

- (NSString *) displayName
{
  return [_serviceData objectForKey: @"name"];
}

- (NSString *) identifier
{
  return [_serviceData objectForKey: @"id"];
}

- (NSString *) serviceType
{
  return [_serviceData objectForKey: @"type"];
}

- (NSString *) serviceName
{
  return [_serviceData objectForKey: @"serviceName"];
}

- (NLRenderer *) renderer
{
	return _room.renderer;
}

- (BOOL) isDefaultScreen
{
  NSString *defaultScreen = [_serviceData objectForKey: @"defaultScreen"];

  return (defaultScreen != nil && [defaultScreen isEqualToString: @"true"]);
}

+ (NSDictionary *) allocCompleteServiceData: (NSDictionary *) serviceData
{
  NSString *identifier = [serviceData objectForKey: @"id"];
  NSString *name = [serviceData objectForKey: @"name"];
  NSMutableDictionary *copy = nil;
  
  if (identifier != nil)
  {
    
    if ([serviceData objectForKey: @"type"] == nil)
    {
      copy = [serviceData mutableCopy];
      [copy setObject: identifier forKey: @"type"];
    }
    
    if (name == nil)
    {
      name = [GuiXmlParser stripSpecialAffixesFromString: identifier];
      if (copy == nil)
        copy = [serviceData mutableCopy];
      [copy setObject: name forKey: @"name"];
    }
    else
    {
      NSString *newName = [GuiXmlParser stripSpecialAffixesFromString: name];
      
      if (![newName isEqualToString: name])
      {
        if (copy == nil)
          copy = [serviceData mutableCopy];
        [copy setObject: newName forKey: @"name"];
      }
    }

    if ([serviceData objectForKey: @"serviceName"] == nil)
    {
      if (copy == nil)
        copy = [serviceData mutableCopy];
      [copy setObject: identifier forKey: @"serviceName"];
    }
    
    if (copy == nil)
      [serviceData retain];
    else
      serviceData = copy;
  }
  
  return serviceData;
}

- (void) dealloc
{
#if DEBUG
  //**/NSLog( @"Service %@ (%08X)", [self displayName], self );
#endif
  [_serviceData release];
  //[_comms release];
  [super dealloc];
}

@end
