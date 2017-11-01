//
//  ITRemoteService.h
//  iLinX
//
//  Created by mcf on 21/10/2009.
//  Copyright 2011 Janus Technology Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ITRemoteService : NSNetService <NSNetServiceDelegate>
{
@public
  NSUInteger _serviceMagic;
@private
  CFSocketRef _ipv4socket;
  NSMutableSet *_pairingRequests;
}

- (id) init;

@end
