//
//  NLBrowseListITunes.h
//  iLinX
//
//  Created by mcf on 04/11/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ITRequest.h"
#import "ITStatus.h"
#import "NLBrowseList.h"

@class ITSession;
@class ITURLConnection;
@class NLBrowseListITunesType;

@interface NLBrowseListITunes : NLBrowseList <ITRequestDelegate, ITStatusDelegate>
{
@protected
  ITSession *_session;
  ITURLConnection *_conn;
  NSMutableDictionary *_pendingCalls;
  NSTimer *_loadListTimer;
  NLBrowseListITunesType *_type;
  NSArray *_items;
  NSMutableArray *_sectionTitles;
  NSMutableArray *_sectionLengths;
  NSMutableArray *_sectionOffsets;
}

- (id) initWithSource: (NLSource *) source title: (NSString *) title
              session: (ITSession *) session;
- (id) initWithSource: (NLSource *) source title: (NSString *) title
              session: (ITSession *) session items: (NSMutableArray *) items
                 type: (NLBrowseListITunesType *) type;
- (id) initWithSource: (NLSource *) source title: (NSString *) title
              session: (ITSession *) session type: (NLBrowseListITunesType *) type;

// For inheriting classes to implement

- (void) loadList;

@end
