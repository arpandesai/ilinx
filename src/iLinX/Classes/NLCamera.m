//
//  NLCamera.m
//  iLinX
//
//  Created by mcf on 29/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLCamera.h"
#import "GuiXmlParser.h"
#import "JavaScriptSupport.h"

// Time to wait before giving up on fetching an image
#define URL_FETCH_TIMEOUT 20

// Time to wait when sending a fire-and-forget command
#define URL_REQUEST_TIMEOUT 0.3

static NSMutableDictionary *_allCameras;

@interface NLCamera ()

- (NLCamera *) initWithCameraData: (NSDictionary *) data;
- (void) addControls: (NSDictionary *) data withBaseAddress: (NSURL *) addr;
- (void) addPresets: (NSDictionary *) data withBaseAddress: (NSURL *) addr;
- (void) requestURL: (NSURL *) url;
- (void) fetchImage;
- (void) resetRefreshTimer;
- (void) refreshTimerFired: (NSTimer *) timer;
- (void) notifyDelegates;
- (void) stopRefreshing;

- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response;
- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) data;
- (void) connectionDidFinishLoading: (NSURLConnection *) connection;
- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error;

@end


@implementation NLCamera

@synthesize
  displayName = _displayName,
  serviceName = _serviceName,
  image = _image,
  presetNames = _presetNames;

+ (NLCamera *) cameraWithCameraData: (NSDictionary *) data
{
  NSString *name = [data objectForKey: @"id"];
  NLCamera *newCamera;
  
  if (_allCameras == nil)
    _allCameras = [NSMutableDictionary new];
  
  if (name == nil)
    newCamera = nil;
  else
  {
    newCamera = [_allCameras objectForKey: [data objectForKey: name]];
    if (newCamera == nil)
    {
      newCamera = [[NLCamera alloc] initWithCameraData: data];
      [_allCameras setObject: newCamera forKey: name];
      [newCamera release];
    }
  }
  
  return newCamera;
}

+ (void) flushCameraCache
{
  [_allCameras release];
  _allCameras = nil;
}

- (void) addDelegate: (id<NLCameraDelegate>) delegate
{
  if ([_delegates count] == 0)
    [self resetRefreshTimer];

  [_delegates addObject: delegate];
}

- (void) removeDelegate: (id<NLCameraDelegate>) delegate
{
  NSUInteger oldCount = [_delegates count];
  
  if (oldCount > 0)
  {
    [_delegates removeObject: delegate];
    if ([_delegates count] == 0)
      [self stopRefreshing];
  }  
}

- (NSTimeInterval) refreshInterval
{
  return _refreshInterval;
}

- (void) setRefreshInterval: (NSTimeInterval) interval
{
  if (interval != _refreshInterval)
  {
    _refreshInterval = interval;
    [self resetRefreshTimer];
  }
}

- (NSUInteger) capabilities
{
  NSUInteger capabilities = 0;
  
  if (_up != nil && _down != nil)
    capabilities |= NLCAMERA_CAPABILITY_UP_DOWN;
  if (_left != nil && _right != nil)
    capabilities |= NLCAMERA_CAPABILITY_LEFT_RIGHT;
  if (_centre != nil)
    capabilities |= NLCAMERA_CAPABILITY_CENTRE;
  if (_zoomIn != nil && _zoomOut != nil)
    capabilities |= NLCAMERA_CAPABILITY_ZOOM;

  return capabilities;
}

- (void) panUp
{
  [self requestURL: _up];
}

- (void) panDown
{
  [self requestURL: _down];
}

- (void) panLeft
{
  [self requestURL: _left];
}

- (void) panRight
{
  [self requestURL: _right];
}

- (void) recentre
{
  [self requestURL: _centre];
}

- (void) zoomIn
{
  [self requestURL: _zoomIn];
}

- (void) zoomOut
{
  [self requestURL: _zoomOut];
}

- (void) selectPreset: (NSUInteger) presetNumber
{
  if (presetNumber < [_presetURLs count])
    [self requestURL: [_presetURLs objectAtIndex: presetNumber]];
}

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects
{
  NSString *result = [NSString stringWithFormat: @"{ displayName: \"%@\", serviceName: \"%@\", imageURL: \"%@\", "
                      "upURL: \"%@\", downURL: \"%@\", leftURL: \"%@\", rightURL: \"%@\", "
                      "centerURL: \"%@\", zoomInURL: \"%@\", zoomOutURL: \"%@\", presets: [",
                      [_displayName javaScriptEscapedString], [_serviceName javaScriptEscapedString], 
                      _imageURL, _up, _down, _left, _right, _centre, _zoomIn, _zoomOut];
  NSInteger count = [_presetNames count];
  
  for (NSInteger i = 0; i < count; ++i)
  {
    result = [result stringByAppendingFormat: @"%@{ name: \"%@\", URL: \"%@\" }",
              (i == 0)?@"":@", ", [[_presetNames objectAtIndex: i] javaScriptEscapedString],
              [_presetURLs objectAtIndex: i]];
  }
  
  return [result stringByAppendingString: @"] }"];
}

- (NLCamera *) initWithCameraData: (NSDictionary *) data
{
  NSString *addr = [data objectForKey: @"ip"];
  NSString *port = [data objectForKey: @"port"];
  NSString *imagePath = [data objectForKey: @"image"];
  
  _presetNames = [NSMutableArray new];
  _presetURLs = [NSMutableArray new];
  _delegates = [NSMutableSet new];

  if (addr == nil)
    _refreshInterval = 0;
  else
  {
    NSURL *addrURL;
    
    addr = [NSString stringWithFormat: @"http://%@", addr];
    
    if (port != nil && ![port isEqualToString: @"80"])
      addr = [NSString stringWithFormat: @"%@:%@", addr, port];
    addrURL = [NSURL URLWithString: addr];
    _imageURL = [[NSURL URLWithString: imagePath relativeToURL: addrURL] retain];
    _serviceName = [[data objectForKey: @"id"] retain];
    _displayName = [[GuiXmlParser stripSpecialAffixesFromString: _serviceName] retain];
    
    NSArray *children = [data objectForKey: @"#children"];
    NSUInteger i;
    
    for (i = 0; i < [children count]; ++i)
    {
      NSDictionary *child = [children objectAtIndex: i];
      NSString *type = [child objectForKey: @"#elementName"];
      
      if ([type isEqualToString: @"controls"])
        [self addControls: child withBaseAddress: addrURL];
      else if ([type isEqualToString: @"presets"])
        [self addPresets: child withBaseAddress: addrURL];
    }
    
    _refreshInterval = 1.0;
  }
  
  return self;
}

- (void) addControls: (NSDictionary *) data withBaseAddress: (NSURL *) addr
{
  NSArray *children = [data objectForKey: @"#children"];
  NSUInteger i;
  
  for (i = 0; i < [children count]; ++i)
  {
    NSDictionary *child = [children objectAtIndex: i];
    NSString *type = [child objectForKey: @"#elementName"];
    NSString *command = [child objectForKey: @"url"];
    NSURL **pItem;
    
    if (command != nil && [command length] > 0)
    {
      if ([type isEqualToString: @"up"])
        pItem = &_up;
      else if ([type isEqualToString: @"dn"])
        pItem = &_down;
      else if ([type isEqualToString: @"left"])
        pItem = &_left;
      else if ([type isEqualToString: @"right"])
        pItem = &_right;
      else if ([type isEqualToString: @"center"])
        pItem = &_centre;
      else if ([type isEqualToString: @"plus"])
        pItem = &_zoomIn;
      else if ([type isEqualToString: @"minus"])
        pItem = &_zoomOut;
      else
        pItem = NULL;
      
      if (pItem != NULL)
        *pItem = [[NSURL URLWithString: command relativeToURL: addr] retain];
    }
  }
}

- (void) addPresets: (NSDictionary *) data withBaseAddress: (NSURL *) addr
{
  NSArray *children = [data objectForKey: @"#children"];
  NSUInteger i;
  
  for (i = 0; i < [children count]; ++i)
  {
    NSDictionary *child = [children objectAtIndex: i];
    NSString *type = [child objectForKey: @"#elementName"];
    
    if ([type isEqualToString: @"preset"])
    {
      NSString *name = [child objectForKey: @"display"];
      NSString *command = [child objectForKey: @"command"];
      
      if (name != nil && [name length] > 0 && command != nil && [command length] > 0)
      {
        [_presetNames addObject: name];
        [_presetURLs addObject: [NSURL URLWithString: command relativeToURL: addr]];
      }
    }
  }
}

- (void) requestURL: (NSURL *) url
{
  if (url != nil)
  {
    NSString *urlString = [url absoluteString];
    NSURL *randomURL;

    if ([urlString rangeOfString: @"?"].length == 0)
      randomURL = [NSURL URLWithString: [urlString stringByAppendingFormat: @"?random=%u", _random++]];
    else
      randomURL = [NSURL URLWithString: [urlString stringByAppendingFormat: @"&random=%u", _random++]];

    NSURLRequest *request = [NSURLRequest requestWithURL: randomURL
                                             cachePolicy: NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                         timeoutInterval: URL_REQUEST_TIMEOUT];

    [NSURLConnection connectionWithRequest: request delegate: nil];
  }
}

- (void) fetchImage
{
  if (_imageConnection == nil && _imageURL != nil)
  {
    NSString *urlString = [_imageURL absoluteString];
    NSURL *randomURL;
    
    if ([urlString rangeOfString: @"?"].length == 0)
      randomURL = [NSURL URLWithString: [urlString stringByAppendingFormat: @"?random=%u", _random++]];
    else
      randomURL = [NSURL URLWithString: [urlString stringByAppendingFormat: @"&random=%u", _random++]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL: randomURL
                                             cachePolicy: NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                         timeoutInterval: URL_FETCH_TIMEOUT];

    _imageConnection = [[NSURLConnection connectionWithRequest: request delegate: self] retain];
  }
}

- (void) resetRefreshTimer
{
  [self fetchImage];
  if (_refreshTimer != nil)
    [_refreshTimer invalidate];
  if (_refreshInterval <= 0)
    _refreshTimer = nil;
  else
  {
    _refreshTimer = [NSTimer
                     scheduledTimerWithTimeInterval: _refreshInterval target: self
                     selector: @selector(refreshTimerFired:) userInfo: nil repeats: TRUE];
  }
}

- (void) refreshTimerFired: (NSTimer *) timer
{
  [self fetchImage];
}

- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response
{
  if (connection == _imageConnection)
  {
    //NSString *mime = response.MIMEType;
    //NSURL *url = response.URL;

    // If it returns a not found type response, treat as a failure
    
    if ([response.MIMEType rangeOfString: @"image"].length == 0)
    {
      [connection cancel];
      [self connection: connection didFailWithError: nil];
    }
  }  
}

- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) data
{
  if (connection == _imageConnection)
  {
    if (_imageData == nil)
      _imageData = [data mutableCopy];
    else
      [_imageData appendData: data]; 
  }
}

- (void) connectionDidFinishLoading: (NSURLConnection *) connection
{
  if (connection == _imageConnection)
  {
    if (_imageData != nil)
    {
      //const void *pBytes = [_imageData bytes];

      [_image release];
      _image = [[UIImage imageWithData: _imageData] retain];
      [_imageData release];
      _imageData = nil;
      [self notifyDelegates];
    }
    
    [_imageConnection release];
    _imageConnection = nil;
  }
}

- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error
{
  if (connection == _imageConnection)
  {
    [_imageData release];
    _imageData = nil;
    [_imageConnection release];
    _imageConnection = nil;
  }
}

- (void) stopRefreshing
{
  if (_refreshTimer != nil)
  {
    [_refreshTimer invalidate];
    _refreshTimer = nil;
  }
  
  if (_imageConnection != nil)
  {
    [_imageConnection cancel];
    [self connection: _imageConnection didFailWithError: nil];
  }
}

- (void) notifyDelegates
{
  NSSet *delegates = [NSSet setWithSet: _delegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<NLCameraDelegate> delegate;
  
  while ((delegate = [enumerator nextObject]))
    [delegate camera: self hasNewImage: _image];
}

- (void) dealloc
{
  [self stopRefreshing];
  [_serviceName release];
  [_displayName release];
  [_image release];
  [_imageURL release];
  [_up release];
  [_down release];
  [_left release];
  [_right release];
  [_centre release];
  [_zoomIn release];
  [_zoomOut release];
  [_presetNames release];
  [_presetURLs release];
  [_delegates release];
  [super dealloc];
}

@end
