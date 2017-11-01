
//
//  NLRoom.m
//  iLinX
//
//  Created by mcf on 09/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLRoom.h"
#import "NLService.h"
#import "NLServiceList.h"
#import "NLSource.h"
#import "NLSourceList.h"
#import "GuiXmlParser.h"
#import "JavaScriptSupport.h"

#define _pcomms NETSTREAMSCOMMS_PRODUCTION_ONLY(_comms)

@implementation NLRoom

@synthesize
  serviceName = _serviceName,
  displayName = _displayName,
  services = _services,
  sources = _sources,
  zones = _zones,
  macros = _macros,
  renderer = _renderer,
  videoServiceName = _videoServiceName;

- (id) initWithName: (NSString *) name comms: (NetStreamsComms *) comms
{
  if ((self = [super init]) != nil)
  {
    _serviceName = [name retain];
    _displayName = [[GuiXmlParser stripSpecialAffixesFromString: name] retain];
    _services = [NLServiceList new];
    _comms = [comms retain];
    
#if DEBUG
    //**/NSLog( @"Room created: %@ (%08X)", _displayName, self );
#endif
  }

  return self;
}

// Execute a macro in the context of the current room
- (NLService *) executeMacro: (NSString *) macroName
{
  return [self executeMacro: macroName returnExecutionDelay: NULL];
}

- (NLService *) executeMacro: (NSString *) macroName returnExecutionDelay: (NSTimeInterval *) pDelay
{
  return [self executeMacroString: [_macros objectForKey: macroName] returnExecutionDelay: pDelay];
}

- (NLService *) executeMacroString: (NSString *) macroString
{
  return [self executeMacroString: macroString returnExecutionDelay: NULL];
}

- (NLService *) executeMacroString: (NSString *) macroString returnExecutionDelay: (NSTimeInterval *) pDelay;
{
  NLService *newService = nil;
  NSTimeInterval delay = 0;

#if !defined(DEMO_BUILD)
  if (macroString != nil)
  {
    [_pcomms send: [macroString stringByAppendingFormat: @",{{NS_CUR_ROOM=%@}}", _serviceName] to: nil];
    if ([macroString hasPrefix: @"MACRO {{"] && [macroString hasSuffix: @"}}"])
      macroString = [macroString substringWithRange: NSMakeRange( 8, [macroString length] - 10 )];
    
    NSRange foundCmd = [macroString rangeOfString: @"~UI#CHANGE_SCREEN " options: NSBackwardsSearch];
    
    if (foundCmd.length > 0)
    {
      NSRange foundTarget = [macroString rangeOfString: @"#@" options: NSBackwardsSearch range: NSMakeRange( 0, foundCmd.location )];
      
      if (foundTarget.length > 0)
      {
        NSString *target = [macroString substringWithRange: NSMakeRange( foundTarget.location + 2, foundCmd.location - (foundTarget.location + 2) )];
        
        if ([target compare: @"All" options: NSCaseInsensitiveSearch] == NSOrderedSame ||
            [target compare: @"NS_CUR_ROOM" options: NSCaseInsensitiveSearch] == NSOrderedSame ||
            [target compare: _serviceName options: NSCaseInsensitiveSearch] == NSOrderedSame ||
            [target compare: [NSString stringWithFormat: @"%@ TL UI", _serviceName] 
                    options: NSCaseInsensitiveSearch] == NSOrderedSame)
        {
          // We have found a CHANGE_SCREEN command applicable to this user interface
          NSString *screenType = [macroString substringFromIndex: foundCmd.location + foundCmd.length];
          NSRange endMarker = [screenType rangeOfString: @"|"];
          
          if (endMarker.length > 0)
            screenType = [screenType substringToIndex: endMarker.location];
          
          NSRange comma = [screenType rangeOfString: @","];
          NSUInteger serviceCount = [_services countOfList];
          NSUInteger i;
          
          if (comma.length > 0)
          {
            NSString *screenName = [screenType substringFromIndex: comma.location + 1];
            
            if ([screenName hasPrefix: @"{{"] && [screenName hasSuffix: @"}}"])
              screenName = [screenName substringWithRange: NSMakeRange( 2, [screenName length] - 4 )];
            
            for (i = 0; i < serviceCount; ++i)
            {
              NLService *service = [_services serviceAtIndex: i];
              
              if ([service.displayName compare: screenName options: NSCaseInsensitiveSearch] == NSOrderedSame ||
                  [service.serviceName compare: screenName options: NSCaseInsensitiveSearch] == NSOrderedSame)
              {
                newService = service;
                break;
              }
            }
            
            if (newService == nil)
              screenType = [screenType substringToIndex: comma.location];
          }
          
          if (newService == nil)
          {
            if ([screenType hasPrefix: @"{{"] && [screenType hasSuffix: @"}}"])
              screenType = [screenType substringWithRange: NSMakeRange( 2, [screenType length] - 4 )];
            // The following is in the Flash version, but shouldn't be here because the
            // service names retain these suffices (whereas the Flash screen names do not).
            //if ([screenType hasSuffix: @"-IR"] || [screenType hasSuffix: @"-SERIAL"])
            //  screenType = [screenType substringToIndex: [screenType rangeOfString: @"-" options: NSBackwardsSearch].location];
            
            if ([screenType isEqualToString: @"currentSourceType"] || [[NLSource sourceControlTypes] containsObject: screenType])
              screenType = @"Audio";
            else
            {
              NSArray *sources = _sources.sources;
              NSUInteger sourceCount = [sources count];
              
              for (i = 0; i < sourceCount; ++i)
              {
                NLSource *source = [sources objectAtIndex: i];
                
                if ([source.sourceControlType isEqualToString: screenType])
                {
                  screenType = @"Audio";
                  break;
                }
              }
            }
            
            for (i = 0; i < serviceCount; ++i)
            {
              NLService *service = [_services serviceAtIndex: i];
              
              if ([service.serviceType compare: screenType options: NSCaseInsensitiveSearch] == NSOrderedSame)
              {
                newService = service;
                break;
              }
            }
            
            if (newService == nil)
            {
              newService = [[[NLService alloc]
                             initWithServiceData: [NSDictionary dictionaryWithObjectsAndKeys: 
                                                   screenType, @"id", @"CHANGE_SCREEN", @"type", nil]
                             room: self comms: _comms] autorelease];
            }
          }
          
          if (pDelay != NULL)
          {
            NSRange delayStringPos = [macroString rangeOfString: @"#DELAY " options: NSCaseInsensitiveSearch];
            
            while (delayStringPos.location < foundCmd.location)
            {
              NSScanner *scanner = [NSScanner scannerWithString: [macroString substringFromIndex: NSMaxRange( delayStringPos )]];
              NSInteger delayItem;
              
              [scanner setCharactersToBeSkipped: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
              if ([scanner scanInteger: &delayItem])
                delay += delayItem;
              delayStringPos = [macroString rangeOfString: @"#DELAY " options: NSCaseInsensitiveSearch
                                                    range: NSMakeRange( NSMaxRange( delayStringPos ),
                                                                       [macroString length] - NSMaxRange( delayStringPos ) )];
            }
            delay /= 1000;
          }
        }
      }
    }
  }
#endif
  
  if (pDelay != NULL)
    *pDelay = delay;

  return newService;
}

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects
{
  NSString *macrosString = nil;
  
  if ((statusMask & JSON_MACROS) != 0)
  {
    for (NSString *name in [_macros allKeys])
    {
      if (macrosString == nil)
        macrosString = [NSString stringWithFormat: @"[\"%@\"", [name javaScriptEscapedString]];
      else
        macrosString = [macrosString stringByAppendingFormat: @", \"%@\"", [name javaScriptEscapedString]];
    }
  }

  if (macrosString == nil)
    macrosString = @"[]";
  else
    macrosString = [macrosString stringByAppendingString: @"]"];

  return [NSString stringWithFormat: @"{ displayName: \"%@\", serviceName: \"%@\", services: %@, "
          "sources: %@, zones: %@, renderer: %@, macros: %@, videoServiceName: \"%@\" }",
          [_displayName javaScriptEscapedString], [_serviceName javaScriptEscapedString], 
          (_services == nil)?@"[]":[_services jsonStringForStatus: statusMask withObjects: withObjects],
          (_sources == nil)?@"[]":[_sources jsonStringForStatus: statusMask withObjects: withObjects],
          (_zones == nil)?@"[]":[_zones jsonStringForStatus: statusMask withObjects: withObjects],
          (_renderer == nil)?@"null":[_renderer jsonStringForStatus: statusMask withObjects: withObjects],
          macrosString, (_videoServiceName == nil)?@"":[_videoServiceName javaScriptEscapedString]];
}

- (void) dealloc
{
#if DEBUG
  //**/NSLog( @"Room destroyed: %@ (%08X)", _displayName, self );
#endif
  [_serviceName release];
  [_displayName release];
  [_services release];
  [_sources release];
  [_zones release];
  [_macros release];
  
  // Make sure renderer is nil before releasing it so that subsequent calls to room.renderer
  // in other dealloc routines don't get returned an invalid value.
  NLRenderer *renderer = _renderer;
  
  _renderer = nil;
  [renderer release];
  [_videoServiceName release];
  [_comms release];
  [super dealloc];
}

@end
