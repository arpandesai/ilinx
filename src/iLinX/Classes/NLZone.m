//
//  NLZone.m
//  iLinX
//
//  Created by mcf on 12/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLZone.h"
#import "GuiXmlParser.h"
#import "JavaScriptSupport.h"

@implementation NLZone

@synthesize
  serviceName = _serviceName,
  displayName = _displayName;

- (id) initWithServiceName: (NSString *) serviceName
{
  if (self = [super init])
  {
    _serviceName = [serviceName retain];
    if ([_serviceName compare: @"Audio_Renderers" options: NSCaseInsensitiveSearch] == NSOrderedSame)
      _displayName = [NSLocalizedString( @"All Rooms", @"Name of all room multi-room" ) retain];
    else
      _displayName = [[GuiXmlParser stripSpecialAffixesFromString: _serviceName] retain];
  }
  
  return self;
}

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects
{
  return [NSString stringWithFormat: @"{ displayName: \"%@\", serviceName: \"%@\", audioSessionName: \"%@\" }",
          [_displayName javaScriptEscapedString], [_serviceName javaScriptEscapedString], 
          [self.audioSessionName javaScriptEscapedString]];
}

- (NSString *) audioSessionName
{
  return [NSString stringWithFormat:
          NSLocalizedString( @"%@ MultiRoom", @"Name of audio session associated with a given multi-room" ), [self displayName]];
}

- (void) dealloc
{
  [_serviceName release];
  [_displayName release];
  [super dealloc];
}

@end
