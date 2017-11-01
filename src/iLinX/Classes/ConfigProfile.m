//
//  ConfigProfile.m
//  iLinX
//
//  Created by mcf on 27/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "ConfigProfile.h"
#import "JavaScriptSupport.h"
#import "RelativeFileURL.h"

static NSString * const kConnectionTypeKey = @"connectionTypeKey";
static NSString * const kWasDirectConnectKey = @"WasDirectConnect";
static NSString * const kMulticastIpKey = @"multicastIpKey";
static NSString * const kMulticastPortKey = @"multicastPortKey";
static NSString * const kDirectConnectIpKey = @"directConnectIpKey";
static NSString * const kDirectConnectPortKey = @"directConnectPortKey";
static NSString *kRestoreStateKey = @"RestoreState";
static NSString * const kStaticMenuRoomKey = @"staticMenuRoomKey";
static NSString * const kTitleBarMacroKey = @"titleBarMacroKey";
static NSString * const kExtraArtworkUrlKey = @"extraArtworkKey";

@implementation ConfigProfile

@synthesize
  name = _name,
  autoDiscovery = _autoDiscovery,
  wasAutoDiscovery = _wasAutoDiscovery,
  multicastAddress = _multicastAddress,
  multicastPort = _multicastPort,
  directAddress = _directAddress,
  directPort = _directPort,
  state = _state,
  staticMenuRoom = _staticMenuRoom,
  titleBarMacro = _titleBarMacro,
  buttonRows = _buttonRows,
  buttonsPerRow = _buttonsPerRow,
  artworkURL = _artworkURL,
  skinURL = _skinURL;

- (void) setArtworkURL: (NSString *) artworkURL
{
  [_artworkURL release];
  _artworkURL = [artworkURL retain];
  [_resolvedArtworkURL release];
  _resolvedArtworkURL = nil;
}

- (NSURL *) resolvedArtworkURL
{
  if (_resolvedArtworkURL == nil && [_artworkURL length] > 0)
    _resolvedArtworkURL = [[NSURL URLWithILinXString: _artworkURL] retain];
  
  return _resolvedArtworkURL;
}

- (void) setSkinURL: (NSString *) skinURL
{
  [_skinURL release];
  _skinURL = [skinURL retain];
  [_resolvedSkinURL release];
  _resolvedSkinURL = nil;
}

- (NSURL *) resolvedSkinURL
{
  if (_resolvedSkinURL == nil && [_skinURL length] > 0)
    _resolvedSkinURL = [[NSURL URLWithILinXString: _skinURL] retain];
  
  return _resolvedSkinURL;
}

- (id) init
{
  if (self = [super init])
  {
    self.name = NSLocalizedString( @"<Unnamed>", @"Default name for a new profile" );
    self.autoDiscovery = YES;
    self.wasAutoDiscovery = YES;
    self.multicastAddress = @"239.255.16.90";
    self.multicastPort = 8000;
    self.directAddress = @"";
    self.directPort = 80;
    self.state = [NSMutableArray arrayWithCapacity: 5];
    self.staticMenuRoom = @"iPod Settings";
    self.titleBarMacro = @"";
    self.buttonRows = 0;
    self.buttonsPerRow = 0;
    self.artworkURL = @"";
    self.skinURL = @"";
  }
  
  return self;
}

- (id) initWithOldSettings
{
  if (self = [super init])
  {
    self.name = NSLocalizedString( @"Default", @"Name for default profile copied from old settings" );
    self.autoDiscovery = ([[NSUserDefaults standardUserDefaults] integerForKey: kConnectionTypeKey] == 0);
    self.wasAutoDiscovery = ![[NSUserDefaults standardUserDefaults] boolForKey: kWasDirectConnectKey];
    self.multicastAddress = [[NSUserDefaults standardUserDefaults] objectForKey: kMulticastIpKey];
    if (_multicastAddress == nil)
      self.multicastAddress = @"239.255.16.90";
    self.multicastPort = [[NSUserDefaults standardUserDefaults] integerForKey: kMulticastPortKey];
    if (_multicastPort == 0)
      self.multicastPort = 8000;
    self.directAddress = [[NSUserDefaults standardUserDefaults] objectForKey: kDirectConnectIpKey];
    if (_directAddress == nil)
      self.directAddress = @"";
    self.directPort = [[NSUserDefaults standardUserDefaults] integerForKey: kDirectConnectPortKey];
    if (_directPort == 0)
      self.directPort = 80;
    self.staticMenuRoom = [[NSUserDefaults standardUserDefaults] objectForKey: kStaticMenuRoomKey];
    if (_staticMenuRoom == nil)
      self.staticMenuRoom = @"iPod Settings";
    _state = [[[NSUserDefaults standardUserDefaults] objectForKey: kRestoreStateKey] mutableCopy];
    if (_state == nil)
      self.state = [NSMutableArray arrayWithCapacity: 5];
    self.titleBarMacro = [[NSUserDefaults standardUserDefaults] objectForKey: kTitleBarMacroKey];
    if (_titleBarMacro == nil)
      self.titleBarMacro = @"";
    self.buttonRows = 0;
    self.buttonsPerRow = 0;    
    self.artworkURL = [[NSUserDefaults standardUserDefaults] objectForKey: kExtraArtworkUrlKey];
    if (_artworkURL == nil)
      self.artworkURL = @"";
    self.skinURL = @"";
  }
  
  return self;
}

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects
{
  return [NSString stringWithFormat: @"{ displayName: \"%@\" }", [_name javaScriptEscapedString]];
}

- (id) initWithCoder: (NSCoder *) decoder
{
  if (self = [super init])
  {
    self.name = [decoder decodeObjectForKey: @"name"];
    if (_name == nil)
      self.name = @"";
    self.autoDiscovery = [decoder decodeBoolForKey: @"autoDiscovery"];
    self.wasAutoDiscovery = [decoder decodeBoolForKey: @"wasAutoDiscovery"];
    self.multicastAddress = [decoder decodeObjectForKey: @"multicastAddress"];
    if (_multicastAddress == nil)
      self.multicastAddress = @"239.255.16.90";
    self.multicastPort = [decoder decodeIntegerForKey: @"multicastPort"];
    if (_multicastPort == 0)
      self.multicastPort = 8000;
    self.directAddress = [decoder decodeObjectForKey: @"directAddress"];
    if (_directAddress == nil)
      self.directAddress = @"";
    self.directPort = [decoder decodeIntegerForKey: @"directPort"];
    if (_directPort == 0)
      _directPort = 80;
    _state = [[decoder decodeObjectForKey: @"state"] mutableCopy];
    if (_state == nil)
      self.state = [NSMutableArray arrayWithCapacity: 5];    
    self.staticMenuRoom = [decoder decodeObjectForKey: @"staticMenuRoom"];
    if (_staticMenuRoom == nil)
      self.staticMenuRoom = @"iPod Settings";
    self.titleBarMacro = [decoder decodeObjectForKey: @"titleBarMacro"];
    if (_titleBarMacro == nil)
      self.titleBarMacro = @"";
    self.buttonRows = [decoder decodeIntegerForKey: @"buttonRows"];
    self.buttonsPerRow = [decoder decodeIntegerForKey: @"buttonsPerRow"];
    self.artworkURL = [decoder decodeObjectForKey: @"artworkURL"];
    if (_artworkURL == nil)
      self.artworkURL = @"";
    self.skinURL = [decoder decodeObjectForKey: @"skinURL"];
    if (_skinURL == nil)
      self.skinURL = @"";
  }
  
  return self;
}

- (void) encodeWithCoder: (NSCoder *) encoder
{
  [encoder encodeObject: self.name forKey: @"name"];
  [encoder encodeBool: self.autoDiscovery forKey: @"autoDiscovery"];
  [encoder encodeBool: self.wasAutoDiscovery forKey: @"wasAutoDiscovery"];
  [encoder encodeObject: self.multicastAddress forKey: @"multicastAddress"];
  [encoder encodeInteger: self.multicastPort forKey: @"multicastPort"];
  [encoder encodeObject: self.directAddress forKey: @"directAddress"];
  [encoder encodeInteger: self.directPort forKey: @"directPort"];
  [encoder encodeObject: self.state forKey: @"state"];
  [encoder encodeObject: self.staticMenuRoom forKey: @"staticMenuRoom"];
  [encoder encodeObject: self.titleBarMacro forKey: @"titleBarMacro"];
  [encoder encodeInteger: self.buttonRows forKey: @"buttonRows"];
  [encoder encodeInteger: self.buttonsPerRow forKey: @"buttonsPerRow"];
  [encoder encodeObject: self.artworkURL forKey: @"artworkURL"];
  [encoder encodeObject: self.skinURL forKey: @"skinURL"];
}

- (BOOL) isEqual: (id) object
{
  BOOL equal = (object == self);
  
  if (!equal)
  {
    equal = ([object class] == [self class]);
  
    if (equal)
    {
      // N.B. state is deliberately excluded from the comparison as it 
      // is irrelevant for whether profiles are essentially the same
      // because it is a transient value

      ConfigProfile *other = (ConfigProfile *) object;
      
      equal = (other.autoDiscovery == _autoDiscovery) &&
      (other.wasAutoDiscovery == _wasAutoDiscovery) &&
      (other.multicastPort == _multicastPort) &&
      (other.directPort == _directPort) &&
      [_name isEqualToString: other.name] &&
      [_multicastAddress isEqualToString: other.multicastAddress] &&
      [_directAddress isEqualToString: other.directAddress] &&
      [_staticMenuRoom isEqualToString: other.staticMenuRoom] &&
      [_titleBarMacro isEqualToString: other.titleBarMacro] &&
      other.buttonRows == _buttonRows &&
      other.buttonsPerRow == _buttonsPerRow &&
      [_artworkURL isEqualToString: other.artworkURL] &&
      [_skinURL isEqualToString: other.skinURL];
    }
  }
  
  return equal;
}

- (NSUInteger) hash
{
  return _multicastPort + (_directPort << 1) + [_name hash] + [_multicastAddress hash] +
  [_directAddress hash] + [_staticMenuRoom hash] + [_titleBarMacro hash] + 
  +_buttonRows + _buttonsPerRow + [_artworkURL hash] +
  [_skinURL hash] + (_autoDiscovery?2:3);
}

- (id) copyWithZone: (NSZone *) zone
{
  ConfigProfile *copy;

  if (zone != nil)
    copy = [self retain];
  else
  {
    NSMutableArray *copyState = [_state mutableCopy];

    copy = [ConfigProfile alloc];
    copy.name = _name;
    copy.autoDiscovery = _autoDiscovery;
    copy.wasAutoDiscovery = _wasAutoDiscovery;
    copy.multicastAddress = _multicastAddress;
    copy.multicastPort = _multicastPort;
    copy.directAddress = _directAddress;
    copy.directPort = _directPort;
    copy.state = copyState;
    [copyState release];
    copy.staticMenuRoom = _staticMenuRoom;
    copy.titleBarMacro = _titleBarMacro;
    copy.buttonRows = _buttonRows;
    copy.buttonsPerRow = _buttonsPerRow;
    copy.artworkURL = _artworkURL;
    copy.skinURL = _skinURL;
  }

  return copy;
}

- (id) mutableCopyWithZone: (NSZone *) zone
{
  return [self copyWithZone: zone];
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"%@: {\n  name: %@\n  autoDiscovery: %@\n  multicastAddress: %@\n  multicastPort: %d\n"
		      "  directAddress: %@\n directPort: %d\n  state: %@\n  staticMenuRoom: %@\n  titleBarMacro: %@\n"
		      "  buttonRows: %d\n  buttonsPerRow: %d\n  artworkURL: %@\n  skinURL: %@\n}",
          [super description], _name, (_autoDiscovery?@"YES":@"NO"),
          _multicastAddress, _multicastPort,
          _directAddress, _directPort,
          _state,
          _staticMenuRoom, _titleBarMacro, _buttonRows, _buttonsPerRow, _artworkURL, _skinURL];
}

- (void) dealloc
{
  [_name release];
  [_multicastAddress release];
  [_directAddress release];
  [_state release];
  [_staticMenuRoom release];
  [_titleBarMacro release];
  [_artworkURL release];
  [_resolvedArtworkURL release];
  [_skinURL release];
  [_resolvedSkinURL release];
  [super dealloc];
}

@end
