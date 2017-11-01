//
//  ArtworkRequest.m
//  iLinX
//
//  Created by mcf on 19/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "ArtworkRequest.h"
#import "ArtworkCache.h"
#import "ConfigManager.h"
#import "ConfigProfile.h"
#import "NLSource.h"
#import "RelativeFileURL.h"

#define URL_FETCH_TIMEOUT 10

static NSURL *g_lastArtworkURL = nil;
static ArtworkCache *g_cache = nil;
static NSMutableDictionary *g_imageCache = nil;

@interface ArtworkRequest ()

- (id) initWithSource: (NLSource *) source item: (NSDictionary *) item
               target: (id) target action: (SEL) action;
- (void) retrieveCurrentImage;
- (UIImage *) getSubImage: (UIImage *) image;
- (void) reportFoundImage: (UIImage *) image;

- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response;
- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) data;
- (void) connectionDidFinishLoading: (NSURLConnection *) connection;
- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error;

@end

@implementation ArtworkRequest

+ (ArtworkRequest *) allocRequestImageForSource: (NLSource *) source item: (NSDictionary *) item 
                                    target: (id) target action: (SEL) action
{
  NSURL *artworkURL = [[ConfigManager currentProfileData] resolvedArtworkURL];  
  ArtworkRequest *request;
  
  if ((artworkURL == nil && g_lastArtworkURL != nil) ||
      ![artworkURL isEqual: g_lastArtworkURL])
  {
    [g_cache release];
    g_cache = nil;
    [g_imageCache release];
    g_imageCache = nil;
  }

  if (g_cache == nil && artworkURL != nil)
  {
    g_cache = [[ArtworkCache alloc] initWithArtworkURL: artworkURL];
    g_imageCache = [NSMutableDictionary new];
  }
  
  if (g_cache == nil)
  {
    request = nil;
    [target performSelector: action withObject: nil];
  }
  else
  {
    request = [[ArtworkRequest alloc] initWithSource: source item: item target: target action: action];
    [g_cache addRequest: request];
  }
  
  return request;
}

+ (void) flushCache
{
  [g_imageCache removeAllObjects];
}

- (id) initWithSource: (NLSource *) source item: (NSDictionary *) item
               target: (id) target action: (SEL) action
{
  if (self = [super init])
  {
    _source = [source retain];
    _item = [item retain];
    _target = target;
    _action = action;
  }
  
  return self;
}

- (void) invalidate
{
  _target = nil;
  _action = nil;
}

- (void) startSearch: (ArtworkCache *) cache
{
  _imagesData = [[cache findMatchesForSource: _source item: _item] retain];
  _currentImage = 0;
  _artworkURL = [cache.artworkURL retain];
  [self retrieveCurrentImage];
}

- (void) retrieveCurrentImage
{
  NSUInteger count = [_imagesData count];
  UIImage *image = nil;
  NSString *href;
  NSURL *url = nil;
  NSString *absoluteString = nil;

  if (_target == nil)
    _currentImage = count;

  while (_currentImage < count)
  {
    href = [[_imagesData objectAtIndex: _currentImage] objectForKey: @"href"];
    
    if (href == nil)
      ++_currentImage;
    else
    {
      NSRange var = [href rangeOfString: @"${"];
      
      while (var.length > 0)
      {
        NSInteger varNameStart = NSMaxRange( var );
        NSInteger endOfString = [href length] - varNameStart;
        NSRange varEnd = [href rangeOfString: @"}" options: 0 range: NSMakeRange( varNameStart, endOfString )];
        
        if (varEnd.length == 0)
          var = [href rangeOfString: @"${" options: 0 range: NSMakeRange( varNameStart, endOfString )];
        else
        {
          NSString *varName = [href substringWithRange: NSMakeRange( varNameStart, varEnd.location - varNameStart )];
          NSString *substitution;
          
          if ([varName isEqualToString: @"sourceName"])
            substitution = _source.displayName;
          else if ([varName isEqualToString: @"serviceName"])
            substitution = _source.serviceName;
          else if ([varName isEqualToString: @"sourceType"])
            substitution = _source.sourceType;
          else if ([varName isEqualToString: @"controlType"])
            substitution = _source.controlType;
          else if ([varName isEqualToString: @"sourceControlType"])
            substitution = _source.sourceControlType;
          else
            substitution = [_item objectForKey: varName];
          
          if (substitution == nil)
            substitution = @"";
          else
          {
            substitution = [substitution stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            substitution = [substitution stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
          }
          
          href = [href stringByReplacingCharactersInRange: NSMakeRange( var.location, NSMaxRange( varEnd ) - var.location )
                                               withString: substitution];
          var = [href rangeOfString: @"${" options: 0 range: NSMakeRange( var.location, [href length] - var.location )];
        }
      }
      
      url = [NSURL URLWithString: href relativeToURL: _artworkURL];
      absoluteString = [url absoluteString];
      
      image = [g_imageCache objectForKey: absoluteString];
      if (image != nil)
      {
        image = [self getSubImage: image];
        if (image == nil)
        {
          url = nil;
          ++_currentImage;
        }
      }
      if (url != nil)
        break;
    }
  }
  
  if (_currentImage >= count)
    [self reportFoundImage: nil];
  else if (image != nil)
    [self reportFoundImage: image];
  else
  {
    NSURLRequest *request = [NSURLRequest requestWithURL: url 
                                             cachePolicy: NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval: URL_FETCH_TIMEOUT];
    
    _currentImageHref = [absoluteString retain];
    _connection = [[NSURLConnection alloc] initWithRequest: request delegate: self];
  }
}

- (void) reportFoundImage: (UIImage *) image
{
  if (_target != nil)
  {
    [_target performSelector: _action withObject: image];
    [self invalidate];
    [_artworkURL release];
    _artworkURL = nil;
  }
}

- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response
{
  if (connection == _connection)
  {
    if ([response.MIMEType rangeOfString: @"image"].length == 0)
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
    UIImage *image = [UIImage imageWithData: _data];

    [g_imageCache setObject: image forKey: _currentImageHref];
    [_data release];
    _data = nil;
    [_connection release];
    _connection = nil;
    [_currentImageHref release];
    _currentImageHref = nil;

    image = [self getSubImage: image];
    if (image != nil)
      [self reportFoundImage: image];
    else
    {
      ++_currentImage;
      [self retrieveCurrentImage];
    }
  }
}

- (UIImage *) getSubImage: (UIImage *) image
{
  NSDictionary *imageMetadata = [_imagesData objectAtIndex: _currentImage];
  NSString *offsetStr = [imageMetadata objectForKey: @"offset"];
  
  if (offsetStr != nil)
  {
    NSString *subImageName = [_currentImageHref stringByAppendingFormat: @"#%@", offsetStr];
    UIImage *cachedSubImage = [g_imageCache objectForKey: subImageName];
    
    if (cachedSubImage != nil)
      image = cachedSubImage;
    else
    {
      NSUInteger offset = [offsetStr integerValue];
      NSUInteger itemx = [[imageMetadata objectForKey: @"itemx"] integerValue];
      NSUInteger itemy = [[imageMetadata objectForKey: @"itemy"] integerValue];
      NSUInteger rows = image.size.height / itemy;
      NSUInteger columns = image.size.width / itemx;
    
      if (offset < rows * columns)
      {
        NSUInteger x = offset % columns;
        NSUInteger y = offset / columns;
        CGImageRef subImage = CGImageCreateWithImageInRect( [image CGImage],
                                                           CGRectMake( itemx * x, itemy * y, itemx, itemy ) );
      
        image = [UIImage imageWithCGImage: subImage];        
        CGImageRelease( subImage );
        [g_imageCache setObject: image forKey: subImageName];
      }
      else
        image = nil;
    }
  }
  
  return image;
}

- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error
{
  if (connection == _connection)
  {
    [_data release];
    _data = nil;
    [_connection release];
    _connection = nil;
    [_currentImageHref release];
    _currentImageHref = nil;
    
    ++_currentImage;
    [self retrieveCurrentImage];
  }
}

- (void) dealloc
{
  [_source release];
  [_item release];
  [_imagesData release];
  [_connection release];
  [_data release];
  [_artworkURL release];
  [super dealloc];
}

@end
