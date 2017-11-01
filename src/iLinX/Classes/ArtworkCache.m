//
//  ArtworkCache.m
//  iLinX
//
//  Created by mcf on 18/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "ArtworkCache.h"
#import "ArtworkRequest.h"
#import "NLSource.h"

#define URL_FETCH_TIMEOUT 10

@interface ArtworkCacheItem : NSObject
{
@public
  NSString *_tag;
  NSMutableDictionary *_matches;
}

- (id) initWithTag: (NSString *) tag;

@end

@implementation ArtworkCacheItem

- (id) initWithTag: (NSString *) tag
{
  if (self = [super init])
  {
    _tag = [tag retain];
    _matches = [NSMutableDictionary new];
  }
  
  return self;
}

- (void) dealloc
{
  [_tag release];
  [_matches release];
  [super dealloc];
}

@end

@interface ArtworkCache ()

- (NSArray *) findMatchesForSource: (NLSource *) source item: (NSDictionary *) item
                         matchTree: (ArtworkCacheItem *) matchTree matches: (NSMutableArray *) matches;

- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response;
- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) data;
- (void) connectionDidFinishLoading: (NSURLConnection *) connection;
- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error;

@end

@implementation ArtworkCache

@synthesize
  artworkURL = _artworkURL;

- (id) initWithArtworkURL: (NSURL *) artworkURL
{
  if (self = [super init])
  {
    _artworkURL = [artworkURL retain];
    
    NSURLRequest *request = [NSURLRequest requestWithURL: _artworkURL
                                             cachePolicy: NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval: URL_FETCH_TIMEOUT];
    
    _connection = [[NSURLConnection alloc] initWithRequest: request delegate: self];
    _pendingRequests = [NSMutableArray new];
  }
  
  return self;
}

- (void) addRequest: (ArtworkRequest *) request
{
  if (_pendingRequests != nil)
    [_pendingRequests addObject: request];
  else
    [request startSearch: self];
}

- (NSArray *) findMatchesForSource: (NLSource *) source item: (NSDictionary *) item
{
  NSMutableArray *matches = [NSMutableArray arrayWithCapacity: 4];

  if (_matchTree != nil)
    [self findMatchesForSource: source item: item matchTree: _matchTree matches: matches];
  
  return matches;
}

- (NSArray *) findMatchesForSource: (NLSource *) source item: (NSDictionary *) item
                         matchTree: (ArtworkCacheItem *) matchTree matches: (NSMutableArray *) matches
{
  NSString *tag = matchTree->_tag;
  NSString *value;
  NSArray *items;
  NSUInteger count;
  NSUInteger i;
  
  if ([tag isEqualToString: @"sourceName"])
    value = source.displayName;
  else if ([tag isEqualToString: @"serviceName"])
    value = source.serviceName;
  else if ([tag isEqualToString: @"sourceType"])
    value = source.sourceType;
  else if ([tag isEqualToString: @"controlType"])
    value = source.controlType;
  else if ([tag isEqualToString: @"sourceControlType"])
    value = source.sourceControlType;
  else
    value = [item objectForKey: tag];
  
  items = [matchTree->_matches objectForKey: value];
  count = [items count];
  for (i = 0; i < count; ++i)
  {
    id match = [items objectAtIndex: i];
    
    if ([match isKindOfClass: [NSDictionary class]])
      [matches addObject: match];
    else
      [self findMatchesForSource: source item: item matchTree: match matches: matches];
  }
  
  items = [matchTree->_matches objectForKey: @""];
  count = [items count];
  for (i = 0; i < count; ++i)
  {
    id match = [items objectAtIndex: i];
    
    if ([match isKindOfClass: [NSDictionary class]])
      [matches addObject: match];
    else
      [self findMatchesForSource: source item: item matchTree: match matches: matches];
  }
  
  return matches;
}

- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response
{
  if (connection == _connection)
  {
    if ([response.MIMEType rangeOfString: @"text/xml"].length == 0)
    {
      [connection cancel];
      [self connection: connection didFailWithError: nil];
    }
  }
}

- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) data
{
  if (connection == _connection)
  {
    if (_data == nil)
      _data = [data mutableCopy];
    else
      [_data appendData: data];
  }
}

- (void) connectionDidFinishLoading: (NSURLConnection *) connection
{
  if (connection == _connection)
  {
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData: _data];
    
    // Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
    [parser setDelegate: self];
    [parser setShouldProcessNamespaces: NO];
    [parser setShouldReportNamespacePrefixes: NO];
    [parser setShouldResolveExternalEntities: NO];

    [parser parse];

    [_data release];
    _data = nil;
    [_connection release];
    _connection = nil;
    [parser release];
    [_gallery release];
    _gallery = nil;
    [_currentMatch release];
    _currentMatch = nil;
    [_buildStack release];
    _buildStack = nil;
    
    NSUInteger count = [_pendingRequests count];
    NSUInteger i;
    
    for (i = 0; i < count; ++i)
      [(ArtworkRequest *) [_pendingRequests objectAtIndex: i] startSearch: self];
    
    [_pendingRequests release];
    _pendingRequests = nil;
  }
}

- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error
{
  if (connection == _connection)
  {
    [_data release];
    _data = nil;
    [_connection release];
    _connection = nil;

    NSUInteger count = [_pendingRequests count];
    NSUInteger i;
    
    for (i = 0; i < count; ++i)
      [(ArtworkRequest *) [_pendingRequests objectAtIndex: i] startSearch: self];
    
    [_pendingRequests release];
    _pendingRequests = nil;
  }
}

- (void) parser: (NSXMLParser *) parser didStartElement: (NSString *) elementName 
   namespaceURI: (NSString *) namespaceURI qualifiedName: (NSString *) qName attributes: (NSDictionary *) attributeDict
{
  if (qName != nil)
    elementName = qName;
    
  if ([elementName isEqualToString: @"gallery"])
  {
    _gallery = [NSMutableDictionary new];
  }
  else if ([elementName isEqualToString: @"art"])
  {
    _buildStack = [NSMutableArray new];
  }
  else if ([elementName isEqualToString: @"check"])
  {
    NSString *tag = [attributeDict objectForKey: @"tag"];

    if (tag != nil)
    {
      _currentMatch = [[ArtworkCacheItem alloc] initWithTag: tag];
      [_buildStack addObject: _currentMatch];
      [_currentMatch release];
      _currentMatch = nil;
    }
  }
  else if ([elementName isEqualToString: @"value"])
  {
    [_buildStack addObject: attributeDict];
    [_currentMatch release];
    _currentMatch = nil;
    [_text release];
    _text = [@"" retain];
  }
  else if ([elementName isEqualToString: @"image"])
  {
    NSString *href = [attributeDict objectForKey: @"href"];

    if (href != nil)
    {
      if (_buildStack == nil)
      {
        if (_gallery != nil)
        {
          // Gallery image
          NSString *idStr = [attributeDict objectForKey: @"id"];
      
          if (idStr != nil)
            [_gallery setObject: attributeDict forKey: idStr];
        }
      }
      else
      {
        NSDictionary *data = attributeDict;
        NSString *offset = [attributeDict objectForKey: @"offset"];
        
        if ([href hasPrefix: @"#"])
          data = [_gallery objectForKey: [href substringFromIndex: 1]];

        if (offset != nil && 
            ([data objectForKey: @"itemx"] == nil ||
             [data objectForKey: @"itemy"] == nil))
          data = nil;
          
        if (data != nil)
        {
          if (offset == nil || data == attributeDict)
            [data retain];
          else
          {
            data = [data mutableCopy];
            [(NSMutableDictionary *) data setObject: offset forKey: @"offset"];
          }
          _currentImage = data;
        }
      }
    }
  }
}

- (void) parser: (NSXMLParser *) parser didEndElement: (NSString *) elementName
   namespaceURI: (NSString *) namespaceURI qualifiedName: (NSString *) qName
{     
  if (qName)
    elementName = qName;

  if ([elementName isEqualToString: @"extraArtwork"])
  {
    [_gallery release];
    _gallery = nil;
  }
  else if ([elementName isEqualToString: @"art"])
  {
    _matchTree = _currentMatch; 
    _currentMatch = nil;
    [_currentImage release];
    _currentImage = nil;
    [_buildStack release];
    _buildStack = nil;
  }
  else if ([elementName isEqualToString: @"check"])
  {
    _currentMatch = [[_buildStack lastObject] retain];
    [_buildStack removeLastObject];
  }
  else if ([elementName isEqualToString: @"value"])
  {
    if (_buildStack != nil && [_buildStack count] > 0)
    {
      NSDictionary *currentValueData = [_buildStack lastObject];
      BOOL indexed = NO;
      NSArray *matches;
      NSString *match;
      id item;
      
      [_buildStack removeLastObject];

      if (_currentMatch != nil)
        item = _currentMatch;
      else
        item = _currentImage;
      
      match = [currentValueData objectForKey: @"match"];
      if (match != nil)
        matches = [NSArray arrayWithObject: match];
      else
      {
        NSString *separator = [currentValueData objectForKey: @"separator"];
        
        if (separator == nil)
        {
          if ([[currentValueData objectForKey: @"matchany"] isEqualToString: @"yes"])
            matches = [NSArray arrayWithObject: @""];
          else
            matches = nil;
        }
        else
        {
          match = [currentValueData objectForKey: @"matchanyof"];
          if (match != nil)
            matches = [match componentsSeparatedByString: separator];
          else if ([[currentValueData objectForKey: @"matchindexlist"] isEqualToString: @"yes"] && item == _currentImage &&
                   [_currentImage objectForKey: @"itemx"] != nil && [_currentImage objectForKey: @"itemy"] != nil)
          {
            matches = [_text componentsSeparatedByString: separator];
            indexed = YES;
          }
          else
            matches = nil;
        }
      }
      
      ArtworkCacheItem *currentCheck = [_buildStack lastObject];
      NSUInteger count = [matches count];
      NSUInteger i;
      
      for (i = 0; i < count; ++i)
      {
        NSString *value = [[matches objectAtIndex: i] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSMutableArray *items = [currentCheck->_matches objectForKey: value];
        id itemToInsert;
        
        if (indexed)
        {
          itemToInsert = [NSMutableDictionary dictionaryWithDictionary: _currentImage];
          [itemToInsert setObject: [NSString stringWithFormat: @"%u", i] forKey: @"offset"];
        }
        else
          itemToInsert = item;
        
        if (items != nil)
          [items addObject: itemToInsert];
        else
        {
          items = [NSMutableArray arrayWithObject: itemToInsert];
          [currentCheck->_matches setObject: items forKey: value];
        }
      }
    }

    [_currentMatch release];
    _currentMatch = nil;
    [_currentImage release];
    _currentImage = nil;
    [_text release];
    _text = nil;
  }
}

- (void) parser: (NSXMLParser *) parser foundCharacters: (NSString *) string
{
  NSString *oldText = _text;
  
  _text = [[_text stringByAppendingString: string] retain];
  [oldText release];
}

- (void) dealloc
{
  [_artworkURL release];
  [_connection release];
  [_data release];
  [_matchTree release];
  [_currentMatch release];
  [_currentImage release];
  [_text release];
  [_pendingRequests release];
  [super dealloc];
}

@end
