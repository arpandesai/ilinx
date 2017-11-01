//
//  NLServiceHVAC.h
//  iLinX
//
//  Created by mcf on 13/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetStreamsComms.h"
#import "NLService.h"

#define SERVICE_HVAC_OUTSIDE_TEMP_CHANGED     0x0001
#define SERVICE_HVAC_OUTSIDE_HUMIDITY_CHANGED 0x0002
#define SERVICE_HVAC_ZONE_TEMP_CHANGED        0x0004
#define SERVICE_HVAC_ZONE_HUMIDITY_CHANGED    0x0008
#define SERVICE_HVAC_CURRENT_SETPOINT_CHANGED 0x0010
#define SERVICE_HVAC_HEAT_SETPOINT_CHANGED    0x0020
#define SERVICE_HVAC_COOL_SETPOINT_CHANGED    0x0040
#define SERVICE_HVAC_TEMP_SCALE_CHANGED       0x0080
#define SERVICE_HVAC_MODES_CHANGED            0x0100
#define SERVICE_HVAC_MODE_TITLES_CHANGED      0x0200
#define SERVICE_HVAC_MODE_STATES_CHANGED      0x0400
#define SERVICE_HVAC_STATE_HEADER_CHANGED     0x0800
#define SERVICE_HVAC_STATE_LINE1_CHANGED      0x1000
#define SERVICE_HVAC_STATE_LINE2_CHANGED      0x2000
#define SERVICE_HVAC_STATE_LINE2I_CHANGED     0x4000
#define SERVICE_HVAC_SHOW_ICON_CHANGED        0x8000

@class NLServiceHVAC;

@protocol NLServiceHVACDelegate <NSObject>
@optional
- (void) service: (NLServiceHVAC *) service changed: (NSUInteger) changed;
- (void) service: (NLServiceHVAC *) service controlMode: (NSUInteger) controlMode
          button: (NSUInteger) button changed: (NSUInteger) changed;
@end

// Capabilities
#define SERVICE_HVAC_HAS_COOLING              0x0001
#define SERVICE_HVAC_HAS_INDOOR_HUMIDITY      0x0002
#define SERVICE_HVAC_HAS_OUTDOOR_TEMP         0x0004
#define SERVICE_HVAC_HAS_OUTDOOR_HUMIDITY     0x0008


@interface NLServiceHVAC : NLService <NetStreamsMsgDelegate>
{
@protected
  NSMutableSet *_delegates;
  NSUInteger _capabilities;
  NSString *_outsideTemperature;
  NSString *_outsideHumidity;
  NSString *_zoneTemperature;
  NSString *_zoneHumidity;
  NSString *_currentSetPointTemperature;
  NSString *_heatSetPointTemperature;
  NSString *_coolSetPointTemperature;
  NSString *_temperatureScale;
  NSString *_temperatureScaleRaw;
  NSArray *_controlModes;
  NSMutableArray *_controlModeTitles;
  NSMutableArray *_controlModeStates;
  NSString *_currentStateHeader;
  NSString *_currentStateLine1;
  NSString *_currentStateLine2WithIcon;
  NSString *_currentStateLine2NoIcon;
  BOOL _showIcon;
  NSUInteger _pendingUpdates;
  id _statusRspHandle;
  id _registerMsgHandle;
  id _queryMsgHandle;
}

@property (readonly) NSUInteger capabilities;
@property (readonly) NSString *outsideTemperature;
@property (readonly) NSString *outsideHumidity;
@property (readonly) NSString *zoneTemperature;
@property (readonly) NSString *zoneHumidity;
@property (readonly) NSString *currentSetPointTemperature;
@property (readonly) NSString *heatSetPointTemperature;
@property (readonly) NSString *coolSetPointTemperature;
@property (readonly) NSString *temperatureScale;
@property (readonly) NSArray *controlModes;
@property (readonly) NSArray *controlModeTitles;
@property (readonly) NSArray *controlModeStates;
@property (readonly) NSString *currentStateHeader;
@property (readonly) NSString *currentStateLine1;
@property (readonly) NSString *currentStateLine2WithIcon;
@property (readonly) NSString *currentStateLine2NoIcon;
@property (readonly) BOOL showIcon;

- (void) addDelegate: (id<NLServiceHVACDelegate>) delegate;
- (void) removeDelegate: (id<NLServiceHVACDelegate>) delegate;

- (NSUInteger) buttonCountInControlMode: (NSUInteger) controlMode;
- (NSString *) nameForButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode;
- (BOOL) indicatorPresentOnButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode;
- (BOOL) indicatorStateForButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode;
- (void) pushButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode;
- (void) releaseButton: (NSUInteger) buttonIndex inControlMode: (NSUInteger) controlMode;
- (CGFloat) heatSetPointMin;
- (CGFloat) heatSetPointMax;
- (CGFloat) heatSetPointStep;
- (void) setHeatSetPoint: (CGFloat) setPoint;
- (void) raiseHeatSetPoint;
- (void) lowerHeatSetPoint;
- (CGFloat) coolSetPointMin;
- (CGFloat) coolSetPointMax;
- (CGFloat) coolSetPointStep;
- (void) setCoolSetPoint: (CGFloat) setPoint;
- (void) raiseCoolSetPoint;
- (void) lowerCoolSetPoint;

// Used by derived classes
- (void) notifyDelegates: (NSUInteger) changed;
- (void) notifyDelegatesOfButton: (NSUInteger) button inControlMode: (NSUInteger) controlMode changed: (NSUInteger) changed;
- (void) registerForNetStreams;
- (void) registerQueryStatus;
- (void) deregisterFromNetStreams;
- (void) deregisterQueryStatus;


@end
