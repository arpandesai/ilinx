//
//  NLBrowseListNetStreams.h
//  iLinX
//
//  Created by mcf on 06/11/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLBrowseList.h"
#import "NLListDataSource.h"
#import "NetStreamsComms.h"

#define ADD_ALL_SONGS_NO            0
#define ADD_ALL_SONGS_CHILDREN_ONLY 1
#define ADD_ALL_SONGS_YES           2

// Internal data structure used by NLBrowseList and its inheriting classes

@interface DataRequest : NSObject
{
  BOOL _isAlphaRequest;
  NSRange _range;
  NSUInteger _subBlockSize;
  NSUInteger _remaining;
  NSUInteger _pending;
  BOOL _changed;
}

@property (assign) BOOL isAlphaRequest;
@property (assign) NSRange range;
@property (assign) NSUInteger subBlockSize;
@property (assign) NSUInteger remaining;
@property (assign) NSUInteger pending;
@property (assign) BOOL changed;

+ (DataRequest *) dataRequestWithRange: (NSRange) range subBlockSize: (NSUInteger) subBlockSize;
+ (DataRequest *) dataRequestForLetter: (unichar) letter;

@end

@class NaimVersionHandler;

@interface NLBrowseListNetStreams : NLBrowseList <NetStreamsMsgDelegate>
{
@protected
  NSString *_rootPath;
  NSUInteger _menuLevel;
  NSUInteger _addAllSongs;
  NSInteger _listOffset;
  NetStreamsComms *_netStreamsComms;
  NSMutableDictionary *_content;
  NSMutableArray *_sectionData;
  NSUInteger _indexedSections;
  NSTimer *_indexRequestDelayTimer;
  NSMutableArray *_pendingRequests;
  DataRequest *_bogusResponse;
  NSUInteger _count;
  NSUInteger _originalCount;
  NSString *_lastKey;
  id _menuRspHandle;
  id _currentMessageHandle;
  NSUInteger _listType;
  NSUInteger _highestIndexSoFar;
  BOOL _doRefreshWhenRequestComplete;
  NSString *_noItemsCaption;
  BOOL _isVTuner;
  NaimVersionHandler *_naimVersionHandler;
  NSTimer *_metadataTimer;
}

- (id) initWithSource: (NLSource *) source title: (NSString *) title 
                 path: (NSString *) rootPath listCount: (NSUInteger) count 
          addAllSongs: (NSUInteger) addAllSongs comms: (NetStreamsComms *) comms;

// For inheriting classes only
@property (nonatomic, retain) NSString *lastKey;

+ (NSArray *) emptyBlock;
- (void) reinit;
- (void) registerForData;
- (NSMutableArray *) blockForIndex: (NSUInteger) index;
- (NSMutableArray *) blockForIndex: (NSUInteger) index prioritised: (BOOL) prioritised;
- (void) handleListResponse: (NSDictionary *) data forRequest: (DataRequest *) currentRequest;

@end
