/*
*/

#import <UIKit/UIKit.h>
#import "NetStreamsComms.h"
#import "GuiXmlParser.h"
#import "NLListDataSource.h"

@class NLRoom;

// Protocol implemented by objects that want to receive requests from 
// DigiLinX to display a pop-up UI message
@protocol NLPopupMessageDelegate <NSObject>

- (void) receivedPopupMessage: (NSString *) message timeout: (NSTimeInterval) timeout;

@end

@interface NLRoomList : NLListDataSource <NetStreamsCommsDelegate, NetStreamsMsgDelegate, GuiXmlDelegate>
{
  NSArray *_specialEntries;
  NSMutableArray *_roomList;
  BOOL _discoveryInProgress;
  NetStreamsComms *_netStreamsComms;
  NSString *_defaultHost;
  NSUInteger _defaultPort;
  NLRoom *_currentRoom;
  NSUInteger _inUseCount;
  NSError *_lastError;
  id _uiMessageDelegate;
  NSMutableSet *_popupMessageDelegates;
  NSOperationQueue *_opQueue;
}

@property (nonatomic, retain) NetStreamsComms *netStreamsComms;

@property (readonly) NLRoom *currentRoom;
@property (readonly) NSError *lastError;

// Direct connection
- (void) connectToRoom: (NSString *) roomServiceName;
- (void) connectToRoom: (NSString *) roomServiceName defaultHost: (NSString *) host port: (NSUInteger) port;
- (NSString *) connectedHost;
- (NSUInteger) connectedPort;

// Reset the current item in the list to be the current room
- (void) resetCurrentItemToCurrentRoom;

- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects;

// Interface for registering to be a popup message delegate
- (void) addPopupMessageDelegate: (id<NLPopupMessageDelegate>) delegate;
- (void) removePopupMessageDelegate: (id<NLPopupMessageDelegate>) delegate;

@end
