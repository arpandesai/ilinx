//
//  GuiXmlParser.m
//  iLinX
//
//  Created by mcf on 09/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "GuiXmlParser.h"
#import "NLCamera.h"
#import "NLRenderer.h"
#import "NLRoom.h"
#import "NLService.h"
#import "NLServiceList.h"
#import "NLSource.h"
#import "NLSourceList.h"
#import "NLSourceMediaServerITunes.h"
#import "NLZone.h"
#import "NLZoneList.h"

static NSString *ILINX_TIMERS_SERVICE_NAME = @"ilinxtimers";
static NSString *ILINX_ITUNES_LICENCE_KEY = @"licence";
static NSString *ILINX_ITUNES_LIBRARY_KEY = @"library";

@interface GuiXmlParser ()

- (id) init;
- (void) parser: (NSXMLParser *) parser didStartElement: (NSString *) elementName 
   namespaceURI: (NSString *) namespaceURI qualifiedName: (NSString *) qName attributes: (NSDictionary *) attributeDict;
- (void) parserDidStartElement: (NSString *) elementName attributes: (NSDictionary *) attributeDict;
- (void) parser: (NSXMLParser *) parser didEndElement: (NSString *) elementName
   namespaceURI: (NSString *) namespaceURI qualifiedName: (NSString *) qName;
- (void) parser: (NSXMLParser *) parser foundCharacters: (NSString *) string;
- (void) configureITunesLibrary: (NSArray *) configurationData;

@end

@implementation GuiXmlParser

@synthesize delegate = _delegate;

+ (NSString *) stripSpecialAffixesFromString: (NSString *) string
{
  if ([string hasPrefix: @"__"])
  {
    NSRange endUnderscores = [string rangeOfString: @"__" options: 0 range: NSMakeRange( 2, [string length] - 2 )];
    
    if (endUnderscores.length > 0 && NSMaxRange( endUnderscores ) < [string length])
      string = [string substringFromIndex: NSMaxRange( endUnderscores )];
  }

  if ([string hasSuffix: @"__"])
  {
    NSRange endUnderscores = [string rangeOfString: @"__" options: NSBackwardsSearch
                                             range: NSMakeRange( 0, [string length] - 2 )];

    if (endUnderscores.length > 0 && endUnderscores.location > 0)
      string = [string substringToIndex: endUnderscores.location];
  }
  
  return string;
}

- (id) init
{
  if ((self = [super init]) != nil)
  {
    _parseStack = [[NSMutableArray arrayWithCapacity: 10] retain];
    _rooms = [[NSMutableArray arrayWithCapacity: 10] retain];
    _sources = [[NSMutableArray arrayWithCapacity: 10] retain];
    _trailingData = [[NSMutableArray arrayWithCapacity: 10] retain];
    _iTunesLibraries = [[NSMutableDictionary dictionaryWithCapacity: 10] retain];
    [_sources addObject: [NLSource noSourceObject]];
    _parseLevel = 0;
  }

  return self;
}

- (BOOL) parseXMLData: (NSData *) data comms: (NetStreamsComms *) comms
       staticMenuRoom: (NSString *) staticMenuRoom parseError: (NSError **) error
{
  NSXMLParser *parser = [[NSXMLParser alloc] initWithData: data];
  NSError *parseError;
  
  _comms = comms;
  _staticMenuRoom = [staticMenuRoom retain];
  
  // Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
  [parser setDelegate: self];
  
  // Depending on the XML document you're parsing, you may want to enable these features of NSXMLParser.
  [parser setShouldProcessNamespaces: NO];
  [parser setShouldReportNamespacePrefixes: NO];
  [parser setShouldResolveExternalEntities: NO];
  
  [NLCamera flushCameraCache];
  
  [parser parse];
  parseError = [parser parserError];

  if (parseError == nil && _delegate != nil)
  {
    NSUInteger count = [_sources count];
    NSUInteger trailingCount = [_trailingData count];
    NLZoneList *defaultZones = [NLZoneList new];
    NSUInteger i;
    NSUInteger j;
    NSUInteger k;

    [defaultZones addZone: [[[NLZone alloc] initWithServiceName: @"Audio_Renderers"] autorelease]];

    // Convert any sources marked as iTunes sources into the appropriate object type
    
    for (i = 0; i < count; ++i)
    {
      NLSource *source = [_sources objectAtIndex: i];
      NSString *checkName = [[source.serviceName stringByTrimmingCharactersInSet:
                              [NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
      NSDictionary *iTunesLibrary = [_iTunesLibraries objectForKey: checkName];
      
      if (iTunesLibrary != nil)
      {
        NLSourceMediaServerITunes *iTunesSource =
        [NLSourceMediaServerITunes allocSourceWithSourceData: source.sourceData
                                                    libraryId: [iTunesLibrary objectForKey: ILINX_ITUNES_LIBRARY_KEY]
                                                      licence: [iTunesLibrary objectForKey: ILINX_ITUNES_LICENCE_KEY]];
        
        [_sources replaceObjectAtIndex: i withObject: iTunesSource];
        [iTunesSource release];
      }
    }

    // Allow sources to examine the trailing configuration data for further details
    // specific to each source

    for (i = 0; i < trailingCount; ++i)
    {
      NSDictionary *data = [_trailingData objectAtIndex: i];
      
      for (j = 0; j < count; ++j)
      {
        NLSource *source = [_sources objectAtIndex: j];
        
        [source parserFoundTrailingDataOfType: [data objectForKey: @"#elementName"] data: data];
      }
    }
    
    [NLSourceList setMasterSources: _sources];

    for (i = 0; i < [_rooms count]; ++i)
    {
      NLRoom *room = [_rooms objectAtIndex: i];
      
      if (room.renderer != nil)
      {
        if (room.zones == nil)
          room.zones = defaultZones;
        
        if (room.sources == nil)
        {
          NLSourceList *sourceList = [[NLSourceList alloc] initWithRoom: room comms: _comms];
        
          sourceList.sources = _sources;
          room.sources = sourceList;
          [sourceList release];
        }
        else
        {
          // Source definitions in the sources screen are "cut down" relative to the
          // full list at the end, lacking in some important attributes.  So, replace
          // the room-derived source list with one made up of the same sources from
          // the list at the end.
          
          NSMutableArray *sources = [NSMutableArray array];
          
          for (j = 0; j < [room.sources.sources count]; ++j)
          {
            NLSource *roomSource = [room.sources.sources objectAtIndex: j];
            
            for (k = 0; k < [_sources count]; ++k)
            {
              NLSource *source = [_sources objectAtIndex: k];
              
              if ([source.serviceName compare: roomSource.serviceName options: NSCaseInsensitiveSearch] == NSOrderedSame)
              {
                [sources addObject: source];
                break;
              }
            }
          }
          
          room.sources.sources = sources;
        }
      }
      
      if (room.services != nil)
      {
        for (j = 0; j < [room.services.services count]; ++j)
        {
          NLService *service = [room.services serviceAtIndex: j];
          
#if defined(IPAD_BUILD)
          if ([service.identifier isEqualToString: @"iLinX-internal-AudioSettings"])
          {
            // If this room has audio settings, it may also require multiroom and video settings
            // done in this order so that they appear as audio, video, multiroom.

            if ([room.zones countOfList] > 0)
            {
              // Add an extra MultiRoom pseudo-service if MultiRoom is enabled
              
              NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                    NSLocalizedString( @"MultiRoom", "Name of the audio settings option" ), @"name",
                                    @"MultiRoomSettings", @"type",
                                    @"iLinX-internal-MultiRoomSettings", @"serviceName",
                                    @"iLinX-internal-MultiRoomSettings", @"id",
                                    nil];
              NLService *newService = [NLService allocServiceWithServiceData: data room: room comms: _comms];
              [room.services insertService: newService atIndex: j + 1];
              [newService release];
            }
            
            if (room.renderer.videoControls != nil && [room.renderer.videoControls count] > 0)
            {
              // Add an extra video settings pseudo-service if there are video controls
              
              NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                    NSLocalizedString( @"Display Settings", "Name of the display settings option" ), @"name",
                                    @"DisplaySettings", @"type",
                                    @"iLinX-internal-DisplaySettings", @"serviceName",
                                    @"iLinX-internal-DisplaySettings", @"id",
                                    nil];
              NLService *newService = [NLService allocServiceWithServiceData: data room: room comms: _comms];
              
              [room.services insertService: newService atIndex: j + 1];
              [newService release];
            }
          }
#endif

          for (k = 0; k < trailingCount; ++k)
          {
            NSDictionary *data = [_trailingData objectAtIndex: k];
            
            [service parserFoundTrailingDataOfType: [data objectForKey: @"#elementName"] data: data];
          }
        }
      }
      
      if (_staticMenuRooms == nil || [_staticMenuRooms indexOfObject: room.serviceName] != NSNotFound)
        [_delegate parser: self addRoom: room presorted: (_staticMenuRooms != nil)];
    }
    
    [_delegate parser: self addMacros: _macros];
    [defaultZones release];
  }
  
  if (error != NULL)
    *error = parseError;
  
  [parser release];
  
  return (parseError == nil);
}

- (void) parser: (NSXMLParser *) parser didStartElement: (NSString *) elementName 
   namespaceURI: (NSString *) namespaceURI qualifiedName: (NSString *) qName attributes: (NSDictionary *) attributeDict
{
  if (qName)
    elementName = qName;
  
  NSMutableDictionary *newNode = [NSMutableDictionary dictionaryWithDictionary: attributeDict];
  
  [newNode setObject: elementName forKey: @"#elementName"];
  if (_parseLevel > 0)
  {
    NSMutableArray *children = [_currentNode objectForKey: @"#children"];
    
    if (children == nil)
      [_currentNode setObject: [NSMutableArray arrayWithObject: newNode] forKey: @"#children"];
    else
      [children addObject: newNode];
  }

  if (_parseLevel < [_parseStack count])
    [_parseStack replaceObjectAtIndex: _parseLevel withObject: newNode];
  else
    [_parseStack insertObject: newNode atIndex: _parseLevel];
  _currentNode = newNode;
  ++_parseLevel;
  
  if (_buildService != nil)
    [_buildService parserDidStartElement: elementName attributes: attributeDict];
  else
    [self parserDidStartElement: elementName attributes: attributeDict];
}

- (void) parserDidStartElement: (NSString *) elementName attributes: (NSDictionary *) attributeDict
{
  if ([elementName isEqualToString: @"room"])
  {
    NSString *name = [attributeDict objectForKey: @"id"];
    
    if (![name isEqualToString: @"ns-browser"])
      _buildRoom = [[NLRoom alloc] initWithName: name comms: _comms];
  }
  else if ([elementName isEqualToString: @"source"])
  {
    NLSource *source = [NLSource allocSourceWithSourceData: attributeDict comms: _comms];
    
    [_sources addObject: source];
    [source release];
  }
  else if ([elementName isEqualToString: @"avr"])
  {
    NSUInteger count = [_rooms count];
    NSUInteger i;
    
    for (i = 0; i < count; ++i)
    {
      NLRenderer *renderer = ((NLRoom *) [_rooms objectAtIndex: i]).renderer;
      
      if (renderer != nil && [renderer.serviceName compare: [attributeDict objectForKey: @"id"]
                                                   options: NSCaseInsensitiveSearch] == NSOrderedSame)
      {
        _controls = [NSMutableArray arrayWithCapacity: 10];
        renderer.audioControls = _controls;
      }
    }
  }
  else if (_buildRoom != nil)
  {
    BOOL isILinXTimers = ([ILINX_TIMERS_SERVICE_NAME caseInsensitiveCompare:
                           [[attributeDict objectForKey: @"serviceName"]
                            stringByReplacingOccurrencesOfString: @" " withString: @""]] == NSOrderedSame);
    NLService *audioSettingsService = nil;
    
    if ([elementName isEqualToString: @"screen"] && 
     ([[attributeDict objectForKey: @"enabled"] isEqualToString: @"1"] || isILinXTimers))
    {
      NSString *type = [attributeDict objectForKey: @"type"];
      
      // Unfortunately, screens don't translate straightforwardly to services.  There are
      // exceptions:
      // Locations - we handle this elsewhere with the location button
      // Sources - handled within the A/V screen
      // video - handled as settings within the A/V screen
      // Intercom - ignored completely as we can't support this service
      // Audio - name is fiddled to be A/V.
      // For all the rest, they are handled as services, with their id being their name
      
      if (type == nil)
        type = [attributeDict objectForKey: @"id"];
      if (type == nil)
        type = @"unknown";
      
      if ([type isEqualToString: @"video"] || [type isEqualToString: @"Panorama"])
      {
        NSString *videoServiceName = [attributeDict objectForKey: @"serviceName"];

        // Additional info about video controls; record the controls
        // It appears possible for both video and Panorama screens to be defined, so 
        // combine both sets of controls if required.

        _controls = [_buildRoom.renderer.videoControls retain];
        if (_controls == nil)
          _controls = [[NSMutableArray arrayWithCapacity: 10] retain];
        if (videoServiceName != nil && ![videoServiceName isEqualToString: @"undefined"])
          _buildRoom.videoServiceName = videoServiceName;
      }
      else if ([type isEqualToString: @"Zones"])
      {
        // Additional info about groups
        _buildZones = [NLZoneList new];
      }
      else if ([type isEqualToString: @"Sources"])
      {
        // Sources static menu
        NLSourceList *sources = [[NLSourceList alloc] initWithRoom: _buildRoom comms: _comms];
        
        _buildRoom.sources = sources;
        [sources release];
        _buildSources = YES;
      }
      else if ([type isEqualToString: @"Locations"])
      {
        if (_staticMenuRoom != nil && [_buildRoom.serviceName compare: _staticMenuRoom
                                                              options: NSCaseInsensitiveSearch] == NSOrderedSame)
          _staticMenuRooms = [NSMutableArray new];
      }
      else if (!([type isEqualToString: @"Sources"] || [type isEqualToString: @"Intercom"]))
      {
        NSMutableDictionary *serviceData = [attributeDict mutableCopy];
        NSString *name;
        
        if (isILinXTimers)
        {
          name = NSLocalizedString( @"Timers", @"Name of timers service" );
          type = @"Timers";
          [serviceData setObject: type forKey: @"type"];
        }
        else if ([type isEqualToString: @"Audio"])
        {
          NSString *rendererName = [attributeDict objectForKey: @"serviceName"];
          NSString *settingsEnabled = [attributeDict objectForKey: @"settingsEnabled"];
          BOOL enabled = (settingsEnabled == nil || ![settingsEnabled isEqualToString: @"0"]);
          
          name = NSLocalizedString( @"A/V", "Name of the audio/video service" );
          if (rendererName != nil)
          {
            NLRenderer *renderer = [[NLRenderer alloc] initWithName: rendererName room: _buildRoom
                                                    settingsEnabled: enabled comms: _comms];
            
            _buildRoom.renderer = renderer;
            [renderer release];
            
#if defined(IPAD_BUILD)
            if (enabled || _controls != nil)
            {
              // Add an extra Audio Settings pseudo-service
              NSDictionary *audioSettingsData = [NSDictionary dictionaryWithObjectsAndKeys:
                                                 NSLocalizedString( @"Audio Settings", "Name of the audio settings option" ), @"name",
                                                 @"AudioSettings", @"type",
                                                 @"iLinX-internal-AudioSettings", @"serviceName",
                                                 @"iLinX-internal-AudioSettings", @"id",
                                                 nil];
              audioSettingsService = [NLService allocServiceWithServiceData: audioSettingsData 
                                                                       room: _buildRoom comms: _comms];
            }
#endif
            
            if (_controls != nil)
            {									
              renderer.videoControls = _controls;
              [_controls release];
              _controls = nil;
            }
          }
        }
        else
          name = [attributeDict objectForKey: @"id"];        
        if (name == nil)
          name = type;
        
        name = [GuiXmlParser stripSpecialAffixesFromString: name];
        [serviceData setObject: name forKey: @"name"];
        if ([serviceData objectForKey: @"type"] == nil)
          [serviceData setObject: type forKey: @"type"];
        
        _buildService = [NLService allocServiceWithServiceData: serviceData room: _buildRoom comms: _comms];
        [serviceData release];        
        [_buildRoom.services addService: _buildService];
        if (audioSettingsService != nil)
        {
          [_buildRoom.services addService: audioSettingsService];
          [audioSettingsService release];
        }
      }
    }
    else if ([elementName isEqualToString: @"menu"])
    {
      if ([[attributeDict objectForKey: @"enabled"] isEqualToString: @"0"])
      {
        // Menu is disabled, so ignore it.
        if (_buildSources)
        {
          _buildRoom.sources = nil;
          _buildSources = NO;
        }
        else if (_staticMenuRooms != nil && _staticMenuRoom != nil &&
                 [_buildRoom.serviceName compare: _staticMenuRoom options: NSCaseInsensitiveSearch] == NSOrderedSame)
        {
          [_staticMenuRoom release];
          _staticMenuRoom = nil;
          [_staticMenuRooms release];
          _staticMenuRooms = nil;
        }
        else if (_buildZones != nil)
        {
          // Ensure a zero entry list for zones if MultiRoom is disabled
          _buildZones.zones = [NSMutableArray array];
          _buildRoom.zones = _buildZones;
          [_buildZones release];
          _buildZones = nil;
        }
      }
    }
    else if ([elementName isEqualToString: @"item"])
    {
      if (_buildSources)
      {
        NLSource *source = [NLSource allocSourceWithSourceData: attributeDict comms: _comms];
      
        [_buildRoom.sources addSource: source];
        [source release];
      }
      else if (_staticMenuRoom != nil && _staticMenuRooms != nil)
      {
        [_staticMenuRooms addObject: [attributeDict objectForKey: @"roomName"]];
      }
      else if (_buildZones != nil)
      {
        NLZone *zone = [[NLZone alloc] initWithServiceName: [attributeDict objectForKey: @"groupName"]];
        
        [_buildZones addZone: zone];
        [zone release];
      }
    }
    else if (_controls != nil && [elementName isEqualToString: @"control"])
    {
      NSString *title = [attributeDict objectForKey: @"display"];
      
      if (title != nil && [title length] > 0)
        [_controls addObject: attributeDict];
    }
  }
  else if (_controls != nil && [elementName isEqualToString: @"data"])
  {
    NSString *title = [attributeDict objectForKey: @"display"];
    
    if (title != nil && [title length] > 0)
      [_controls addObject: attributeDict];
  }
}

- (void) parser: (NSXMLParser *) parser didEndElement: (NSString *) elementName
   namespaceURI: (NSString *) namespaceURI qualifiedName: (NSString *) qName
{     
  if (qName)
    elementName = qName;

  if (_buildService != nil)
  {
    if ([elementName isEqualToString: @"screen"])
    {
      [_buildService release];
      _buildService = nil;
    }
    else
    {
      [_buildService parserDidEndElement: elementName];
    }
  }
  else if (_buildRoom != nil)
  {
    if ([elementName isEqualToString: @"room"])
    {
      // Finished parsing contents for a room
      
      // Check if we have some video controls that we were never able to tie up with a renderer
      if (_controls != nil)
      {
        [_controls release];
        _controls = nil;
      }
      
      [_rooms addObject: _buildRoom];
      [_buildRoom release];
      _buildRoom = nil;
    }
    else if ([elementName isEqualToString: @"menu"] && _buildSources)
    {
      // Finished parsing the sources for a give room
      _buildSources = NO;
    }
    else if ([elementName isEqualToString: @"screen"])
    {
      if (_staticMenuRooms != nil && _staticMenuRoom != nil)
      {
        // Finished parsing the locations menu for the static menu room
        [_staticMenuRoom release];
        _staticMenuRoom = nil;
      }
      else if (_buildZones != nil)
      {
        // Finished parsing the Zones (multiroom) menu
        _buildRoom.zones = _buildZones;
        [_buildZones release];
        _buildZones = nil;
      }
      else if (_controls != nil)
      {
        // Finished parsing the Video menu
        if (_buildRoom.renderer != nil)
        {
          _buildRoom.renderer.videoControls = _controls;
          [_controls release];
          _controls = nil;
        }
      }
    }
  }
  else if ([elementName isEqualToString: @"macros"])
  {
    NSArray *macrosData = [_currentNode objectForKey: @"#children"];
    NSUInteger count = [macrosData count];
    NSUInteger i;

    _macros = [[NSMutableDictionary dictionaryWithCapacity: count] retain];

    // Iterate over each macro
    for (i = 0; i < count; ++i)
    {
      NSDictionary *macro = [macrosData objectAtIndex: i];
      NSString *description = [[[macro objectForKey: @"desc"]
                                stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
      NSArray *children = [macro objectForKey: @"#children"];
      NSDictionary *child = nil;
      NSInteger j;
      
      // Find the steps section
      for (j = 0; j < [children count]; ++j)
      {
        child = [children objectAtIndex: j];
        if ([[child objectForKey: @"#elementName"] isEqualToString: @"steps"])
          break;
      }
      
      if (j < [children count])
      {
        children = [child objectForKey: @"#children"];

        if ([description isEqualToString: @"ilinx itunes library settings"])
          [self configureITunesLibrary: children];
        else
        {
          NSString *mergedMacro = @"MACRO {{";
        
          for (j = 0; j < [children count]; ++j)
            mergedMacro = [mergedMacro stringByAppendingFormat: @"%@|", [[children objectAtIndex: j] objectForKey: @"data"]];
        
          mergedMacro = [mergedMacro stringByAppendingString: @"}}"];
          [_macros setObject: mergedMacro forKey: [macro objectForKey: @"name"]]; 
        }
      }
    }
  }  
  else if (_parseLevel == 2 &&
           ![elementName isEqualToString: @"rooms"] && ![elementName isEqualToString: @"sources"])
  {
    [_trailingData addObject: _currentNode];
  }
  
  if (--_parseLevel == 0)
    _currentNode = nil;
  else
    _currentNode = [_parseStack objectAtIndex: _parseLevel - 1];
}

- (void) parser: (NSXMLParser *) parser foundCharacters: (NSString *) string
{
  if (_buildService)
    [_buildService parserFoundCharacters: string];
  else
  {
    NSMutableDictionary *textNode = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     @"#TEXT", @"#elementName", string, @"content", nil];
    NSMutableArray *children = [_currentNode objectForKey: @"#children"];
    
    if (children == nil)
      [_currentNode setObject: [NSMutableArray arrayWithObject: textNode] forKey: @"#children"];
    else
      [children addObject: textNode];
  }
}

- (void) configureITunesLibrary: (NSArray *) configurationData
{
  if ([configurationData count] >= 3)
  {
    NSString *source = [[[[configurationData objectAtIndex: 0] objectForKey: @"data"]
                         stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    
    if ([source hasPrefix: @"#@"] && [source hasSuffix: @"#"])
      source = [source substringWithRange: NSMakeRange( 2, [source length] - 3 )];

    [_iTunesLibraries setObject: [NSDictionary dictionaryWithObjectsAndKeys:
                                  [[configurationData objectAtIndex: 1] objectForKey: @"data"], ILINX_ITUNES_LIBRARY_KEY,
                                  [[configurationData objectAtIndex: 2] objectForKey: @"data"], ILINX_ITUNES_LICENCE_KEY, nil]
                         forKey: source];
  }
}

- (void) dealloc
{
  [_parseStack release];
  [_rooms release];
  [_sources release];
  [_trailingData release];
  [_buildRoom release];
  [_buildService release];
  [_staticMenuRoom release];
  [_staticMenuRooms release];
  [_macros release];
  [_iTunesLibraries release];
  [super dealloc];
}

@end
