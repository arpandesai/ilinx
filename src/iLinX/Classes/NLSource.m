//
//  NLSource.m
//  iLinX
//
//  Created by mcf on 15/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLSource.h"
#import "NLSourceIROnly.h"
#import "NLSourceLocal.h"
#import "NLSourceMediaServerNetStreams.h"
#import "NLSourceTuner.h"
#import "GuiXmlParser.h"
#import "JavaScriptSupport.h"

// If we don't receive a response to our menu list message, assume a comms problem and retry
// after this interval (seconds).  The NetStreams system appears to screw up menu requests
// on a reasonably regular basis (either returning truncated packets or a "menu error"
// response to a perfectly reasonable request), so this retry interval needs to be long
// enough to avoid continually sending multiple requests for the same thing, but short
// enough to avoid a long user interface delay when it does screw up.
#define NO_COMMS_RETRY_INTERVAL 5

// The iPort is VERY slow to respond to menu requests and so for that device we have a much
// longer retry interval.  Otherwise it clogs up the device's queue with requests.
#define NO_COMMS_SLOW_RETRY_INTERVAL 40

static NSString *NO_SOURCE_NAME = @"iLinX-NOSOURCE";
static NLSource *g_noSourceObject = nil;
static NSSet *g_sourceControlTypes = nil;

@interface NLSource ()

- (void) determineSourceControlType;
+ (NSString *) determineSourceControlTypeOf: (NSDictionary *) sourceData;

@end

@implementation NLSource

@synthesize
  isSlowSource = _isSlowSource,
  sourceData = _sourceData;

+ (NLSource *) noSourceObject
{
  if (g_noSourceObject == nil)
  {
    NSDictionary *noSourceData =
    [NSDictionary dictionaryWithObjectsAndKeys:
     NO_SOURCE_NAME, @"serviceName",
     @"0", @"searchable",
     @"NOCTRL", @"controlType",
     @"NOSOURCE", @"sourceType",
     @"NOSOURCE", @"sourceControlType",
     @"none", @"type", nil];
    
    g_noSourceObject = [[NLSource alloc] initWithSourceData: noSourceData comms: nil];
  }
  
  return g_noSourceObject;
}

+ (id) allocSourceWithSourceData: (NSDictionary *) sourceData comms: (NetStreamsComms *) comms
{
  NSString *sourceControlType = [self determineSourceControlTypeOf: sourceData];
  NLSource *newSource;
  
  if ([sourceControlType caseInsensitiveCompare: @"MEDIASERVER"] == NSOrderedSame ||
      [sourceControlType caseInsensitiveCompare: @"VTUNER"] == NSOrderedSame)
    newSource = [NLSourceMediaServerNetStreams alloc];
  else if ([sourceControlType caseInsensitiveCompare: @"TUNER"] == NSOrderedSame ||
           [sourceControlType caseInsensitiveCompare: @"XM TUNER"] == NSOrderedSame ||
           [sourceControlType caseInsensitiveCompare: @"ZTUNER"] == NSOrderedSame)
    newSource = [NLSourceTuner alloc];
  else if ([sourceControlType caseInsensitiveCompare: @"LOCALSOURCE"] == NSOrderedSame ||
           [sourceControlType caseInsensitiveCompare: @"LOCALSOURCE-STREAM"] == NSOrderedSame)
    newSource = [NLSourceLocal alloc];
  else if ([sourceControlType caseInsensitiveCompare: @"TRNSPRT"] == NSOrderedSame ||
           [sourceControlType caseInsensitiveCompare: @"DVD"] == NSOrderedSame ||
           [sourceControlType caseInsensitiveCompare: @"PVR"] == NSOrderedSame)
    newSource = [NLSourceIROnly alloc];
  else
    newSource = [NLSource alloc];

  return [newSource initWithSourceData: sourceData comms: comms];
}

+ (NSSet *) sourceControlTypes
{
  if (g_sourceControlTypes == nil)
  {
    g_sourceControlTypes = [[NSSet setWithObjects:
                             @"NOSOURCE",
                             @"BROWSE",
                             @"TRNSPRT",
                             @"DVD",
                             @"LOCALSOURCE",
                             @"LOCALSOURCE-STREAM",
                             @"MEDIASERVER",
                             @"PVR",
                             @"TUNER",
                             @"VTUNER",
                             @"XM TUNER",
                             @"ZTUNER",
                             nil] retain];
  }

  return g_sourceControlTypes;
}

- (id) initWithSourceData: (NSDictionary *) sourceData comms: (NetStreamsComms *) comms
{
  if (self = [super init])
  {
    _sourceData = [sourceData mutableCopy];
    _comms = comms;//[comms retain];
    [self determineSourceControlType];
  }
  
#if DEBUG
  //**/NSLog( @"Source created: %@ (%08X)", [self displayName], self );
#endif
  return self;
}

- (void) parserFoundTrailingDataOfType: (NSString *) type data: (NSDictionary *) data
{
}

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects
{
  NSString *result = [NSString stringWithFormat: @"{ displayName: \"%@\"", [self displayName]];
  
  for (NSString *key in [_sourceData allKeys])
    result = [result stringByAppendingFormat: @", \"%@\": \"%@\"",
              [key javaScriptEscapedString], [[_sourceData objectForKey: key] javaScriptEscapedString]];
  
  return [result stringByAppendingString: @" }"];
}

- (BOOL) isCurrentSource
{
  return _isCurrentSource;
}

- (void) setIsCurrentSource: (BOOL) isCurrentSource
{
  _isCurrentSource = isCurrentSource;
}

- (NSString *) displayName
{
  if (_displayName == nil)
  {
    _displayName = [[GuiXmlParser stripSpecialAffixesFromString: [_sourceData objectForKey: @"serviceName"]] retain];
  
    if ([_displayName length] == 0 || [_displayName isEqualToString: NO_SOURCE_NAME])
    {
      [_displayName release];
      _displayName = [NSLocalizedString( @"A/V Off", @"Title to show when no source selected" ) retain];
    }
  }
  
  return _displayName;
}

- (NSString *) serviceName
{
  return [_sourceData objectForKey: @"serviceName"];
}

- (NSString *) sourceType
{
  return [_sourceData objectForKey: @"sourceType"];
}

- (NSString *) controlType
{
  return [_sourceData objectForKey: @"controlType"];
}

- (NSString *) sourceControlType
{
  return [_sourceData objectForKey: @"sourceControlType"];
}

- (NSTimeInterval) retryInterval
{
  if (_isSlowSource)
    return NO_COMMS_SLOW_RETRY_INTERVAL;
  else
    return NO_COMMS_RETRY_INTERVAL;
}

- (NLBrowseList *) browseMenu
{
  return nil;
}

- (NSString *) browseRootPath
{
  return @"media";
}

- (NSString *) controlState
{
  return @"PLAY";
}

- (void) determineSourceControlType
{
  NSString *sourceControlType = [_sourceData objectForKey: @"sourceControlType"];
  
  if (sourceControlType == nil)
    [_sourceData setObject: [NLSource determineSourceControlTypeOf: _sourceData] forKey: @"sourceControlType"];
}

+ (NSString *) determineSourceControlTypeOf: (NSDictionary *) sourceData
{
  NSString *sourceControlType = [sourceData objectForKey: @"sourceControlType"];
  
  if (sourceControlType == nil)
  {
    NSString *sourceType = [sourceData objectForKey: @"sourceType"];
    NSString *serviceType = [sourceData objectForKey: @"type"];
    
    // a source type of NOCTRL is for the local source -- find out what type of local source it is
    if ([sourceType isEqualToString: @"NOCTRL"])
    {
      if ([serviceType caseInsensitiveCompare: @"audio/localsource"] == NSOrderedSame)
        sourceControlType = @"LOCALSOURCE";
      else
        sourceControlType = @"LOCALSOURCE-STREAM";
    }
    else if ([sourceType caseInsensitiveCompare: @"multiplexer"] == NSOrderedSame)
      sourceControlType = @"LOCALSOURCE";
    else if ([sourceType caseInsensitiveCompare: @"Generic"] == NSOrderedSame)
    {
      sourceControlType = @"LOCALSOURCE";
      // genericSource = YES;
    }
    else if ([sourceType caseInsensitiveCompare: @"MUX"] == NSOrderedSame)
    {
      // We're an NNP so use the local source screen without the "streaming" label
      sourceControlType = @"LOCALSOURCE";
    }
    else if ([sourceType caseInsensitiveCompare: @"MULTI TUNER"] == NSOrderedSame)
    {
      // We're an NNT so use the multi tuner screen
      sourceControlType = @"TUNER";
    }
    else
    {
      // a source type of HTTP is a media server
      if ([sourceType rangeOfString: @"HTTP" options: NSCaseInsensitiveSearch].length != 0 ||
          [sourceType rangeOfString: @"MEDIASERVER" options: NSCaseInsensitiveSearch].length != 0)
      {
        sourceControlType = @"MEDIASERVER";
        // _root.searchable = [[_sourceData objectForKey: @"searchable"] isEqualToString: @"1"];
      }
      // if it's not a local source or media server, then just take the user to the screen named "sourceType-controlType"
      else if ([sourceType caseInsensitiveCompare: @"SIRIUS"] == NSOrderedSame)
      {
        sourceControlType = @"XM TUNER";
        //currentSourceModifier = @"Sirius";
      }
      else
      {
        sourceControlType = [sourceType uppercaseString];
      }
    }
  }
  
  return sourceControlType;
}

- (void) activate
{
}

- (void) deactivate
{
}

- (NSDictionary *) metadata
{
  return nil;
}

- (NSDictionary *) metadataWithDefault: (NSDictionary *) metadata
{
  return metadata;
}

- (void) setMetadata: (NSDictionary *) metadata
{  
}

- (void) dealloc
{
#if DEBUG
  //**/NSLog( @"Source destroyed: %@ (%08X)", [self displayName], self );
#endif
  [_sourceData release];
  [_displayName release];
  //[_comms release];
  [super dealloc];
}

@end
