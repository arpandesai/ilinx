//
//  ConfigProfile.h
//  iLinX
//
//  Created by mcf on 27/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ConfigProfile : NSObject <NSCoding, NSCopying, NSMutableCopying>
{
@private
  NSString *_name;
  BOOL _autoDiscovery;
  BOOL _wasAutoDiscovery;
  NSString *_multicastAddress;
  NSInteger _multicastPort;
  NSString *_directAddress;
  NSInteger _directPort;
  NSMutableArray *_state;
  NSString *_staticMenuRoom;
  NSString *_titleBarMacro;
  NSString *_artworkURL;
  NSInteger _buttonRows;
  NSInteger _buttonsPerRow;
  NSURL *_resolvedArtworkURL;
  NSString *_skinURL;
  NSURL *_resolvedSkinURL;
}

@property (nonatomic, retain) NSString *name;
@property (assign) BOOL autoDiscovery;
@property (assign) BOOL wasAutoDiscovery;
@property (nonatomic, retain) NSString *multicastAddress;
@property (assign) NSInteger multicastPort;
@property (nonatomic, retain) NSString *directAddress;
@property (assign) NSInteger directPort;
@property (nonatomic, retain) NSMutableArray *state;
@property (nonatomic, retain) NSString *staticMenuRoom;
@property (nonatomic, retain) NSString *titleBarMacro;
@property (nonatomic, retain) NSString *artworkURL;
@property (readonly) NSURL *resolvedArtworkURL;
@property (nonatomic, retain) NSString *skinURL;
@property (assign) NSInteger buttonRows;
@property (assign) NSInteger buttonsPerRow;
@property (readonly) NSURL *resolvedSkinURL;

- (id) initWithOldSettings;
- (NSString *) jsonStringForStatus: (NSUInteger) statusMask withObjects: (BOOL) withObjects;

@end
