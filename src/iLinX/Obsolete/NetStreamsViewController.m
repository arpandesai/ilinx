//
//  NetStreamsViewController.m
//  NetStreams
//
//  Created by mcf on 19/12/2008.
//  Copyright Micropraxis Ltd 2008. All rights reserved.
//

#import "NetStreamsViewController.h"

static NSString * const kSoundEnabledKey = @"soundEnabledKey";
static NSString * const kMulticastIpKey = @"multicastIpKey";
static NSString * const kMulticastPortKey = @"multicastPortKey";
static NSString * const kInitialUrlKey = @"initialUrlKey";

@interface NetStreamsViewController ()
@property(nonatomic,retain) NSString *initialUrl;
@end

@implementation NetStreamsViewController

@synthesize netStreamsComms=_netStreamsComms,initialUrl =_initialUrl,
soundFileURLRef=_soundFileURLRef, soundFileObject=_soundFileObject;


- (void) setOrientation: (NSString *) newOrientation
{
  UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
  
  if ([newOrientation compare: @"portrait"] == NSOrderedSame)
  {
    if (UIInterfaceOrientationIsLandscape( orientation ))
      orientation = UIInterfaceOrientationPortrait;
  }
  else
  {
    if (UIInterfaceOrientationIsPortrait( orientation ))
      orientation = UIInterfaceOrientationLandscapeRight;
  }
  
  [[UIDevice currentDevice] setOrientation: orientation];
  [[UIApplication sharedApplication] setStatusBarOrientation: orientation animated: NO];
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void) loadView
{
  [super loadView];

  if (_netStreamsComms != nil)
  {
    [_netStreamsComms disconnect];
    self.netStreamsComms = nil;
  }
  
  self.netStreamsComms = [NetStreamsComms new];
  if (_netStreamsComms != nil)
    [_netStreamsComms setDelegate: self];
  
  
  CGRect buttonFrame;
  
  _multicastIp = [[NSUserDefaults standardUserDefaults] stringForKey: kMulticastIpKey];
  
  if (_multicastIp != nil)
  {
    self.initialUrl = [[NSUserDefaults standardUserDefaults] stringForKey: kInitialUrlKey];
    _soundEnabled = [[NSUserDefaults standardUserDefaults] boolForKey: kSoundEnabledKey];
    _multicastPort = (uint16_t) [[NSUserDefaults standardUserDefaults] integerForKey: kMulticastPortKey];
  }
  else
  {
    // no default values have been set, create them here based on what's in our Settings bundle info
    
    NSString *pathStr = [[NSBundle mainBundle] bundlePath];
    NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent: @"Settings.bundle"];
    NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent: @"Root.plist"];
    NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile: finalPath];
    NSArray *prefSpecifierArray = [settingsDict objectForKey: @"PreferenceSpecifiers"];
    NSDictionary *prefItem;
    NSString *multicastPortStr = nil;
    id soundEnabledId = nil;
    
    for (prefItem in prefSpecifierArray)
    {
      NSString *keyValueStr = [prefItem objectForKey: @"Key"];
      id defaultValue = [prefItem objectForKey: @"DefaultValue"];
      
      if ([keyValueStr isEqualToString: kMulticastIpKey])
        _multicastIp = defaultValue;
      else if ([keyValueStr isEqualToString: kMulticastPortKey])
        multicastPortStr = defaultValue;
      else if ([keyValueStr isEqualToString: kInitialUrlKey])
        self.initialUrl = defaultValue;
      else if ([keyValueStr isEqualToString: kSoundEnabledKey])
        soundEnabledId = defaultValue;
    }
    
    // since no default values have been set (i.e. no preferences file created), create it here
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                 soundEnabledId, kSoundEnabledKey,
                                 _multicastIp, kMulticastIpKey,
                                 multicastPortStr, kMulticastPortKey,
                                 self.initialUrl, kInitialUrlKey,
                                 nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults: appDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _soundEnabled = [[NSUserDefaults standardUserDefaults] boolForKey: kSoundEnabledKey];
    _multicastPort = (uint16_t) [[NSUserDefaults standardUserDefaults] integerForKey: kMulticastPortKey];
  }
  
  UIView *myView = [self view];
  
  buttonFrame.origin.x = 0;
  buttonFrame.origin.y = 0;
  buttonFrame.size.width = myView.bounds.size.width;
  buttonFrame.size.height = myView.bounds.size.height;
  
  _webView = [[UIWebView alloc] initWithFrame: buttonFrame];
  
  _webView.delegate = self;
  _webView.detectsPhoneNumbers = NO;
  _webView.autoresizesSubviews = YES;
  _webView.contentMode = UIViewContentModeRedraw;
  _webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth; 
  
  [myView setBackgroundColor: [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 1.0]];
  [_webView setBackgroundColor: [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 1.0]];
  _loadingMessageDone = NO;
  [_webView loadHTMLString: @"<style>body { border: 0; margin: 0; padding: 0; } table { top: 0%; left: 0%; width: 100%; height: 100%; } td { background-color: #000000; color: #ffffff; font-family: sans-serif; text-align: center; vertical-align: middle; text-size: x-large; }</style><table><td>Loading GUI</table>"
                   baseURL: [NSURL URLWithString: @"file:///"]];
  [myView addSubview: _webView];
}

/* Implement viewDidLoad if you need to do additional setup after loading the view.
 */
- (void) viewDidLoad
{
  [super viewDidLoad];
  
  // Get the main bundle for the app
  CFBundleRef mainBundle = CFBundleGetMainBundle();
  
  _soundFileURLRef = CFBundleCopyResourceURL( mainBundle, CFSTR("tap"), CFSTR("aif"), NULL );
  
  // Create a system sound object representing the sound file
  AudioServicesCreateSystemSoundID( _soundFileURLRef, &_soundFileObject );
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
  BOOL retValue = (interfaceOrientation == UIInterfaceOrientationPortrait ||
                   interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
  
  
  if (_webView != nil)
  {
    NSString *orient;
    
    if (retValue)
      orient = @"landscape";
    else
      orient = @"portrait";
    
    orient = [_webView stringByEvaluatingJavaScriptFromString:
              [NSString stringWithFormat: @"nets_orientationOK( \"%@\" );", orient]];
    if (orient != nil && [orient length] > 0)
      retValue = [orient isEqualToString: @"1"];
  }
  
  return retValue;
}

- (void) didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
  
  // Release anything that's not essential, such as cached data
  if (_webView != nil)
    [_webView stringByEvaluatingJavaScriptFromString: @"nets_garbageCollect();"];  
}


- (void) dealloc
{
  [super dealloc];
  
  AudioServicesDisposeSystemSoundID( self.soundFileObject );
  CFRelease( _soundFileURLRef );
}

@end


@implementation NetStreamsViewController (UIWebViewDelegate)

- (void) webViewDidFinishLoad: (UIWebView *) webView
{
  if (_loadingMessageDone)
    [webView stringByEvaluatingJavaScriptFromString: @"nets_iPhoneInit();"];
  else
  {
    _loadingMessageDone = YES;
    [_webView loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: _initialUrl]]];
  }
}

- (BOOL) webView: (UIWebView *) webView shouldStartLoadWithRequest: (NSURLRequest *) request
  navigationType: (UIWebViewNavigationType) navigationType
{
  BOOL load;
  NSURL *url = [request URL];
  NSString *scheme = [url scheme];
  
  if ([scheme compare: @"nets"] == NSOrderedSame)
  {
    NSString *command = [url host];
    //NSString *path = [url path];
    NSString *params = [[url query] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    BOOL click = NO;
    
    if ([command hasSuffix: @"_click"])
    {
      command = [command substringToIndex: [command length] - 6];
      click = YES;
    }
    
    if ([command compare: @"connect"] == NSOrderedSame)
      [_netStreamsComms connect: params];
    else if ([command compare: @"disconnect"] == NSOrderedSame)
      [_netStreamsComms disconnect];
    else if ([command compare: @"discover"] == NSOrderedSame)
      [_netStreamsComms discoverWithAddress: _multicastIp andPort: _multicastPort];
    else if ([command compare: @"sendraw"] == NSOrderedSame)
      [_netStreamsComms sendRaw: params];
    else if ([command compare: @"orient"] == NSOrderedSame)
      [self setOrientation: params];
    else if ([command compare: @"click"] == NSOrderedSame)
      AudioServicesPlayAlertSound( self.soundFileObject );
    load = NO;
    
    if (click && _soundEnabled)
      AudioServicesPlayAlertSound( self.soundFileObject );          
  }
  else
    load = YES;
  
  return load;
}

@end

@implementation NetStreamsViewController (NetStreamsCommsDelegate)
- (void) connected: (NetStreamsComms *) comms
{
  if (_webView != nil)
    [_webView stringByEvaluatingJavaScriptFromString: @"nets_connected();"];
}

- (void) disconnected: (NetStreamsComms *) comms error: (NSError *) error
{
  if (_webView != nil)
    [_webView stringByEvaluatingJavaScriptFromString: @"nets_disconnected();"];
}

- (void) receivedRaw: (NetStreamsComms *) comms data: (NSString *) netStreamsMessage
{
  if (_webView != nil)
  {
    [_webView stringByEvaluatingJavaScriptFromString:
      [NSString stringWithFormat: @"nets_message( \"%@\" );", 
        [netStreamsMessage stringByReplacingOccurrencesOfString: @"\"" withString: @"\\\""]]];
  }
}

- (void) discoveredService: (NetStreamsComms *) comms address: (NSString *) deviceAddress
                   netmask: (NSString *) netmask type: (NSString *) type
                   version: (NSString *) version name: (NSString *) name
                    permId: (NSString *) permId room: (NSString *) room
{
  if (_webView != nil)
    [_webView stringByEvaluatingJavaScriptFromString:
      [NSString stringWithFormat: @"nets_discovered( \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\" );",
        deviceAddress, netmask, type, version, name, permId, room]];
}

- (void) discoveryComplete: (NetStreamsComms *) comms error: (NSError *) error
{
  if (_webView != nil)
  {
    [_webView stringByEvaluatingJavaScriptFromString:
     [NSString stringWithFormat: @"nets_discoveryComplete( %u );", 
      (error == nil) ? 0 : [error code]]];
  }
}

@end