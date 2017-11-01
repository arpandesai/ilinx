//
//  NLSourceMediaServerNetStreams.h
//  iLinX
//
//  Created by mcf on 19/10/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLSourceMediaServer.h"
#import "NetStreamsComms.h"

@interface NLSourceMediaServerNetStreams : NLSourceMediaServer <NetStreamsMsgDelegate, NSXMLParserDelegate>
{
@private
  id _statusRspHandle;
  id _registerMsgHandle;
  NLBrowseList *_browseMenu;
  NSUInteger _debounceShuffle;
  NSString *_extendedURL;
  NSURLConnection *_extendedConnection;
  NSMutableData *_extendedData;
  NSDictionary *_metadata;
}

@end
