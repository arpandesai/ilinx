//
//  NLBrowseListITunesWaiting.m
//  iLinX
//
//  Created by mcf on 18/11/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "NLBrowseListITunesWaiting.h"
#import "NLBrowseListITunesType.h"
#import "DebugTracing.h"
#import "ITSession.h"
#import "WeakReference.h"

@interface NLBrowseListITunesWaiting ()

- (void) statusCheckTimerFired: (NSTimer *) timer;

@end

@interface NLWaitingListReference : NSDebugObject
{
@private
  WeakReference *_waitingList;
}

- (id) initWithWaitingList: (NLBrowseListITunesWaiting *) waitingList;
- (void) timerFired: (NSTimer *) timer;

@end

@implementation NLWaitingListReference

- (id) initWithWaitingList: (NLBrowseListITunesWaiting *) waitingList
{
  if ((self = [super init]) != nil)
    _waitingList = [[WeakReference weakReferenceForObject: waitingList] retain];
  
  return self;
}

- (void) timerFired: (NSTimer *) timer
{
  [(NLBrowseListITunesWaiting *) [_waitingList referencedObject] statusCheckTimerFired: timer];
}

- (void) dealloc
{
  [_waitingList release];
  [super dealloc];
}

@end

@implementation NLBrowseListITunesWaiting

- (id) initWithSource: (NLSource *) source session: (ITSession *) session
{
  NLBrowseListITunesType *type = [NLBrowseListITunesType allocTypeDataForType: @"Connecting" session: session parentFilter: nil
                                                                          item: [NSDictionary dictionary]];
  NLWaitingListReference *timerTarget = [[NLWaitingListReference alloc] initWithWaitingList: self];
  
  self = [super initWithSource: source title: NSLocalizedString( @"Connecting",
                                                                @"Title of special item showing we are connecting to iTunes" )
                       session: session items: [NSMutableArray array] type: type];
  [type release];
  _pendingMessage = [[session errorMessage] retain];
  _statusCheckTimer = [NSTimer scheduledTimerWithTimeInterval: 1 target: timerTarget selector: @selector(timerFired:) 
                                                     userInfo: nil repeats: YES];
  [timerTarget release];

  return self;
}

- (BOOL) dataPending
{
  return [_session isPending];
}

- (NSString *) pendingMessage
{
  return _pendingMessage;
}

- (void) statusCheckTimerFired: (NSTimer *) timer
{
  NSString *errorMessage = [_session errorMessage];
  
  if (![errorMessage isEqualToString: _pendingMessage])
  {
    NSSet *delegates = [NSSet setWithSet: _listDataDelegates];
    NSEnumerator *enumerator = [delegates objectEnumerator];
    id<ListDataDelegate> delegate;

    [_pendingMessage release];
    _pendingMessage = [errorMessage retain];
    
    while ((delegate = [enumerator nextObject]))
    {
      if ([delegate respondsToSelector: @selector(itemsChangedInListData:range:)])
        [delegate itemsChangedInListData: self range: NSMakeRange( 0, 0 )];
    }
  }
}

- (void) dealloc
{
  [_pendingMessage release];
  [_statusCheckTimer invalidate];
  [super dealloc];
}

@end
