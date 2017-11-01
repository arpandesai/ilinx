/*
*/

#import <SystemConfiguration/SystemConfiguration.h>

#import "NetStreamsDataController.h"
#import "GuiXmlParser.h"
#import "GuiRoom.h"
#import "ResponseXmlParser.h"

// Time in seconds before we give up on retrieving a gui.xml and assume the
// device is unreachable
#define GUI_RETRIEVAL_TIMEOUT 2

// Interval in seconds for polling current status of sources, renderer etc.
#define CURRENT_STATUS_HEARTBEAT_INTERVAL 2

static NSString * const kMulticastIpKey = @"multicastIpKey";
static NSString * const kMulticastPortKey = @"multicastPortKey";

@interface NetStreamsDataController ()

@property (nonatomic, copy, readwrite) NSMutableArray *locationList;
@property (nonatomic, retain) NSString *defaultHost;
@property (nonatomic, retain) NSString *lastLocation;

- (void) createRoomData;
- (void) currentStatusTimerFired: (NSTimer *) timer;

@end


@implementation NetStreamsDataController

@synthesize 
  locationList=_locationList,
  defaultHost = _defaultHost,
  lastLocation = _lastLocation,
  netStreamsComms = _netStreamsComms;

- (id) init
{
  if (self = [super init])
    [self createRoomData];
  
  return self;
}

// Custom set accessor to ensure the new list is mutable
- (void) setLocationList: (NSMutableArray *) newList
{
  if (_locationList != newList)
  {
    [_locationList release];
    _locationList = [newList mutableCopy];
  }
}

- (void) getGuiDataFromHost: (NSString *) host
{
  // Although the NSXMLParser class can parse directly from a given URL, it has a very long timeout
  // (default of 1 minute?) before giving up on the fetch.  Since we know that this file should be
  // available on the local network, it should be a sub 1 second response time.  So, instead we do
  // the fetching with an explicit timeout and then pass the received data to the parser.
  
  SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName( NULL, [host UTF8String] );
  SCNetworkReachabilityFlags flags;
  Boolean success = SCNetworkReachabilityGetFlags( reachability, &flags );
      
  CFRelease( reachability );
  if (success && (flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired))
  {
    NSURL *guiXmlURL = [NSURL URLWithString: [NSString stringWithFormat: @"http://%@/gui.xml", host]];
    NSURLRequest *xmlRequest = [NSURLRequest requestWithURL: guiXmlURL
                                                  cachePolicy: NSURLRequestUseProtocolCachePolicy
                                              timeoutInterval: GUI_RETRIEVAL_TIMEOUT];
    NSURLResponse *xmlResponse = nil;
    NSError *error = nil;
    NSData *xmlData = [NSURLConnection sendSynchronousRequest: xmlRequest returningResponse: &xmlResponse error: &error];
    
    if (xmlData != nil && error == nil)
    {
      GuiXmlParser *parser = [[GuiXmlParser alloc] init];    
  
      parser.delegate = self;
      [parser parseXMLData: xmlData parseError: &error];
      if (error == nil)
      {
        self.defaultHost = host;
        [_netStreamsComms cancelDiscovery];
        [_netStreamsComms connect: host];
      }

      [parser release];
    }
  }
}

- (void) parser: (GuiXmlParser *) parser addRoom: (GuiRoom *) room
{
  NSUInteger i;
  
  for (i = 0; i < [_locationList count]; ++i)
  {
    NSString *itemTitle = ((GuiRoom *) [_locationList objectAtIndex: i]).name;
    
    if (itemTitle == nil || [room.name localizedCaseInsensitiveCompare: itemTitle] != NSOrderedDescending)
      break;
  }
  
  [_locationList insertObject: room atIndex: i];
}

- (void) discoverLocations
{
  _discoveryInProgress = YES;
  if (_currentLocation >= 0)
    self.lastLocation = [self titleForCurrentLocation];
  else
    self.lastLocation = nil;
  _currentLocation = -1;
  _currentSource = -1;
  self.defaultHost = nil;
  
  NSMutableArray *roomList = [[NSMutableArray alloc] init];
  GuiRoom *tempRoom = [[GuiRoom alloc] init];
  
  tempRoom.name = nil;
  [roomList addObject: tempRoom];
  [tempRoom release];
  self.locationList = roomList;
  [roomList release];
  
  [_netStreamsComms discoverWithAddress: _multicastIp andPort: _multicastPort];
}

- (BOOL) locationDiscoveryIsComplete
{
  return !_discoveryInProgress;
}

- (unsigned) countOfLocations
{
  return [_locationList count];
}

- (NSString *) titleForCurrentLocation
{
  if (_currentLocation < 0)
    return @"";
  else
    return [self titleForLocationAtIndex: _currentLocation];
}

- (NSString *) titleForLocationAtIndex: (unsigned) index
{
  if (index >= [_locationList count])
    return @"";
  else
  {
    NSString *title = ((GuiRoom *) [_locationList objectAtIndex: index]).name;
    
    if (title == nil)
      title = NSLocalizedString( @"Discovering, please wait...", 
                                @"Message to display when discovering rooms and services" );

    return title;
  }
}

- (BOOL) locationIsSelectedAtIndex: (unsigned) index
{
  return (index == _currentLocation);
}

- (void) selectLocationAtIndex: (unsigned) index
{
  if ([self locationIsSelectableAtIndex: index])
  {
    if (_currentLocation != index)
    {
      _currentLocation = index;
      _currentSource = -1;
    }
  }
}

- (BOOL) locationIsSelectableAtIndex: (unsigned) index
{
  unsigned count = [_locationList count];
  
  return !(index >= count || (index == count - 1 && _discoveryInProgress));
}

// Accessor methods for services available in the current location
- (unsigned) countOfServices
{
  if (_currentLocation < 0)
    return 0;
  else
    return [((GuiRoom *) [_locationList objectAtIndex: _currentLocation]).screens count];
}

- (id) serviceAtIndex: (unsigned) theIndex
{
  if (_currentLocation < 0)
    return nil;
  else
    return [((GuiRoom *) [_locationList objectAtIndex: _currentLocation]).screens objectAtIndex: theIndex];
}

- (NSString *) titleForServiceAtIndex: (unsigned) theIndex
{
  if (_currentLocation < 0)
    return @"";
  else
    return [(NSDictionary *) [self serviceAtIndex: theIndex] valueForKey: @"name"];
}

// Sources information for current location
- (unsigned) countOfSources
{
  return [((GuiRoom *) [_locationList objectAtIndex: _currentLocation]).sources count];
}

- (id) sourceAtIndex: (unsigned) theIndex
{
  return [((GuiRoom *) [_locationList objectAtIndex: _currentLocation]).sources objectAtIndex: theIndex];
}

- (NSString *) titleForSourceAtIndex: (unsigned) theIndex
{
  if (theIndex >= [self countOfSources])
    return @"";
  else
    return [(NSDictionary *) [self sourceAtIndex: theIndex] valueForKey: @"serviceName"];  
}

- (BOOL) sourceIsSelectedAtIndex: (unsigned) index
{
  return (index == _currentSource);
}

- (void) selectSourceAtIndex: (unsigned) index
{
  if (index < [self countOfSources])
    _currentSource = index;
}

- (id) currentSource
{
  if (_currentSource < 0)
    return nil;
  else
    return [self sourceAtIndex: _currentSource];
}

- (NSString *) titleForCurrentSource
{
  if (_currentSource < 0)
    return @"";
  else
    return [self titleForSourceAtIndex: _currentSource];
}


// Direct connection

- (void) connectToLocation: (NSString *) location
{
  NSUInteger i;
  
  for (i = 0; i < [_locationList count]; ++i)
  {
    if ([self locationIsSelectableAtIndex: i] && [[self titleForLocationAtIndex: i] isEqualToString: location])
    {
      [self selectLocationAtIndex: i];
      break;
    }
  }
}

- (void) connectToLocation: (NSString *) location defaultHost: (NSString *) host
{
  [self connectToLocation: location];

  if (_currentLocation < 0)
  {
    [self getGuiDataFromHost: host];
    [self connectToLocation: location];
  }
}

- (void) disconnectFromLocation
{
  _currentLocation = -1;
  _currentSource = -1;
}

- (NSString *) connectedHost
{
  return _defaultHost;
}

- (void) dealloc
{
  [_locationList release];
  [_defaultHost release];
  [_lastLocation release];
  [_netStreamsComms release];
  [super dealloc];
}


- (void) createRoomData
{
  if (_netStreamsComms != nil)
  {
    [_netStreamsComms disconnect];
    self.netStreamsComms = nil;
  }
  
  self.netStreamsComms = [NetStreamsComms new];
  if (_netStreamsComms != nil)
    [_netStreamsComms setDelegate: self];
  
  _multicastIp = [[NSUserDefaults standardUserDefaults] stringForKey: kMulticastIpKey];
  
  if (_multicastIp == nil)
  {
    // no default values have been set, create them here based on what's in our Settings bundle info
    
    NSString *pathStr = [[NSBundle mainBundle] bundlePath];
    NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent: @"Settings.bundle"];
    NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent: @"Root.plist"];
    NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile: finalPath];
    NSArray *prefSpecifierArray = [settingsDict objectForKey: @"PreferenceSpecifiers"];
    NSDictionary *prefItem;
    NSString *multicastPortStr = nil;
    
    for (prefItem in prefSpecifierArray)
    {
      NSString *keyValueStr = [prefItem objectForKey: @"Key"];
      id defaultValue = [prefItem objectForKey: @"DefaultValue"];
      
      if ([keyValueStr isEqualToString: kMulticastIpKey])
        _multicastIp = defaultValue;
      else if ([keyValueStr isEqualToString: kMulticastPortKey])
        multicastPortStr = defaultValue;
    }
    
    // since no default values have been set (i.e. no preferences file created), create it here
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                 _multicastIp, kMulticastIpKey,
                                 multicastPortStr, kMulticastPortKey,
                                 nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults: appDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
  _multicastPort = (uint16_t) [[NSUserDefaults standardUserDefaults] integerForKey: kMulticastPortKey];
  
  [self discoverLocations];
}

- (void) currentStatusTimerFired: (NSTimer *) timer
{
  // Check status of renderer in current location (if any)
  if (_currentLocation >= 0)
  {
    NSString *currentRenderer = ((GuiRoom *) [_locationList objectAtIndex: _currentLocation]).renderer;
    
    if (currentRenderer != nil)
    {
      [_netStreamsComms sendRaw: [NSString stringWithFormat: @"#@%@#QUERY RENDERER", currentRenderer]];
    
      // Check current source in current location (if any)
      [_netStreamsComms sendRaw: [NSString stringWithFormat: @"#@%@#QUERY CURRENT_SOURCE", currentRenderer]];
  
      // If we're listing sources at the moment, check which are available
      if (_trackingSources)
        [_netStreamsComms sendRaw: [NSString stringWithFormat: @"#@%@#MENU_LIST 1,1000,SOURCES", currentRenderer]];
    }
  }
}

@end

@implementation NetStreamsDataController (NetStreamsCommsDelegate)

- (void) connected: (NetStreamsComms *) comms
{
  _currentStatusTimer = [NSTimer
               scheduledTimerWithTimeInterval: (NSTimeInterval) CURRENT_STATUS_HEARTBEAT_INTERVAL
               target: self selector: @selector(currentStatusTimerFired:) userInfo: nil repeats: TRUE];  
}

- (void) disconnected: (NetStreamsComms *) comms error: (NSError *) error
{
  [_currentStatusTimer invalidate];
  _currentStatusTimer = nil;
}

- (void) receivedRaw: (NetStreamsComms *) comms data: (NSString *) netStreamsMessage
{
  // Parse data
  if ([netStreamsMessage hasPrefix: @"#@"])
  {
    NSRange restOfString = NSMakeRange( 2, [netStreamsMessage length] - 2 );
    NSRange fromAddressStart = [netStreamsMessage rangeOfString: @":" options: 0 range: restOfString];
    NSRange messageStart = [netStreamsMessage rangeOfString: @"#" options: 0 range: restOfString];
    NSInteger fromAddressLength = messageStart.location - (fromAddressStart.location + 1);
    NSRange optionsStart = [netStreamsMessage rangeOfString: @"%" options: 0 range: 
                            NSMakeRange( fromAddressStart.location, fromAddressLength )];
    
    if (fromAddressStart.length != 0 && messageStart.length != 0 && 
        messageStart.location > fromAddressStart.location)
    {
      if (optionsStart.length > 0)
        fromAddressLength = optionsStart.location - (fromAddressStart.location + 1);
      
      NSString *fromAddress = [netStreamsMessage substringWithRange: 
                               NSMakeRange( fromAddressStart.location + 1, fromAddressLength )];
      NSString *message = [netStreamsMessage substringWithRange:
                           NSMakeRange( messageStart.location + 1,
                                       [netStreamsMessage length] - (messageStart.location + 1) )];
      NSDictionary *resultData;
      NSRange xmlStart = [message rangeOfString: @"{{"];
      NSRange xmlEnd = [message rangeOfString: @"}}"];
      
      if (xmlStart.length == 0 || xmlEnd.length == 0 || xmlEnd.location < xmlStart.location)
        resultData = nil;
      else
      {
        ResponseXmlParser *responseParser = [ResponseXmlParser new];
        
        resultData = [[responseParser parseResponseXML: 
                      [message substringWithRange:
                       NSMakeRange( xmlStart.location + 2, xmlEnd.location - (xmlStart.location + 2) )]] retain];
        if (resultData != nil)
          message = [[message substringToIndex: xmlStart.location]
                     stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
      }
      
      // Now decide what to do about it on the basis of who it is from and what
      // sort of a message it is
      
      [resultData release];
    }
  }
}

- (void) discoveredService: (NetStreamsComms *) comms address: (NSString *) deviceAddress
                   netmask: (NSString *) netmask type: (NSString *) type
                   version: (NSString *) version name: (NSString *) name
                    permId: (NSString *) permId room: (NSString *) room
{
  if (_discoveryInProgress)
    [self getGuiDataFromHost: deviceAddress];
}

- (void) discoveryComplete: (NetStreamsComms *) comms error: (NSError *) error
{
  if (_discoveryInProgress)
  {
    [_locationList removeLastObject];    
    _discoveryInProgress = NO;
    
    // Ensure something is always selected, if possible.
    if (_lastLocation != nil)
    {
      [self connectToLocation: _lastLocation];
      self.lastLocation = nil;
    }
    
    if (_currentLocation < 0 && [_locationList count] > 0)
      _currentLocation = 0;
  }
}

@end