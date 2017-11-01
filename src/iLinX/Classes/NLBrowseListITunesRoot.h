//
//  NLBrowseListITunesRoot.h
//  iLinX
//
//  Created by mcf on 05/11/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ITRequest.h"
#import "NLBrowseListITunes.h"
#import "NLSourceMediaServer.h"

@class ITURLConnection;

@interface NLBrowseListITunesRoot : NLBrowseListITunes
{
}

- (id) initWithSource: (NLSource *) source title: (NSString *) title
              session: (ITSession *) session;

@end
