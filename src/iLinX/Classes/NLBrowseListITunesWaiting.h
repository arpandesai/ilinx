//
//  NLBrowseListITunesWaiting.h
//  iLinX
//
//  Created by mcf on 18/11/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLBrowseListITunes.h"

@interface NLBrowseListITunesWaiting : NLBrowseListITunes
{
@private
  NSString *_pendingMessage;
  NSTimer *_statusCheckTimer;
}

- (id) initWithSource: (NLSource *) source session: (ITSession *) session;

@end
