/*
*/

#import <SystemConfiguration/SystemConfiguration.h>

#import "NLRoomList.h"
#import "ConfigManager.h"
#import "ConfigProfile.h"
#import "GuiXmlParser.h"
#import "NLRoom.h"
#import "NLRenderer.h"
#import "NLSource.h"
#import "NLSourceList.h"
#import "JavaScriptSupport.h"

#include <sys/types.h> 
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

//#if defined(DEBUG)
#define LOG_DISCOVERY 1
//#endif

// Time in seconds before we give up on retrieving a gui.xml and assume the
// device is unreachable
#define GUI_RETRIEVAL_TIMEOUT 10

// Default port for HTTP
#define DEFAULT_HTTP_PORT 80

@interface NLRoomList ()

@property (nonatomic, copy, readwrite) NSMutableArray *roomList;
@property (nonatomic, retain) NSString *defaultHost;

- (void) createRoomData;
- (void) guiDataComplete: (NSData *) data fromHost: (NSString *) host port: (NSUInteger) port 
                   error: (NSError *) error isOneOff: (BOOL) isOneOff;
- (void) _cancelDiscovery;
- (void) _clearOperations;

@end

@interface NLValidateHostOperation : NSOperation
{
  NLRoomList *_owner;
  NSString *_host;
  NSUInteger _port;
  NSURLConnection *_connection;
  NSURL *_target;
  NSMutableData *_data;
  NSError *_error;
  BOOL _isExecuting;
  BOOL _isFinished;
  BOOL _isOneOff;
}

- (id) initWithOwner: (NLRoomList *) owner host: (NSString *) host port: (NSUInteger) port isOneOff: (BOOL) isOneOff;

- (void) _beginOperation;
- (void) _downloadOperation;
- (void) _endOperation;
- (NSError *) _checkReachability;
- (NSError *) _checkRendererUsable;
- (NSError *) _fetchGuiXml;

- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response;
- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) data;
- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error;
- (void) connectionDidFinishLoading: (NSURLConnection *) connection;

@end

@implementation NLValidateHostOperation

- (id) initWithOwner: (NLRoomList *) owner host: (NSString *) host port: (NSUInteger) port isOneOff: (BOOL) isOneOff
{
  if ((self = [super init]) != nil)
  {
    _owner = owner;
    _host = [host retain];
    _port = port;
    _isExecuting = NO;
    _isFinished = NO;
    _isOneOff = isOneOff;
  }
  
  return self;
}

- (void) start
{
  NSLog( @"Download and parse %@ started.", _target );
    
  [self willChangeValueForKey: @"isExecuting"];
  _isExecuting = YES;
  [self didChangeValueForKey: @"isExecuting"];
  [self _beginOperation];
}

- (void) finish
{
  [_connection cancel];
  [_connection release];
  _connection = nil;

  [self willChangeValueForKey: @"isExecuting"];
  [self willChangeValueForKey: @"isFinished"];
  
  _isExecuting = NO;
  _isFinished = YES;
  
  [self didChangeValueForKey: @"isExecuting"];
  [self didChangeValueForKey: @"isFinished"];
}

- (BOOL) isConcurrent
{
  return YES;
}

- (BOOL) isExecuting
{
  return _isExecuting;
}

- (BOOL) isFinished
{
  return _isFinished;
}

- (void) cancel
{
  [_connection cancel];
  [_connection release];
  _connection = nil;
  [super cancel];
}

- (void) _beginOperation
{
  if (![self isCancelled])
    _error = [[self _checkReachability] retain];
  if (_error == nil && ![self isCancelled])
    _error = [[self _checkRendererUsable] retain];
  [self performSelectorOnMainThread: @selector(_downloadOperation) withObject: nil waitUntilDone: NO];
}

- (void) _downloadOperation
{
  if (_error == nil && ![self isCancelled])
    _error = [[self _fetchGuiXml] retain];
  
  if ([self isCancelled])
    [self finish];
  else if (_error != nil)
    [self _endOperation];
}

- (void) _endOperation
{
  [_owner guiDataComplete: _data fromHost: _host port: _port error: _error isOneOff: _isOneOff];
  [self finish];
}

- (NSError *) _checkReachability
{
  SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName( NULL, [_host UTF8String] );
  SCNetworkReachabilityFlags flags;
  Boolean success;
  NSError *err = nil;
  
  // Though not mentioned in the documentation, apparently this can return NULL (because we've had a
  // NULL pointer crash when trying to release the handle!)
  if (reachability == NULL)
  {
    success = NO;
#if LOG_DISCOVERY
    NSLog( @"NLValidateHostOperation %@: Unable to create reachability for %@", self, _host );
#endif
  }
  else
  {
#if LOG_DISCOVERY
    NSLog( @"NLValidateHostOperation %@: checking reachability of %@", self, _host );
#endif
    success = SCNetworkReachabilityGetFlags( reachability, &flags );
#if LOG_DISCOVERY
    NSLog( @"NLValidateHostOperation %@: reachability check complete", self );
#endif
    CFRelease( reachability );    
  }
  
  if (!success || !(flags & kSCNetworkFlagsReachable) || (flags & kSCNetworkFlagsConnectionRequired))
  {
#if LOG_DISCOVERY
    NSLog( @"NLValidateHostOperation %@: Unable to reach %@ for GUI data", self, _host );
#endif    
    err = [[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                     code: kNetStreamsNetworkUnavailable 
                                 userInfo: [NSDictionary 
                                            dictionaryWithObject: 
                                            [NSString stringWithFormat: NSLocalizedString( @"Device %@ is not reachable",
                                                                                          @"Error shown if unable to reach device" ), _host]
                                            forKey: NSLocalizedDescriptionKey]];
  }
  
  return [err autorelease];
}

- (NSError *) _checkRendererUsable
{
#if LOG_DISCOVERY
  NSLog( @"NLValidateHostOperation %@: Checking renderer %@ is usable", self, _host );
#endif
  int sockfd = socket( AF_INET, SOCK_STREAM, 0 );
  struct sockaddr_in serv_addr;
  struct hostent *server = gethostbyname( [_host cStringUsingEncoding: NSUTF8StringEncoding] );
  char buffer[1024];
  int n;
  NSError *err = nil;
  CFSocketRef sr;
  
  if (sockfd >= 0)
    sr = CFSocketCreateWithNative( kCFAllocatorDefault, sockfd, 0, NULL, NULL );
  else
    sr = NULL;

  if (sr == NULL)
  {
    if (sockfd >= 0)
      close( sockfd );
    err = [[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                     code: kNetStreamsNoSocketsAvailable
                                 userInfo: [NSDictionary dictionaryWithObject: NSLocalizedString( @"No resources to connect to network",
                                                                                                 @"Error shown if unable to create a socket" )
                                                                       forKey: NSLocalizedDescriptionKey]];
  }
  else if (server == NULL)
  {
    err = [[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                     code: kNetStreamsCannotResolveHostName
                                 userInfo: [NSDictionary dictionaryWithObject: 
                                            [NSString stringWithFormat: NSLocalizedString( @"Unable to resolve device address %@",
                                                                                          @"Error shown if unable to resolve address given in renderer address setting" ), _host]
                                                                       forKey: NSLocalizedDescriptionKey]];
    CFSocketInvalidate( sr );
    CFRelease( sr );
  }
  else
  {
    struct timeval tv;
    int yes = 1;
    
    bzero( (char *) &serv_addr, sizeof(serv_addr) );
    bzero( (char *) &tv, sizeof(tv) );
    serv_addr.sin_family = AF_INET;
    bcopy( (char *) server->h_addr, (char *) &serv_addr.sin_addr.s_addr, server->h_length );
    serv_addr.sin_port = htons( 15000 );
    tv.tv_sec = 5;
    setsockopt( sockfd, SOL_SOCKET, SO_SNDTIMEO, (void *) &tv, sizeof(tv) ); 
    setsockopt( sockfd, SOL_SOCKET, SO_RCVTIMEO, (void *) &tv, sizeof(tv) );
    setsockopt( sockfd, SOL_SOCKET, SO_NOSIGPIPE, (void *) &yes, sizeof(yes) );
    
    NSData *addrData = [NSData dataWithBytes: &serv_addr length: sizeof(serv_addr)];
    
    if (CFSocketConnectToAddress( sr, (CFDataRef) addrData, GUI_RETRIEVAL_TIMEOUT ) < 0) 
    {
      err = [[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                       code: kNetStreamsConnectTimedOut 
                                   userInfo: [NSDictionary dictionaryWithObject: 
                                              [NSString stringWithFormat: NSLocalizedString( @"Timed out trying to connect to %@",
                                                                                            @"Error shown if unable to connect to a device" ), _host]
                                                                         forKey: NSLocalizedDescriptionKey]];
      
    }
    else
    {
      n = write( sockfd, "#PING", 6 );
      if (n >= 0) 
      {
        bzero( buffer, sizeof(buffer) );
        n = read( sockfd, buffer, sizeof(buffer) - 1 );
        
      }
      if (n < 0)
        err = [[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                         code: kNetStreamsSendFailed 
                                     userInfo: [NSDictionary 
                                                dictionaryWithObject: 
                                                [NSString stringWithFormat: NSLocalizedString( @"Failed to communicate with device %@",
                                                                                              @"Error shown if unable to send the initial ping message" ), _host]
                                                forKey: NSLocalizedDescriptionKey]];
      else
      {
        buffer[n] = 0;
        
        NSString *response = [NSString stringWithCString: buffer encoding: NSASCIIStringEncoding];
        NSRange errRange = [response rangeOfString: @"errMsg=\""];
        
        if (errRange.location != NSNotFound)
        {
          NSUInteger endPos = NSMaxRange( errRange );
          NSRange end = [response rangeOfString: @"\"" options: 0 range: NSMakeRange( endPos, [response length] - endPos )];
          NSString *errMsg;
          
          if (end.location == NSNotFound)
            errMsg = [response substringFromIndex: endPos];
          else
            errMsg = [response substringWithRange: NSMakeRange( endPos, end.location - endPos )];
          
          err = [[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                           code: kNetStreamsSendFailed 
                                       userInfo: [NSDictionary 
                                                  dictionaryWithObject: 
                                                  [NSString stringWithFormat: NSLocalizedString( @"Device %@ has a problem: %@",
                                                                                                @"Error shown if unable to send the initial ping message" ), _host, errMsg]
                                                  forKey: NSLocalizedDescriptionKey]];
        }
      }
    }
    
    CFSocketInvalidate( sr );
    CFRelease( sr );
  }
  
#if LOG_DISCOVERY
  NSLog( @"NLValidateHostOperation %@: Renderer usability check for %@ returned: %@", self, _host, err );
#endif
  return [err autorelease];
}

- (NSError *) _fetchGuiXml
{
#if LOG_DISCOVERY
  NSLog( @"NLValidateHostOperation %@: Fetching GUI data: http://%@:%u/gui.xml", self, _host, _port );
#endif
  _target = [[NSURL URLWithString: [NSString stringWithFormat: @"http://%@:%u/gui.xml", _host, _port]] retain];
  _data = [NSMutableData new];

  NSURLRequest *xmlRequest = [NSURLRequest requestWithURL: _target
                                                cachePolicy: NSURLRequestUseProtocolCachePolicy
                                            timeoutInterval: GUI_RETRIEVAL_TIMEOUT];
  NSError *err;
  
  _connection = [[NSURLConnection alloc] initWithRequest: xmlRequest delegate: self startImmediately: YES];

  if (_connection != nil)
    err = nil;
  else
    err = [[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                     code: kNetStreamsNoSocketsAvailable
                                 userInfo: [NSDictionary dictionaryWithObject: NSLocalizedString( @"No resources to connect to network",
                                                                                                 @"Error shown if unable to create a socket" )
                                                                       forKey: NSLocalizedDescriptionKey]];

  return [err autorelease];
}

- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response
{
  [_data setLength: 0];
  if ([response isKindOfClass: [NSHTTPURLResponse class]])
  {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    NSInteger statusCode = [httpResponse statusCode];
    
    if (statusCode >= 400)
    {
      [connection cancel];
      [self connection: connection didFailWithError: 
       [[[NSError alloc] initWithDomain: NetStreamsErrorDomain
                                   code: kNetStreamsUnexpectedHTTPResponse 
                               userInfo: [NSDictionary 
                                          dictionaryWithObject: 
                                          [NSString stringWithFormat: NSLocalizedString( @"Unexpected response %d for %@",
                                                                                       @"Error shown if failed to fetch URL" ), 
                                           statusCode, _target]
                                         forKey: NSLocalizedDescriptionKey]] autorelease]];
    }
  }
}

- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) data
{
  [_data appendData: data];
}

- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error
{
  [_connection release];
  _connection = nil;
  [_data release];
  _data = nil;
  _error = [error retain];
  [self _endOperation];
}

- (void) connectionDidFinishLoading: (NSURLConnection *) connection
{
  [_connection release];
  _connection = nil;
  [self _endOperation];
}

- (void) dealloc
{
  [_host release];
  [_target release];
  [_connection release];
  [_data release];
  [_error release];
  [super dealloc];
}

@end

@implementation NLRoomList

@synthesize 
  roomList = _roomList,
  defaultHost = _defaultHost,
  currentRoom = _currentRoom,
  netStreamsComms = _netStreamsComms,
  lastError = _lastError;

- (id) init
{
  if ((self = [super init]) != nil)
  {
    _opQueue = [[NSOperationQueue alloc] init];
    [_opQueue setMaxConcurrentOperationCount: 1];
    [self createRoomData];
    _popupMessageDelegates = [NSMutableSet new];
  }

  return self;
}

// Custom set accessor to ensure the new list is mutable
- (void) setRoomList: (NSMutableArray *) newList
{
  if (_roomList != newList)
  {
    [_roomList release];
    _roomList = [newList mutableCopy];
  }
}

- (void) parser: (GuiXmlParser *) parser addRoom: (NLRoom *) room presorted: (BOOL) presorted
{
  NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<ListDataDelegate> delegate;
  NSUInteger i;
  
  if (presorted)
    i = [_roomList count] - 1;
  else
  {
    for (i = 0; i < [_roomList count]; ++i)
    {
      NSString *itemTitle = ((NLRoom *) [_roomList objectAtIndex: i]).displayName;
      
      if (itemTitle == nil || [room.displayName localizedCaseInsensitiveCompare: itemTitle] != NSOrderedDescending)
        break;
    }
  }
  [_roomList insertObject: room atIndex: i];
  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(itemsInsertedInListData:range:)])
      [delegate itemsInsertedInListData: self range: NSMakeRange( i, 1 )];
  }
}

- (void) parser: (GuiXmlParser *) parser addMacros: (NSDictionary *) macros
{
  for (NLRoom *room in _roomList)
    room.macros = macros;
}

- (void) resetCurrentItemToCurrentRoom
{
  id oldObject = self.listDataCurrentItem;
  id newObject;

  if (_currentRoom == nil)
    _currentIndex = 0;
  else
    _currentIndex = [_roomList indexOfObject: _currentRoom] + [_specialEntries count];
  
  newObject = self.listDataCurrentItem;
  if (newObject != oldObject)
  {
    NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
    NSEnumerator *enumerator = [delegates objectEnumerator];
    id<ListDataDelegate> delegate;

    while ((delegate = [enumerator nextObject]))
    {
      if ([delegate respondsToSelector: @selector(currentItemForListData:changedFrom:to:)])
        [delegate currentItemForListData: self changedFrom: oldObject to: newObject at: _currentIndex];
    }
  }
}

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects
{
  NSString *result;

  if ((statusMask & JSON_CURRENT_LOCATION) == 0)
    result = @"{}";
  else
  {
    NSInteger mainCount = [_roomList count];
    NSInteger specialCount = [_specialEntries count];
    NSUInteger currentRoom = (_currentIndex < specialCount)?mainCount:(_currentIndex - specialCount);
  
    result = [NSString stringWithFormat: @"{ currentIndex: %u, length: %d", currentRoom, mainCount];
  
    if ((statusMask & JSON_ALL_LOCATIONS) == 0)
      result = [result stringByAppendingFormat: @", %d: %@", currentRoom,
                [[_roomList objectAtIndex: currentRoom] jsonStringForStatus: statusMask withObjects: withObjects]];
    else
    {
      for (int i = 0; i < mainCount; ++i)
        result = [result stringByAppendingFormat: @", %d: %@", i,
                  [[_roomList objectAtIndex: i] jsonStringForStatus: statusMask withObjects: withObjects]];
    }
  
    result = [result stringByAppendingString: @" }"];
  }
  
  return result;
}

- (NSString *) listTitle
{
  return NSLocalizedString( @"Location", @"Title of the locations list" );
}

- (BOOL) canBeRefreshed
{
  return YES;
}

- (void) refresh
{
  _discoveryInProgress = YES;
  self.defaultHost = nil;
  
  NSMutableArray *roomList = [[NSMutableArray alloc] init];
  NLRoom *tempRoom = [[NLRoom alloc] init];
  NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<ListDataDelegate> delegate;
  
  tempRoom.displayName = nil;
  [roomList addObject: tempRoom];
  [tempRoom release];

  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(listDataRefreshDidStart:)])
      [delegate listDataRefreshDidStart: self];
  }
  
  NSRange removedRange = NSMakeRange( 0, [self countOfList] );
  
  [_specialEntries release];
  _specialEntries = nil;
  self.roomList = nil;
  _currentIndex = 0;
  delegates = [NSSet setWithSet: _listDataDelegates];
  enumerator = [delegates objectEnumerator];
  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(itemsRemovedInListData:range:)])
      [delegate itemsRemovedInListData: self range: removedRange];
  }
  self.roomList = roomList;
  [roomList release];
  delegates = [NSSet setWithSet: _listDataDelegates];
  enumerator = [delegates objectEnumerator];
  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(itemsInsertedInListData:range:)])
      [delegate itemsInsertedInListData: self range: NSMakeRange( 0, 1 )];
  }
  
  ConfigProfile *profile = [ConfigManager currentProfileData];
  
  [_lastError release];
  _lastError = nil;

  if (profile.autoDiscovery)
    [_netStreamsComms discoverWithAddress: profile.multicastAddress andPort: profile.multicastPort];
  else
  {
    if ([[_opQueue operations] count] > 0)
      [self _clearOperations];
    
#if LOG_DISCOVERY
    NSLog( @"NLRoomList %@: adding queryAndConnect operation to queue", self );
#endif
    
    NSOperation *op = [[NLValidateHostOperation alloc]
                       initWithOwner: self host: profile.directAddress port: profile.directPort isOneOff: YES];
    
    self.defaultHost = nil;
    [_opQueue addOperation: op];
    [op release];
  }
}

- (BOOL) refreshIsComplete
{
  return !_discoveryInProgress;
}

- (NSUInteger) countOfList
{
  return [_specialEntries count] + [_roomList count];
}

- (id) itemAtIndex: (NSUInteger) index
{
  NSUInteger specialCount = [_specialEntries count];
  
  if (index < specialCount)
    return [_specialEntries objectAtIndex: index];
  else if (index - specialCount < [_roomList count])
    return [_roomList objectAtIndex: index - specialCount];
  else
    return nil;
}

- (NSString *) titleForItemAtIndex: (NSUInteger) index
{
  NSUInteger specialCount = [_specialEntries count];
  NSString *title;

  if (index < specialCount)
    title = [[_specialEntries objectAtIndex: index] objectForKey: @"display"];
  else if (index - specialCount >= [_roomList count])
    title = @"";
  else
  {
    title = ((NLRoom *) [_roomList objectAtIndex: index - specialCount]).displayName;
    
    if (title == nil)
      title = NSLocalizedString( @"Discovering, please wait...", 
                                @"Message to display when discovering rooms and services" );
  }
  
  return title;
}

- (BOOL) itemIsSelectedAtIndex: (NSUInteger) index
{
  return ([self itemAtIndex: index] == _currentRoom);
}

- (id<ListDataSource>) selectItemAtIndex: (NSUInteger) index executeAction: (BOOL) executeAction
{
  if ([self itemIsSelectableAtIndex: index])
  {
    NSUInteger specialCount = [_specialEntries count];
    id oldItem = [self.listDataCurrentItem retain];
    id newItem;

    _currentIndex = index;
    if (index < specialCount)
      newItem = [_specialEntries objectAtIndex: index];
    else
    {
      newItem = [_roomList objectAtIndex: index - specialCount];
      [_currentRoom release];
      _currentRoom = [newItem retain];
    }
    
    if (newItem != oldItem)
    {
      NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
      NSEnumerator *enumerator = [delegates objectEnumerator];
      id<ListDataDelegate> delegate;
      
      while ((delegate = [enumerator nextObject]))
      {
        if ([delegate respondsToSelector: @selector(currentItemForListData:changedFrom:to:at:)])
          [delegate currentItemForListData: self changedFrom: oldItem to: newItem at: index];
      }
    }

    [oldItem release];
  }
  
  // No child list, so return nil
  return nil;
}

- (BOOL) itemIsSelectableAtIndex: (NSUInteger) index
{
  unsigned count = [self countOfList];
  
  return !(index >= count || (index == count - 1 && _discoveryInProgress));
}

- (NSUInteger) countOfSections
{
  return 2;
}

- (NSUInteger) countOfListInSection: (NSUInteger) section
{
  NSUInteger count;

  switch (section)
  {
    case 0:
      count = [_specialEntries count];
      break;
    case 1:
      count = [_roomList count];
      break;
    default:
      count = 0;
      break;
  }
  
  return count;
}

- (NSUInteger) convertFromOffset: (NSUInteger) index inSection: (NSUInteger) section
{
  switch (section)
  {
    case 0:
      break;
    case 1:
      index += [_specialEntries count];
      break;
    default:
      index = [self countOfList];
      break;
  }
  
  return index;
}

- (NSIndexPath *) indexPathFromIndex: (NSUInteger) index
{
  NSUInteger specialCount = [_specialEntries count];
  NSIndexPath *result;

  if (index < specialCount)
    result = [NSIndexPath indexPathForRow: index inSection: 0];
  else if (index < specialCount + [_roomList count])
    result = [NSIndexPath indexPathForRow: index - specialCount inSection: 1];
  else
    result = nil;

  return result;
}

// Direct connection

- (void) connectToRoom: (NSString *) roomServiceName
{
  NSUInteger specialEntryCount = [_specialEntries count];
  NSUInteger i;
  
  for (i = 0; i < [_roomList count]; ++i)
  {
    if ([self itemIsSelectableAtIndex: i + specialEntryCount] && 
        [((NLRoom *) [_roomList objectAtIndex: i]).serviceName compare: roomServiceName
                                                               options: NSCaseInsensitiveSearch] == NSOrderedSame)
    {
      [self selectItemAtIndex: i + specialEntryCount];
      break;
    }
  }
}

- (void) connectToRoom: (NSString *) roomServiceName defaultHost: (NSString *) host port: (NSUInteger) port
{
  [self connectToRoom: roomServiceName];
#if 0
  if (_currentRoom == nil)
  {
    ConfigProfile *profile = [ConfigManager currentProfileData];

    if (profile.autoDiscovery)
      [self getGuiDataFromHost: host port: port];
    else
      [self getGuiDataFromHost: profile.directAddress port: profile.directPort];
    [self connectToRoom: roomServiceName];
  }
#endif
}

- (NSString *) connectedHost
{
  return _defaultHost;
}

- (NSUInteger) connectedPort
{
  return _defaultPort;
}

- (void) dealloc
{
  [_opQueue cancelAllOperations];
  [_opQueue release];

  if (_uiMessageDelegate != nil)
    [_netStreamsComms deregisterDelegate: _uiMessageDelegate];
  _netStreamsComms.delegate = nil;
  [_netStreamsComms disconnect];

  // Ensure that we don't retain any sources beyond the existence of the room list
  // that created them
  [NLSourceList setMasterSources: nil];
  [_specialEntries release];
  [_roomList release];
  [_defaultHost release];
  [_currentRoom release];
  [_lastError release];
  [_netStreamsComms release];
  [_popupMessageDelegates release];
  [super dealloc];
}

- (void) createRoomData
{
  if (_netStreamsComms != nil)
  {
    if (_uiMessageDelegate != nil)
    {
      [_netStreamsComms deregisterDelegate: _uiMessageDelegate];
      _uiMessageDelegate = nil;
    }
    _netStreamsComms.delegate = nil;
    [_netStreamsComms disconnect];
    self.netStreamsComms = nil;
  }
  
  _netStreamsComms = [NetStreamsComms new];
  if (_netStreamsComms != nil)
    [_netStreamsComms setDelegate: self];
  
  [self refresh];
}

- (void) addPopupMessageDelegate: (id<NLPopupMessageDelegate>) delegate
{
  [_popupMessageDelegates addObject: delegate];
}

- (void) removePopupMessageDelegate: (id<NLPopupMessageDelegate>) delegate
{
  [_popupMessageDelegates removeObject: delegate];
}

- (void) connected: (NetStreamsComms *) comms
{
  [_lastError release];
  _lastError = nil;
  _uiMessageDelegate = [comms registerDelegate: self forMessage: @"MESSAGE" from: @"*"];
}

- (void) disconnected: (NetStreamsComms *) comms error: (NSError *) error
{
  [_lastError release];
  _lastError = [error retain];
  [comms deregisterDelegate: _uiMessageDelegate];
  _uiMessageDelegate = nil;
}

- (void) discoveredService: (NetStreamsComms *) comms address: (NSString *) deviceAddress
                   netmask: (NSString *) netmask type: (NSString *) type
                   version: (NSString *) version name: (NSString *) name
                    permId: (NSString *) permId room: (NSString *) room
{
#if LOG_DISCOVERY
  NSLog( @"NLRoomList %@: discovered %@ service %@ on %@", self, type, name, deviceAddress );
#endif
  NSArray *ops = [_opQueue operations];
  
  if (_discoveryInProgress && [type isEqualToString: @"audio/renderer"])
  {
#if LOG_DISCOVERY
    NSLog( @"NLRoomList %@: adding validate host operation to queue", self );
#endif
    
    NSOperation *op = [[NLValidateHostOperation alloc]
                       initWithOwner: self host: deviceAddress port: DEFAULT_HTTP_PORT isOneOff: NO];
    
    [_opQueue addOperation: op];
    [op release];
  }
  else
  {
    if ([ops count] > 0 && [[ops objectAtIndex: 0] isCancelled])
      [self _cancelDiscovery];
  }
}

- (void) guiDataComplete: (NSData *) data fromHost: (NSString *) host port: (NSUInteger) port error: (NSError *) error
                isOneOff: (BOOL) isOneOff
{
  if (error == nil && [data length] > 0)
  {
    GuiXmlParser *parser = [[GuiXmlParser alloc] init];
  
    parser.delegate = self;
    [parser parseXMLData: data comms: _netStreamsComms 
          staticMenuRoom: [[ConfigManager currentProfileData] staticMenuRoom] parseError: &error];
    if (error == nil)
    {
#if LOG_DISCOVERY
      NSLog( @"NLRoomList %@: Successfully parsed GUI data: http://%@:%u/gui.xml", self, host, port );
#endif
      self.defaultHost = host;
      _defaultPort = port;
      [_lastError release];
      _lastError = nil;
    }
    else 
    {
#if LOG_DISCOVERY
      NSLog( @"NLRoomList %@: Failed to parse GUI data: http://%@:%u/gui.xml, error: %@", self, host, port, error );
#endif
    }
  
    [parser release];
  }
  else 
  {
#if LOG_DISCOVERY
    if (error != nil)
      NSLog( @"NLRoomList %@: GUI data fetch from http://%@:%u/gui.xml returned error %@", self, host, port, error );
    else
    {
      NSLog( @"NLRoomList %@: no GUI data returned from http://%@:%u/gui.xml", self, host, port );
    }
#endif          
  }

  [_lastError release];
  _lastError = [error retain];
  if (error == nil || isOneOff)
  {
    [self _clearOperations];
    [self performSelector: @selector(_cancelDiscovery) withObject: nil afterDelay: 0];
  }
}

- (void) _cancelDiscovery
{
  [self _clearOperations];
  [_netStreamsComms cancelDiscovery];
}

- (void) discoveryComplete: (NetStreamsComms *) comms error: (NSError *) error
{
#if LOG_DISCOVERY
  NSLog( @"NLRoomList %@: discovery complete", self );
#endif
  [self _clearOperations];
  if (_discoveryInProgress)
  {
    _discoveryInProgress = NO;
    if (error == nil)
      error = _lastError;
    [self performSelectorOnMainThread: @selector(handleDiscoveryComplete:) withObject: error waitUntilDone: NO];
  }
}

- (void) handleDiscoveryComplete: (NSError *) error
{
#if LOG_DISCOVERY
  NSLog( @"NLRoomList %@: handleDiscoveryComplete", self );
#endif
  NLRoom *previousRoom = _currentRoom;
  NSUInteger indexOfCurrent;
  NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<ListDataDelegate> delegate;
  
  if ([[_netStreamsComms connectedDeviceAddress] length] == 0 && _defaultHost != nil)
    [_netStreamsComms connect: _defaultHost];

  [_roomList removeLastObject];    
  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(itemsRemovedInListData:range:)])
      [delegate itemsRemovedInListData: self range: NSMakeRange( [_roomList count], 1 )];
  }
  
  _currentRoom = nil;
  
  // Ensure something is always selected, if possible.
  if (previousRoom != nil)
    [self connectToRoom: previousRoom.serviceName];
  
  if (_currentRoom != nil)
    indexOfCurrent = [_roomList indexOfObject: _currentRoom];
  else if ([_roomList count] == 0)
    indexOfCurrent = 0;
  else
  {
    _currentRoom = [[_roomList objectAtIndex: 0] retain];
    indexOfCurrent = 0;
  }
  
  _currentIndex = [self convertFromOffset: indexOfCurrent inSection: 1];
#if defined(IPAD_BUILD)
  _specialEntries = [NSArray new];
#else
  _specialEntries = [[NSArray arrayWithObject: 
                      [NSDictionary dictionaryWithObjectsAndKeys: 
                       NSLocalizedString( @"Home", @"Name of home entry in the location list" ), @"display",
                       @"Home", @"id",
                       nil]] retain];
#endif
  [error retain];
  [_lastError release];
  _lastError = error;
  
  delegates = [NSSet setWithSet: _listDataDelegates];
  enumerator = [delegates objectEnumerator];
  
  while ((delegate = [enumerator nextObject]))
  {
    if ([delegate respondsToSelector: @selector(itemsInsertedInListData:range:)])
      [delegate itemsInsertedInListData: self range: NSMakeRange( 0, 1 )];
    if ([delegate respondsToSelector: @selector(currentItemForListData:changedFrom:to:)] &&
        [_roomList count] > 0)
      [delegate currentItemForListData: self changedFrom: previousRoom to: _currentRoom at: _currentIndex];
    if ([delegate respondsToSelector: @selector(listDataRefreshDidEnd:)])
      [delegate listDataRefreshDidEnd: self];
  }
  
  [previousRoom release];
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  NSArray *params = [data objectForKey: @"params"];
  
  if ([params count] > 0)
  {
    NSSet *delegates = [_popupMessageDelegates copy];
    NSTimeInterval timeout;
  
    if ([params count] == 1)
      timeout = 0;
    else
      timeout = [[params objectAtIndex: 1] doubleValue];

    for (id<NLPopupMessageDelegate> delegate in delegates)
      [delegate receivedPopupMessage: [params objectAtIndex: 0] 
                             timeout: timeout];
    
    [delegates release];
  }
}

- (void) _clearOperations
{
  if ([[_opQueue operations] count] > 0)
  {
    [_opQueue cancelAllOperations];
    [_opQueue release];
    _opQueue = [[NSOperationQueue alloc] init];
    [_opQueue setMaxConcurrentOperationCount: 1];
  }  
}

@end