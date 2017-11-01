/*
*/

#import <UIKit/UIKit.h>
#import "NetStreamsComms.h"
#import "GuiXmlParser.h"

@interface NetStreamsDataController : NSObject <NetStreamsCommsDelegate, GuiXmlDelegate>
{
  NSMutableArray *_locationList;
  NSInteger _currentLocation;
  NSInteger _currentSource;
  BOOL _discoveryInProgress;
  NetStreamsComms *_netStreamsComms;
  NSString *_multicastIp;
  uint16_t _multicastPort;
  NSString *_defaultHost;
  NSString *_lastLocation;
  NSTimer *_currentStatusTimer;
  BOOL _trackingSources;
}

@property (nonatomic, retain) NetStreamsComms *netStreamsComms;

// Locations information
- (void) discoverLocations;
- (BOOL) locationDiscoveryIsComplete;
- (unsigned) countOfLocations;
- (NSString *) titleForCurrentLocation;
- (NSString *) titleForLocationAtIndex: (unsigned) index;
- (BOOL) locationIsSelectedAtIndex: (unsigned) index;
- (void) selectLocationAtIndex: (unsigned) index;
- (BOOL) locationIsSelectableAtIndex: (unsigned) index;

// Services information for current location
- (unsigned) countOfServices;
- (id) serviceAtIndex: (unsigned) theIndex;
- (NSString *) titleForServiceAtIndex: (unsigned) theIndex;

// Sources information for current location
- (unsigned) countOfSources;
- (id) sourceAtIndex: (unsigned) theIndex;
- (NSString *) titleForSourceAtIndex: (unsigned) theIndex;
- (BOOL) sourceIsSelectedAtIndex: (unsigned) index;
- (void) selectSourceAtIndex: (unsigned) index;
- (id) currentSource;
- (NSString *) titleForCurrentSource;

// Direct connection
- (void) connectToLocation: (NSString *) location;
- (void) connectToLocation: (NSString *) location defaultHost: (NSString *) host;
- (void) disconnectFromLocation;
- (NSString *) connectedHost;

@end
