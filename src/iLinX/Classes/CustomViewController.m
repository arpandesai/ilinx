    //
//  CustomViewController.m
//  iLinX
//
//  Created by mcf on 11/05/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "CustomViewController.h"
#import "ConfigManager.h"
#import "ConfigProfile.h"
#import "ExecutingMacroAlert.h"
#import "JavaScriptSupport.h"
#import "MainNavigationController.h"
#import "NLSourceList.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLServiceList.h"
#import "NLSource.h"
#import "NLSourceList.h"
#import "StandardPalette.h"
#import "SelectItemViewController.h"
#import "SSZipArchive.h"

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#define SITE_LOAD_TIMEOUT 20.0

static NSString * const kEnableSkinKey = @"enableSkinKey";

static NSMutableDictionary *g_customPageCache = nil;
#if 0
static UIWebView *g_preloadedView = nil;
#else
static UIView *g_preloadedView = nil;
#endif
static NLRoomList *g_currentRoomList = nil;

static NSString *kNotificationSkinChanged = @"iLinXSkinChanged";

#define SKIN_STATE_DONE       0
#define SKIN_STATE_PROCESSING 1
#define SKIN_STATE_CHANGED    2
static int g_newSkinState = SKIN_STATE_DONE;

@interface CustomViewController ()

+ (void) threadHandleNewSkin;
+ (BOOL) fetchSkinZipfile: (NSURL *) skinURL;
+ (void) preloadView: (UIWebView *) webView;
+ (NSString *) initialTextForCustomPage: (NSString *) customPage returningURL: (NSURL **) pURL;
- (BOOL) findHideSetting: (NSString *) setting;
- (void) initTitle;
- (NSArray *) parseCommand: (NSString *) command;
- (id) selectItem: (id) item inList: (id<ListDataSource>) list offset: (NSUInteger) offset;
- (NSUInteger) findIndexForItem: (id) item inList: (id<ListDataSource>) list offset: (NSUInteger) offset;
- (NSUInteger) maskFromStatusString: (NSString *) string;
- (void) iLinXSkinChangedNotification: (NSNotification *) notification;

@end

@implementation CustomViewController

@synthesize
#if 0
  view = _page,
#else
  view = _pageParent,
#endif
  title = _title,
  hidesNavigationBar = _hidesNavigationBar,
  hidesToolBar = _hidesToolBar,
  hidesAudioControls = _hidesAudioControls,
  closeMethod = _closeMethod,
  closeTarget = _closeTarget;

+ (NSString *) skinChangedNotificationKey
{
  return kNotificationSkinChanged;
}

+ (void) maybeFetchConfig
{
  if ([[NSUserDefaults standardUserDefaults] boolForKey: kEnableSkinKey])
  {
    @synchronized (self)
    {
      if (g_newSkinState != SKIN_STATE_CHANGED)
      {
        if (g_newSkinState == SKIN_STATE_DONE)
          [self performSelectorInBackground: @selector(threadHandleNewSkin) withObject: nil];
        g_newSkinState = SKIN_STATE_CHANGED;
      }
    }
  }
}

+ (void) threadHandleNewSkin
{
  // New pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  BOOL skinChanged = NO;
  
  while (true)
  {
    @synchronized (self)
    {
      if (g_newSkinState == SKIN_STATE_CHANGED)
        g_newSkinState = SKIN_STATE_PROCESSING;
      else
      {
        g_newSkinState = SKIN_STATE_DONE;
        break;
      }
    }

    // Do we have a skinURL?
    NSURL *skinURL = [ConfigManager currentProfileData].resolvedSkinURL;
    
    if (skinURL == nil)
    {
      // No skinURL, so remove unpacked files
      NSFileManager *fm = [NSFileManager defaultManager];
      NSError *error = nil;
      NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
      NSString *documentsDirectory = [paths objectAtIndex: 0];
      NSString *unpackDirectory = [documentsDirectory stringByAppendingFormat: @"/unpacked"];
      
      if ([fm removeItemAtPath: unpackDirectory error: &error])
      {
        // Removed unpacked folder successfully.  Means that skin has changed from previous
        skinChanged = YES;
      }
      else 
      {
        NSLog( @"Failed to remove %@: %@", unpackDirectory, [error localizedDescription] );
      }
    }
    else
    {
      // Yes, but does it end with a slash?
      NSString *sSkinURL = [skinURL absoluteString];
      
      if ([sSkinURL characterAtIndex: [sSkinURL length] - 1] != '/')
      {
        // Assume URL points to a zipfile and fetch and unpack it
        NSLog( @"Skin URL does not end with '/', assuming it points to a zipfile." );
        if ([self fetchSkinZipfile: skinURL])
          skinChanged = YES;
      }
    }
  }
  
  if (skinChanged)
    [self performSelectorOnMainThread: @selector(postSkinChangedNotification) withObject: nil waitUntilDone: NO];

  // Finished with the pool
  [pool release];
}

+ (void) postSkinChangedNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: kNotificationSkinChanged object: nil];
}

+ (BOOL) fetchSkinZipfile: (NSURL *) skinURL
{
  // Prepare to synchronously fetch the zipfile
  NSURLResponse *response = nil;
  NSError *error = nil;
  NSData *result;
  NSURLRequest *request = [NSMutableURLRequest requestWithURL: skinURL 
                                                  cachePolicy: NSURLRequestReloadRevalidatingCacheData 
                                              timeoutInterval: 5.0];
  BOOL changed = NO;
  
  NSLog( @"Fetching zipfile from %@", [skinURL absoluteString] );
  // Try to fetch the zipfile
  @try
  {
    result = [NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &error];
  }
  @catch (NSException *exception) 
  {
    NSLog( @"Exception fetching zipfile: %@", exception );
  }
  if (result == nil)
  {
    NSLog( @"Error fetching zipfile: %@", [error localizedDescription] );
  }
  else
  {
    // Fetched the zipfile.  Check if it is newer
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString *documentsDirectory = [paths objectAtIndex: 0];
    NSString *filename = [documentsDirectory stringByAppendingPathComponent: @"downloaded.zip"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *unpackDirectory = [documentsDirectory stringByAppendingFormat: @"/unpacked"];
    NSString *unpackDirectoryNew = [documentsDirectory stringByAppendingFormat: @"/unpacked.new"];
    NSDate *localDate;
    NSDate *zipDate;
    
    if (![response isKindOfClass: [NSHTTPURLResponse class]])
      zipDate = nil;
    else
    {
      NSString *lastModified = [[((NSHTTPURLResponse *) response) allHeaderFields] objectForKey: @"Last-Modified"];
      
      if (lastModified == nil)
        zipDate = nil;
      else 
      {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        
        [df setDateFormat: @"EEE, dd MMM yyyy HH:mm:ss zzz"];
        zipDate = [df dateFromString: lastModified];
        if (zipDate == nil)
        {
          [df setDateFormat: @"EEEE, dd-MMM-yy HH:mm:ss zzz"];
          zipDate = [df dateFromString: lastModified];
        }
        if (zipDate == nil)
        {
          [df setDateFormat: @"EEE MMM d HH:mm:ss yyyy"];
          zipDate = [df dateFromString: lastModified];
        }
        [df release];
      }
    }

    if (zipDate == nil)
      localDate = nil;
    else
    {
      if (![fm fileExistsAtPath: filename] || ![fm fileExistsAtPath: unpackDirectory])
        localDate = nil;
      else
      {
        NSDictionary *attrs = [fm attributesOfItemAtPath: filename error: NULL];
        
        localDate = [attrs fileModificationDate];
        if (![zipDate isEqualToDate: localDate])
          localDate = nil;
      }
    }
    
    // ZIP is newer (or at least it might be)
    if (localDate == nil)
    {
      // Save the ZIP
      if (![result writeToFile: filename options: NSDataWritingAtomic error: &error])
        NSLog( @"Failed to save new config to %@: %@", filename, [error localizedDescription] );
      else
      {      
        NSLog( @"Downloaded new config to %@", filename );
        
        // Remove any old unpacked copy of the zipfile, which may not be there anyway
        if ([fm removeItemAtPath: unpackDirectoryNew error: &error])
        {
          // Removed successfully
          NSLog( @"Removed old unpacked zipfile" );
        }
        else
        {
          NSLog( @"Failed to delete %@: %@", unpackDirectoryNew, [error localizedDescription] );
        }
        
        // Unzip it
        error = nil;
        [SSZipArchive unzipFileAtPath: filename toDestination: unpackDirectoryNew overwrite: true password: nil error: &error];
        if (error != nil)
        {
          // Failed to unzip
          NSLog( @"Failed to unzip file: %@", [error localizedDescription] );
        }
        else
        {
          // Unzipped OK
          NSLog( @"Unzipped new config" );
          
          // Move old config out of the way, ignoring error as it may not exist
          if ([fm removeItemAtPath: unpackDirectory error: &error])
          {
            // Removed successfully
            NSLog( @"Removed old skin" );
          }
          else
          {
            NSLog( @"Failed to delete old skin %@: %@", unpackDirectory, [error localizedDescription] );
          }
          
          // Move new config into place
          if ([fm moveItemAtPath: unpackDirectoryNew toPath: unpackDirectory error: &error])
          {
            if (zipDate != nil)
              [fm setAttributes: [NSDictionary dictionaryWithObjectsAndKeys: zipDate, NSFileModificationDate, nil]
                   ofItemAtPath: filename error: &error];
            
            // New config is in place
            changed = YES;
          }
          else
          {
            // Failed to move new config into place
            NSLog( @"Failed to move new config to %@: %@", unpackDirectory, [error localizedDescription] );
          }
        }
      }
    }
  }
  
  return changed;
}

+ (void) setCurrentRoomList: (NLRoomList *) roomList
{
  //NSLog( @"NLRoomList %08X to be released by CustomViewController class", g_currentRoomList );
  [g_currentRoomList release];
  g_currentRoomList = [roomList retain];
  [g_customPageCache release];
  g_customPageCache = nil;

  //NSLog( @"NLRoomList %08X retained by CustomViewController class", g_currentRoomList );
  if (roomList == nil)
  {
    [g_preloadedView release];
    g_preloadedView = nil;
  }
  else
  {
    [g_preloadedView release];
#if 0
    g_preloadedView = [[UIWebView alloc] initWithFrame: CGRectZero];
    [CustomViewController preloadView: g_preloadedView];
#else
    UIWebView *page = [[UIWebView alloc] initWithFrame: CGRectZero];
    
    [page setOpaque: NO];
    page.backgroundColor = [UIColor clearColor];
    g_preloadedView = [[UIView alloc] initWithFrame: CGRectZero];
    g_preloadedView.backgroundColor = [StandardPalette customPageBackgroundColour];
    [g_preloadedView addSubview: page];
    [page release];
    [CustomViewController preloadView: page];
#endif
  }
}

- (id) initWithController: (UIViewController *) controller dataSource: (id<ListDataSource>) dataSource
{
  NSString *customPage;
  
  if ([dataSource isKindOfClass: [NLRoomList class]])
    customPage = @"locations.htm";
  else if ([dataSource isKindOfClass: [NLSourceList class]])
    customPage = @"sources.htm";
  else
    customPage = nil;
  
  return [self initWithController: controller customPage: customPage];
}

- (id) initWithController: (UIViewController *) controller customPage: (NSString *) customPage
{
  // Are skins enabled in the iOS settings app?
  if (![[NSUserDefaults standardUserDefaults] boolForKey: kEnableSkinKey])
  {
    // No, so ignore any custom page
    customPage = nil;
  }
	
  if (self = [super init])
  {
    if (customPage == nil)
    {
      _controller = nil;
      _initialText = nil;
      _initialURL = nil;
    }
    else
    {
      _controller = controller;
      _initialText = [[CustomViewController initialTextForCustomPage: customPage returningURL: &_initialURL] retain];
      [_initialURL retain];
      if (_initialText != nil)
      {
        [self initTitle];
        _hidesNavigationBar = [self findHideSetting: @"hidenavigationbar"];
        _hidesToolBar = _hidesNavigationBar || [self findHideSetting: @"hidetoolbar"];
        _hidesAudioControls = /*_hidesNavigationBar ||*/ [self findHideSetting: @"hideaudiocontrols"];
        _renderers = [NSMutableDictionary new];
      }
    }
  }

  return self;
}

- (void) loadViewWithFrame: (CGRect) frame
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  if (_page != nil)
    _page.delegate = nil;
#if 0
  _page = g_preloadedView;
  g_preloadedView = [[UIWebView alloc] initWithFrame: CGRectZero];
  [CustomViewController preloadView: g_preloadedView];
  _page.frame = frame;
#else
  _pageParent = g_preloadedView;
  _page = [[_pageParent subviews] lastObject];

  UIWebView *page = [[UIWebView alloc] initWithFrame: CGRectZero];
  
  [page setOpaque: NO];
  page.backgroundColor = [UIColor clearColor];
  g_preloadedView = [[UIView alloc] initWithFrame: CGRectZero];
  g_preloadedView.backgroundColor = [StandardPalette customPageBackgroundColour];
  [g_preloadedView addSubview: page];
  [page release];
  [CustomViewController preloadView: page];
  _pageParent.frame = frame;
#endif

#if DEBUG
  /**/NSLog( @"%@ loadViewWithFrame, Web control: %@, previous load: %@", self, _page, _page.request );
#endif
  [_page stopLoading];
  _page.delegate = self;
  [_page loadHTMLString: _initialText baseURL: _initialURL];
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(iLinXSkinChangedNotification:) 
                                               name: kNotificationSkinChanged object: nil];
}

- (BOOL) isValid
{
  return (_initialText != nil);
}

- (void) reloadData
{
  NSString *sMAC = [CustomViewController getMacAddress];
  NSString *statusData = @"iLinX._currentStatus( {";
  
  statusData = [statusData stringByAppendingFormat:@" mac:'%@',", sMAC];
  if ((_statusNeeded & JSON_CURRENT_PROFILE) != 0)
    statusData = [statusData stringByAppendingFormat: @" profiles: %@%@", 
                  [ConfigManager jsonStringForStatus: _statusNeeded withObjects: NO],
                  (g_currentRoomList == nil)?@" ":@","];
  if (g_currentRoomList == nil)
    statusData = [statusData stringByAppendingString: @"});"];
  else
    statusData = [statusData stringByAppendingFormat: @" locations: %@ });", 
                  [g_currentRoomList jsonStringForStatus: _statusNeeded withObjects: NO]];
#if DEBUG
  /**/NSLog( @"%@ reloadData, Web control: %@, JScript: %@", self, _page, statusData );
#endif
  [_page stringByEvaluatingJavaScriptFromString: statusData];  
}

- (void) setMacroHandler: (ExecutingMacroAlert *) macroHandler
{
#if DEBUG
  /**/NSLog( @"%@ setMacroHandler: %@", self, macroHandler );
#endif
  _macroHandler = macroHandler;
}

- (void) viewWillAppear: (BOOL) animated
{
  
}

- (void) viewWillDisappear: (BOOL) animated
{
  NSDictionary *renderers = [NSDictionary dictionaryWithDictionary: _renderers];
  NSEnumerator *enumerator = [renderers keyEnumerator];
  NSString *key;

  while ((key = (NSString *) [enumerator nextObject]) != nil)
  {
    NLRenderer *renderer = [renderers objectForKey: key];
    
    [renderer removeDelegate: self];
  }
  [_renderers removeAllObjects];
}

- (void) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags
{
  [self reloadData];
}

- (void) webViewDidFinishLoad: (UIWebView *) webView
{
#ifdef DEBUG
 /**/NSLog( @"%@ load finished: %@", self, _page.request );
#endif
  _statusNeeded = [self maskFromStatusString: 
                   [webView stringByEvaluatingJavaScriptFromString: @"iLinX._pageLoaded();"]];
  
  [self reloadData];
}

- (void) webView: (UIWebView *) webView didFailLoadWithError: (NSError *) error
{
#ifdef DEBUG
  NSLog( @"%@ load failed: %@ %@", self, _page.request, [error description] );
#endif
}

- (BOOL) webView: (UIWebView *) webView shouldStartLoadWithRequest: (NSURLRequest *) request
  navigationType: (UIWebViewNavigationType) navigationType
{
  BOOL load;
  NSURL *url = [request URL];
  
#ifdef DEBUG
  /**/NSLog( @"%@ loadRequest: %@", self, [url absoluteString] );
#endif
  
  if (![[url scheme] isEqualToString: @"ilinx"])
    load = YES;
  else if (![[url path] isEqualToString: @"/processCommands"])
    load = NO;
  else
  {
    NSString *poppedCommand = [webView stringByEvaluatingJavaScriptFromString: @"iLinX._getCommand();"];
    
    while (poppedCommand != nil && [poppedCommand length] > 0)
    {
#ifdef DEBUG
      /**/NSLog( @"Got cmd: %@", poppedCommand );
#endif
      NSArray *parameters = [self parseCommand: poppedCommand];
      NSInteger count = [parameters count];
      
#ifdef DEBUG
      //**/NSLog( @"parsed cmd: %@", parameters );
#endif
      if (count > 0)
      {
        NSString *cmd = [parameters objectAtIndex: 0];
        
        if ([cmd isEqualToString: @"closeView"] && count == 1)
        {
          if (_closeTarget == nil)
            [_controller dismissModalViewControllerAnimated: YES];
          else
            [_closeTarget performSelector: _closeMethod];
        }
        else if ([cmd isEqualToString: @"setStatusMask"] && count == 2)
        {
          NSUInteger oldStatus = _statusNeeded;
          
          _statusNeeded = [self maskFromStatusString: [parameters objectAtIndex: 1]];
          if (_statusNeeded != oldStatus)
            [self reloadData];
        }
        else if ([cmd isEqualToString: @"goHome"] && count == 1)
          [self selectItem: 0 inList: g_currentRoomList offset: 0];
        else if ([cmd isEqualToString: @"popUpNewPage"] && count == 2)
        {
          CustomViewController *newCustom = [[CustomViewController alloc]
                                             initWithController: _controller
                                             customPage: [parameters objectAtIndex: 1]];
          
          if ([newCustom isValid])
          {
            [newCustom setMacroHandler: _macroHandler];
            SelectItemViewController *container = [[SelectItemViewController alloc]
                                                    initWithCustomViewController: newCustom];

            [_controller presentModalViewController: container animated: YES];
            [container release];
          }
          [newCustom release];
        }
        else if ([cmd isEqualToString: @"selectProfile"] && count == 2)
          [self selectItem: [parameters objectAtIndex: 1] inList: [ConfigManager profileListDataSource]
                    offset: 0];
        else if ([cmd isEqualToString: @"registerForRenderer"] && (count == 2 || count == 3))
        {
          NSString *room = [parameters objectAtIndex: 1];
          
          if ([_renderers objectForKey: room] == nil)
          {
            NSUInteger index = [self findIndexForItem: [parameters objectAtIndex: 1] inList: g_currentRoomList
                                               offset: [g_currentRoomList countOfListInSection: 0]];
          
            if (index < [g_currentRoomList countOfList])
            {
              NLRenderer *renderer = ((NLRoom *) [g_currentRoomList itemAtIndex: index]).renderer;
              
              if (renderer != nil)
              {
                BOOL passive;

                [_renderers setObject: renderer forKey: room];
                if (count != 3)
                  passive = NO;
                else
                {
                  NSObject *param = [parameters objectAtIndex: 2];
                  
                  if ([param isKindOfClass: [NSString class]])
                    passive = ([(NSString *) param compare: @"true" options: NSCaseInsensitiveSearch] == NSOrderedSame);
                  else
                    passive = ([(NSNumber *) param integerValue] ? YES : NO);
                }
                
                if (passive)
                  [renderer addPassiveDelegate: self];
                else
                  [renderer addDelegate: self];
              }
            }
          }
        }
        else if ([cmd isEqualToString: @"deregisterFromRenderer"] && count == 2)
        {
          NSString *room = [parameters objectAtIndex: 1];
          NLRenderer *renderer = [_renderers objectForKey: room];
          
          if (renderer != nil)
          {
            [renderer removeDelegate: self];
            [_renderers removeObjectForKey: room];
          }
        }
        else if ([cmd isEqualToString: @"selectLocation"] && (count == 2 || count == 3))
        {
          id item = [self selectItem: [parameters objectAtIndex: 1] inList: g_currentRoomList
                    offset: [g_currentRoomList countOfListInSection: 0]];
          
          if ([item isKindOfClass: [NLRoom class]])
          {
            NLRoom *room = (NLRoom *) item;
            
            if (room.renderer != nil)
            {
              if (count == 3)
                room.renderer.controlGroup = [parameters objectAtIndex: 2];
              else
                room.renderer.controlGroup = nil;
            }
            
            if ([_controller.navigationController isKindOfClass: [MainNavigationController class]])
              [((MainNavigationController *) _controller.navigationController) setRenderer: room.renderer];
          }
        }
        else if ([cmd isEqualToString: @"selectService"] && count == 2)
          [self selectItem: [parameters objectAtIndex: 1] inList: [g_currentRoomList.currentRoom services]
                    offset: 0];
        else if ([cmd isEqualToString: @"selectSourceInCurrentLocation"] && count == 2)
          [self selectItem: [parameters objectAtIndex: 1] inList: [g_currentRoomList.currentRoom sources]
                    offset: 0];
        else if ([cmd isEqualToString: @"selectSourceInLocation"] && count == 3)
        {
          NSUInteger location = [self findIndexForItem: [parameters objectAtIndex: 1] inList: g_currentRoomList
                                                offset: [g_currentRoomList countOfListInSection: 0]];

          if (location < [g_currentRoomList countOfList])
            [self selectItem: [parameters objectAtIndex: 2] 
                      inList: [(NLRoom *) [g_currentRoomList itemAtOffset: location inSection: 1] sources]
                      offset: 0];
        }
        else if (([cmd isEqualToString: @"runMacroInCurrentLocation"] && count == 2)
                 || ([cmd isEqualToString: @"runMacroInLocation"] && count == 3)
                 || ([cmd isEqualToString: @"runMacroStringInCurrentLocation"] && count == 2)
                 || ([cmd isEqualToString: @"runMacroStringInLocation"] && count == 3))
        {
          NLRoom *room;
          id macro;
          
          if (count == 2)
          {
            room = g_currentRoomList.currentRoom;
            macro = [parameters objectAtIndex: 1];
          }
          else
          {
            NSUInteger location = [self findIndexForItem: [parameters objectAtIndex: 1] inList: g_currentRoomList
                                                  offset: [g_currentRoomList countOfListInSection: 0]];
            
            if (location < [g_currentRoomList countOfList])
              room = [g_currentRoomList itemAtIndex: location];
            else
              room = nil;
            macro = [parameters objectAtIndex: 2];
          }
          
          if (room != nil && [macro isKindOfClass: [NSString class]])
          {
            NSTimeInterval delay;
            NLService *newService;

            if ([cmd rangeOfString: @"MacroString"].length == 0)
              newService = [[room executeMacro: macro returnExecutionDelay: &delay] retain];
            else
              newService = [[room executeMacroString: macro returnExecutionDelay: &delay] retain];
            [webView stringByEvaluatingJavaScriptFromString: 
             [NSString stringWithFormat: @"iLinX._postMacroDelay( %u );", (NSUInteger) (delay * 1000)]];
            
            if (newService != nil)
            {
              [_macroHandler selectNewService: newService afterDelay: delay animated: YES];
              [newService release];
            }
          }
          else
          {
            [webView stringByEvaluatingJavaScriptFromString:  @"iLinX._postMacroDelay( 0 );"];
          }
        }
        else if ([cmd isEqualToString: @"log"] && count == 2)
        {
#ifndef DEBUG
          // No point in doing the logging in DEBUG build as it's already logged in the "received cmd" above
          NSLog( @"JS Log: %@", [parameters objectAtIndex: 1] );
#endif
        }
      }
      
      poppedCommand = [webView stringByEvaluatingJavaScriptFromString: @"iLinX._getCommand();"];
    }
    
    load = NO;
  }
  
  return load;
}

+ (void) preloadView: (UIWebView *) webView
{
  NSURL *initialURL = nil;
  NSString *initialText = [self initialTextForCustomPage: @"default.htm" returningURL: &initialURL];
  UIColor *customPageColour = [StandardPalette customPageBackgroundColour];

  if (initialText == nil)
  {
    size_t componentCount;
    NSUInteger red;
    NSUInteger green;
    NSUInteger blue;
    
    if (customPageColour == nil)
      componentCount = 0;
    else
    {
      CGColorRef colour = [customPageColour CGColor];
      CGColorSpaceRef colourSpace = CGColorGetColorSpace( colour );
    
      componentCount = CGColorSpaceGetNumberOfComponents( colourSpace );
      if (componentCount == 3)
      {
        const float *components = CGColorGetComponents( colour );
        
        red = (NSUInteger) (components[0] * 255);
        green = (NSUInteger) (components[1] * 255);
        blue = (NSUInteger) (components[2] * 255);
      }
    }
    
    if (componentCount != 3)
    {
      red = 255;
      green = 255;
      blue = 255;
    }

    initialText = [NSString stringWithFormat: @"<html><body bgcolor=\"rgb(%d,%d,%d)\"></body></html>",
                   red, green, blue];
  }

  webView.frame = [UIApplication sharedApplication].keyWindow.bounds;
#if 0
  //if (customPageColour != nil)
  //{
    //g_preloadedView.backgroundColor = customPageColour;
    //webView.backgroundColor = customPageColour;
    [g_preloadedView setOpaque: NO];
    [webView setOpaque: NO];
    g_preloadedView.backgroundColor = [UIColor clearColor];
    webView.backgroundColor = [UIColor clearColor];
  //}
#endif
  [webView loadHTMLString: initialText baseURL: initialURL];
}

+ (NSString *) initialTextForCustomPage: (NSString *) customPage returningURL: (NSURL **) pURL
{
  NSURL *skinURL = [ConfigManager currentProfileData].resolvedSkinURL;
  BOOL localFile = NO;
  NSURL *initialURL;
  NSString *initialText;
  id item;
  
  if (skinURL == nil)
    initialURL = [NSURL URLWithString: customPage relativeToURL: nil];
  else
  {
    NSString *sSkinURL = [skinURL absoluteString];
    
    if ([sSkinURL characterAtIndex: [sSkinURL length] - 1] == '/')
      initialURL = [NSURL URLWithString: customPage relativeToURL: skinURL];
    else
    {
      // Yes, using locally unpacked zipfile
      NSURL *urlToDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory: NSDocumentDirectory inDomains: NSUserDomainMask] lastObject];

      initialURL = [NSURL URLWithString: [NSString stringWithFormat: @"%@/unpacked/%@", [urlToDocumentsDirectory absoluteString], customPage]];
      localFile = YES;
    }
  }

  //**/NSLog( @"custom page %@ initialURL: %@", customPage, initialURL );
  
  // Do we have a cache yet?
  if (g_customPageCache != nil)
  {
    // Yes, so look in the cache
    item = [g_customPageCache objectForKey: customPage];        
    if ([item isKindOfClass: [NSString class]])
    {
      // Found it
      initialText = (NSString *) item;
#ifdef DEBUG
      //**/NSLog( @"cached initial text for custom page %@: %@", customPage, initialText );
#endif
    }
    else
    {
      // Didn't find it
      initialText = nil;
    }
  } 
  else
  {
    // No cache yet, so create it
    item = nil;
    initialText = nil;
    g_customPageCache = [[NSMutableDictionary alloc] initWithCapacity: 2];
  }
  
  // Have we found the text yet?
  if (item == nil && initialText == nil)
  {
    if (localFile)
    {
      // Yes, using locally unpacked zipfile so look for file
      NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
      NSString *documentsDirectory = [paths objectAtIndex: 0];
      NSString *filename = [documentsDirectory stringByAppendingFormat: @"/unpacked/%@", customPage];

      // Read contents of file
      initialText = [NSString stringWithContentsOfFile: filename encoding: NSUTF8StringEncoding error: nil];
#ifdef DEBUG
      //**/NSLog( @"local zip initial text for custom page %@: %@", customPage, initialText );
#endif
    }
    
    if (initialText == nil)
    {
      // Do it the old way, fetching each page from the remote website	
      //**/NSLog( @"Fetching %@ from website", customPage );

      NSURLResponse *response = nil;
      NSError *error = nil;
      NSURLRequest *request = [NSURLRequest requestWithURL: initialURL 
                                               cachePolicy: NSURLRequestReturnCacheDataElseLoad
                                           timeoutInterval: 2.0];
      NSData *responseData = [NSURLConnection sendSynchronousRequest: request
                                                   returningResponse: &response error: &error];
		
      if (responseData != nil && error == nil && 
        (![response isKindOfClass: [NSHTTPURLResponse class]] || [((NSHTTPURLResponse *) response) statusCode] == 200))
        initialText = [[[NSString alloc] initWithData: responseData encoding: NSUTF8StringEncoding] autorelease];
#ifdef DEBUG
      //**/NSLog( @"remote initial text for custom page %@: %@", customPage, initialText );
#endif
    }
		
    if (initialText == nil)
      [g_customPageCache setObject: [NSNull null] forKey: customPage];
    else 
      [g_customPageCache setObject: initialText forKey: customPage];
  }

  if (pURL != NULL)
    *pURL = initialURL;

  return initialText;
}

- (BOOL) findHideSetting: (NSString *) setting
{
  NSString *metaTag = [NSString stringWithFormat: @"<meta name=\"%@\" content=\"", setting];
  NSRange where = [_initialText rangeOfString: metaTag options: NSCaseInsensitiveSearch];
  BOOL value;

  if (where.length == 0)
    value = NO;
  else
    value = ([_initialText rangeOfString: @"y" options: NSCaseInsensitiveSearch
                                   range: NSMakeRange( NSMaxRange( where ), 1 )].length > 0);

  return value;
}

- (void) initTitle
{
  NSRange start = [_initialText rangeOfString: @"<title>" options: NSCaseInsensitiveSearch];
  
  if (start.length > 0)
  {
    NSInteger endOfStart = NSMaxRange( start );
    NSRange end = [_initialText rangeOfString: @"</title>" options: NSCaseInsensitiveSearch
                                        range: NSMakeRange( endOfStart, [_initialText length] - endOfStart )];
    
    if (end.length > 0)
    {
      _title = [_initialText substringWithRange: NSMakeRange( endOfStart, end.location - endOfStart )];
      _title = [_title stringByReplacingOccurrencesOfString: @"&lt;" withString: @"<"];
      _title = [_title stringByReplacingOccurrencesOfString: @"&gt;" withString: @">"];
      _title = [_title stringByReplacingOccurrencesOfString: @"&quot;" withString: @"\""];
      _title = [[_title stringByReplacingOccurrencesOfString: @"&amp;" withString: @"&"] retain];
    }
  }
}

- (NSArray *) parseCommand: (NSString *) command
{
  NSMutableArray *parameters;
  
  command = [command stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if ([command length] == 0 || [command characterAtIndex: [command length] - 1] != ')')
    parameters = nil;
  else
  {
    NSRange commandNameRange = [command rangeOfString: @"("];
    
    if (commandNameRange.length == 0)
      parameters = nil;
    else
    {
      parameters = [NSMutableArray arrayWithObject: 
                    [[command substringToIndex: commandNameRange.location] 
                     stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]];
      command = [command substringWithRange: NSMakeRange( commandNameRange.location + 1, 
                                                         [command length] - commandNameRange.location - 2 )];
      
      NSArray *args = [command componentsSeparatedByString: @"\""];
      NSInteger count = [args count];
      BOOL inQuotes = NO;

      for (NSInteger i = 0; i < count; ++i)
      {
        if (inQuotes)
        {
          NSString *arg = [args objectAtIndex: i];
          
          arg = [arg stringByReplacingOccurrencesOfString: @"\\n" withString: @"\n"];
          arg = [arg stringByReplacingOccurrencesOfString: @"\\r" withString: @"\r"];
          arg = [arg stringByReplacingOccurrencesOfString: @"\\t" withString: @"\t"];
          arg = [arg stringByReplacingOccurrencesOfString: @"\\\\" withString: @"\\"];
          if ([arg length] == 0 || [arg characterAtIndex: [arg length] - 1] != '\\')
            inQuotes = (i == count - 1);
          else
            arg = [[arg substringToIndex: [arg length] - 1] stringByAppendingString: @"\""];
          [parameters replaceObjectAtIndex: [parameters count] - 1 withObject: 
           [[parameters lastObject] stringByAppendingString: arg]];
        }
        else
        {
          NSArray *subArgs = [[args objectAtIndex: i] componentsSeparatedByString: @","];
          NSInteger subCount = [subArgs count];
          NSInteger j = (i == 0)?0:1;
          
          for ( ; j < subCount - 1; ++j)
            [parameters addObject: [NSNumber numberWithInteger: [[subArgs objectAtIndex: j] integerValue]]];

          inQuotes = (i < count - 1);
          if (inQuotes)
            [parameters addObject: @""];
          else
          {
            NSString *last = [[subArgs lastObject] stringByTrimmingCharactersInSet:
                              [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            if ([last isEqualToString: @"true"])
              [parameters addObject: [NSNumber numberWithInteger: !0]];
            else if ([last isEqualToString: @"false"])
              [parameters addObject: [NSNumber numberWithInteger: 0]];
            else if ([last length] > 0)
              [parameters addObject: [NSNumber numberWithInteger: [[subArgs lastObject] integerValue]]];
          }
        }
      }
      
      if (inQuotes)
        parameters = nil;
    }
  }

  return parameters;
}

- (id) selectItem: (id) item inList: (id<ListDataSource>) list offset: (NSUInteger) offset
{
  NSUInteger index = [self findIndexForItem: item inList: list offset: offset];
  id selectedItem;

  if (![list itemIsSelectableAtIndex: index])
    selectedItem = nil;
  else
  {
    [list selectItemAtIndex: index];
    selectedItem = [list itemAtIndex: index];
  }
  
  return selectedItem;
}

- (NSUInteger) findIndexForItem: (id) item inList: (id<ListDataSource>) list offset: (NSUInteger) offset
{
  NSUInteger index;
  
  if ([item isKindOfClass: [NSNumber class]])
    index = [item integerValue] + offset;
  else 
  {
    NSUInteger count = [list countOfList];
    
    for (index = offset; index < count; ++index)
    {
      id listItem = [list itemAtIndex: index];
      
      if ([listItem respondsToSelector: @selector(serviceName)])
      {
        if ([[listItem serviceName] isEqualToString: item])
          break;
      }
      else if ([[list titleForItemAtIndex: index] isEqualToString: item])
        break;
    }
  }
  
  return index;
}

- (NSUInteger) maskFromStatusString: (NSString *) string
{
  NSUInteger mask = 0;
  
  if ([string rangeOfString: @"f" options: NSCaseInsensitiveSearch].length > 0)
    mask |= (JSON_FAVOURITES|JSON_CURRENT_LOCATION);
  
  if ([string rangeOfString: @"L"].length > 0)
    mask |= JSON_ALL_LOCATIONS;
  else if ([string rangeOfString: @"l"].length > 0)
    mask |= JSON_CURRENT_LOCATION;
  
  if ([string rangeOfString: @"m" options: NSCaseInsensitiveSearch].length > 0)
    mask |= (JSON_MACROS|JSON_CURRENT_LOCATION);
  
  if ([string rangeOfString: @"P"].length > 0)
    mask |= JSON_ALL_PROFILES;
  else if ([string rangeOfString: @"p"].length > 0)
    mask |= JSON_CURRENT_PROFILE;
  
  if ([string rangeOfString: @"r" options: NSCaseInsensitiveSearch].length > 0)
    mask |= (JSON_RENDERER|JSON_CURRENT_LOCATION);
  
  if ([string rangeOfString: @"S"].length > 0)
    mask |= (JSON_ALL_SOURCES|JSON_CURRENT_LOCATION);
  else if ([string rangeOfString: @"s"].length > 0)
    mask |= (JSON_CURRENT_SOURCE|JSON_CURRENT_LOCATION);
  
  if ([string rangeOfString: @"V"].length > 0)
    mask |= (JSON_ALL_SERVICES|JSON_CURRENT_LOCATION);
  else if ([string rangeOfString: @"v"].length > 0)
    mask |= (JSON_CURRENT_SERVICE|JSON_CURRENT_LOCATION);
  
  if ([string rangeOfString: @"Z"].length > 0)
    mask |= (JSON_ALL_ZONES|JSON_CURRENT_LOCATION);
  else if ([string rangeOfString: @"z"].length > 0)
    mask |= (JSON_CURRENT_ZONE|JSON_CURRENT_LOCATION);
  
  return mask;
}

+ (NSString *) getMacAddress
{
  int                 mgmtInfoBase[6];
  char                *msgBuffer = NULL;
  size_t              length;
  unsigned char       macAddress[6];
  struct if_msghdr    *interfaceMsgStruct;
  struct sockaddr_dl  *socketStruct;
  NSString            *macAddressStringOrError = NULL;

  // Setup the management Information Base (mib)
  mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
  mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
  mgmtInfoBase[2] = 0;              
  mgmtInfoBase[3] = AF_LINK;        // Request link layer information
  mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
  
  // With all configured interfaces requested, get handle index
  if ((mgmtInfoBase[5] = if_nametoindex( "en0" )) == 0) 
    macAddressStringOrError = @"if_nametoindex failure";
  else
  {
    // Get the size of the data available (store in len)
    if (sysctl( mgmtInfoBase, 6, NULL, &length, NULL, 0 ) < 0) 
      macAddressStringOrError = @"sysctl mgmtInfoBase failure";
    else
    {
      // Alloc memory based on above call
      if ((msgBuffer = malloc( length )) == NULL)
        macAddressStringOrError = @"buffer allocation failure";
      else
      {
        // Get system information, store in buffer
        if (sysctl( mgmtInfoBase, 6, msgBuffer, &length, NULL, 0 ) < 0)
          macAddressStringOrError = @"sysctl msgBuffer failure";
      }
    }
  }

  // Before going any further...
  if (macAddressStringOrError != NULL)
    NSLog( @"Error: %@", macAddressStringOrError );
  else
  {
    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
    // Copy link layer address data in socket structure to an array
    // Check for socketStruct == NULL obviously not needed, but without it Analyze complains
    if (socketStruct == NULL || socketStruct->sdl_data == NULL)
      macAddressStringOrError = @"no mac address data returned";
    else
    {
      memcpy( &macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6 );

      // Read from char array into a string object, into traditional Mac address format
      macAddressStringOrError = [NSString stringWithFormat: @"%02X:%02X:%02X:%02X:%02X:%02X", 
                                 macAddress[0], macAddress[1], macAddress[2], 
                                 macAddress[3], macAddress[4], macAddress[5]];
      //  NSLog( @"Mac Address: %@", macAddressStringOrError );
    }
  }

  // Release the buffer memory
  if (msgBuffer != NULL)
    free( msgBuffer );

  return macAddressStringOrError;
}

- (void) iLinXSkinChangedNotification: (NSNotification *) notification
{
#if CHANGE_NOTIFICATION_IMPLEMENTED
  CGRect frame;
  
#if 0
  if (_page == nil)
    frame = CGRectZero;
  else
    frame = _page.frame
#else
  if (_pageParent == nil)
    frame = CGRectZero;
  else
    frame = _pageParent.frame;
#endif
  [self loadViewWithFrame: frame];
#endif
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [_initialURL release];
  [_initialText release];
  if (_page != nil)
  {
    _page.delegate = nil;
    [_page stopLoading];
  }
#if 0
  [_page release];
#else
  [_pageParent release];
#endif
  [_title release];
  [_renderers release];
  [super dealloc];
}


@end
